import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:postgres/postgres.dart';
import 'package:server/ai/candidate_quality_data_support.dart';
import 'package:server/ai/optimize_rejection_history_support.dart';
import 'package:server/database.dart';
import 'package:server/meta/meta_deck_card_list_support.dart';

const _defaultArtifactDir =
    'test/artifacts/aggressive_candidate_quality_v2_2026-05-05';
const _heuristicSource = 'deterministic_heuristic_v1';
const _metaSynergySource = 'meta_decks_cooccurrence_v1';
const _rejectionPenaltySource = 'quality_gate_history_v1';
const _defaultMaxStalePruneOnApply = 100;
const _postgresWriteApprovalEnv = 'MANALOOM_CONFIRM_POSTGRES_WRITES';
const _postgresWriteApprovalValue = 'I_HAVE_EXPLICIT_APPROVAL';
const _failureInjectionEnv = 'MANALOOM_ENABLE_FOUNDATION_FAILURE_INJECTION';
const _failureInjectionValue = 'I_UNDERSTAND_THIS_MUST_ROLL_BACK';
const _staleGeneratedRowsCsvHeaders = <String>[
  'table',
  'card_id',
  'card_name',
  'tag',
  'role',
  'format',
  'subformat',
  'bracket_scope',
  'budget_tier',
  'commander_name_normalized',
  'commander_name',
  'card_name_normalized',
  'archetype',
  'function',
  'source',
  'score',
  'confidence',
  'penalty',
  'evidence_count',
  'evidence',
  'updated_at',
];

