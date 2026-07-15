import 'dart:convert';

import 'package:postgres/postgres.dart';

import 'battle_learning_evidence_support.dart';

const _trustedEngineContracts = {
  'canonical_rules_execution',
  'canonical_rules_execution_secondary',
  'native_reviewed_rules_execution',
};

Future<Map<String, dynamic>> loadDeckBattleLearningEvidence({
  required Pool pool,
  required String deckId,
  int limit = 20,
}) async {
  final table = await pool.execute(
    """
    SELECT EXISTS (
      SELECT 1 FROM information_schema.tables
      WHERE table_schema = 'public' AND table_name = 'battle_simulations'
    )
    """,
  );
  if (table.isEmpty || table.first[0] != true) {
    return _emptyEvidence(deckId);
  }

  final rows = await pool.execute(
    Sql.named(
      '''
      SELECT id::text, deck_a_id::text, deck_b_id::text, game_log,
             metrics, created_at
      FROM battle_simulations
      WHERE (deck_a_id = CAST(@deckId AS uuid)
             OR deck_b_id = CAST(@deckId AS uuid))
        AND simulation_type = 'battle'
      ORDER BY created_at DESC
      LIMIT @limit
      ''',
    ),
    parameters: {'deckId': deckId, 'limit': limit.clamp(1, 100)},
  );

  final exposedNames = <String>{};
  final engineCounts = <String, int>{};
  var trustedBattles = 0;
  var positiveBattles = 0;
  String? latestReplayId;
  DateTime? latestCreatedAt;
  for (final row in rows) {
    final payload = _jsonMap(row[3]);
    final metrics = _jsonMap(row[4]);
    final engineContract =
        (payload['engine_contract'] ?? metrics['engine_contract'])
                ?.toString() ??
            '';
    engineCounts[engineContract] = (engineCounts[engineContract] ?? 0) + 1;
    if (!_trustedEngineContracts.contains(engineContract)) continue;
    trustedBattles++;
    final evidence = _map(payload['battle_learning_evidence']);
    if (evidence['schema_version'] != battlePositiveEvidenceSchema) continue;
    if (evidence['natural_sample'] != true) continue;
    if (evidence['positive_exposure_ready'] == true) positiveBattles++;
    for (final name
        in evidence['exposed_card_names_normalized'] as List? ?? const []) {
      final normalized = name?.toString().trim() ?? '';
      if (normalized.isNotEmpty) exposedNames.add(normalized);
    }
    latestReplayId ??= row[0]?.toString();
    latestCreatedAt ??= row[5] is DateTime
        ? row[5] as DateTime
        : DateTime.tryParse(row[5]?.toString() ?? '');
  }

  final sortedNames = exposedNames.toList()..sort();
  return {
    'schema_version': battlePositiveEvidenceSchema,
    'aggregate_schema_version': 'deck_battle_learning_evidence_v1',
    'source': 'battle_simulations',
    'deck_id': deckId,
    'battle_count': rows.length,
    'trusted_battle_count': trustedBattles,
    'positive_exposure_battle_count': positiveBattles,
    'positive_exposure_ready': positiveBattles > 0,
    'exposed_card_names_normalized': sortedNames,
    'latest_replay_id': latestReplayId,
    'latest_created_at': latestCreatedAt?.toUtc().toIso8601String(),
    'engine_contract_counts': Map<String, int>.fromEntries(
      engineCounts.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    ),
    'comparison_input_ready': false,
    'strategy_proof': false,
    'swap_superiority_proven': false,
    'promotion_allowed': false,
  };
}

Map<String, dynamic> _emptyEvidence(String deckId) => {
      'schema_version': battlePositiveEvidenceSchema,
      'aggregate_schema_version': 'deck_battle_learning_evidence_v1',
      'source': 'battle_simulations',
      'deck_id': deckId,
      'battle_count': 0,
      'trusted_battle_count': 0,
      'positive_exposure_battle_count': 0,
      'positive_exposure_ready': false,
      'exposed_card_names_normalized': const <String>[],
      'engine_contract_counts': const <String, int>{},
      'comparison_input_ready': false,
      'strategy_proof': false,
      'swap_superiority_proven': false,
      'promotion_allowed': false,
    };

Map<String, dynamic> _map(Object? value) => value is Map
    ? value.map((key, value) => MapEntry(key.toString(), value))
    : const <String, dynamic>{};

Map<String, dynamic> _jsonMap(Object? value) {
  if (value is Map) return _map(value);
  if (value is String && value.trim().isNotEmpty) {
    try {
      return _map(jsonDecode(value));
    } on FormatException {
      return const {};
    }
  }
  return const {};
}
