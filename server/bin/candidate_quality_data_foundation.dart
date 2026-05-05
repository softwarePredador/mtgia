import 'dart:convert';
import 'dart:io';

import 'package:postgres/postgres.dart';
import 'package:server/ai/candidate_quality_data_support.dart';
import 'package:server/database.dart';
import 'package:server/meta/meta_deck_card_list_support.dart';

const _defaultArtifactDir =
    'test/artifacts/aggressive_candidate_quality_v2_2026-05-05';
const _heuristicSource = 'deterministic_heuristic_v1';
const _metaSynergySource = 'meta_decks_cooccurrence_v1';
const _rejectionPenaltySource = 'quality_gate_history_v1';

Future<void> main(List<String> args) async {
  if (args.contains('--help') || args.contains('-h')) {
    _printUsage();
    return;
  }

  final apply = args.contains('--apply');
  final dryRun = args.contains('--dry-run') || !apply;
  if (apply && args.contains('--dry-run')) {
    throw ArgumentError('Use apenas um modo: --dry-run ou --apply.');
  }

  final artifactDir = Directory(
    _readArg(args, '--artifact-dir=') ?? _defaultArtifactDir,
  );
  final minSynergyEvidence =
      int.tryParse(_readArg(args, '--min-synergy-evidence=') ?? '') ?? 2;
  final maxSynergyRows =
      int.tryParse(_readArg(args, '--max-synergy-rows=') ?? '') ?? 5000;

  await artifactDir.create(recursive: true);

  final database = Database();
  await database.connect();
  final pool = database.connection;
  final startedAt = DateTime.now();

  try {
    final preCounts = await _loadPreCounts(pool);
    final cards = await _loadCandidateCards(pool);
    final legalStatuses = await _loadCommanderLegalStatuses(pool);

    final tagRows = <Map<String, dynamic>>[];
    final roleRows = <Map<String, dynamic>>[];
    final cardsById = <String, CandidateQualityCard>{};
    final cardsByName = <String, CandidateQualityCard>{};

    for (final card in cards) {
      cardsById[card.id] = card;
      cardsByName.putIfAbsent(
        normalizeCandidateQualityKey(card.name),
        () => card,
      );

      final tags = inferCandidateFunctionTags(
        name: card.name,
        typeLine: card.typeLine,
        oracleText: card.oracleText,
        manaCost: card.manaCost,
      );
      for (final tag in tags) {
        tagRows.add({
          'card_id': card.id,
          'card_name': card.name,
          'tag': tag.tag,
          'confidence': tag.confidence,
          'source': _heuristicSource,
          'evidence': tag.evidence,
        });
      }

      final scores = buildCandidateRoleScores(
        name: card.name,
        typeLine: card.typeLine,
        oracleText: card.oracleText,
        manaCost: card.manaCost,
        priceUsd: card.priceUsd,
        priceUsdFoil: card.priceUsdFoil,
        cmc: card.cmc,
        metaUsageCount: card.metaUsageCount,
        metaDeckCount: card.metaDeckCount,
      );
      for (final score in scores) {
        roleRows.add({
          'card_id': card.id,
          'card_name': card.name,
          'role': score.role,
          'score': score.score,
          'format': 'commander',
          'subformat': 'any',
          'bracket_scope': score.bracketScope,
          'budget_tier': score.budgetTier,
          'source': _heuristicSource,
          'evidence': score.evidence,
        });
      }
    }

    final synergyRows = await _loadCommanderSynergyRows(
      pool: pool,
      cardsByName: cardsByName,
      roleRows: roleRows,
      minEvidence: minSynergyEvidence,
      maxRows: maxSynergyRows,
    );
    final penaltyRows = await _loadRejectionPenaltyRows(pool);
    final samplePools = _buildSampleCandidatePools(
      synergyRows: synergyRows,
      roleRows: roleRows,
      cardsById: cardsById,
      cardsByName: cardsByName,
      legalStatuses: legalStatuses,
    );

    var applied = false;
    var upsertedTags = 0;
    var upsertedRoleScores = 0;
    var upsertedSynergies = 0;
    var upsertedPenalties = 0;
    var prunedStaleFunctionTags = 0;
    var prunedStaleRoleScores = 0;
    var prunedStaleSynergies = 0;
    var prunedStalePenalties = 0;
    final staleRowsBeforeApply = await _countStaleGeneratedRows(
      pool: pool,
      tagRows: tagRows,
      roleRows: roleRows,
      synergyRows: synergyRows,
      penaltyRows: penaltyRows,
    );
    if (apply) {
      await _ensureCandidateQualitySchema(pool);
      upsertedTags = await _upsertFunctionTags(pool, tagRows);
      upsertedRoleScores = await _upsertRoleScores(pool, roleRows);
      upsertedSynergies = await _upsertCommanderSynergies(pool, synergyRows);
      upsertedPenalties = await _upsertRejectionPenalties(pool, penaltyRows);
      prunedStaleFunctionTags = await _pruneStaleFunctionTags(pool, tagRows);
      prunedStaleRoleScores = await _pruneStaleRoleScores(pool, roleRows);
      prunedStaleSynergies =
          await _pruneStaleCommanderSynergies(pool, synergyRows);
      prunedStalePenalties =
          await _pruneStaleRejectionPenalties(pool, penaltyRows);
      applied = true;
    }

    final postCounts = await _loadPreCounts(pool);
    final summary = {
      'schema_version': candidateQualitySchemaVersion,
      'mode': dryRun ? 'dry_run' : 'apply',
      'started_at': startedAt.toIso8601String(),
      'finished_at': DateTime.now().toIso8601String(),
      'db_mutations': applied,
      'artifact_dir': artifactDir.path,
      'pre_counts': preCounts,
      'post_counts': postCounts,
      'cards_scanned': cards.length,
      'cards_with_function_tags':
          tagRows.map((row) => row['card_id']).toSet().length,
      'function_tag_rows_planned': tagRows.length,
      'role_score_rows_planned': roleRows.length,
      'commander_synergy_rows_planned': synergyRows.length,
      'rejection_penalty_rows_planned': penaltyRows.length,
      'function_tag_coverage_pct': cards.isEmpty
          ? 0
          : (tagRows.map((r) => r['card_id']).toSet().length /
              cards.length *
              100),
      'upserted_function_tags': upsertedTags,
      'upserted_role_scores': upsertedRoleScores,
      'upserted_commander_synergies': upsertedSynergies,
      'upserted_rejection_penalties': upsertedPenalties,
      'stale_generated_rows_before_apply': staleRowsBeforeApply,
      'pruned_stale_function_tags': prunedStaleFunctionTags,
      'pruned_stale_role_scores': prunedStaleRoleScores,
      'pruned_stale_commander_synergies': prunedStaleSynergies,
      'pruned_stale_rejection_penalties': prunedStalePenalties,
      'tag_counts': _countBy(tagRows, 'tag'),
      'role_counts': _countBy(roleRows, 'role'),
      'budget_tier_counts': _countBy(roleRows, 'budget_tier'),
      'bracket_scope_counts': _countBy(roleRows, 'bracket_scope'),
      'sample_candidate_pool_count': samplePools.length,
      'legality_color_identity_guard':
          'Samples and lookup SQL keep commander legal/restricted/null status and commander color identity filters; tags never override legalities, color_identity, or bracket policy.',
      'unresolved': {
        'ai_generated_tags': 'not used',
        'optimizer_runtime_consumption':
            'not enabled in request path during stage 1',
        'human_reviewed_tags': 'not proven',
      },
    };

    await _writeJson(
        '${artifactDir.path}/summary_${summary['mode']}.json', summary);
    await _writeJson('${artifactDir.path}/function_tag_rows_preview.json',
        tagRows.take(500).toList());
    await _writeJson('${artifactDir.path}/role_score_rows_preview.json',
        roleRows.take(500).toList());
    await _writeJson('${artifactDir.path}/commander_synergy_rows_preview.json',
        synergyRows.take(500).toList());
    await _writeJson('${artifactDir.path}/rejection_penalty_rows_preview.json',
        penaltyRows.take(500).toList());
    await _writeJson(
        '${artifactDir.path}/sample_candidate_pools.json', samplePools);
    await _writeCsv(
      '${artifactDir.path}/tag_counts.csv',
      _countBy(tagRows, 'tag')
          .entries
          .map((entry) => {'tag': entry.key, 'count': entry.value})
          .toList(),
      const ['tag', 'count'],
    );
    await _writeSummaryMarkdown(
      '${artifactDir.path}/summary_${summary['mode']}.md',
      summary,
    );

    stdout.writeln(apply
        ? '[OK] Candidate quality foundation aplicada.'
        : '[OK] Candidate quality foundation dry-run concluido.');
    stdout.writeln('  - Artefatos: ${artifactDir.path}');
    stdout.writeln('  - Cards escaneadas: ${cards.length}');
    stdout.writeln('  - Tags planejadas: ${tagRows.length}');
    stdout.writeln('  - Role scores planejados: ${roleRows.length}');
    stdout.writeln('  - Synergy rows planejadas: ${synergyRows.length}');
    stdout.writeln('  - Penalty rows planejadas: ${penaltyRows.length}');
  } finally {
    await database.close();
  }
}

