import 'package:postgres/postgres.dart';

/// Loads the canonical multi-role metadata used by structural deck gates.
///
/// The materialized snapshot is preferred because it is the shared PostgreSQL
/// read model. The source tables remain a fail-safe for older disposable
/// databases that have not created the view yet.
Future<Map<String, Map<String, dynamic>>>
loadCanonicalCardRoleMetadataByCardId({
  required Pool pool,
  required Iterable<String> cardIds,
}) async {
  final ids = cardIds
    .map((id) => id.trim())
    .where((id) => id.isNotEmpty)
    .toSet()
    .toList(growable: false)..sort();
  if (ids.isEmpty) return const <String, Map<String, dynamic>>{};

  if (await _hasCanonicalRoleRelation(pool, 'card_intelligence_snapshot')) {
    try {
      final rows = await pool.execute(
        Sql.named('''
          SELECT card_id::text, function_tag_details, semantic_tags_v2
          FROM card_intelligence_snapshot
          WHERE card_id::text = ANY(@cardIds)
        '''),
        parameters: {'cardIds': TypedValue(Type.textArray, ids)},
      );
      return {
        for (final row in rows)
          row[0].toString(): {
            'functional_tags': row[1],
            'semantic_tags_v2': row[2],
          },
      };
    } catch (_) {
      // Fall through to the canonical source tables. A stale view must not
      // silently remove persisted role evidence from Generate/Rebuild.
    }
  }

  final metadata = <String, Map<String, dynamic>>{};
  if (await _hasCanonicalRoleRelation(pool, 'card_function_tags')) {
    final rows = await pool.execute(
      Sql.named('''
        SELECT card_id::text,
               jsonb_agg(
                 jsonb_build_object(
                   'tag', tag,
                   'confidence', confidence,
                   'evidence', evidence,
                   'source', source
                 )
                 ORDER BY confidence DESC, tag, source
               ) AS functional_tags
        FROM card_function_tags
        WHERE card_id::text = ANY(@cardIds)
        GROUP BY card_id
      '''),
      parameters: {'cardIds': TypedValue(Type.textArray, ids)},
    );
    for (final row in rows) {
      metadata.putIfAbsent(
            row[0].toString(),
            () => <String, dynamic>{},
          )['functional_tags'] =
          row[1];
    }
  }

  if (await _hasCanonicalRoleRelation(pool, 'card_semantic_tags_v2')) {
    final rows = await pool.execute(
      Sql.named('''
        SELECT card_id::text,
               jsonb_agg(
                 jsonb_build_object(
                   'schema_version', schema_version,
                   'source', source,
                   'speed', speed,
                   'mana_efficiency', mana_efficiency,
                   'card_advantage_type', card_advantage_type,
                   'interaction_scope', interaction_scope,
                   'tags', tags,
                   'role_confidence', role_confidence,
                   'engine', engine,
                   'payoff', payoff,
                   'enabler', enabler,
                   'wincon', wincon,
                   'combo_piece', combo_piece,
                   'protection_type', protection_type,
                   'recursion_type', recursion_type,
                   'explanation_reason', explanation_reason
                 )
                 ORDER BY role_confidence DESC, source
               ) AS semantic_tags_v2
        FROM card_semantic_tags_v2
        WHERE card_id::text = ANY(@cardIds)
        GROUP BY card_id
      '''),
      parameters: {'cardIds': TypedValue(Type.textArray, ids)},
    );
    for (final row in rows) {
      metadata.putIfAbsent(
            row[0].toString(),
            () => <String, dynamic>{},
          )['semantic_tags_v2'] =
          row[1];
    }
  }

  return metadata;
}

Future<bool> _hasCanonicalRoleRelation(Pool pool, String relationName) async {
  try {
    final rows = await pool.execute(
      Sql.named('SELECT to_regclass(@name) IS NOT NULL'),
      parameters: {'name': relationName},
    );
    return rows.isNotEmpty && rows.first[0] == true;
  } catch (_) {
    return false;
  }
}