Future<void> main(List<String> args) async {
  if (args.contains('--help') || args.contains('-h')) {
    _printUsage();
    return;
  }

  final apply = args.contains('--apply');
  final pruneStaleOnly = args.contains('--prune-stale-only');
  final explicitDryRun = args.contains('--dry-run');
  final dryRun = explicitDryRun || (!apply && !pruneStaleOnly);
  if ([apply, pruneStaleOnly, explicitDryRun].where((mode) => mode).length >
      1) {
    throw ArgumentError(
      'Use apenas um modo: --dry-run, --apply ou --prune-stale-only.',
    );
  }
  if ((apply || pruneStaleOnly) &&
      Platform.environment[_postgresWriteApprovalEnv] !=
          _postgresWriteApprovalValue) {
    throw StateError(
      'PostgreSQL write refused: export '
      '$_postgresWriteApprovalEnv=$_postgresWriteApprovalValue.',
    );
  }
  final pruneTarget = _readArg(args, '--target=');
  final maxPrune = int.tryParse(_readArg(args, '--max-prune=') ?? '') ?? 1;
  final maxStalePruneOnApply =
      int.tryParse(_readArg(args, '--max-stale-prune-on-apply=') ?? '') ??
      _defaultMaxStalePruneOnApply;
  final allowLargeStalePrune = args.contains('--allow-large-stale-prune');
  final fullArtifacts = args.contains('--full-artifacts');
  final testFailAfterLane = _readArg(args, '--test-fail-after-lane=');
  if (testFailAfterLane != null &&
      Platform.environment[_failureInjectionEnv] != _failureInjectionValue) {
    throw StateError(
      'Foundation failure injection refused: export '
      '$_failureInjectionEnv=$_failureInjectionValue.',
    );
  }
  if (maxStalePruneOnApply < 0) {
    throw ArgumentError('--max-stale-prune-on-apply deve ser >= 0.');
  }
  if (pruneStaleOnly) {
    if (pruneTarget != 'card_role_scores') {
      throw ArgumentError(
        '--prune-stale-only exige --target=card_role_scores nesta etapa.',
      );
    }
    if (maxPrune < 0) {
      throw ArgumentError('--max-prune deve ser >= 0.');
    }
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
        edhrecInclusionRate: card.edhrecInclusionRate,
        edhrecSampleDecks: card.edhrecSampleDecks,
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
    validateCandidateQualityPlannedDatasets(
      tagRows: tagRows,
      roleRows: roleRows,
      synergyRows: synergyRows,
      penaltyRows: penaltyRows,
    );
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
    var prunedRows = <Map<String, dynamic>>[];
    final staleGeneratedRowsBeforeApply = await _loadStaleGeneratedRowsSnapshot(
      pool: pool,
      tagRows: tagRows,
      roleRows: roleRows,
      synergyRows: synergyRows,
      penaltyRows: penaltyRows,
    );
    final staleRowsBeforeApply = staleGeneratedRowsBeforeApply.map(
      (table, rows) => MapEntry(table, rows.length),
    );
    if (apply) {
      _guardApplyStalePrune(
        staleRowsByTable: staleRowsBeforeApply,
        maxRowsPerTable: maxStalePruneOnApply,
        allowLargeStalePrune: allowLargeStalePrune,
      );
    }
    final flattenedStaleRows = _flattenStaleGeneratedRows(
      staleGeneratedRowsBeforeApply,
    );
    await _writeJson(
      '${artifactDir.path}/stale_generated_rows_preview.json',
      staleGeneratedRowsBeforeApply,
    );
    await _writeCsv(
      '${artifactDir.path}/stale_generated_rows_preview.csv',
      flattenedStaleRows,
      _staleGeneratedRowsCsvHeaders,
    );

    if (apply) {
      final mutationCounts = await pool.runTx<Map<String, int>>((
        session,
      ) async {
        await session.execute(
          "SELECT pg_advisory_xact_lock(hashtext('manaloom_candidate_quality_foundation'))",
        );
        await session.execute('SET LOCAL max_parallel_workers_per_gather = 0');
        final transactionStaleRows = await _loadStaleGeneratedRows(
          pool: session,
          tagRows: tagRows,
          roleRows: roleRows,
          synergyRows: synergyRows,
          penaltyRows: penaltyRows,
        );
        _guardStalePreviewUnchanged(
          preview: staleGeneratedRowsBeforeApply,
          transactionRows: transactionStaleRows,
        );
        await _ensureCandidateQualitySchema(session);
        final counts = <String, int>{};
        counts['upserted_function_tags'] = await _upsertFunctionTags(
          session,
          tagRows,
        );
        _maybeInjectFoundationFailure(
          configuredLane: testFailAfterLane,
          completedLane: 'card_function_tags',
        );
        counts['upserted_role_scores'] = await _upsertRoleScores(
          session,
          roleRows,
        );
        _maybeInjectFoundationFailure(
          configuredLane: testFailAfterLane,
          completedLane: 'card_role_scores',
        );
        counts['upserted_commander_synergies'] =
            await _upsertCommanderSynergies(session, synergyRows);
        _maybeInjectFoundationFailure(
          configuredLane: testFailAfterLane,
          completedLane: 'commander_card_synergy',
        );
        counts['upserted_rejection_penalties'] =
            await _upsertRejectionPenalties(session, penaltyRows);
        _maybeInjectFoundationFailure(
          configuredLane: testFailAfterLane,
          completedLane: 'optimize_rejection_penalties',
        );
        counts['pruned_function_tags'] = await _pruneStaleFunctionTags(
          session,
          tagRows,
        );
        counts['pruned_role_scores'] = await _pruneStaleRoleScores(
          session,
          roleRows,
        );
        counts['pruned_commander_synergies'] =
            await _pruneStaleCommanderSynergies(session, synergyRows);
        counts['pruned_rejection_penalties'] =
            await _pruneStaleRejectionPenalties(session, penaltyRows);
        _maybeInjectFoundationFailure(
          configuredLane: testFailAfterLane,
          completedLane: 'prunes',
        );
        return counts;
      });
      upsertedTags = mutationCounts['upserted_function_tags'] ?? 0;
      upsertedRoleScores = mutationCounts['upserted_role_scores'] ?? 0;
      upsertedSynergies = mutationCounts['upserted_commander_synergies'] ?? 0;
      upsertedPenalties = mutationCounts['upserted_rejection_penalties'] ?? 0;
      prunedStaleFunctionTags = mutationCounts['pruned_function_tags'] ?? 0;
      prunedStaleRoleScores = mutationCounts['pruned_role_scores'] ?? 0;
      prunedStaleSynergies = mutationCounts['pruned_commander_synergies'] ?? 0;
      prunedStalePenalties = mutationCounts['pruned_rejection_penalties'] ?? 0;
      applied = mutationCounts.values.any((count) => count > 0);
    } else if (pruneStaleOnly) {
      final expectedRows =
          staleGeneratedRowsBeforeApply[pruneTarget] ??
          const <Map<String, dynamic>>[];
      prunedRows = await _pruneStaleRoleScoresWithGuard(
        pool: pool,
        roleRows: roleRows,
        expectedRows: expectedRows,
        maxPrune: maxPrune,
      );
      prunedStaleRoleScores = prunedRows.length;
      applied = prunedRows.isNotEmpty;
      await _writeJson(
        '${artifactDir.path}/stale_generated_rows_pruned.json',
        prunedRows,
      );
      await _writeCsv(
        '${artifactDir.path}/stale_generated_rows_pruned.csv',
        prunedRows.map((row) => {'table': pruneTarget, ...row}).toList(),
        _staleGeneratedRowsCsvHeaders,
      );
    }

    final postCounts = await _loadPreCounts(pool);
    final summary = {
      'schema_version': candidateQualitySchemaVersion,
      'mode':
          dryRun
              ? 'dry_run'
              : pruneStaleOnly
              ? 'prune_stale_only'
              : 'apply',
      'started_at': startedAt.toIso8601String(),
      'finished_at': DateTime.now().toIso8601String(),
      'db_mutations': applied,
      'artifact_dir': artifactDir.path,
      'prune_target': pruneTarget,
      'max_prune': maxPrune,
      'apply_stale_prune_guard': {
        'max_stale_prune_on_apply': maxStalePruneOnApply,
        'allow_large_stale_prune': allowLargeStalePrune,
      },
      'artifact_scope': fullArtifacts ? 'full' : 'preview_500',
      'pre_counts': preCounts,
      'post_counts': postCounts,
      'cards_scanned': cards.length,
      'cards_with_function_tags':
          tagRows.map((row) => row['card_id']).toSet().length,
      'function_tag_rows_planned': tagRows.length,
      'role_score_rows_planned': roleRows.length,
      'commander_synergy_rows_planned': synergyRows.length,
      'rejection_penalty_rows_planned': penaltyRows.length,
      'planned_dataset_sha256': {
        'card_function_tags': _rowsDigest(tagRows),
        'card_role_scores': _rowsDigest(roleRows),
        'commander_card_synergy': _rowsDigest(synergyRows),
        'optimize_rejection_penalties': _rowsDigest(penaltyRows),
      },
      'planned_dataset_unique_rows': {
        'card_function_tags': tagRows.length,
        'card_role_scores': roleRows.length,
        'commander_card_synergy': synergyRows.length,
        'optimize_rejection_penalties': penaltyRows.length,
      },
      'cards_with_edhrec_signal':
          cards
              .where(
                (card) =>
                    card.edhrecInclusionRate > 0 || card.edhrecSampleDecks > 0,
              )
              .length,
      'function_tag_coverage_pct':
          cards.isEmpty
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
      'pruned_rows': prunedRows,
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
            'enabled through persisted functional_tags, semantic_tags_v2, and card_role_scores with deterministic fallback',
        'human_reviewed_tags': 'not proven',
      },
    };

    await _writeJson(
      '${artifactDir.path}/summary_${summary['mode']}.json',
      summary,
    );
    await _writeJson(
      '${artifactDir.path}/function_tag_rows_preview.json',
      tagRows.take(500).toList(),
    );
    await _writeJson(
      '${artifactDir.path}/role_score_rows_preview.json',
      roleRows.take(500).toList(),
    );
    await _writeJson(
      '${artifactDir.path}/commander_synergy_rows_preview.json',
      synergyRows.take(500).toList(),
    );
    await _writeJson(
      '${artifactDir.path}/rejection_penalty_rows_preview.json',
      penaltyRows.take(500).toList(),
    );
    if (fullArtifacts) {
      await _writeJson(
        '${artifactDir.path}/function_tag_rows_full.json',
        tagRows,
      );
      await _writeJson(
        '${artifactDir.path}/role_score_rows_full.json',
        roleRows,
      );
      await _writeJson(
        '${artifactDir.path}/commander_synergy_rows_full.json',
        synergyRows,
      );
      await _writeJson(
        '${artifactDir.path}/rejection_penalty_rows_full.json',
        penaltyRows,
      );
    }
    await _writeJson(
      '${artifactDir.path}/sample_candidate_pools.json',
      samplePools,
    );
    await _writeCsv(
      '${artifactDir.path}/tag_counts.csv',
      _countBy(tagRows, 'tag').entries
          .map((entry) => {'tag': entry.key, 'count': entry.value})
          .toList(),
      const ['tag', 'count'],
    );
    await _writeSummaryMarkdown(
      '${artifactDir.path}/summary_${summary['mode']}.md',
      summary,
    );

    stdout.writeln(
      apply
          ? '[OK] Candidate quality foundation aplicada.'
          : pruneStaleOnly
          ? '[OK] Candidate quality stale prune concluido.'
          : '[OK] Candidate quality foundation dry-run concluido.',
    );
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
  dart run bin/candidate_quality_data_foundation.dart --prune-stale-only --target=card_role_scores --max-prune=1
  dart run bin/candidate_quality_data_foundation.dart --dry-run --artifact-dir=test/artifacts/acqv2

Opcoes:
  --dry-run                    Gera cobertura/artefatos sem alterar banco (default)
  --apply                      Cria schema aditivo e faz upsert idempotente
  --prune-stale-only           Remove somente stale generated rows do target explicitado
  --target=<table>             Target do prune-only; atualmente card_role_scores
  --max-prune=<N>              Limite de rows deletaveis no prune-only (default: 1)
  --max-stale-prune-on-apply=<N>
                               Limite por tabela para prune automatico no --apply (default: $_defaultMaxStalePruneOnApply)
  --allow-large-stale-prune    Permite --apply mesmo quando stale prune passa do limite
  MANALOOM_CONFIRM_POSTGRES_WRITES=I_HAVE_EXPLICIT_APPROVAL e obrigatorio para qualquer modo mutante
  --test-fail-after-lane=<lane> Injeta falha transacional somente com $_failureInjectionEnv=$_failureInjectionValue
  --full-artifacts             Grava datasets planejados completos alem dos previews de 500 rows
  --artifact-dir=<path>        Diretorio de artefatos
  --min-synergy-evidence=<N>   Minimo de ocorrencias por commander/card (default: 2)
  --max-synergy-rows=<N>       Limite de rows de synergy a materializar (default: 5000)
  --help                       Mostra esta ajuda
''');
}

String _rowsDigest(List<Map<String, dynamic>> rows) {
  final canonical = rows.map(jsonEncode).toList()..sort();
  return sha256.convert(utf8.encode(canonical.join('\n'))).toString();
}

void validateCandidateQualityPlannedDatasets({
  required List<Map<String, dynamic>> tagRows,
  required List<Map<String, dynamic>> roleRows,
  required List<Map<String, dynamic>> synergyRows,
  required List<Map<String, dynamic>> penaltyRows,
}) {
  _guardUniquePlannedRows(
    dataset: 'card_function_tags',
    rows: tagRows,
    keyColumns: const ['card_id', 'tag', 'source'],
  );
  _guardUniquePlannedRows(
    dataset: 'card_role_scores',
    rows: roleRows,
    keyColumns: const [
      'card_id',
      'role',
      'format',
      'subformat',
      'bracket_scope',
      'source',
    ],
  );
  _guardUniquePlannedRows(
    dataset: 'commander_card_synergy',
    rows: synergyRows,
    keyColumns: const [
      'commander_name_normalized',
      'card_id',
      'role',
      'source',
    ],
  );
  _guardUniquePlannedRows(
    dataset: 'optimize_rejection_penalties',
    rows: penaltyRows,
    keyColumns: const [
      'card_name_normalized',
      'commander_name_normalized',
      'archetype',
      'function',
      'source',
    ],
  );
}

void _guardUniquePlannedRows({
  required String dataset,
  required List<Map<String, dynamic>> rows,
  required List<String> keyColumns,
}) {
  final seen = <String>{};
  final duplicateKeys = <String>{};
  for (final row in rows) {
    final key = jsonEncode([
      for (final column in keyColumns) row[column]?.toString() ?? '',
    ]);
    if (!seen.add(key)) duplicateKeys.add(key);
  }
  if (duplicateKeys.isEmpty) return;
  final ordered = duplicateKeys.toList()..sort();
  throw StateError(
    'Planned dataset uniqueness preflight failed: $dataset has '
    '${duplicateKeys.length} duplicate primary/conflict key(s): '
    '${ordered.take(5).join(', ')}',
  );
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
    required this.edhrecInclusionRate,
    required this.edhrecSampleDecks,
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
  final double edhrecInclusionRate;
  final int edhrecSampleDecks;

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
    'edhrec_card_snapshots',
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
  final hasEdhrecSnapshots = await _hasTable(pool, 'edhrec_card_snapshots');
  final edhrecCte =
      hasEdhrecSnapshots
          ? '''
WITH edhrec_insights AS (
  SELECT
    LOWER(card_name) AS normalized_card_name,
    MAX(COALESCE(inclusion, 0))::double precision AS edhrec_inclusion_rate,
    MAX(COALESCE(num_decks, 0))::int AS edhrec_sample_decks
  FROM edhrec_card_snapshots
  WHERE card_name IS NOT NULL
    AND TRIM(card_name) <> ''
  GROUP BY LOWER(card_name)
)
'''
          : '';
  final metaJoin =
      hasMetaInsights
          ? 'LEFT JOIN card_meta_insights cmi ON LOWER(cmi.card_name) = LOWER(c.name)'
          : '';
  final edhrecJoin =
      hasEdhrecSnapshots
          ? 'LEFT JOIN edhrec_insights ei ON ei.normalized_card_name = LOWER(c.name)'
          : '';
  final metaUsageSelect =
      hasMetaInsights ? 'COALESCE(cmi.usage_count, 0)::int' : '0::int';
  final metaDeckSelect =
      hasMetaInsights ? 'COALESCE(cmi.meta_deck_count, 0)::int' : '0::int';
  final edhrecRateSelect =
      hasEdhrecSnapshots
          ? 'COALESCE(ei.edhrec_inclusion_rate, 0)::double precision'
          : '0::double precision';
  final edhrecSampleSelect =
      hasEdhrecSnapshots
          ? 'COALESCE(ei.edhrec_sample_decks, 0)::int'
          : '0::int';
  final edhrecOrder =
      hasEdhrecSnapshots
          ? '''
  COALESCE(ei.edhrec_inclusion_rate, 0) DESC,
  COALESCE(ei.edhrec_sample_decks, 0) DESC,
'''
          : '';
  final metaOrder =
      hasMetaInsights
          ? '''
  COALESCE(cmi.meta_deck_count, 0) DESC,
  COALESCE(cmi.usage_count, 0) DESC,
'''
          : '';
  final sql = '''
$edhrecCte
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
  $metaUsageSelect AS usage_count,
  $metaDeckSelect AS meta_deck_count,
  $edhrecRateSelect AS edhrec_inclusion_rate,
  $edhrecSampleSelect AS edhrec_sample_decks
FROM cards c
$metaJoin
$edhrecJoin
WHERE c.name IS NOT NULL
  AND c.name NOT LIKE 'A-%'
  AND c.name NOT LIKE '\\_%' ESCAPE '\\'
  AND c.name NOT LIKE '%World Champion%'
  AND c.name NOT LIKE '%Heroes of the Realm%'
ORDER BY LOWER(c.name),
$edhrecOrder$metaOrder
  c.set_code ASC NULLS LAST,
  c.id ASC
''';

  final rows = await pool.execute(sql);
  return rows
      .map((row) {
        return CandidateQualityCard(
          id: row[0] as String,
          name: (row[1] as String?) ?? '',
          typeLine: (row[2] as String?) ?? '',
          oracleText: (row[3] as String?) ?? '',
          manaCost: (row[4] as String?) ?? '',
          colors:
              (row[5] as List?)?.map((e) => e.toString()).toList() ??
              const <String>[],
          colorIdentity:
              (row[6] as List?)?.map((e) => e.toString()).toList() ??
              const <String>[],
          cmc: row[7],
          priceUsd: row[8],
          priceUsdFoil: row[9],
          metaUsageCount: (row[10] as int?) ?? 0,
          metaDeckCount: (row[11] as int?) ?? 0,
          edhrecInclusionRate: (row[12] as num?)?.toDouble() ?? 0,
          edhrecSampleDecks: (row[13] as int?) ?? 0,
        );
      })
      .toList(growable: false);
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
      if (row[0] != null) row[0] as String: (row[1] as String?) ?? '',
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
      final role =
          roleRow == null
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

  final output =
      counts.values.where((entry) => entry.evidenceCount >= minEvidence).map((
          entry,
        ) {
          final score =
              (50 + entry.evidenceCount * 7 + entry.cardMetaDeckCount * 2)
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
          final byEvidence = (b['evidence_count'] as int).compareTo(
            a['evidence_count'] as int,
          );
          if (byEvidence != 0) return byEvidence;
          return (a['card_name'] as String).compareTo(b['card_name'] as String);
        });

  return output.take(maxRows).toList(growable: false);
}

Future<List<Map<String, dynamic>>> _loadRejectionPenaltyRows(Pool pool) async {
  if (!await _hasTable(pool, 'optimization_analysis_logs')) {
    throw StateError(
      'Candidate-quality foundation requires optimization_analysis_logs; '
      'refusing to interpret a missing source as an empty authoritative set.',
    );
  }

  final explicitRejectionPredicate = explicitOptimizeQualityRejectionSql('oal');
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
  AND oal.operation_mode = 'optimize'
  AND $explicitRejectionPredicate
GROUP BY commander_name, archetype, value
ORDER BY reject_count DESC, card_name ASC
''');

  return aggregateCandidateQualityRejectionPenaltyRows(
    rows.map(
      (row) => {
        'commander_name': (row[0] as String?) ?? '',
        'archetype': (row[1] as String?) ?? '',
        'card_name': (row[2] as String?) ?? '',
        'reject_count': (row[3] as int?) ?? 0,
      },
    ),
  ).take(2000).toList(growable: false);
}

