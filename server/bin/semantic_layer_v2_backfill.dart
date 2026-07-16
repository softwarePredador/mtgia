#!/usr/bin/env dart
// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:postgres/postgres.dart';
import 'package:server/ai/candidate_quality_data_support.dart';
import 'package:server/ai/functional_card_tags.dart';
import 'package:server/ai/optimization_functional_roles.dart';
import 'package:server/database.dart';

const _defaultArtifactDir =
    'test/artifacts/semantic_layer_v2_backfill_2026-07-16';
const _postgresWriteApprovalEnv = 'MANALOOM_CONFIRM_POSTGRES_WRITES';
const _postgresWriteApprovalValue = 'I_HAVE_EXPLICIT_APPROVAL';
const _failureInjectionEnv =
    'MANALOOM_ENABLE_SEMANTIC_BACKFILL_FAILURE_INJECTION';
const _failureInjectionValue = 'I_UNDERSTAND_THIS_MUST_ROLL_BACK';
const _defaultMaxStalePruneOnApply = 100;
const _advisoryLockName = 'manaloom_semantic_layer_v2_backfill';

Future<void> main(List<String> args) async {
  if (args.contains('--help') || args.contains('-h')) {
    _printUsage();
    return;
  }

  final apply = args.contains('--apply');
  final explicitDryRun = args.contains('--dry-run');
  if (apply && explicitDryRun) {
    throw ArgumentError('Use apenas um modo: --dry-run ou --apply.');
  }
  if (apply &&
      Platform.environment[_postgresWriteApprovalEnv] !=
          _postgresWriteApprovalValue) {
    throw StateError(
      'PostgreSQL write refused: export '
      '$_postgresWriteApprovalEnv=$_postgresWriteApprovalValue.',
    );
  }

  final limit = int.tryParse(_readArg(args, '--limit=') ?? '') ?? 0;
  final chunkSize = int.tryParse(_readArg(args, '--chunk-size=') ?? '') ?? 2500;
  final maxStalePruneOnApply =
      int.tryParse(_readArg(args, '--max-stale-prune-on-apply=') ?? '') ??
      _defaultMaxStalePruneOnApply;
  final allowLargeStalePrune = args.contains('--allow-large-stale-prune');
  final reviewSampleLimit =
      int.tryParse(_readArg(args, '--review-sample-limit=') ?? '') ?? 0;
  final testFailAfterLane = _readArg(args, '--test-fail-after-lane=');
  if (limit < 0) {
    throw ArgumentError('--limit deve ser >= 0.');
  }
  if (apply && limit > 0) {
    throw ArgumentError(
      '--limit e permitido somente em dry-run; o apply autoritativo exige '
      'varredura completa antes de podar rows stale.',
    );
  }
  if (chunkSize <= 0 || chunkSize > 10000) {
    throw ArgumentError('--chunk-size deve ficar entre 1 e 10000.');
  }
  if (maxStalePruneOnApply < 0) {
    throw ArgumentError('--max-stale-prune-on-apply deve ser >= 0.');
  }
  if (reviewSampleLimit < 0 || reviewSampleLimit > 100) {
    throw ArgumentError('--review-sample-limit deve ficar entre 0 e 100.');
  }
  if (testFailAfterLane != null) {
    const allowedFailureLanes = {
      'card_semantic_tags_v2',
      'card_function_tags',
      'prunes',
    };
    if (!apply) {
      throw ArgumentError('--test-fail-after-lane exige --apply.');
    }
    if (!allowedFailureLanes.contains(testFailAfterLane)) {
      throw ArgumentError(
        '--test-fail-after-lane invalido: $testFailAfterLane.',
      );
    }
    if (Platform.environment[_failureInjectionEnv] != _failureInjectionValue) {
      throw StateError(
        'Semantic backfill failure injection refused: export '
        '$_failureInjectionEnv=$_failureInjectionValue.',
      );
    }
  }

  final artifactDir = Directory(
    _readArg(args, '--artifact-dir=') ?? _defaultArtifactDir,
  );
  await artifactDir.create(recursive: true);

  final database = Database();
  await database.connect();
  final pool = database.connection;
  final startedAt = DateTime.now().toUtc();

  try {
    final totalCardRows = await _loadTotalCardCount(pool);
    final cards = await _loadAnalyzedCards(pool, limit: limit);
    if (apply && cards.isEmpty) {
      throw StateError(
        'Apply abortado: a varredura autoritativa nao encontrou cartas '
        'analisaveis.',
      );
    }
    final sourceDatasetSha256 = _cardSourceRowsDigest(cards);
    final plan = _buildPlan(cards);
    validateSemanticLayerV2PlannedDatasets(
      semanticRows: plan.semanticRows,
      functionRows: plan.functionRows,
      analyzedCardIds: cards.map((card) => card.id).toSet(),
      expectedAuthoritativeCardCount: limit == 0 ? totalCardRows : null,
    );

    final preCounts = await _loadOwnedCounts(pool);
    final stalePreview = await _loadStaleOwnedRows(
      pool,
      semanticRows: plan.semanticRows,
      functionRows: plan.functionRows,
    );
    final missingPreview = await _loadMissingOwnedRows(
      pool,
      semanticRows: plan.semanticRows,
      functionRows: plan.functionRows,
    );
    final stalePreviewSummary = _staleRowsSummary(stalePreview);
    final missingPreviewSummary = _staleRowsSummary(missingPreview);
    if (reviewSampleLimit > 0) {
      _printFunctionRowReviewSamples(
        label: 'stale',
        rows: stalePreview['card_function_tags'] ?? const [],
        cards: cards,
        sampleLimit: reviewSampleLimit,
      );
      _printFunctionRowReviewSamples(
        label: 'missing',
        rows: missingPreview['card_function_tags'] ?? const [],
        cards: cards,
        sampleLimit: reviewSampleLimit,
      );
    }
    if (apply) {
      _guardApplyStalePrune(
        staleRows: stalePreview,
        maxRowsPerTable: maxStalePruneOnApply,
        allowLargeStalePrune: allowLargeStalePrune,
      );
    }

    var mutationCounts = <String, int>{
      'upserted_card_semantic_tags_v2': 0,
      'upserted_card_function_tags': 0,
      'pruned_card_semantic_tags_v2': 0,
      'pruned_card_function_tags': 0,
    };
    if (apply) {
      mutationCounts = await pool.runTx<Map<String, int>>((session) async {
        await session.execute(
          "SELECT pg_advisory_xact_lock(hashtext('$_advisoryLockName'))",
        );
        await _ensureSchema(session);
        await _lockAuthoritativeTables(session);

        final transactionCards = await _loadAnalyzedCards(session);
        _guardSourceDatasetUnchanged(
          previewRows: cards,
          transactionRows: transactionCards,
          previewSha256: sourceDatasetSha256,
        );
        final transactionStaleRows = await _loadStaleOwnedRows(
          session,
          semanticRows: plan.semanticRows,
          functionRows: plan.functionRows,
        );
        _guardStalePreviewUnchanged(
          preview: stalePreview,
          transactionRows: transactionStaleRows,
        );

        final counts = <String, int>{};
        counts['upserted_card_semantic_tags_v2'] = await _upsertSemanticRows(
          session,
          plan.semanticRows,
          chunkSize: chunkSize,
        );
        _maybeInjectSemanticBackfillFailure(
          configuredLane: testFailAfterLane,
          completedLane: 'card_semantic_tags_v2',
        );
        counts['upserted_card_function_tags'] = await _upsertFunctionRows(
          session,
          plan.functionRows,
          chunkSize: chunkSize,
        );
        _maybeInjectSemanticBackfillFailure(
          configuredLane: testFailAfterLane,
          completedLane: 'card_function_tags',
        );
        counts['pruned_card_semantic_tags_v2'] = await _pruneSemanticRows(
          session,
          plan.semanticRows,
        );
        counts['pruned_card_function_tags'] = await _pruneFunctionRows(
          session,
          plan.functionRows,
        );
        _maybeInjectSemanticBackfillFailure(
          configuredLane: testFailAfterLane,
          completedLane: 'prunes',
        );
        return counts;
      });
    }

    final postCounts = await _loadOwnedCounts(pool);
    final dbMutations = mutationCounts.values.any((count) => count > 0);
    final completedAt = DateTime.now().toUtc();
    final summary = <String, dynamic>{
      'schema_version': semanticLayerV2SchemaVersion,
      'source': semanticLayerV2Source,
      'mode': apply ? 'apply' : 'dry_run',
      'scope': limit > 0 ? 'limited_non_authoritative' : 'full_authoritative',
      'apply_executed': apply,
      'db_mutations': dbMutations,
      'started_at': startedAt.toIso8601String(),
      'finished_at': completedAt.toIso8601String(),
      'duration_ms': completedAt.difference(startedAt).inMilliseconds,
      'artifact_safety': const {
        'aggregate_only': true,
        'raw_rules_text_saved': false,
        'card_ids_saved': false,
        'card_names_saved': false,
        'full_row_payloads_saved': false,
        'secrets_saved': false,
        'free_text_evidence_saved': false,
      },
      'source_dataset': {
        'total_card_rows': totalCardRows,
        'analyzed_card_rows': cards.length,
        'sha256': sourceDatasetSha256,
      },
      'planned_datasets': {
        'card_semantic_tags_v2': {
          'rows': plan.semanticRows.length,
          'unique_rows': plan.semanticRows.length,
          'sha256': semanticLayerV2RowsDigest(plan.semanticRows),
        },
        'card_function_tags': {
          'rows': plan.functionRows.length,
          'unique_rows': plan.functionRows.length,
          'sha256': semanticLayerV2RowsDigest(plan.functionRows),
        },
      },
      'pre_owned_counts': preCounts,
      'post_owned_counts': postCounts,
      'stale_owned_rows_before_apply': stalePreviewSummary,
      'missing_owned_rows_before_apply': missingPreviewSummary,
      'apply_stale_prune_guard': {
        'max_rows_per_table': maxStalePruneOnApply,
        'allow_large_stale_prune': allowLargeStalePrune,
      },
      'actual_mutation_counts': mutationCounts,
      ...plan.audit.toJson(),
    };
    _assertSanitized(summary);
    await _writeJson(
      '${artifactDir.path}/summary_${summary['mode']}.json',
      summary,
    );
    await _writeMarkdownReport(
      '${artifactDir.path}/summary_${summary['mode']}.md',
      summary,
    );
    print('[OK] Semantic Layer v2 ${summary['mode']} concluido.');
    print('  - Artefatos agregados: ${artifactDir.path}');
    print('  - Cartas analisadas: ${cards.length}');
    print('  - Semantic rows planejadas: ${plan.semanticRows.length}');
    print('  - Function rows planejadas: ${plan.functionRows.length}');
    print('  - DB mutations: $dbMutations');
  } finally {
    await database.close();
  }
}