void _printUsage() {
  stdout.writeln('''
candidate_quality_data_foundation.dart - Base segura para candidatos aggressive optimize

Uso:
  dart run bin/candidate_quality_data_foundation.dart --dry-run
  dart run bin/candidate_quality_data_foundation.dart --apply
  dart run bin/candidate_quality_data_foundation.dart --dry-run --artifact-dir=test/artifacts/acqv2

Opcoes:
  --dry-run                    Gera cobertura/artefatos sem alterar banco (default)
  --apply                      Cria schema aditivo e faz upsert idempotente
  --artifact-dir=<path>        Diretorio de artefatos
  --min-synergy-evidence=<N>   Minimo de ocorrencias por commander/card (default: 2)
  --max-synergy-rows=<N>       Limite de rows de synergy a materializar (default: 5000)
  --help                       Mostra esta ajuda
''');
}

class CandidateQualityCard {
  const CandidateQualityCard({
    required this.id,
    required this.name,
    required this.typeLine,
    required this.oracleText,
    required this.manaCost,
    required this.colors,
    required this.colorIdentity,
    required this.cmc,
    required this.priceUsd,
    required this.priceUsdFoil,
    required this.metaUsageCount,
    required this.metaDeckCount,
  });

  final String id;
  final String name;
  final String typeLine;
  final String oracleText;
  final String manaCost;
  final List<String> colors;
  final List<String> colorIdentity;
  final Object? cmc;
  final Object? priceUsd;
  final Object? priceUsdFoil;
  final int metaUsageCount;
  final int metaDeckCount;

  Set<String> get resolvedIdentity => resolveCandidateQualityIdentity(
        colorIdentity: colorIdentity,
        colors: colors,
        oracleText: oracleText,
        manaCost: manaCost,
      );
}

