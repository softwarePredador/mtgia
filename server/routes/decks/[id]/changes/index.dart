import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

import '../../../../lib/decks/deck_revision_support.dart';
import '../../../../lib/logger.dart';

/// GET /decks/:id/changes?limit=20&before_revision=N
///
/// O ledger de mudanças do deck (DCK-P0-01), da mais nova para a mais velha:
/// operação, revisão de antes e de depois, quando, se desfaz outra, o que
/// mudou nas cartas (com o nome de cada uma) e nos metadados, e se pode ser
/// desfeita agora (só a mais nova, `can_undo`). Só o dono lê.
Future<Response> onRequest(RequestContext context, String deckId) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }
  final userId = context.read<String>();
  final pool = context.read<Pool>();
  final query = context.request.uri.queryParameters;
  final limit = (int.tryParse(query['limit'] ?? '') ?? 20).clamp(1, 100);
  final beforeRevision = int.tryParse(query['before_revision'] ?? '');

  if (!isDeckUuid(deckId)) return _notFound();
  try {
    final owned = await pool.execute(
      Sql.named('''
        SELECT revision FROM decks
        WHERE id = CAST(@deckId AS uuid) AND user_id = CAST(@userId AS uuid)
      '''),
      parameters: {'deckId': deckId, 'userId': userId},
    );
    if (owned.isEmpty) return _notFound();
    final revision = (owned.first[0] as num).toInt();
    final events = await pool.execute(
      Sql.named('''
        SELECT id::text, operation, revision_before, revision_after,
               undo_of_event_id::text, created_at, cards_before, cards_after,
               metadata_before, metadata_after
        FROM deck_change_events
        WHERE deck_id = CAST(@deckId AS uuid)
          AND (CAST(@beforeRevision AS bigint) IS NULL
               OR revision_after < CAST(@beforeRevision AS bigint))
        ORDER BY revision_after DESC
        LIMIT @limit
      '''),
      parameters: {
        'deckId': deckId,
        'beforeRevision': beforeRevision,
        'limit': limit,
      },
    );
    final rows = [for (final row in events) row.toColumnMap()];
    final cardIds = <String>{
      for (final row in rows)
        for (final key in const ['cards_before', 'cards_after'])
          for (final card in _jsonList(row[key])) '${card['card_id']}',
    };
    final names = <String, String>{};
    if (cardIds.isNotEmpty) {
      final result = await pool.execute(
        Sql.named('''
          SELECT id::text, name FROM cards
          WHERE id = ANY(CAST(@ids AS uuid[]))
        '''),
        parameters: {'ids': cardIds.toList()},
      );
      for (final row in result) {
        names[row[0] as String] = row[1] as String;
      }
    }
    List<Map<String, Object?>>? cards(Object? raw) =>
        raw == null
            ? null
            : [
              for (final card in _jsonList(raw))
                {...card, 'name': names['${card['card_id']}']},
            ];

    return Response.json(
      body: {
        'deck_id': deckId,
        'revision': revision,
        'events': [
          for (final row in rows)
            {
              'id': row['id'],
              'operation': row['operation'],
              'revision_before': row['revision_before'],
              'revision_after': row['revision_after'],
              'undo_of_event_id': row['undo_of_event_id'],
              'created_at':
                  (row['created_at'] as DateTime?)?.toUtc().toIso8601String(),
              'cards_before': cards(row['cards_before']),
              'cards_after': cards(row['cards_after']),
              'metadata_before': _jsonMap(row['metadata_before']),
              'metadata_after': _jsonMap(row['metadata_after']),
              'can_undo': row['revision_after'] == revision,
            },
        ],
        if (rows.length == limit)
          'next_before_revision': rows.last['revision_after'],
      },
      headers: {'ETag': deckRevisionEtag(revision)},
    );
  } catch (error) {
    Log.e('[ERROR] list deck changes failed: ${error.runtimeType}');
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: const {
        'error': 'Não foi possível ler o histórico do deck agora.',
        'error_code': 'deck_changes_failed',
      },
    );
  }
}

Response _notFound() => Response.json(
  statusCode: HttpStatus.notFound,
  body: const {'error': 'Deck não encontrado.', 'error_code': 'deck_not_found'},
);

List<Map<String, dynamic>> _jsonList(Object? raw) {
  final value = raw is String ? jsonDecode(raw) : raw;
  if (value is! List) return const [];
  return [
    for (final item in value)
      if (item is Map) item.cast<String, dynamic>(),
  ];
}

Map<String, dynamic> _jsonMap(Object? raw) {
  final value = raw is String ? jsonDecode(raw) : raw;
  return value is Map ? value.cast<String, dynamic>() : <String, dynamic>{};
}