class _SemanticLayerV2Plan {
  const _SemanticLayerV2Plan({
    required this.semanticRows,
    required this.functionRows,
    required this.audit,
  });

  final List<Map<String, dynamic>> semanticRows;
  final List<Map<String, dynamic>> functionRows;
  final _SemanticLayerV2Audit audit;
}

_SemanticLayerV2Plan _buildPlan(List<_BackfillCard> cards) {
  final audit = _SemanticLayerV2Audit();
  final semanticRows = <Map<String, dynamic>>[];
  final functionRows = <Map<String, dynamic>>[];

  for (final card in cards) {
    final semantic = inferSemanticCardAnalysisV2(
      name: card.name,
      typeLine: card.typeLine,
      oracleText: card.oracleText,
      manaCost: card.manaCost,
      cmc: card.cmc,
    );
    audit.add(card, semantic);

    // One authoritative snapshot row per analyzed card is intentional. Empty
    // tag arrays distinguish an analyzed/unknown card from a missing snapshot.
    semanticRows.add({
      'card_id': card.id,
      'card_name': card.name,
      ...semantic.toJson(),
    });
    for (final tag in semantic.tags) {
      functionRows.add({
        'card_id': card.id,
        'card_name': card.name,
        'tag': tag.tag,
        'confidence': double.parse(tag.confidence.toStringAsFixed(3)),
        'source': semanticLayerV2Source,
        'evidence': tag.evidence,
      });
    }
  }

  semanticRows.sort((a, b) {
    final byCard = (a['card_id'] as String).compareTo(b['card_id'] as String);
    if (byCard != 0) return byCard;
    return (a['source'] as String).compareTo(b['source'] as String);
  });
  functionRows.sort((a, b) {
    final byCard = (a['card_id'] as String).compareTo(b['card_id'] as String);
    if (byCard != 0) return byCard;
    final byTag = (a['tag'] as String).compareTo(b['tag'] as String);
    if (byTag != 0) return byTag;
    return (a['source'] as String).compareTo(b['source'] as String);
  });
  return _SemanticLayerV2Plan(
    semanticRows: semanticRows,
    functionRows: functionRows,
    audit: audit,
  );
}