List<Map<String, dynamic>> aggregateCandidateQualityRejectionPenaltyRows(
  Iterable<Map<String, dynamic>> rawRows,
) {
  final aggregates = <String, _RejectionPenaltyAggregate>{};
  for (final row in rawRows) {
    final rawCardName = _normalizeDisplayName(
      row['card_name']?.toString() ?? '',
    );
    final safeCardName = rawCardName.startsWith('{') ? '' : rawCardName;
    final cardNameNormalized = normalizeCandidateQualityKey(safeCardName);
    if (safeCardName.isEmpty || cardNameNormalized.isEmpty) continue;

    final commanderName = _normalizeDisplayName(
      row['commander_name']?.toString() ?? '',
    );
    final commanderNameNormalized = normalizeCandidateQualityKey(commanderName);
    final archetype = normalizeCandidateQualityKey(
      row['archetype']?.toString() ?? '',
    );
    final function = normalizeCandidateQualityKey(
      row['function']?.toString() ?? '',
    );
    final rejectCount = switch (row['reject_count']) {
      final int value => value,
      final num value => value.toInt(),
      final Object value => int.tryParse(value.toString()) ?? 0,
      _ => 0,
    };
    if (rejectCount <= 0) continue;
    final key = jsonEncode([
      cardNameNormalized,
      commanderNameNormalized,
      archetype,
      function,
      _rejectionPenaltySource,
    ]);
    final aggregate = aggregates.putIfAbsent(
      key,
      () => _RejectionPenaltyAggregate(
        cardNameNormalized: cardNameNormalized,
        cardName: safeCardName,
        commanderNameNormalized: commanderNameNormalized,
        commanderName: commanderName,
        archetype: archetype,
        function: function,
      ),
    );
    aggregate
      ..cardName = _preferredDisplayName(aggregate.cardName, safeCardName)
      ..commanderName = _preferredDisplayName(
        aggregate.commanderName,
        commanderName,
      )
      ..rejectCount += rejectCount;
  }

  final output =
      aggregates.values.map((aggregate) {
          return {
            'card_name_normalized': aggregate.cardNameNormalized,
            'card_name': aggregate.cardName,
            'commander_name_normalized': aggregate.commanderNameNormalized,
            'commander_name': aggregate.commanderName,
            'archetype': aggregate.archetype,
            'function': aggregate.function,
            'penalty': (aggregate.rejectCount * 35).clamp(35, 500).toInt(),
            'reject_count': aggregate.rejectCount,
            'source': _rejectionPenaltySource,
            'evidence': 'aggregated_failed_optimization_additions',
          };
        }).toList()
        ..sort((a, b) {
          final byReject = (b['reject_count'] as int).compareTo(
            a['reject_count'] as int,
          );
          if (byReject != 0) return byReject;
          final byCard = (a['card_name_normalized'] as String).compareTo(
            b['card_name_normalized'] as String,
          );
          if (byCard != 0) return byCard;
          final byCommander = (a['commander_name_normalized'] as String)
              .compareTo(b['commander_name_normalized'] as String);
          if (byCommander != 0) return byCommander;
          return (a['archetype'] as String).compareTo(b['archetype'] as String);
        });
  return output;
}