Future<Map<String, int>> _loadPreCounts(Pool pool) async {
  final tables = [
    'cards',
    'card_meta_insights',
    'meta_decks',
    'optimization_analysis_logs',
    'card_function_tags',
    'card_role_scores',
    'commander_card_synergy',
    'optimize_rejection_penalties',
  ];
  final counts = <String, int>{};
  for (final table in tables) {
    if (!await _hasTable(pool, table)) {
      counts[table] = 0;
      continue;
    }
    final result = await pool.execute('SELECT COUNT(*)::int FROM $table');
    counts[table] = (result.first[0] as int?) ?? 0;
  }
  return counts;
}

Future<List<CandidateQualityCard>> _loadCandidateCards(Pool pool) async {
  final hasMetaInsights = await _hasTable(pool, 'card_meta_insights');
  final sql = hasMetaInsights
      ? '''
SELECT DISTINCT ON (LOWER(c.name))
  c.id::text,
  c.name,
  COALESCE(c.type_line, '') AS type_line,
  COALESCE(c.oracle_text, '') AS oracle_text,
  COALESCE(c.mana_cost, '') AS mana_cost,
  COALESCE(c.colors, ARRAY[]::text[]) AS colors,
  COALESCE(c.color_identity, ARRAY[]::text[]) AS color_identity,
  c.cmc,
  c.price_usd,
  c.price_usd_foil,
  COALESCE(cmi.usage_count, 0)::int AS usage_count,
  COALESCE(cmi.meta_deck_count, 0)::int AS meta_deck_count
FROM cards c
LEFT JOIN card_meta_insights cmi ON LOWER(cmi.card_name) = LOWER(c.name)
WHERE c.name IS NOT NULL
  AND c.name NOT LIKE 'A-%'
  AND c.name NOT LIKE '\\_%' ESCAPE '\\'
  AND c.name NOT LIKE '%World Champion%'
  AND c.name NOT LIKE '%Heroes of the Realm%'
ORDER BY LOWER(c.name),
  COALESCE(cmi.meta_deck_count, 0) DESC,
  COALESCE(cmi.usage_count, 0) DESC,
  c.set_code ASC NULLS LAST,
  c.id ASC
'''
      : '''
SELECT DISTINCT ON (LOWER(c.name))
  c.id::text,
  c.name,
  COALESCE(c.type_line, '') AS type_line,
  COALESCE(c.oracle_text, '') AS oracle_text,
  COALESCE(c.mana_cost, '') AS mana_cost,
  COALESCE(c.colors, ARRAY[]::text[]) AS colors,
  COALESCE(c.color_identity, ARRAY[]::text[]) AS color_identity,
  c.cmc,
  c.price_usd,
  c.price_usd_foil,
  0::int AS usage_count,
  0::int AS meta_deck_count
FROM cards c
WHERE c.name IS NOT NULL
  AND c.name NOT LIKE 'A-%'
  AND c.name NOT LIKE '\\_%' ESCAPE '\\'
  AND c.name NOT LIKE '%World Champion%'
  AND c.name NOT LIKE '%Heroes of the Realm%'
ORDER BY LOWER(c.name), c.set_code ASC NULLS LAST, c.id ASC
''';

  final rows = await pool.execute(sql);
  return rows.map((row) {
    return CandidateQualityCard(
      id: row[0] as String,
      name: (row[1] as String?) ?? '',
      typeLine: (row[2] as String?) ?? '',
      oracleText: (row[3] as String?) ?? '',
      manaCost: (row[4] as String?) ?? '',
      colors: (row[5] as List?)?.map((e) => e.toString()).toList() ??
          const <String>[],
      colorIdentity: (row[6] as List?)?.map((e) => e.toString()).toList() ??
          const <String>[],
      cmc: row[7],
      priceUsd: row[8],
      priceUsdFoil: row[9],
      metaUsageCount: (row[10] as int?) ?? 0,
      metaDeckCount: (row[11] as int?) ?? 0,
    );
  }).toList(growable: false);
}

Future<Map<String, String>> _loadCommanderLegalStatuses(Pool pool) async {
  if (!await _hasTable(pool, 'card_legalities'))
    return const <String, String>{};
  final rows = await pool.execute('''
SELECT card_id::text, status
FROM card_legalities
WHERE format = 'commander'
''');
  return {
    for (final row in rows)
      if (row[0] != null) row[0] as String: (row[1] as String?) ?? ''
  };
}