void validateSemanticLayerV2PlannedDatasets({
  required List<Map<String, dynamic>> semanticRows,
  required List<Map<String, dynamic>> functionRows,
  required Set<String> analyzedCardIds,
  int? expectedAuthoritativeCardCount,
}) {
  _guardUniquePlannedRows(
    dataset: 'card_semantic_tags_v2',
    rows: semanticRows,
    keyColumns: const ['card_id', 'source'],
  );
  _guardUniquePlannedRows(
    dataset: 'card_function_tags',
    rows: functionRows,
    keyColumns: const ['card_id', 'tag', 'source'],
  );

  final semanticCardIds = <String>{};
  final expectedFunctions = <String, String>{};
  for (final row in semanticRows) {
    final cardId = row['card_id']?.toString() ?? '';
    final source = row['source']?.toString() ?? '';
    if (cardId.isEmpty ||
        source != semanticLayerV2Source ||
        row['schema_version'] != semanticLayerV2SchemaVersion) {
      throw StateError(
        'Semantic v2 planned dataset preflight failed: invalid snapshot '
        'identity/source/schema.',
      );
    }
    semanticCardIds.add(cardId);
    final tags = row['tags'];
    if (tags is! List) {
      throw StateError(
        'Semantic v2 planned dataset preflight failed: tags must be a list.',
      );
    }
    for (final rawTag in tags) {
      if (rawTag is! Map) {
        throw StateError(
          'Semantic v2 planned dataset preflight failed: malformed tag.',
        );
      }
      final tag = rawTag['tag']?.toString() ?? '';
      final key = jsonEncode([cardId, tag, source]);
      final value = jsonEncode(
        _canonicalizeJsonValue({
          'confidence': rawTag['confidence'],
          'evidence': rawTag['evidence'],
        }),
      );
      if (tag.isEmpty || expectedFunctions.containsKey(key)) {
        throw StateError(
          'Semantic v2 planned dataset preflight failed: duplicate/empty '
          'snapshot tag.',
        );
      }
      expectedFunctions[key] = value;
    }
  }
  if (!_sameStringSet(semanticCardIds, analyzedCardIds) ||
      semanticRows.length != analyzedCardIds.length) {
    throw StateError(
      'Semantic v2 planned dataset preflight failed: expected exactly one '
      'snapshot row per analyzed card.',
    );
  }
  if (expectedAuthoritativeCardCount != null &&
      (analyzedCardIds.length != expectedAuthoritativeCardCount ||
          semanticRows.length != expectedAuthoritativeCardCount)) {
    throw StateError(
      'Semantic v2 planned dataset preflight failed: full authoritative '
      'scope must contain exactly one snapshot for every cards row '
      '(expected=$expectedAuthoritativeCardCount, '
      'loaded=${analyzedCardIds.length}, planned=${semanticRows.length}).',
    );
  }

  final actualFunctions = <String, String>{};
  for (final row in functionRows) {
    final cardId = row['card_id']?.toString() ?? '';
    final tag = row['tag']?.toString() ?? '';
    final source = row['source']?.toString() ?? '';
    if (!analyzedCardIds.contains(cardId) ||
        tag.isEmpty ||
        source != semanticLayerV2Source) {
      throw StateError(
        'Semantic v2 planned dataset preflight failed: invalid functional '
        'tag identity/source.',
      );
    }
    actualFunctions[jsonEncode([cardId, tag, source])] = jsonEncode(
      _canonicalizeJsonValue({
        'confidence': row['confidence'],
        'evidence': row['evidence'],
      }),
    );
  }
  if (expectedFunctions.length != actualFunctions.length ||
      expectedFunctions.entries.any(
        (entry) => actualFunctions[entry.key] != entry.value,
      )) {
    throw StateError(
      'Semantic v2 planned dataset preflight failed: functional tags do not '
      'exactly mirror snapshot tags.',
    );
  }
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
    'Semantic v2 planned dataset uniqueness preflight failed: $dataset has '
    '${duplicateKeys.length} duplicate primary/conflict key(s): '
    '${ordered.take(5).join(', ')}',
  );
}