String _normalizeDisplayName(String value) {
  return value.trim().replaceAll(RegExp(r'\s+'), ' ');
}

String _preferredDisplayName(String current, String candidate) {
  if (current.isEmpty) return candidate;
  if (candidate.isEmpty) return current;
  final byLower = current.toLowerCase().compareTo(candidate.toLowerCase());
  if (byLower != 0) return byLower <= 0 ? current : candidate;
  return current.compareTo(candidate) <= 0 ? current : candidate;
}

class _RejectionPenaltyAggregate {
  _RejectionPenaltyAggregate({
    required this.cardNameNormalized,
    required this.cardName,
    required this.commanderNameNormalized,
    required this.commanderName,
    required this.archetype,
    required this.function,
  });

  final String cardNameNormalized;
  String cardName;
  final String commanderNameNormalized;
  String commanderName;
  final String archetype;
  final String function;
  int rejectCount = 0;
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
    samples.add(
      _buildOneSamplePool(
        label: commanderName,
        commanderIdentity: commander.resolvedIdentity,
        roles: const ['ramp', 'draw', 'removal', 'protection', 'wipe'],
        roleRowsByCardId: roleRowsByCardId,
        cardsById: cardsById,
        legalStatuses: legalStatuses,
      ),
    );
  }

  for (final fallback in fallbackShells) {
    if (samples.length >= 3) break;
    samples.add(
      _buildOneSamplePool(
        label: fallback['label'] as String,
        commanderIdentity: (fallback['identity'] as Set<String>),
        roles: (fallback['roles'] as List<String>),
        roleRowsByCardId: roleRowsByCardId,
        cardsById: cardsById,
        legalStatuses: legalStatuses,
      ),
    );
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

Future<void> _ensureCandidateQualitySchema(Session pool) async {
  for (final statement in candidateQualitySchemaStatements) {
    await pool.execute(statement);
  }
  for (final statement in candidateQualityIndexStatements) {
    await pool.execute(statement);
  }
  await pool.execute(optimizeCandidateQualitySummaryViewStatement);
  await pool.execute(cardIntelligenceSnapshotViewStatement);
}

Future<int> _upsertFunctionTags(
  Session session,
  List<Map<String, dynamic>> rows,
) async {
  var count = 0;
  for (final batch in _batches(rows, 1000)) {
    final result = await session.execute(
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
WHERE (
  card_function_tags.card_name,
  card_function_tags.confidence,
  card_function_tags.evidence
) IS DISTINCT FROM (
  EXCLUDED.card_name,
  EXCLUDED.confidence,
  EXCLUDED.evidence
)
RETURNING 1
'''),
      parameters: {'rows': jsonEncode(batch)},
    );
    count += result.length;
  }
  return count;
}

Future<int> _upsertRoleScores(
  Session session,
  List<Map<String, dynamic>> rows,
) async {
  var count = 0;
  for (final batch in _batches(rows, 1000)) {
    final result = await session.execute(
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
WHERE (
  card_role_scores.card_name,
  card_role_scores.score,
  card_role_scores.budget_tier,
  card_role_scores.evidence
) IS DISTINCT FROM (
  EXCLUDED.card_name,
  EXCLUDED.score,
  EXCLUDED.budget_tier,
  EXCLUDED.evidence
)
RETURNING 1
'''),
      parameters: {'rows': jsonEncode(batch)},
    );
    count += result.length;
  }
  return count;
}

