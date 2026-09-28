import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

import '../../../../lib/analytics/activation_event_catalog.dart';
import '../../../../lib/auth_middleware.dart';
import '../../../../lib/decks/deck_trash_support.dart';
import '../../../../lib/http_responses.dart';

Future<Response> onRequest(RequestContext context) async {
  final method = context.request.method;
  if (method == HttpMethod.post) {
    return _postEvent(context);
  }
  if (method == HttpMethod.get) {
    return _getSummary(context);
  }
  return methodNotAllowed();
}

/// BT-KPI-001: grava só o que o catálogo `activation_events_v1` aceita
/// (`lib/analytics/activation_event_catalog.dart`). Evento fora do catálogo,
/// campo fora do esquema ou texto livre: 400, sem linha gravada. `deck_id`
/// de deck que não é do dono (ou está na lixeira): 404 `deck_not_found`.
/// A mesma chave de idempotência do mesmo usuário grava uma vez só: a
/// repetição responde 200 com `duplicate: true`.
Future<Response> _postEvent(RequestContext context) async {
  final userId = getUserId(context);
  final pool = context.read<Pool>();

  Object? body;
  try {
    body = await context.request.json();
  } catch (_) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body:
          const ActivationEventRejection(
            activationEventBodyInvalid,
            null,
            'JSON inválido.',
          ).toJson(),
    );
  }

  final validation = validateActivationEvent(body);
  final rejection = validation.rejection;
  if (rejection != null) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: rejection.toJson(),
    );
  }
  final event = validation.record!;

  try {
    if (event.deckId != null) {
      final owned = await pool.execute(
        Sql.named('''
          SELECT 1 FROM decks
          WHERE id = CAST(@deckId AS uuid)
            AND user_id = CAST(@userId AS uuid)
            AND deleted_at IS NULL
        '''),
        parameters: {'deckId': event.deckId, 'userId': userId},
      );
      if (owned.isEmpty) return deckNotFoundResponse();
    }

    final inserted = await pool.execute(
      Sql.named('''
        INSERT INTO activation_funnel_events (
          user_id, event_name, format, deck_id, source, metadata, dedupe_key
        ) VALUES (
          CAST(@userId AS uuid), @eventName, @format, CAST(@deckId AS uuid),
          @source, CAST(@metadata AS jsonb), @dedupeKey
        )
        ON CONFLICT (user_id, dedupe_key) WHERE dedupe_key IS NOT NULL
        DO NOTHING
        RETURNING id
      '''),
      parameters: {
        'userId': userId,
        'eventName': event.eventName,
        'format': event.format,
        'deckId': event.deckId,
        'source': event.source,
        'metadata': jsonEncode(event.metadata),
        'dedupeKey': event.dedupeKey,
      },
    );
    final duplicate = inserted.isEmpty;

    return Response.json(
      statusCode: duplicate ? HttpStatus.ok : HttpStatus.created,
      body: {
        'ok': true,
        'catalog_version': activationEventCatalogVersion,
        if (duplicate) 'duplicate': true,
        if (event.droppedFields.isNotEmpty)
          'dropped_fields': event.droppedFields,
      },
    );
  } catch (_) {
    return internalServerError('Falha ao registrar evento de ativação');
  }
}

Future<Response> _getSummary(RequestContext context) async {
  final userId = getUserId(context);
  final pool = context.read<Pool>();

  final days =
      int.tryParse(context.request.uri.queryParameters['days'] ?? '30') ?? 30;
  final safeDays = days.clamp(1, 90);

  try {
    final result = await pool.execute(
      Sql.named('''
        SELECT event_name, COUNT(*)::int AS total
        FROM activation_funnel_events
        WHERE user_id = @userId
          AND created_at >= NOW() - (@days * INTERVAL '1 day')
        GROUP BY event_name
        ORDER BY event_name ASC
      '''),
      parameters: {'userId': userId, 'days': safeDays},
    );

    final events = <Map<String, dynamic>>[];
    for (final row in result) {
      events.add({'event_name': row[0], 'count': row[1]});
    }

    return Response.json(body: {'days': safeDays, 'events': events});
  } catch (_) {
    return internalServerError('Falha ao buscar resumo de ativação');
  }
}