String semanticLayerV2RowsDigest(List<Map<String, dynamic>> rows) {
  final canonical =
      rows.map((row) => jsonEncode(_canonicalizeJsonValue(row))).toList()
        ..sort();
  return sha256.convert(utf8.encode(canonical.join('\n'))).toString();
}

Object? _canonicalizeJsonValue(Object? value) {
  if (value is Map) {
    final entries =
        value.entries
            .map((entry) => MapEntry(entry.key.toString(), entry.value))
            .toList()
          ..sort((a, b) => a.key.compareTo(b.key));
    return <String, Object?>{
      for (final entry in entries)
        entry.key: _canonicalizeJsonValue(entry.value),
    };
  }
  if (value is List) {
    return value.map(_canonicalizeJsonValue).toList(growable: false);
  }
  return value;
}

class _SemanticLayerV2Audit {
  final roleCounts = <String, int>{};
  final speedCounts = <String, int>{};
  final manaEfficiencyCounts = <String, int>{};
  final cardAdvantageCounts = <String, int>{};
  final interactionCounts = <String, int>{};
  final falsePositiveCandidates = <String, int>{};
  final regressions = <String, int>{};
  var rows = 0;
  var taggedRows = 0;
  var unknownRows = 0;
  var ambiguousRows = 0;

  void add(_BackfillCard card, SemanticCardAnalysisV2 semantic) {
    rows++;
    if (semantic.tags.isEmpty) {
      unknownRows++;
    } else {
      taggedRows++;
    }
    if (semantic.tags.length >= 4 ||
        (semantic.tags.isNotEmpty && semantic.roleConfidence < 0.65)) {
      ambiguousRows++;
    }
    _inc(speedCounts, semantic.speed);
    _inc(manaEfficiencyCounts, semantic.manaEfficiency);
    _inc(cardAdvantageCounts, semantic.cardAdvantageType);
    _inc(interactionCounts, semantic.interactionScope);
    for (final tag in semantic.tags) {
      _inc(roleCounts, tag.tag);
    }
    _flagFalsePositiveCandidates(card, semantic);
  }

  Map<String, dynamic> toJson() => {
    'coverage': {
      'card_rows': rows,
      'tagged_rows': taggedRows,
      'unknown_rows': unknownRows,
      'ambiguous_rows': ambiguousRows,
      'coverage_pct':
          rows == 0
              ? 0
              : double.parse(((taggedRows / rows) * 100).toStringAsFixed(3)),
    },
    'role_counts': _sorted(roleCounts),
    'speed_counts': _sorted(speedCounts),
    'mana_efficiency_counts': _sorted(manaEfficiencyCounts),
    'card_advantage_type_counts': _sorted(cardAdvantageCounts),
    'interaction_scope_counts': _sorted(interactionCounts),
    'false_positive_candidates': _sorted(falsePositiveCandidates),
    'regressions': _sorted(regressions),
  };

  void _flagFalsePositiveCandidates(
    _BackfillCard card,
    SemanticCardAnalysisV2 semantic,
  ) {
    final tags = semantic.tags.map((tag) => tag.tag).toSet();
    final oracle = card.oracleText.toLowerCase();
    if (tags.contains('tutor') && looksLikeOptimizationLandSearchText(oracle)) {
      _inc(regressions, 'land_search_counted_as_tutor');
    }
    if (tags.contains('lifegain') &&
        (oracle.contains("can't gain life") ||
            oracle.contains('cannot gain life'))) {
      _inc(regressions, 'lifegain_hate_counted_as_lifegain');
    }
    if (tags.contains('removal') &&
        oracle.contains('exile target') &&
        oracle.contains('return') &&
        oracle.contains('battlefield')) {
      _inc(falsePositiveCandidates, 'blink_like_removal');
    }
    if (tags.contains('ramp') &&
        semantic.manaEfficiency == 'expensive' &&
        semantic.cardAdvantageType == 'none') {
      _inc(falsePositiveCandidates, 'expensive_ramp_review');
    }
  }
}

class _BackfillCard {
  const _BackfillCard({
    required this.id,
    required this.name,
    required this.typeLine,
    required this.oracleText,
    required this.manaCost,
    required this.cmc,
  });

  final String id;
  final String name;
  final String typeLine;
  final String oracleText;
  final String? manaCost;
  final Object? cmc;

  factory _BackfillCard.fromRow(ResultRow row) {
    final map = row.toColumnMap();
    return _BackfillCard(
      id: map['id'].toString(),
      name: (map['name'] as String?)?.trim() ?? '',
      typeLine: (map['type_line'] as String?)?.trim() ?? '',
      oracleText: (map['oracle_text'] as String?) ?? '',
      manaCost: (map['mana_cost'] as String?)?.trim(),
      cmc: map['cmc'],
    );
  }

