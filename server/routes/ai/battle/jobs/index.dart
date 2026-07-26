import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

import '../../../../lib/battle/battle_job_contract.dart';
import '../../../../lib/battle/battle_job_service.dart';
import '../../../../lib/battle/battle_job_store.dart';
import '../../../../lib/http_responses.dart';
import '../../../../lib/logger.dart';
import '../../../../lib/observability.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method == HttpMethod.get) {
    return _list(context);
  }
  if (context.request.method == HttpMethod.post) {
    return _create(context);
  }
  return methodNotAllowed();
}

Future<Response> _list(RequestContext context) async {
  try {
    final filter = parseBattleJobListFilter(
      context.request.uri.queryParameters,
    );
    final service = BattleJobService(
      BattleJobStore(context.read<Pool>()),
      quotaPolicy: BattleJobQuotaPolicy.fromEnvironment(Platform.environment),
    );
    final jobs = await service.list(context.read<String>(), filter: filter);
    return Response.json(
      body: {
        'schema_version': battleJobListSchemaVersion,
        'jobs': jobs.map((job) => job.toJson()).toList(growable: false),
      },
    );
  } on BattleJobValidationException catch (error) {
    return _unprocessable(error);
  } catch (error, stackTrace) {
    Log.e('[battle-jobs] list failed type=${error.runtimeType}');
    await _capture(context, error, stackTrace, operation: 'list');
    return internalServerError('Falha ao consultar Battle jobs.');
  }
}

Future<Response> _create(RequestContext context) async {
  final declaredLength = int.tryParse(
    _header(context.request.headers, 'content-length') ?? '',
  );
  if (declaredLength != null && declaredLength > battleJobMaximumBodyBytes) {
    return _bodyTooLarge();
  }

  final bodyText = await context.request.body();
  if (utf8.encode(bodyText).length > battleJobMaximumBodyBytes) {
    return _bodyTooLarge();
  }

  late final Map<String, dynamic> body;
  try {
    final decoded = jsonDecode(bodyText);
    if (decoded is! Map) throw const FormatException();
    body = decoded.map((key, value) => MapEntry(key.toString(), value));
  } on FormatException {
    return Response.json(
      statusCode: HttpStatus.unprocessableEntity,
      body: {
        'error': 'battle_job_json_invalid',
        'message': 'O corpo precisa ser um objeto JSON valido.',
      },
    );
  }

  try {
    final input = BattleJobCreateInput.parse(
      body,
      headerIdempotencyKey: _header(context.request.headers, 'idempotency-key'),
    );
    final service = BattleJobService(
      BattleJobStore(context.read<Pool>()),
      quotaPolicy: BattleJobQuotaPolicy.fromEnvironment(Platform.environment),
    );
    final result = await service.create(
      userId: context.read<String>(),
      input: input,
    );
    return Response.json(
      statusCode: result.created ? HttpStatus.created : HttpStatus.ok,
      body: {'job': result.job.toJson(), 'created': result.created},
    );
  } on BattleJobValidationException catch (error) {
    return _unprocessable(error);
  } on BattleJobNotFoundException {
    return notFound('Deck ou oponente nao encontrado.');
  } on BattleJobIdempotencyConflictException {
    return Response.json(
      statusCode: HttpStatus.conflict,
      body: {
        'error': 'battle_job_idempotency_conflict',
        'message':
            'A chave de idempotencia ja foi usada para outro Battle job.',
      },
    );
  } on BattleJobQuotaExceededException catch (error) {
    return Response.json(
      statusCode: HttpStatus.tooManyRequests,
      headers: {'Retry-After': '${error.retryAfterSeconds}'},
      body: {
        'error': 'battle_job_quota_exceeded',
        'scope': error.scope,
        'limit': error.limit,
        'retry_after_seconds': error.retryAfterSeconds,
      },
    );
  } catch (error, stackTrace) {
    Log.e('[battle-jobs] create failed type=${error.runtimeType}');
    await _capture(context, error, stackTrace, operation: 'create');
    return internalServerError('Falha ao criar Battle job.');
  }
}

Response _unprocessable(BattleJobValidationException error) => Response.json(
  statusCode: HttpStatus.unprocessableEntity,
  body: {'error': error.code, 'message': error.message},
);

Response _bodyTooLarge() => Response.json(
  statusCode: HttpStatus.requestEntityTooLarge,
  body: {
    'error': 'battle_job_body_too_large',
    'message': 'O pedido excede o limite de 64 KiB.',
  },
);

String? _header(Map<String, String> headers, String name) {
  final normalized = name.toLowerCase();
  for (final entry in headers.entries) {
    if (entry.key.toLowerCase() == normalized) return entry.value.trim();
  }
  return null;
}

Future<void> _capture(
  RequestContext context,
  Object error,
  StackTrace stackTrace, {
  required String operation,
}) {
  return captureRouteException(
    context,
    StateError('Battle job $operation failed'),
    stackTrace: stackTrace,
    tags: {
      'route': 'ai_battle_jobs',
      'operation': operation,
      'error_type': '${error.runtimeType}',
    },
  );
}