Future<int> _upsertCommanderSynergies(
  Session session,
  List<Map<String, dynamic>> rows,
) async {
  var count = 0;
  for (final batch in _batches(rows, 1000)) {
    final result = await session.execute(
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
WHERE (
  commander_card_synergy.commander_name,
  commander_card_synergy.card_name,
  commander_card_synergy.score,
  commander_card_synergy.evidence_count,
  commander_card_synergy.evidence
) IS DISTINCT FROM (
  EXCLUDED.commander_name,
  EXCLUDED.card_name,
  EXCLUDED.score,
  EXCLUDED.evidence_count,
  EXCLUDED.evidence
)
RETURNING 1
'''),
      parameters: {'rows': jsonEncode(batch)},
    );
    count += result.length;
  }
  return count;
}

Future<int> _upsertRejectionPenalties(
  Session session,
  List<Map<String, dynamic>> rows,
) async {
  var count = 0;
  for (final batch in _batches(rows, 1000)) {
    final result = await session.execute(
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
WHERE (
  optimize_rejection_penalties.card_name,
  optimize_rejection_penalties.commander_name,
  optimize_rejection_penalties.penalty,
  optimize_rejection_penalties.reject_count,
  optimize_rejection_penalties.evidence
) IS DISTINCT FROM (
  EXCLUDED.card_name,
  EXCLUDED.commander_name,
  EXCLUDED.penalty,
  EXCLUDED.reject_count,
  EXCLUDED.evidence
)
RETURNING 1
'''),
      parameters: {'rows': jsonEncode(batch)},
    );
    count += result.length;
  }
  return count;
}

