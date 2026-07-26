import 'dart:convert';

import 'package:postgres/postgres.dart';

import 'battle_engine_config.dart';
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
  final table = await pool.execute("""
    SELECT
      to_regclass('public.battle_simulations') IS NOT NULL,
      to_regclass('public.battle_simulation_attempts') IS NOT NULL
    """);
  if (table.isEmpty || table.first[0] != true || table.first[1] != true) {
    return _emptyEvidence(deckId);
  }

  final currentDeckHash = await _loadCurrentDeckHash(pool, deckId);
  if (currentDeckHash == null) return _emptyEvidence(deckId);

  final rows = await pool.execute(
    Sql.named('''
      SELECT battle_simulations.id::text,
             battle_simulations.deck_a_id::text,
             battle_simulations.deck_b_id::text,
             battle_simulations.game_log,
             battle_simulations.metrics,
             battle_simulations.created_at,
             attempt.outcome,
             attempt.deck_a_hash,
             attempt.deck_b_hash
      FROM battle_simulations
      JOIN battle_simulation_attempts attempt
        ON attempt.replay_id = battle_simulations.id
      WHERE (
          battle_simulations.deck_a_id = CAST(@deckId AS uuid)
          OR battle_simulations.deck_b_id = CAST(@deckId AS uuid)
        )
        AND battle_simulations.simulation_type = 'battle'
      ORDER BY battle_simulations.created_at DESC
      LIMIT @limit
      '''),
    parameters: {'deckId': deckId, 'limit': limit.clamp(1, 100)},
  );

  final exposedNames = <String>{};
  final engineCounts = <String, int>{};
  var trustedBattles = 0;
  var compatibleRevisionBattles = 0;
  var reliableCompatibleBattles = 0;
  var staleRevisionBattles = 0;
  var censoredBattles = 0;
  var timeoutBattles = 0;
  var positiveBattles = 0;
  String? latestReplayId;
  DateTime? latestCreatedAt;
  for (final row in rows) {
    final payload = _jsonMap(row[3]);
    final metrics = _jsonMap(row[4]);
    final subjectDeckKey = row[1]?.toString() == deckId ? 'deck_a' : 'deck_b';
    final recordedDeckHash =
        subjectDeckKey == 'deck_a' ? row[7]?.toString() : row[8]?.toString();
    final revisionCompatible =
        recordedDeckHash != null && recordedDeckHash == currentDeckHash;
    if (revisionCompatible) {
      compatibleRevisionBattles++;
    } else {
      staleRevisionBattles++;
    }
    final engineContract =
        (payload['engine_contract'] ?? metrics['engine_contract'])
            ?.toString() ??
        '';
    engineCounts[engineContract] = (engineCounts[engineContract] ?? 0) + 1;
    final outcome = row[6]?.toString();
    if (outcome == 'censored') censoredBattles++;
    if (outcome == 'timeout') timeoutBattles++;
    if (!_trustedEngineContracts.contains(engineContract)) continue;
    trustedBattles++;
    if (outcome != 'completed' || !revisionCompatible) continue;
    reliableCompatibleBattles++;
    final evidenceBySubject = _map(
      payload['battle_learning_evidence_by_subject'],
    );
    final evidence =
        _map(evidenceBySubject[subjectDeckKey]).isNotEmpty
            ? _map(evidenceBySubject[subjectDeckKey])
            : _map(payload['battle_learning_evidence']);
    if (evidence['schema_version'] != battlePositiveEvidenceSchema) continue;
    if (evidence['subject_deck_key'] != subjectDeckKey) continue;
    if (evidence['natural_sample'] != true) continue;
    if (evidence['positive_exposure_ready'] == true) positiveBattles++;
    for (final name
        in evidence['exposed_card_names_normalized'] as List? ?? const []) {
      final normalized = name?.toString().trim() ?? '';
      if (normalized.isNotEmpty) exposedNames.add(normalized);
    }
    latestReplayId ??= row[0]?.toString();
    latestCreatedAt ??=
        row[5] is DateTime
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
    'compatible_revision_battle_count': compatibleRevisionBattles,
    'reliable_compatible_battle_count': reliableCompatibleBattles,
    'stale_revision_battle_count': staleRevisionBattles,
    'censored_battle_count': censoredBattles,
    'timeout_battle_count': timeoutBattles,
    'positive_exposure_battle_count': positiveBattles,
    'positive_exposure_ready': positiveBattles > 0,
    'current_deck_hash': currentDeckHash,
    'deck_hash_schema': externalBattleDeckHashSchema,
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

Future<String?> _loadCurrentDeckHash(Pool pool, String deckId) async {
  final rows = await pool.execute(
    Sql.named('''
      SELECT
        card.name,
        card.set_code,
        card.collector_number,
        deck_card.quantity,
        deck_card.is_commander
      FROM deck_cards deck_card
      JOIN cards card ON card.id = deck_card.card_id
      WHERE deck_card.deck_id = CAST(@deckId AS uuid)
      '''),
    parameters: {'deckId': deckId},
  );
  if (rows.isEmpty) return null;
  return canonicalExternalBattleDeckHash({
    'cards': [
      for (final row in rows)
        {
          'name': row[0],
          'set_code': row[1],
          'collector_number': row[2],
          'quantity': row[3],
          'is_commander': row[4],
        },
    ],
  });
}

Map<String, dynamic> _emptyEvidence(String deckId) => {
  'schema_version': battlePositiveEvidenceSchema,
  'aggregate_schema_version': 'deck_battle_learning_evidence_v1',
  'source': 'battle_simulations',
  'deck_id': deckId,
  'battle_count': 0,
  'trusted_battle_count': 0,
  'compatible_revision_battle_count': 0,
  'reliable_compatible_battle_count': 0,
  'stale_revision_battle_count': 0,
  'censored_battle_count': 0,
  'timeout_battle_count': 0,
  'positive_exposure_battle_count': 0,
  'positive_exposure_ready': false,
  'exposed_card_names_normalized': const <String>[],
  'engine_contract_counts': const <String, int>{},
  'comparison_input_ready': false,
  'strategy_proof': false,
  'swap_superiority_proven': false,
  'promotion_allowed': false,
};

Map<String, dynamic> _map(Object? value) =>
    value is Map
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