Future<List<Map<String, dynamic>>> _loadCommanderSynergyRows({
  required Pool pool,
  required Map<String, CandidateQualityCard> cardsByName,
  required List<Map<String, dynamic>> roleRows,
  required int minEvidence,
  required int maxRows,
}) async {
  if (!await _hasTable(pool, 'meta_decks'))
    return const <Map<String, dynamic>>[];

  final roleByCardId = <String, Map<String, dynamic>>{};
  for (final row in roleRows) {
    final cardId = row['card_id'] as String;
    final current = roleByCardId[cardId];
    if (current == null || (row['score'] as int) > (current['score'] as int)) {
      roleByCardId[cardId] = row;
    }
  }

  final rows = await pool.execute('''
SELECT commander_name, partner_commander_name, format, card_list
FROM meta_decks
WHERE format IN ('EDH', 'cEDH')
  AND card_list IS NOT NULL
  AND TRIM(card_list) <> ''
  AND commander_name IS NOT NULL
  AND TRIM(commander_name) <> ''
''');

  final counts = <String, _SynergyAggregate>{};
  for (final row in rows) {
    final commander = ((row[0] as String?) ?? '').trim();
    final partner = ((row[1] as String?) ?? '').trim();
    final format = ((row[2] as String?) ?? 'EDH').trim();
    final cardList = (row[3] as String?) ?? '';
    final parsed = parseMetaDeckCardList(cardList: cardList, format: format);
    final commanderKeys = {
      normalizeCandidateQualityKey(commander),
      if (partner.isNotEmpty) normalizeCandidateQualityKey(partner),
    };

    for (final cardName in parsed.effectiveCards.keys) {
      final normalizedCard = normalizeCandidateQualityKey(cardName);
      if (commanderKeys.contains(normalizedCard)) continue;
      final card = cardsByName[normalizedCard];
      if (card == null) continue;
      final roleRow = roleByCardId[card.id];
      final role = roleRow == null
          ? 'utility'
          : (roleRow['role'] as String?) ?? 'utility';
      final key = [
        normalizeCandidateQualityKey(commander),
        card.id,
        role,
      ].join('|');
      counts
          .putIfAbsent(
            key,
            () => _SynergyAggregate(
              commanderNameNormalized: normalizeCandidateQualityKey(commander),
              commanderName: commander,
              cardId: card.id,
              cardName: card.name,
              role: role,
              cardMetaDeckCount: card.metaDeckCount,
            ),
          )
          .evidenceCount++;
    }
  }

  final output = counts.values
      .where((entry) => entry.evidenceCount >= minEvidence)
      .map((entry) {
    final score = (50 + entry.evidenceCount * 7 + entry.cardMetaDeckCount * 2)
        .clamp(1, 100)
        .toInt();
    return {
      'commander_name_normalized': entry.commanderNameNormalized,
      'commander_name': entry.commanderName,
      'card_id': entry.cardId,
      'card_name': entry.cardName,
      'role': entry.role,
      'score': score,
      'source': _metaSynergySource,
      'evidence_count': entry.evidenceCount,
      'evidence': 'meta_decks_cooccurrence',
    };
  }).toList()
    ..sort((a, b) {
      final byScore = (b['score'] as int).compareTo(a['score'] as int);
      if (byScore != 0) return byScore;
      final byEvidence =
          (b['evidence_count'] as int).compareTo(a['evidence_count'] as int);
      if (byEvidence != 0) return byEvidence;
      return (a['card_name'] as String).compareTo(b['card_name'] as String);
    });

  return output.take(maxRows).toList(growable: false);
}

Future<List<Map<String, dynamic>>> _loadRejectionPenaltyRows(Pool pool) async {
  if (!await _hasTable(pool, 'optimization_analysis_logs')) {
    return const <Map<String, dynamic>>[];
  }

  final rows = await pool.execute('''
SELECT
  COALESCE(commander_name, '') AS commander_name,
  COALESCE(target_archetype, '') AS archetype,
  value AS card_name,
  COUNT(*)::int AS reject_count
FROM optimization_analysis_logs oal
CROSS JOIN LATERAL jsonb_array_elements_text(oal.additions_list) AS value
WHERE oal.additions_list IS NOT NULL
  AND jsonb_typeof(oal.additions_list) = 'array'
  AND (
    COALESCE(oal.validation_score, 0) < 70
    OR COALESCE(oal.validation_verdict, '') <> 'aprovado'
  )
GROUP BY commander_name, archetype, value
ORDER BY reject_count DESC, card_name ASC
LIMIT 2000
''');

  return rows.map((row) {
    final rawCardName = ((row[2] as String?) ?? '').trim();
    final safeCardName = rawCardName.startsWith('{') ? '' : rawCardName;
    final commanderName = ((row[0] as String?) ?? '').trim();
    final archetype = ((row[1] as String?) ?? '').trim().toLowerCase();
    final rejectCount = (row[3] as int?) ?? 0;
    return {
      'card_name_normalized': normalizeCandidateQualityKey(safeCardName),
      'card_name': safeCardName,
      'commander_name_normalized': normalizeCandidateQualityKey(commanderName),
      'commander_name': commanderName,
      'archetype': archetype,
      'function': '',
      'penalty': (rejectCount * 35).clamp(35, 500).toInt(),
      'reject_count': rejectCount,
      'source': _rejectionPenaltySource,
      'evidence': 'aggregated_failed_optimization_additions',
    };
  }).where((row) {
    return (row['card_name'] as String).isNotEmpty &&
        (row['card_name_normalized'] as String).isNotEmpty;
  }).toList(growable: false);
}