Future<Map<String, List<Map<String, dynamic>>>> _loadStaleGeneratedRows({
  required Session pool,
  required List<Map<String, dynamic>> tagRows,
  required List<Map<String, dynamic>> roleRows,
  required List<Map<String, dynamic>> synergyRows,
  required List<Map<String, dynamic>> penaltyRows,
}) async {
  return {
    'card_function_tags': await _loadStaleFunctionTags(pool, tagRows),
    'card_role_scores': await _loadStaleRoleScores(pool, roleRows),
    'commander_card_synergy': await _loadStaleCommanderSynergies(
      pool,
      synergyRows,
    ),
    'optimize_rejection_penalties': await _loadStaleRejectionPenalties(
      pool,
      penaltyRows,
    ),
  };
}

Future<Map<String, List<Map<String, dynamic>>>>
_loadStaleGeneratedRowsSnapshot({
  required Pool pool,
  required List<Map<String, dynamic>> tagRows,
  required List<Map<String, dynamic>> roleRows,
  required List<Map<String, dynamic>> synergyRows,
  required List<Map<String, dynamic>> penaltyRows,
}) {
  return pool.runTx((session) async {
    // The production PostgreSQL container has a bounded /dev/shm. These broad
    // anti-joins are deterministic and safer as one non-parallel snapshot.
    await session.execute('SET LOCAL max_parallel_workers_per_gather = 0');
    return _loadStaleGeneratedRows(
      pool: session,
      tagRows: tagRows,
      roleRows: roleRows,
      synergyRows: synergyRows,
      penaltyRows: penaltyRows,
    );
  });
}

List<Map<String, dynamic>> _flattenStaleGeneratedRows(
  Map<String, List<Map<String, dynamic>>> rowsByTable,
) {
  final rows = <Map<String, dynamic>>[];
  for (final entry in rowsByTable.entries) {
    for (final row in entry.value) {
      rows.add({'table': entry.key, ...row});
    }
  }
  return rows;
}

