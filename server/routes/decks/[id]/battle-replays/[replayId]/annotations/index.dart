import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

import '../../../../../../lib/battle/battle_replay_annotation_service.dart';
import '../../../../../../lib/battle/battle_replay_read_service.dart';
import '../../../../../../lib/http_responses.dart';
import '../../../../../../lib/logger.dart';
import '../../../../../../lib/observability.dart';

const _maximumAnnotationBodyBytes = 16 * 1024;

Future<Response> onRequest(
  RequestContext context,
  String deckId,
  String replayId,
) async {
  if (!isBattleReplayUuid(deckId)) {
    return notFound('Deck nao encontrado.');
  }
  if (!isBattleReplayUuid(replayId)) {
    return notFound('Replay nao encontrado.');
  }

  if (context.request.method == HttpMethod.get) {
    return _list(context, deckId: deckId, replayId: replayId);
  }
  if (context.request.method == HttpMethod.post) {
    return _create(context, deckId: deckId, replayId: replayId);
  }
  return methodNotAllowed();
}

Future<Response> _list(
  RequestContext context, {
  required String deckId,
  required String replayId,
}) async {
  final service = BattleReplayAnnotationService(context.read<Pool>());
  try {
    final annotations = await service.list(
      userId: context.read<String>(),
      deckId: deckId,
      replayId: replayId,
      limit: _limit(context.request.uri.queryParameters['limit']),
    );
    return Response.json(
      body: {
        'schema_version': battleReplayAnnotationSchema,
        'data': annotations,
        'immutable_replay': true,
      },
    );
  } catch (error, stackTrace) {
    Log.e('[battle-annotations] list failed type=${error.runtimeType}');
    await captureRouteException(
      context,
      StateError('Battle annotation list failed'),
      stackTrace: stackTrace,
      tags: {
        'route': 'battle_replay_annotations_list',
        'error_type': '${error.runtimeType}',
      },
    );
    return internalServerError('Falha ao carregar anotacoes do replay');
  }
}

Future<Response> _create(
  RequestContext context, {
  required String deckId,
  required String replayId,
}) async {
  final bodyText = await context.request.body();
  if (utf8.encode(bodyText).length > _maximumAnnotationBodyBytes) {
    return Response.json(
      statusCode: HttpStatus.requestEntityTooLarge,
      body: {
        'error': 'battle_annotation_body_too_large',
        'message': 'A anotacao excede o limite permitido.',
      },
    );
  }

  late final Map<String, dynamic> body;
  try {
    final decoded = jsonDecode(bodyText);
    if (decoded is! Map) throw const FormatException();
    body = decoded.map((key, value) => MapEntry(key.toString(), value));
  } on FormatException {
    return badRequest('JSON invalido.');
  }

  final headerKey = _header(context.request.headers, 'idempotency-key');
  final bodyKey = body['idempotency_key'];
  final idempotencyKey = headerKey ?? (bodyKey is String ? bodyKey.trim() : '');
  final service = BattleReplayAnnotationService(context.read<Pool>());

  try {
    final outcome = await service.create(
      userId: context.read<String>(),
      deckId: deckId,
      replayId: replayId,
      idempotencyKey: idempotencyKey,
      body: body,
    );
    return Response.json(
      statusCode: outcome.created ? HttpStatus.created : HttpStatus.ok,
      body: {'annotation': outcome.annotation, 'created': outcome.created},
    );
  } on BattleReplayAnnotationValidationException catch (error) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'error': 'invalid_battle_annotation', 'message': error.message},
    );
  } on BattleReplayAnnotationNotFoundException {
    return notFound('Replay nao encontrado.');
  } on BattleReplayAnnotationRevisionUnavailableException {
    return Response.json(
      statusCode: HttpStatus.conflict,
      body: {
        'error': 'battle_replay_revision_unavailable',
        'message':
            'Este replay nao possui uma revisao de deck compativel para anotacao.',
      },
    );
  } on BattleReplayAnnotationIdempotencyConflictException {
    return Response.json(
      statusCode: HttpStatus.conflict,
      body: {
        'error': 'battle_annotation_idempotency_conflict',
        'message': 'A chave de idempotencia ja foi usada por outra anotacao.',
      },
    );
  } on BattleReplayAnnotationAlreadyRecordedException {
    return Response.json(
      statusCode: HttpStatus.conflict,
      body: {
        'error': 'battle_annotation_already_recorded',
        'message': 'Esta escolha imutavel ja foi registrada.',
      },
    );
  } catch (error, stackTrace) {
    Log.e('[battle-annotations] create failed type=${error.runtimeType}');
    await captureRouteException(
      context,
      StateError('Battle annotation create failed'),
      stackTrace: stackTrace,
      tags: {
        'route': 'battle_replay_annotations_create',
        'error_type': '${error.runtimeType}',
      },
    );
    return internalServerError('Falha ao salvar anotacao do replay');
  }
}

int _limit(String? raw) => (int.tryParse(raw ?? '') ?? 50).clamp(1, 100);

String? _header(Map<String, String> headers, String name) {
  final normalized = name.toLowerCase();
  for (final entry in headers.entries) {
    if (entry.key.toLowerCase() == normalized) return entry.value.trim();
  }
  return null;
}