List<Map<String, dynamic>> _buildSampleCandidatePools({
  required List<Map<String, dynamic>> synergyRows,
  required List<Map<String, dynamic>> roleRows,
  required Map<String, CandidateQualityCard> cardsById,
  required Map<String, CandidateQualityCard> cardsByName,
  required Map<String, String> legalStatuses,
}) {
  final roleRowsByCardId = <String, List<Map<String, dynamic>>>{};
  for (final row in roleRows) {
    roleRowsByCardId.putIfAbsent(row['card_id'] as String, () => []).add(row);
  }

  final commanderNames = <String>[];
  for (final row in synergyRows) {
    final commanderName = (row['commander_name'] as String?) ?? '';
    if (commanderName.isNotEmpty && !commanderNames.contains(commanderName)) {
      commanderNames.add(commanderName);
    }
    if (commanderNames.length >= 3) break;
  }

  final fallbackShells = <Map<String, dynamic>>[
    {
      'label': 'aggro_red',
      'identity': const {'R'},
      'roles': const ['removal', 'ramp', 'draw', 'protection'],
    },
    {
      'label': 'control_blue_white',
      'identity': const {'W', 'U'},
      'roles': const ['removal', 'draw', 'wipe', 'protection'],
    },
    {
      'label': 'midrange_golgari',
      'identity': const {'B', 'G'},
      'roles': const ['ramp', 'draw', 'removal', 'recursion'],
    },
  ];

  final samples = <Map<String, dynamic>>[];
  for (final commanderName in commanderNames) {
    final commander = cardsByName[normalizeCandidateQualityKey(commanderName)];
    if (commander == null) continue;
    samples.add(_buildOneSamplePool(
      label: commanderName,
      commanderIdentity: commander.resolvedIdentity,
      roles: const ['ramp', 'draw', 'removal', 'protection', 'wipe'],
      roleRowsByCardId: roleRowsByCardId,
      cardsById: cardsById,
      legalStatuses: legalStatuses,
    ));
  }

  for (final fallback in fallbackShells) {
    if (samples.length >= 3) break;
    samples.add(_buildOneSamplePool(
      label: fallback['label'] as String,
      commanderIdentity: (fallback['identity'] as Set<String>),
      roles: (fallback['roles'] as List<String>),
      roleRowsByCardId: roleRowsByCardId,
      cardsById: cardsById,
      legalStatuses: legalStatuses,
    ));
  }

  return samples.take(3).toList(growable: false);
}

Map<String, dynamic> _buildOneSamplePool({
  required String label,
  required Set<String> commanderIdentity,
  required List<String> roles,
  required Map<String, List<Map<String, dynamic>>> roleRowsByCardId,
  required Map<String, CandidateQualityCard> cardsById,
  required Map<String, String> legalStatuses,
}) {
  final candidates = <Map<String, dynamic>>[];
  for (final entry in roleRowsByCardId.entries) {
    final card = cardsById[entry.key];
    if (card == null) continue;
    final status = legalStatuses[card.id];
    final commanderLegal =
        status == null || status == 'legal' || status == 'restricted';
    if (!commanderLegal) continue;
    if (!card.resolvedIdentity.every(commanderIdentity.contains)) continue;

    final best = entry.value
        .where((row) => roles.contains(row['role']))
        .fold<Map<String, dynamic>?>(null, (current, row) {
      if (current == null ||
          (row['score'] as int) > (current['score'] as int)) {
        return row;
      }
      return current;
    });
    if (best == null) continue;
    candidates.add({
      'card_name': card.name,
      'role': best['role'],
      'score': best['score'],
      'budget_tier': best['budget_tier'],
      'bracket_scope': best['bracket_scope'],
      'legal_status':
          status ?? 'not_listed_treated_as_allowed_by_existing_optimizer',
      'color_identity': card.resolvedIdentity.toList()..sort(),
    });
  }

  candidates.sort((a, b) {
    final byScore = (b['score'] as int).compareTo(a['score'] as int);
    if (byScore != 0) return byScore;
    return (a['card_name'] as String).compareTo(b['card_name'] as String);
  });

  return {
    'label': label,
    'commander_identity': commanderIdentity.toList()..sort(),
    'roles_requested': roles,
    'guardrails': const [
      'commander legality status legal/restricted/null only',
      'card color identity subset of commander identity',
      'metadata tags do not modify legalities or color identity',
    ],
    'candidates': candidates.take(12).toList(),
  };
}

Future<void> _ensureCandidateQualitySchema(Pool pool) async {
  for (final statement in candidateQualitySchemaStatements) {
    await pool.execute(statement);
  }
  for (final statement in candidateQualityIndexStatements) {
    await pool.execute(statement);
  }
  await pool.execute(optimizeCandidateQualitySummaryViewStatement);
}

Future<int> _upsertFunctionTags(
  Pool pool,
  List<Map<String, dynamic>> rows,
) async {
  var count = 0;
  await pool.runTx((session) async {
    for (final batch in _batches(rows, 1000)) {
      await session.execute(
        Sql.named('''
WITH input AS (
  SELECT *
  FROM jsonb_to_recordset(@rows::jsonb) AS x(
    card_id text,
    card_name text,
    tag text,
    confidence numeric,
    source text,
    evidence text
  )
)
INSERT INTO card_function_tags (
  card_id, card_name, tag, confidence, source, evidence, updated_at
)
SELECT
  card_id::uuid,
  card_name,
  tag,
  confidence,
  source,
  evidence,
  CURRENT_TIMESTAMP
FROM input
ON CONFLICT (card_id, tag, source) DO UPDATE SET
  card_name = EXCLUDED.card_name,
  confidence = EXCLUDED.confidence,
  evidence = EXCLUDED.evidence,
  updated_at = CURRENT_TIMESTAMP
'''),
        parameters: {'rows': jsonEncode(batch)},
      );
      count += batch.length;
    }
  });
  return count;
}