void _guardApplyStalePrune({
  required Map<String, int> staleRowsByTable,
  required int maxRowsPerTable,
  required bool allowLargeStalePrune,
}) {
  if (allowLargeStalePrune) return;
  final oversized = staleRowsByTable.entries
      .where((entry) => entry.value > maxRowsPerTable)
      .toList(growable: false);
  if (oversized.isEmpty) return;

  final details = oversized
      .map((entry) => '${entry.key}=${entry.value}')
      .join(', ');
  throw StateError(
    'Apply abortado: stale prune acima do limite por tabela '
    '($details; limite=$maxRowsPerTable). Revise '
    'stale_generated_rows_preview.* e rerode com '
    '--allow-large-stale-prune apenas em janela controlada.',
  );
}

void _guardStalePreviewUnchanged({
  required Map<String, List<Map<String, dynamic>>> preview,
  required Map<String, List<Map<String, dynamic>>> transactionRows,
}) {
  final datasets = <String>{...preview.keys, ...transactionRows.keys};
  for (final dataset in datasets) {
    final expected = preview[dataset] ?? const <Map<String, dynamic>>[];
    final actual = transactionRows[dataset] ?? const <Map<String, dynamic>>[];
    if (expected.length != actual.length ||
        _rowsDigest(expected) != _rowsDigest(actual)) {
      throw StateError(
        'Apply abortado antes da primeira escrita: stale preview mudou para '
        '$dataset (preview=${expected.length}, tx=${actual.length}).',
      );
    }
  }
}

void _maybeInjectFoundationFailure({
  required String? configuredLane,
  required String completedLane,
}) {
  if (configuredLane == null || configuredLane != completedLane) return;
  throw StateError(
    'Injected candidate-quality foundation failure after $completedLane; '
    'the global transaction must roll back.',
  );
}

Future<List<Map<String, dynamic>>> _loadStaleFunctionTags(
  Session session,
  List<Map<String, dynamic>> rows,
) async {
  if (rows.isEmpty || !await _hasTable(session, 'card_function_tags')) {
    return const [];
  }
  final result = await session.execute(
    Sql.named('''
WITH planned AS (
  SELECT *
  FROM jsonb_to_recordset(@rows::jsonb) AS x(
    card_id text,
    tag text
  )
)
SELECT
  existing.card_id::text,
  existing.card_name,
  existing.tag,
  existing.confidence,
  existing.source,
  existing.evidence,
  existing.updated_at
FROM card_function_tags existing
WHERE existing.source = @source
  AND NOT EXISTS (
    SELECT 1
    FROM planned p
    WHERE existing.card_id = p.card_id::uuid
      AND existing.tag = p.tag
  )
ORDER BY existing.card_name, existing.tag
'''),
    parameters: {'rows': jsonEncode(rows), 'source': _heuristicSource},
  );
  return result.map((row) => _jsonSafeMap(row.toColumnMap())).toList();
}

Future<List<Map<String, dynamic>>> _loadStaleRoleScores(
  Session session,
  List<Map<String, dynamic>> rows,
) async {
  if (rows.isEmpty || !await _hasTable(session, 'card_role_scores')) {
    return const [];
  }
  final result = await session.execute(
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
SELECT
  existing.card_id::text,
  existing.card_name,
  existing.role,
  existing.score,
  existing.format,
  existing.subformat,
  existing.bracket_scope,
  existing.budget_tier,
  existing.source,
  existing.evidence,
  existing.updated_at
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
ORDER BY existing.card_name, existing.role, existing.bracket_scope
'''),
    parameters: {'rows': jsonEncode(rows), 'source': _heuristicSource},
  );
  return result.map((row) => _jsonSafeMap(row.toColumnMap())).toList();
}

Future<List<Map<String, dynamic>>> _loadStaleCommanderSynergies(
  Session session,
  List<Map<String, dynamic>> rows,
) async {
  if (rows.isEmpty || !await _hasTable(session, 'commander_card_synergy')) {
    return const [];
  }
  final result = await session.execute(
    Sql.named('''
WITH planned AS (
  SELECT *
  FROM jsonb_to_recordset(@rows::jsonb) AS x(
    commander_name_normalized text,
    card_id text,
    role text
  )
)
SELECT
  existing.commander_name_normalized,
  existing.commander_name,
  existing.card_id::text,
  existing.card_name,
  existing.role,
  existing.score,
  existing.source,
  existing.evidence_count,
  existing.evidence,
  existing.updated_at
FROM commander_card_synergy existing
WHERE existing.source = @source
  AND NOT EXISTS (
    SELECT 1
    FROM planned p
    WHERE existing.commander_name_normalized = p.commander_name_normalized
      AND existing.card_id = p.card_id::uuid
      AND existing.role = p.role
  )
ORDER BY existing.commander_name, existing.card_name, existing.role
'''),
    parameters: {'rows': jsonEncode(rows), 'source': _metaSynergySource},
  );
  return result.map((row) => _jsonSafeMap(row.toColumnMap())).toList();
}

Future<List<Map<String, dynamic>>> _loadStaleRejectionPenalties(
  Session session,
  List<Map<String, dynamic>> rows,
) async {
  if (!await _hasTable(session, 'optimize_rejection_penalties')) {
    return const [];
  }
  final result = await session.execute(
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
SELECT
  existing.card_name_normalized,
  existing.card_name,
  existing.commander_name_normalized,
  existing.commander_name,
  existing.archetype,
  existing.function,
  existing.penalty,
  existing.reject_count,
  existing.source,
  existing.evidence,
  existing.updated_at
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
ORDER BY existing.card_name, existing.commander_name, existing.archetype
'''),
    parameters: {'rows': jsonEncode(rows), 'source': _rejectionPenaltySource},
  );
  return result.map((row) => _jsonSafeMap(row.toColumnMap())).toList();
}