  Map<String, dynamic> toSourceDigestRow() => {
    'id': id,
    'name': name,
    'type_line': typeLine,
    'oracle_text': oracleText,
    'mana_cost': manaCost,
    'cmc': cmc?.toString(),
  };
}

Future<void> _ensureSchema(Session session) async {
  for (final statement in candidateQualitySchemaStatements) {
    await session.execute(statement);
  }
  for (final statement in candidateQualityIndexStatements) {
    await session.execute(statement);
  }
  await session.execute(optimizeCandidateQualitySummaryViewStatement);
  await session.execute(cardIntelligenceSnapshotViewStatement);
}

Future<void> _lockAuthoritativeTables(Session session) async {
  await session.execute('LOCK TABLE cards IN SHARE MODE');
  await session.execute(
    'LOCK TABLE card_semantic_tags_v2 IN SHARE ROW EXCLUSIVE MODE',
  );
  await session.execute(
    'LOCK TABLE card_function_tags IN SHARE ROW EXCLUSIVE MODE',
  );
}

Future<List<_BackfillCard>> _loadAnalyzedCards(
  Session session, {
  int limit = 0,
}) async {
  final limitClause = limit > 0 ? 'LIMIT @limit' : '';
  final rows = await session.execute(
    Sql.named('''
SELECT id, name, type_line, oracle_text, mana_cost, cmc
FROM cards
ORDER BY id ASC
$limitClause
'''),
    parameters: limit > 0 ? {'limit': limit} : const {},
  );
  return rows.map(_BackfillCard.fromRow).toList(growable: false);
}

Future<int> _loadTotalCardCount(Session session) async {
  final result = await session.execute('SELECT COUNT(*)::int FROM cards');
  return (result.first[0] as int?) ?? 0;
}

String _cardSourceRowsDigest(List<_BackfillCard> cards) {
  return semanticLayerV2RowsDigest(
    cards.map((card) => card.toSourceDigestRow()).toList(growable: false),
  );
}

void _guardSourceDatasetUnchanged({
  required List<_BackfillCard> previewRows,
  required List<_BackfillCard> transactionRows,
  required String previewSha256,
}) {
  final transactionSha256 = _cardSourceRowsDigest(transactionRows);
  if (previewRows.length != transactionRows.length ||
      previewSha256 != transactionSha256) {
    throw StateError(
      'Apply abortado antes da primeira escrita: o dataset fonte cards mudou '
      'entre o planejamento e a transacao.',
    );
  }
}

Future<Map<String, int>> _loadOwnedCounts(Session session) async {
  final counts = <String, int>{};
  for (final table in const ['card_semantic_tags_v2', 'card_function_tags']) {
    if (!await _hasTable(session, table)) {
      counts[table] = 0;
      continue;
    }
    final result = await session.execute(
      Sql.named('SELECT COUNT(*)::int FROM $table WHERE source = @source'),
      parameters: {'source': semanticLayerV2Source},
    );
    counts[table] = (result.first[0] as int?) ?? 0;
  }
  return counts;
}

Future<Map<String, List<Map<String, dynamic>>>> _loadStaleOwnedRows(
  Session session, {
  required List<Map<String, dynamic>> semanticRows,
  required List<Map<String, dynamic>> functionRows,
}) async {
  return {
    'card_semantic_tags_v2': await _loadStaleSemanticRows(
      session,
      semanticRows,
    ),
    'card_function_tags': await _loadStaleFunctionRows(session, functionRows),
  };
}

Future<Map<String, List<Map<String, dynamic>>>> _loadMissingOwnedRows(
  Session session, {
  required List<Map<String, dynamic>> semanticRows,
  required List<Map<String, dynamic>> functionRows,
}) async {
  return {
    'card_semantic_tags_v2': await _loadMissingSemanticRows(
      session,
      semanticRows,
    ),
    'card_function_tags': await _loadMissingFunctionRows(session, functionRows),
  };
}

Future<List<Map<String, dynamic>>> _loadMissingSemanticRows(
  Session session,
  List<Map<String, dynamic>> rows,
) async {
  final result = await session.execute(
    Sql.named('''
WITH planned AS (
  SELECT *
  FROM jsonb_to_recordset(@rows::jsonb) AS x(card_id text)
)
SELECT planned.card_id, @source::text AS source
FROM planned
WHERE NOT EXISTS (
  SELECT 1
  FROM card_semantic_tags_v2 existing
  WHERE existing.card_id = planned.card_id::uuid
    AND existing.source = @source
)
ORDER BY planned.card_id
'''),
    parameters: {
      'rows': jsonEncode([
        for (final row in rows) {'card_id': row['card_id']},
      ]),
      'source': semanticLayerV2Source,
    },
  );
  return result.map((row) => row.toColumnMap()).toList(growable: false);
}

Future<List<Map<String, dynamic>>> _loadMissingFunctionRows(
  Session session,
  List<Map<String, dynamic>> rows,
) async {
  final result = await session.execute(
    Sql.named('''
WITH planned AS (
  SELECT *
  FROM jsonb_to_recordset(@rows::jsonb) AS x(card_id text, tag text)
)
SELECT planned.card_id, planned.tag, @source::text AS source
FROM planned
WHERE NOT EXISTS (
  SELECT 1
  FROM card_function_tags existing
  WHERE existing.card_id = planned.card_id::uuid
    AND existing.tag = planned.tag
    AND existing.source = @source
)
ORDER BY planned.card_id, planned.tag
'''),
    parameters: {
      'rows': jsonEncode([
        for (final row in rows) {'card_id': row['card_id'], 'tag': row['tag']},
      ]),
      'source': semanticLayerV2Source,
    },
  );
  return result.map((row) => row.toColumnMap()).toList(growable: false);
}