Future<int> _upsertRoleScores(
  Pool pool,
  List<Map<String, dynamic>> rows,
) async {
  var count = 0;
  await pool.runTx((session) async {
    for (final batch in _batches(rows, 1000)) {
      await session.execute(
        Sql.named('''
WITH input AS (
  SELECT *
  FROM jsonb_to_recordset(@rows::jsonb) AS x(
    card_id text,
    card_name text,
    role text,
    score int,
    format text,
    subformat text,
    bracket_scope text,
    budget_tier text,
    source text,
    evidence text
  )
)
INSERT INTO card_role_scores (
  card_id,
  card_name,
  role,
  score,
  format,
  subformat,
  bracket_scope,
  budget_tier,
  source,
  evidence,
  updated_at
)
SELECT
  card_id::uuid,
  card_name,
  role,
  score,
  format,
  subformat,
  bracket_scope,
  budget_tier,
  source,
  evidence,
  CURRENT_TIMESTAMP
FROM input
ON CONFLICT (card_id, role, format, subformat, bracket_scope, source)
DO UPDATE SET
  card_name = EXCLUDED.card_name,
  score = EXCLUDED.score,
  budget_tier = EXCLUDED.budget_tier,
  evidence = EXCLUDED.evidence,
  updated_at = CURRENT_TIMESTAMP
'''),
        parameters: {'rows': jsonEncode(batch)},
      );
      count += batch.length;
    }
  });
  return count;
}

Future<int> _upsertCommanderSynergies(
  Pool pool,
  List<Map<String, dynamic>> rows,
) async {
  var count = 0;
  await pool.runTx((session) async {
    for (final batch in _batches(rows, 1000)) {
      await session.execute(
        Sql.named('''
WITH input AS (
  SELECT *
  FROM jsonb_to_recordset(@rows::jsonb) AS x(
    commander_name_normalized text,
    commander_name text,
    card_id text,
    card_name text,
    role text,
    score int,
    source text,
    evidence_count int,
    evidence text
  )
)
INSERT INTO commander_card_synergy (
  commander_name_normalized,
  commander_name,
  card_id,
  card_name,
  role,
  score,
  source,
  evidence_count,
  evidence,
  updated_at
)
SELECT
  commander_name_normalized,
  commander_name,
  card_id::uuid,
  card_name,
  role,
  score,
  source,
  evidence_count,
  evidence,
  CURRENT_TIMESTAMP
FROM input
ON CONFLICT (commander_name_normalized, card_id, role, source)
DO UPDATE SET
  commander_name = EXCLUDED.commander_name,
  card_name = EXCLUDED.card_name,
  score = EXCLUDED.score,
  evidence_count = EXCLUDED.evidence_count,
  evidence = EXCLUDED.evidence,
  updated_at = CURRENT_TIMESTAMP
'''),
        parameters: {'rows': jsonEncode(batch)},
      );
      count += batch.length;
    }
  });
  return count;
}

Future<int> _upsertRejectionPenalties(
  Pool pool,
  List<Map<String, dynamic>> rows,
) async {
  var count = 0;
  await pool.runTx((session) async {
    for (final batch in _batches(rows, 1000)) {
      await session.execute(
        Sql.named('''
WITH input AS (
  SELECT *
  FROM jsonb_to_recordset(@rows::jsonb) AS x(
    card_name_normalized text,
    card_name text,
    commander_name_normalized text,
    commander_name text,
    archetype text,
    function text,
    penalty int,
    reject_count int,
    source text,
    evidence text
  )
)
INSERT INTO optimize_rejection_penalties (
  card_name_normalized,
  card_name,
  commander_name_normalized,
  commander_name,
  archetype,
  function,
  penalty,
  reject_count,
  source,
  evidence,
  updated_at
)
SELECT
  card_name_normalized,
  card_name,
  commander_name_normalized,
  commander_name,
  archetype,
  function,
  penalty,
  reject_count,
  source,
  evidence,
  CURRENT_TIMESTAMP
FROM input
ON CONFLICT (
  card_name_normalized,
  commander_name_normalized,
  archetype,
  function,
  source
) DO UPDATE SET
  card_name = EXCLUDED.card_name,
  commander_name = EXCLUDED.commander_name,
  penalty = EXCLUDED.penalty,
  reject_count = EXCLUDED.reject_count,
  evidence = EXCLUDED.evidence,
  updated_at = CURRENT_TIMESTAMP
'''),
        parameters: {'rows': jsonEncode(batch)},
      );
      count += batch.length;
    }
  });
  return count;
}

Future<Map<String, int>> _countStaleGeneratedRows({
  required Pool pool,
  required List<Map<String, dynamic>> tagRows,
  required List<Map<String, dynamic>> roleRows,
  required List<Map<String, dynamic>> synergyRows,
  required List<Map<String, dynamic>> penaltyRows,
}) async {
  return {
    'card_function_tags': await _countStaleFunctionTags(pool, tagRows),
    'card_role_scores': await _countStaleRoleScores(pool, roleRows),
    'commander_card_synergy':
        await _countStaleCommanderSynergies(pool, synergyRows),
    'optimize_rejection_penalties':
        await _countStaleRejectionPenalties(pool, penaltyRows),
  };
}

Future<int> _countStaleFunctionTags(
  Pool pool,
  List<Map<String, dynamic>> rows,
) async {
  if (rows.isEmpty || !await _hasTable(pool, 'card_function_tags')) return 0;
  final result = await pool.execute(
    Sql.named('''
WITH planned AS (
  SELECT *
  FROM jsonb_to_recordset(@rows::jsonb) AS x(
    card_id text,
    tag text
  )
)
SELECT COUNT(*)::int
FROM card_function_tags existing
WHERE existing.source = @source
  AND NOT EXISTS (
    SELECT 1
    FROM planned p
    WHERE existing.card_id = p.card_id::uuid
      AND existing.tag = p.tag
  )
'''),
    parameters: {
      'rows': jsonEncode(rows),
      'source': _heuristicSource,
    },
  );
  return (result.first[0] as int?) ?? 0;
}