Future<int> _pruneStaleFunctionTags(
  Session pool,
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
    parameters: {'rows': jsonEncode(rows), 'source': _heuristicSource},
  );
  return (result.first[0] as int?) ?? 0;
}

Future<List<Map<String, dynamic>>> _pruneStaleRoleScoresWithGuard({
  required Pool pool,
  required List<Map<String, dynamic>> roleRows,
  required List<Map<String, dynamic>> expectedRows,
  required int maxPrune,
}) async {
  if (!await _hasTable(pool, 'card_role_scores')) {
    throw StateError('Prune abortado: tabela card_role_scores nao existe.');
  }
  final expectedKeys = _roleScoreKeys(expectedRows);
  if (expectedRows.length > maxPrune) {
    throw StateError(
      'Prune abortado: ${expectedRows.length} stale card_role_scores excede '
      '--max-prune=$maxPrune.',
    );
  }

  return pool.runTx((session) async {
    final actualRows = await _loadStaleRoleScores(session, roleRows);
    final actualKeys = _roleScoreKeys(actualRows);
    if (!_sameStringSet(expectedKeys, actualKeys)) {
      throw StateError(
        'Prune abortado: stale card_role_scores mudou entre dry-run e '
        'transacao.',
      );
    }
    if (actualRows.length > maxPrune) {
      throw StateError(
        'Prune abortado: ${actualRows.length} stale card_role_scores excede '
        '--max-prune=$maxPrune.',
      );
    }
    if (actualRows.isEmpty) return const <Map<String, dynamic>>[];

    final result = await session.execute(
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
  RETURNING
    existing.card_id::text,
    existing.card_name,
    existing.role,
    existing.score,
    existing.format,
    existing.subformat,
    existing.bracket_scope,
    existing.budget_tier,
    existing.source,
    existing.evidence,
    existing.updated_at
)
SELECT * FROM deleted
'''),
      parameters: {'rows': jsonEncode(roleRows), 'source': _heuristicSource},
    );
    final deletedRows =
        result.map((row) => _jsonSafeMap(row.toColumnMap())).toList();
    final deletedKeys = _roleScoreKeys(deletedRows);
    if (!_sameStringSet(actualKeys, deletedKeys)) {
      throw StateError(
        'Prune abortado: deleted card_role_scores diverge do preview.',
      );
    }
    return deletedRows;
  });
}

Future<int> _pruneStaleRoleScores(
  Session pool,
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
    parameters: {'rows': jsonEncode(rows), 'source': _heuristicSource},
  );
  return (result.first[0] as int?) ?? 0;
}

Future<int> _pruneStaleCommanderSynergies(
  Session pool,
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
    parameters: {'rows': jsonEncode(rows), 'source': _metaSynergySource},
  );
  return (result.first[0] as int?) ?? 0;
}

Future<int> _pruneStaleRejectionPenalties(
  Session pool,
  List<Map<String, dynamic>> rows,
) async {
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
    parameters: {'rows': jsonEncode(rows), 'source': _rejectionPenaltySource},
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

Future<bool> _hasTable(Session session, String tableName) async {
  final result = await session.execute(
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

Set<String> _roleScoreKeys(List<Map<String, dynamic>> rows) {
  return rows
      .map(
        (row) => [
          row['card_id'],
          row['role'],
          row['format'],
          row['subformat'],
          row['bracket_scope'],
          row['source'],
        ].map((value) => value?.toString() ?? '').join('|'),
      )
      .toSet();
}

bool _sameStringSet(Set<String> a, Set<String> b) {
  return a.length == b.length && a.containsAll(b);
}

Map<String, dynamic> _jsonSafeMap(Map<String, dynamic> row) {
  return row.map((key, value) => MapEntry(key, _jsonSafeValue(value)));
}

Object? _jsonSafeValue(Object? value) {
  if (value is DateTime) return value.toIso8601String();
  if (value is List) return value.map(_jsonSafeValue).toList();
  return value;
}

String? _readArg(List<String> args, String prefix) {
  for (final arg in args) {
    if (arg.startsWith(prefix)) return arg.substring(prefix.length);
  }
  return null;
}

Future<void> _writeJson(String path, Object? payload) async {
  await File(
    path,
  ).writeAsString(const JsonEncoder.withIndent('  ').convert(payload));
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
  final buffer =
      StringBuffer()
        ..writeln('# Aggressive Candidate Quality v2 - ${summary['mode']}')
        ..writeln()
        ..writeln('- Schema version: `${summary['schema_version']}`')
        ..writeln('- DB mutations: `${summary['db_mutations']}`')
        ..writeln('- Cards scanned: `${summary['cards_scanned']}`')
        ..writeln(
          '- Cards with deterministic tags: `${summary['cards_with_function_tags']}`',
        )
        ..writeln(
          '- Function tag rows planned: `${summary['function_tag_rows_planned']}`',
        )
        ..writeln(
          '- Role score rows planned: `${summary['role_score_rows_planned']}`',
        )
        ..writeln(
          '- Commander synergy rows planned: `${summary['commander_synergy_rows_planned']}`',
        )
        ..writeln(
          '- Rejection penalty rows planned: `${summary['rejection_penalty_rows_planned']}`',
        )
        ..writeln(
          '- Stale generated rows before apply/prune: '
          '`${summary['stale_generated_rows_before_apply']}`',
        )
        ..writeln(
          '- Pruned stale role scores: '
          '`${summary['pruned_stale_role_scores']}`',
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