Future<List<Map<String, dynamic>>> _loadStaleSemanticRows(
  Session session,
  List<Map<String, dynamic>> rows,
) async {
  if (!await _hasTable(session, 'card_semantic_tags_v2')) return const [];
  final result = await session.execute(
    Sql.named('''
WITH planned AS (
  SELECT *
  FROM jsonb_to_recordset(@rows::jsonb) AS x(card_id text)
)
SELECT existing.card_id::text, existing.source
FROM card_semantic_tags_v2 existing
WHERE existing.source = @source
  AND NOT EXISTS (
    SELECT 1
    FROM planned p
    WHERE existing.card_id = p.card_id::uuid
  )
ORDER BY existing.card_id
'''),
    parameters: {
      'rows': jsonEncode([
        for (final row in rows) {'card_id': row['card_id']},
      ]),
      'source': semanticLayerV2Source,
    },
  );
  return result.map((row) => row.toColumnMap()).toList(growable: false);
}

Future<List<Map<String, dynamic>>> _loadStaleFunctionRows(
  Session session,
  List<Map<String, dynamic>> rows,
) async {
  if (!await _hasTable(session, 'card_function_tags')) return const [];
  final result = await session.execute(
    Sql.named('''
WITH planned AS (
  SELECT *
  FROM jsonb_to_recordset(@rows::jsonb) AS x(card_id text, tag text)
)
SELECT existing.card_id::text, existing.tag, existing.source
FROM card_function_tags existing
WHERE existing.source = @source
  AND NOT EXISTS (
    SELECT 1
    FROM planned p
    WHERE existing.card_id = p.card_id::uuid
      AND existing.tag = p.tag
  )
ORDER BY existing.card_id, existing.tag
'''),
    parameters: {
      'rows': jsonEncode([
        for (final row in rows) {'card_id': row['card_id'], 'tag': row['tag']},
      ]),
      'source': semanticLayerV2Source,
    },
  );
  return result.map((row) => row.toColumnMap()).toList(growable: false);
}

Map<String, Map<String, dynamic>> _staleRowsSummary(
  Map<String, List<Map<String, dynamic>>> staleRows,
) {
  return staleRows.map((table, rows) {
    final tagCounts = <String, int>{};
    for (final row in rows) {
      final tag = row['tag']?.toString().trim() ?? '';
      if (tag.isEmpty) continue;
      tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
    }
    return MapEntry(table, {
      'rows': rows.length,
      'sha256': semanticLayerV2RowsDigest(rows),
      if (tagCounts.isNotEmpty) 'tag_counts': _sorted(tagCounts),
    });
  });
}

void _printFunctionRowReviewSamples({
  required String label,
  required List<Map<String, dynamic>> rows,
  required List<_BackfillCard> cards,
  required int sampleLimit,
}) {
  final namesById = {for (final card in cards) card.id: card.name};
  final namesByTag = <String, Set<String>>{};
  final countsByTag = <String, int>{};
  for (final row in rows) {
    final tag = row['tag']?.toString().trim() ?? '';
    final cardId = row['card_id']?.toString() ?? '';
    if (tag.isEmpty || cardId.isEmpty) continue;
    countsByTag[tag] = (countsByTag[tag] ?? 0) + 1;
    final name = namesById[cardId]?.trim() ?? '';
    if (name.isNotEmpty) {
      namesByTag.putIfAbsent(tag, () => <String>{}).add(name);
    }
  }
  final tags = countsByTag.keys.toList()..sort();
  for (final tag in tags) {
    final samples = (namesByTag[tag] ?? const <String>{}).toList()..sort();
    stdout.writeln(
      '[REVIEW] $label card_function_tags tag=$tag '
      'count=${countsByTag[tag]} '
      'samples=${samples.take(sampleLimit).join(' | ')}',
    );
  }
}

void _guardApplyStalePrune({
  required Map<String, List<Map<String, dynamic>>> staleRows,
  required int maxRowsPerTable,
  required bool allowLargeStalePrune,
}) {
  if (allowLargeStalePrune) return;
  final oversized = staleRows.entries
      .where((entry) => entry.value.length > maxRowsPerTable)
      .toList(growable: false);
  if (oversized.isEmpty) return;
  final details = oversized
      .map((entry) => '${entry.key}=${entry.value.length}')
      .join(', ');
  throw StateError(
    'Apply abortado: stale prune acima do limite por tabela '
    '($details; limite=$maxRowsPerTable). Revise o resumo agregado e use '
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
        semanticLayerV2RowsDigest(expected) !=
            semanticLayerV2RowsDigest(actual)) {
      throw StateError(
        'Apply abortado antes da primeira escrita: stale preview mudou para '
        '$dataset (preview=${expected.length}, tx=${actual.length}).',
      );
    }
  }
}