Future<int> _countStaleRoleScores(
  Pool pool,
  List<Map<String, dynamic>> rows,
) async {
  if (rows.isEmpty || !await _hasTable(pool, 'card_role_scores')) return 0;
  final result = await pool.execute(
    Sql.named('''
WITH planned AS (
  SELECT *
  FROM jsonb_to_recordset(@rows::jsonb) AS x(
    card_id text,
    role text,
    format text,
    subformat text,
    bracket_scope text
  )
)
SELECT COUNT(*)::int
FROM card_role_scores existing
WHERE existing.source = @source
  AND NOT EXISTS (
    SELECT 1
    FROM planned p
    WHERE existing.card_id = p.card_id::uuid
      AND existing.role = p.role
      AND existing.format = p.format
      AND existing.subformat = p.subformat
      AND existing.bracket_scope = p.bracket_scope
  )
'''),
    parameters: {
      'rows': jsonEncode(rows),
      'source': _heuristicSource,
    },
  );
  return (result.first[0] as int?) ?? 0;
}

Future<int> _countStaleCommanderSynergies(
  Pool pool,
  List<Map<String, dynamic>> rows,
) async {
  if (rows.isEmpty || !await _hasTable(pool, 'commander_card_synergy')) {
    return 0;
  }
  final result = await pool.execute(
    Sql.named('''
WITH planned AS (
  SELECT *
  FROM jsonb_to_recordset(@rows::jsonb) AS x(
    commander_name_normalized text,
    card_id text,
    role text
  )
)
SELECT COUNT(*)::int
FROM commander_card_synergy existing
WHERE existing.source = @source
  AND NOT EXISTS (
    SELECT 1
    FROM planned p
    WHERE existing.commander_name_normalized = p.commander_name_normalized
      AND existing.card_id = p.card_id::uuid
      AND existing.role = p.role
  )
'''),
    parameters: {
      'rows': jsonEncode(rows),
      'source': _metaSynergySource,
    },
  );
  return (result.first[0] as int?) ?? 0;
}

Future<int> _countStaleRejectionPenalties(
  Pool pool,
  List<Map<String, dynamic>> rows,
) async {
  if (rows.isEmpty || !await _hasTable(pool, 'optimize_rejection_penalties')) {
    return 0;
  }
  final result = await pool.execute(
    Sql.named('''
WITH planned AS (
  SELECT *
  FROM jsonb_to_recordset(@rows::jsonb) AS x(
    card_name_normalized text,
    commander_name_normalized text,
    archetype text,
    function text
  )
)
SELECT COUNT(*)::int
FROM optimize_rejection_penalties existing
WHERE existing.source = @source
  AND NOT EXISTS (
    SELECT 1
    FROM planned p
    WHERE existing.card_name_normalized = p.card_name_normalized
      AND existing.commander_name_normalized = p.commander_name_normalized
      AND existing.archetype = p.archetype
      AND existing.function = p.function
  )
'''),
    parameters: {
      'rows': jsonEncode(rows),
      'source': _rejectionPenaltySource,
    },
  );
  return (result.first[0] as int?) ?? 0;
}

Future<int> _pruneStaleFunctionTags(
  Pool pool,
  List<Map<String, dynamic>> rows,
) async {
  if (rows.isEmpty) return 0;
  final result = await pool.execute(
    Sql.named('''
WITH planned AS (
  SELECT *
  FROM jsonb_to_recordset(@rows::jsonb) AS x(
    card_id text,
    tag text
  )
),
deleted AS (
  DELETE FROM card_function_tags existing
  WHERE existing.source = @source
    AND NOT EXISTS (
      SELECT 1
      FROM planned p
      WHERE existing.card_id = p.card_id::uuid
        AND existing.tag = p.tag
    )
  RETURNING 1
)
SELECT COUNT(*)::int FROM deleted
'''),
    parameters: {
      'rows': jsonEncode(rows),
      'source': _heuristicSource,
    },
  );
  return (result.first[0] as int?) ?? 0;
}

Future<int> _pruneStaleRoleScores(
  Pool pool,
  List<Map<String, dynamic>> rows,
) async {
  if (rows.isEmpty) return 0;
  final result = await pool.execute(
    Sql.named('''
WITH planned AS (
  SELECT *
  FROM jsonb_to_recordset(@rows::jsonb) AS x(
    card_id text,
    role text,
    format text,
    subformat text,
    bracket_scope text
  )
),
deleted AS (
  DELETE FROM card_role_scores existing
  WHERE existing.source = @source
    AND NOT EXISTS (
      SELECT 1
      FROM planned p
      WHERE existing.card_id = p.card_id::uuid
        AND existing.role = p.role
        AND existing.format = p.format
        AND existing.subformat = p.subformat
        AND existing.bracket_scope = p.bracket_scope
    )
  RETURNING 1
)
SELECT COUNT(*)::int FROM deleted
'''),
    parameters: {
      'rows': jsonEncode(rows),
      'source': _heuristicSource,
    },
  );
  return (result.first[0] as int?) ?? 0;
}

