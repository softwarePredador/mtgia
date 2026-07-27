import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

import '../../../../lib/battle/interactive_battle_contract.dart';
import '../../../../lib/battle/interactive_battle_request_scope.dart';
import '../../../../lib/battle/interactive_battle_runtime_client.dart';
import '../../../../lib/battle/interactive_battle_service.dart';
import '../../../../lib/battle/interactive_battle_store.dart';
import '../../../../lib/http_responses.dart';
import '../../../../lib/logger.dart';
import '../../../../lib/observability.dart';

const _noStore = <String, String>{'Cache-Control': 'no-store'};

Future<Response> onRequest(RequestContext context) async {
  if (!interactiveBattleFeatureEnabled(Platform.environment)) {
    return _notFound();
  }
  if (context.request.method == HttpMethod.get) return _list(context);
  if (context.request.method == HttpMethod.post) return _create(context);
  return methodNotAllowed();
}

Future<Response> _list(RequestContext context) async {
  final query = context.request.uri.queryParameters;
  if (query.keys.any((key) => !const {'limit', 'deck_id'}.contains(key))) {
    return _unprocessable(
      const InteractiveBattleValidationException(
        'interactive_battle_list_query_invalid',
        'A consulta contém um parâmetro não suportado.',
      ),
    );
  }
  final limit = int.tryParse(query['limit'] ?? '20');
  final deckId = query['deck_id']?.trim().toLowerCase();
  if (limit == null ||
      limit < 1 ||
      limit > 50 ||
      deckId != null && !interactiveBattleUuidPattern.hasMatch(deckId)) {
    return _unprocessable(
      const InteractiveBattleValidationException(
        'interactive_battle_list_query_invalid',
        'limit ou deck_id é inválido.',
      ),
    );
  }

  final scope = _scope(context);
  try {
    final sessions = await scope.service.list(
      context.read<String>(),
      limit: limit,
      deckId: deckId,
    );
    return Response.json(
      headers: _noStore,
      body: {
        'schema_version': interactiveBattleListSchema,
        'sessions': sessions
            .map((session) => session.toPrivateJson())
            .toList(growable: false),
      },
    );
  } catch (error, stackTrace) {
    await _capture(context, error, stackTrace, operation: 'list');
    return internalServerError('Falha ao consultar sessões interativas.');
  } finally {
    scope.close();
  }
}

Future<Response> _create(RequestContext context) async {
  final declaredLength = int.tryParse(
    _header(context.request.headers, 'content-length') ?? '',
  );
  if (declaredLength != null &&
      declaredLength > interactiveBattleMaximumBodyBytes) {
    return _tooLarge();
  }
  final text = await context.request.body();
  if (utf8.encode(text).length > interactiveBattleMaximumBodyBytes) {
    return _tooLarge();
  }
  late final Map<String, dynamic> body;
  try {
    final decoded = jsonDecode(text);
    if (decoded is! Map) throw const FormatException();
    body = decoded.map((key, value) => MapEntry(key.toString(), value));
  } on FormatException {
    return _unprocessable(
      const InteractiveBattleValidationException(
        'interactive_battle_json_invalid',
        'O corpo precisa ser um objeto JSON válido.',
      ),
    );
  }

  final scope = _scope(context);
  try {
    final input = InteractiveBattleCreateInput.parse(
      body,
      headerIdempotencyKey: _header(context.request.headers, 'idempotency-key'),
    );
    final result = await scope.service.create(
      userId: context.read<String>(),
      input: input,
    );
    return Response.json(
      statusCode: result.created ? HttpStatus.created : HttpStatus.ok,
      headers: _noStore,
      body: {
        'created': result.created,
        'session': result.session.toPrivateJson(),
      },
    );
  } on InteractiveBattleValidationException catch (error) {
    return _unprocessable(error);
  } on InteractiveBattleNotFoundException {
    return _notFound();
  } on InteractiveBattleIdempotencyConflictException {
    return _conflict('interactive_battle_idempotency_conflict');
  } on InteractiveBattleQuotaExceededException catch (error) {
    return Response.json(
      statusCode: HttpStatus.tooManyRequests,
      headers: {..._noStore, 'Retry-After': '15'},
      body: {
        'error': 'interactive_battle_quota_exceeded',
        'scope': error.scope,
        'limit': error.limit,
      },
    );
  } on InteractiveBattleStartException catch (error) {
    return Response.json(
      statusCode: HttpStatus.serviceUnavailable,
      headers: {..._noStore, 'Retry-After': '2'},
      body: {'error': error.code, 'session': error.session.toPrivateJson()},
    );
  } on InteractiveBattleRuntimeException catch (error) {
    return _runtimeFailure(error);
  } catch (error, stackTrace) {
    Log.e('[interactive-battle] create failed type=${error.runtimeType}');
    await _capture(context, error, stackTrace, operation: 'create');
    return internalServerError('Falha ao criar sessão interativa.');
  } finally {
    scope.close();
  }
}

InteractiveBattleRequestScope _scope(RequestContext context) =>
    InteractiveBattleRequestScope.open(
      context.read<Pool>(),
      Platform.environment,
    );

Response _unprocessable(InteractiveBattleValidationException error) =>
    Response.json(
      statusCode: HttpStatus.unprocessableEntity,
      headers: _noStore,
      body: {'error': error.code, 'message': error.message},
    );

Response _runtimeFailure(InteractiveBattleRuntimeException error) =>
    Response.json(
      statusCode:
          error.statusCode == HttpStatus.conflict
              ? HttpStatus.conflict
              : HttpStatus.serviceUnavailable,
      headers: {..._noStore, if (error.retryable) 'Retry-After': '2'},
      body: {'error': error.code},
    );

Response _conflict(String code) => Response.json(
  statusCode: HttpStatus.conflict,
  headers: _noStore,
  body: {'error': code},
);

Response _tooLarge() => Response.json(
  statusCode: HttpStatus.requestEntityTooLarge,
  headers: _noStore,
  body: {'error': 'interactive_battle_body_too_large'},
);

Response _notFound() => Response.json(
  statusCode: HttpStatus.notFound,
  headers: _noStore,
  body: {'error': 'interactive_battle_not_found'},
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
}) => captureRouteException(
  context,
  StateError('Interactive battle $operation failed'),
  stackTrace: stackTrace,
  tags: {
    'route': 'interactive_battle_sessions',
    'operation': operation,
    'error_type': '${error.runtimeType}',
  },
);