Future<int> _upsertSemanticRows(
  Session session,
  List<Map<String, dynamic>> rows, {
  required int chunkSize,
}) async {
  var count = 0;
  for (final batch in _batches(rows, chunkSize.clamp(1, 750))) {
    final result = await session.execute(
      Sql.named('''
WITH input AS (
  SELECT *
  FROM jsonb_to_recordset(@rows::jsonb) AS x(
    card_id text,
    card_name text,
    schema_version text,
    speed text,
    mana_efficiency text,
    card_advantage_type text,
    interaction_scope text,
    combo_piece boolean,
    wincon boolean,
    engine boolean,
    payoff boolean,
    enabler boolean,
    protection_type text,
    recursion_type text,
    role_confidence numeric,
    explanation_reason text,
    tags jsonb,
    source text
  )
)
INSERT INTO card_semantic_tags_v2 (
  card_id, card_name, schema_version, speed, mana_efficiency,
  card_advantage_type, interaction_scope, combo_piece, wincon, engine, payoff,
  enabler, protection_type, recursion_type, role_confidence,
  explanation_reason, tags, source, updated_at
)
SELECT
  card_id::uuid, card_name, schema_version, speed, mana_efficiency,
  card_advantage_type, interaction_scope, combo_piece, wincon, engine, payoff,
  enabler, protection_type, recursion_type, role_confidence,
  explanation_reason, tags, source, CURRENT_TIMESTAMP
FROM input
ON CONFLICT (card_id, source) DO UPDATE SET
  card_name = EXCLUDED.card_name,
  schema_version = EXCLUDED.schema_version,
  speed = EXCLUDED.speed,
  mana_efficiency = EXCLUDED.mana_efficiency,
  card_advantage_type = EXCLUDED.card_advantage_type,
  interaction_scope = EXCLUDED.interaction_scope,
  combo_piece = EXCLUDED.combo_piece,
  wincon = EXCLUDED.wincon,
  engine = EXCLUDED.engine,
  payoff = EXCLUDED.payoff,
  enabler = EXCLUDED.enabler,
  protection_type = EXCLUDED.protection_type,
  recursion_type = EXCLUDED.recursion_type,
  role_confidence = EXCLUDED.role_confidence,
  explanation_reason = EXCLUDED.explanation_reason,
  tags = EXCLUDED.tags,
  updated_at = CURRENT_TIMESTAMP
WHERE (
  card_semantic_tags_v2.card_name,
  card_semantic_tags_v2.schema_version,
  card_semantic_tags_v2.speed,
  card_semantic_tags_v2.mana_efficiency,
  card_semantic_tags_v2.card_advantage_type,
  card_semantic_tags_v2.interaction_scope,
  card_semantic_tags_v2.combo_piece,
  card_semantic_tags_v2.wincon,
  card_semantic_tags_v2.engine,
  card_semantic_tags_v2.payoff,
  card_semantic_tags_v2.enabler,
  card_semantic_tags_v2.protection_type,
  card_semantic_tags_v2.recursion_type,
  card_semantic_tags_v2.role_confidence,
  card_semantic_tags_v2.explanation_reason,
  card_semantic_tags_v2.tags
) IS DISTINCT FROM (
  EXCLUDED.card_name,
  EXCLUDED.schema_version,
  EXCLUDED.speed,
  EXCLUDED.mana_efficiency,
  EXCLUDED.card_advantage_type,
  EXCLUDED.interaction_scope,
  EXCLUDED.combo_piece,
  EXCLUDED.wincon,
  EXCLUDED.engine,
  EXCLUDED.payoff,
  EXCLUDED.enabler,
  EXCLUDED.protection_type,
  EXCLUDED.recursion_type,
  EXCLUDED.role_confidence,
  EXCLUDED.explanation_reason,
  EXCLUDED.tags
)
RETURNING 1
'''),
      parameters: {'rows': jsonEncode(batch)},
    );
    count += result.length;
  }
  return count;
}