Future<int> _pruneStaleCommanderSynergies(
  Pool pool,
  List<Map<String, dynamic>> rows,
) async {
  if (rows.isEmpty) return 0;
  final result = await pool.execute(
    Sql.named('''
WITH planned AS (
  SELECT *
  FROM jsonb_to_recordset(@rows::jsonb) AS x(
    commander_name_normalized text,
    card_id text,
    role text
  )
),
deleted AS (
  DELETE FROM commander_card_synergy existing
  WHERE existing.source = @source
    AND NOT EXISTS (
      SELECT 1
      FROM planned p
      WHERE existing.commander_name_normalized = p.commander_name_normalized
        AND existing.card_id = p.card_id::uuid
        AND existing.role = p.role
    )
  RETURNING 1
)
SELECT COUNT(*)::int FROM deleted
'''),
    parameters: {
      'rows': jsonEncode(rows),
      'source': _metaSynergySource,
    },
  );
  return (result.first[0] as int?) ?? 0;
}

Future<int> _pruneStaleRejectionPenalties(
  Pool pool,
  List<Map<String, dynamic>> rows,
) async {
  if (rows.isEmpty) return 0;
  final result = await pool.execute(
    Sql.named('''
WITH planned AS (
  SELECT *
  FROM jsonb_to_recordset(@rows::jsonb) AS x(
    card_name_normalized text,
    commander_name_normalized text,
    archetype text,
    function text
  )
),
deleted AS (
  DELETE FROM optimize_rejection_penalties existing
  WHERE existing.source = @source
    AND NOT EXISTS (
      SELECT 1
      FROM planned p
      WHERE existing.card_name_normalized = p.card_name_normalized
        AND existing.commander_name_normalized = p.commander_name_normalized
        AND existing.archetype = p.archetype
        AND existing.function = p.function
    )
  RETURNING 1
)
SELECT COUNT(*)::int FROM deleted
'''),
    parameters: {
      'rows': jsonEncode(rows),
      'source': _rejectionPenaltySource,
    },
  );
  return (result.first[0] as int?) ?? 0;
}

Iterable<List<Map<String, dynamic>>> _batches(
  List<Map<String, dynamic>> rows,
  int size,
) sync* {
  for (var start = 0; start < rows.length; start += size) {
    final end = (start + size) > rows.length ? rows.length : start + size;
    yield rows.sublist(start, end);
  }
}

Future<bool> _hasTable(Pool pool, String tableName) async {
  final result = await pool.execute(
    Sql.named('SELECT to_regclass(@name)::text'),
    parameters: {'name': 'public.$tableName'},
  );
  return result.isNotEmpty && result.first[0] != null;
}

Map<String, int> _countBy(List<Map<String, dynamic>> rows, String key) {
  final counts = <String, int>{};
  for (final row in rows) {
    final value = row[key]?.toString() ?? '';
    if (value.isEmpty) continue;
    counts[value] = (counts[value] ?? 0) + 1;
  }
  return Map.fromEntries(
    counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
  );
}

String? _readArg(List<String> args, String prefix) {
  for (final arg in args) {
    if (arg.startsWith(prefix)) return arg.substring(prefix.length);
  }
  return null;
}

Future<void> _writeJson(String path, Object? payload) async {
  await File(path).writeAsString(
    const JsonEncoder.withIndent('  ').convert(payload),
  );
}

Future<void> _writeCsv(
  String path,
  List<Map<String, dynamic>> rows,
  List<String> headers,
) async {
  final buffer = StringBuffer()..writeln(headers.join(','));
  for (final row in rows) {
    buffer.writeln(headers.map((header) => _csv(row[header])).join(','));
  }
  await File(path).writeAsString(buffer.toString());
}

String _csv(Object? value) {
  final text = value?.toString() ?? '';
  if (!text.contains(',') && !text.contains('"') && !text.contains('\n')) {
    return text;
  }
  return '"${text.replaceAll('"', '""')}"';
}

Future<void> _writeSummaryMarkdown(
  String path,
  Map<String, dynamic> summary,
) async {
  final buffer = StringBuffer()
    ..writeln('# Aggressive Candidate Quality v2 - ${summary['mode']}')
    ..writeln()
    ..writeln('- Schema version: `${summary['schema_version']}`')
    ..writeln('- DB mutations: `${summary['db_mutations']}`')
    ..writeln('- Cards scanned: `${summary['cards_scanned']}`')
    ..writeln(
      '- Cards with deterministic tags: `${summary['cards_with_function_tags']}`',
    )
    ..writeln(
        '- Function tag rows planned: `${summary['function_tag_rows_planned']}`')
    ..writeln(
        '- Role score rows planned: `${summary['role_score_rows_planned']}`')
    ..writeln(
      '- Commander synergy rows planned: `${summary['commander_synergy_rows_planned']}`',
    )
    ..writeln(
      '- Rejection penalty rows planned: `${summary['rejection_penalty_rows_planned']}`',
    )
    ..writeln()
    ..writeln('## Guardrails')
    ..writeln()
    ..writeln(summary['legality_color_identity_guard'])
    ..writeln()
    ..writeln('## Top tags')
    ..writeln()
    ..writeln('| Tag | Count |')
    ..writeln('|---|---:|');
  final tagCounts = summary['tag_counts'] as Map<String, dynamic>;
  for (final entry in tagCounts.entries.take(20)) {
    buffer.writeln('| ${entry.key} | ${entry.value} |');
  }
  await File(path).writeAsString(buffer.toString());
}

class _SynergyAggregate {
  _SynergyAggregate({
    required this.commanderNameNormalized,
    required this.commanderName,
    required this.cardId,
    required this.cardName,
    required this.role,
    required this.cardMetaDeckCount,
  });

  final String commanderNameNormalized;
  final String commanderName;
  final String cardId;
  final String cardName;
  final String role;
  final int cardMetaDeckCount;
  int evidenceCount = 0;
}
