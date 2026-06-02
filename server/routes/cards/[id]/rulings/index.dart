import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

/// GET /cards/:id/rulings
///
/// Retorna as rulings oficiais (Gatherer/Scryfall, via MTGJSON) de uma carta.
/// `:id` é o `cards.id` (uuid). As rulings são resolvidas pelo `oracle_id`
/// (armazenado em `cards.scryfall_id`), então todas as impressões da mesma
/// carta compartilham as rulings.
///
/// Response:
/// {
///   "card_id": "...",
///   "name": "...",
///   "oracle_id": "...",
///   "rulings": [ { "date": "2022-10-07", "text": "..." }, ... ],
///   "count": 3
/// }
Future<Response> onRequest(RequestContext context, String id) async {
  if (context.request.method != HttpMethod.get) {
    return Response(
      statusCode: 405,
      body: '{"error":"Method not allowed"}',
    );
  }

  final pool = context.read<Pool>();

  try {
    final cardResult = await pool.execute(
      Sql.named('''
        SELECT name, scryfall_id::text AS oracle_id
        FROM cards
        WHERE id = CAST(@id AS uuid)
        LIMIT 1
      '''),
      parameters: {'id': id},
    );

    if (cardResult.isEmpty) {
      return Response.json(
        statusCode: 404,
        body: {'error': 'Card not found'},
      );
    }

    final card = cardResult.first.toColumnMap();
    final oracleId = card['oracle_id'] as String?;
    final name = card['name'] as String?;

    final rulings = <Map<String, dynamic>>[];
    if (oracleId != null && oracleId.isNotEmpty) {
      final rows = await pool.execute(
        Sql.named('''
          SELECT published_at, comment
          FROM card_rulings
          WHERE oracle_id = @oracle_id
          ORDER BY published_at ASC NULLS LAST
        '''),
        parameters: {'oracle_id': oracleId},
      );
      for (final row in rows) {
        final m = row.toColumnMap();
        rulings.add({
          'date': (m['published_at'] as DateTime?)
              ?.toIso8601String()
              .split('T')
              .first,
          'text': m['comment'],
        });
      }
    }

    return Response.json(body: {
      'card_id': id,
      'name': name,
      'oracle_id': oracleId,
      'rulings': rulings,
      'count': rulings.length,
    });
  } catch (e) {
    print('[ERROR] /cards/$id/rulings: $e');
    return Response.json(
      statusCode: 500,
      body: {'error': 'Erro ao buscar rulings'},
    );
  }
}