Future<int> _upsertFunctionRows(
  Session session,
  List<Map<String, dynamic>> rows, {
  required int chunkSize,
}) async {
  var count = 0;
  for (final batch in _batches(rows, chunkSize.clamp(1, 1000))) {
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
  card_id::uuid, card_name, tag, confidence, source, evidence,
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

Future<int> _pruneSemanticRows(
  Session session,
  List<Map<String, dynamic>> rows,
) async {
  final result = await session.execute(
    Sql.named('''
WITH planned AS (
  SELECT *
  FROM jsonb_to_recordset(@rows::jsonb) AS x(card_id text)
), deleted AS (
  DELETE FROM card_semantic_tags_v2 existing
  WHERE existing.source = @source
    AND NOT EXISTS (
      SELECT 1
      FROM planned p
      WHERE existing.card_id = p.card_id::uuid
    )
  RETURNING 1
)
SELECT COUNT(*)::int FROM deleted
'''),
    parameters: {
      'rows': jsonEncode([
        for (final row in rows) {'card_id': row['card_id']},
      ]),
      'source': semanticLayerV2Source,
    },
  );
  return (result.first[0] as int?) ?? 0;
}

Future<int> _pruneFunctionRows(
  Session session,
  List<Map<String, dynamic>> rows,
) async {
  final result = await session.execute(
    Sql.named('''
WITH planned AS (
  SELECT *
  FROM jsonb_to_recordset(@rows::jsonb) AS x(card_id text, tag text)
), deleted AS (
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
      'rows': jsonEncode([
        for (final row in rows) {'card_id': row['card_id'], 'tag': row['tag']},
      ]),
      'source': semanticLayerV2Source,
    },
  );
  return (result.first[0] as int?) ?? 0;
}

void _maybeInjectSemanticBackfillFailure({
  required String? configuredLane,
  required String completedLane,
}) {
  if (configuredLane == null || configuredLane != completedLane) return;
  throw StateError(
    'Injected semantic-layer v2 backfill failure after $completedLane; '
    'the global transaction must roll back.',
  );
}

Future<bool> _hasTable(Session session, String tableName) async {
  final result = await session.execute(
    Sql.named('SELECT to_regclass(@name)::text'),
    parameters: {'name': 'public.$tableName'},
  );
  return result.isNotEmpty && result.first[0] != null;
}

void _inc(Map<String, int> map, String key) {
  final normalized = key.trim().isEmpty ? 'unknown' : key.trim();
  map[normalized] = (map[normalized] ?? 0) + 1;
}

Map<String, int> _sorted(Map<String, int> map) {
  final entries =
      map.entries.toList()..sort((a, b) {
        final byCount = b.value.compareTo(a.value);
        if (byCount != 0) return byCount;
        return a.key.compareTo(b.key);
      });
  return {for (final entry in entries) entry.key: entry.value};
}

Iterable<List<Map<String, dynamic>>> _batches(
  List<Map<String, dynamic>> values,
  int size,
) sync* {
  for (var i = 0; i < values.length; i += size) {
    yield values.sublist(
      i,
      i + size > values.length ? values.length : i + size,
    );
  }
}

bool _sameStringSet(Set<String> a, Set<String> b) {
  return a.length == b.length && a.containsAll(b);
}

Future<void> _writeJson(String path, Object payload) async {
  final encoder = const JsonEncoder.withIndent('  ');
  await File(path).writeAsString('${encoder.convert(payload)}\n');
}

Future<void> _writeMarkdownReport(
  String path,
  Map<String, dynamic> summary,
) async {
  final coverage = summary['coverage'] as Map<String, dynamic>;
  final planned = summary['planned_datasets'] as Map<String, dynamic>;
  final semantic = planned['card_semantic_tags_v2'] as Map<String, dynamic>;
  final functions = planned['card_function_tags'] as Map<String, dynamic>;
  await File(path).writeAsString('''
# Semantic Layer v2 Backfill

## Resultado

- `mode`: `${summary['mode']}`
- `scope`: `${summary['scope']}`
- `apply_executed`: `${summary['apply_executed']}`
- `db_mutations`: `${summary['db_mutations']}`
- `schema_version`: `${summary['schema_version']}`
- `card_rows`: `${coverage['card_rows']}`
- `tagged_rows`: `${coverage['tagged_rows']}`
- `unknown_rows`: `${coverage['unknown_rows']}`
- `semantic_rows_planned`: `${semantic['rows']}`
- `function_rows_planned`: `${functions['rows']}`

## Seguranca operacional

O apply exige aprovacao textual exata, rejeita escopo parcial, revalida o
fingerprint de `cards` e o stale preview sob locks, e executa schema, upserts e
prunes do source `${semanticLayerV2Source}` em uma unica transacao.

## Sanitizacao

Os artefatos contem somente contagens e hashes. Nao salvam texto de regras,
nomes/ids de cartas, payloads completos, credenciais, tokens ou evidencias em
texto livre.
''');
}

void _assertSanitized(Object payload) {
  final text = jsonEncode(payload);
  final forbiddenPatterns = [
    'OPENAI'
        '_API'
        '_KEY',
    'DATABASE'
        '_URL',
    'JWT',
    r'Bearer\s+',
    r'postgres:\/\/',
    r'@gmail\.com',
    r'@example\.com',
    'oracle'
        '_text',
    'deck'
        'list',
    r'[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}',
  ];
  if (RegExp(
    '(${forbiddenPatterns.join('|')})',
    caseSensitive: false,
  ).hasMatch(text)) {
    throw StateError('Artifact sanitization failed for Semantic Layer v2.');
  }
}

String? _readArg(List<String> args, String prefix) {
  for (final arg in args) {
    if (arg.startsWith(prefix)) return arg.substring(prefix.length);
  }
  return null;
}

void _printUsage() {
  print('''
semantic_layer_v2_backfill.dart - Backfill autoritativo da Semantic Layer v2

Uso:
  dart run bin/semantic_layer_v2_backfill.dart --dry-run
  MANALOOM_CONFIRM_POSTGRES_WRITES=I_HAVE_EXPLICIT_APPROVAL dart run bin/semantic_layer_v2_backfill.dart --apply
  dart run bin/semantic_layer_v2_backfill.dart --dry-run --limit=500

Opcoes:
  --dry-run                    Planeja e gera resumo agregado sem mutar banco (default)
  --apply                      Aplica o plano completo em uma unica transacao
  --limit=<N>                  Limita apenas dry-run; proibido no apply
  --chunk-size=<N>             Tamanho maximo de lote (default: 2500)
  --max-stale-prune-on-apply=<N>
                               Limite por tabela para prune automatico (default: $_defaultMaxStalePruneOnApply)
  --allow-large-stale-prune    Autoriza prune acima do limite apos revisao
  --review-sample-limit=<N>    Imprime ate N nomes publicos por tag stale/missing (0-100); nao persiste nomes
  --test-fail-after-lane=<lane>
                               Injeta falha transacional controlada; lanes:
                               card_semantic_tags_v2, card_function_tags, prunes
  --artifact-dir=<path>        Diretorio dos artefatos agregados
  --help                       Mostra esta ajuda

Qualquer apply exige exatamente:
  $_postgresWriteApprovalEnv=$_postgresWriteApprovalValue

Failure injection exige adicionalmente:
  $_failureInjectionEnv=$_failureInjectionValue
''');
}
