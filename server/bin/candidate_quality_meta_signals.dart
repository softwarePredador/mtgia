import 'dart:convert';
import 'dart:io';

import 'package:postgres/postgres.dart';
import 'package:server/ai/aggressive_candidate_meta_signal_support.dart';
import 'package:server/ai/candidate_quality_data_support.dart';
import 'package:server/basic_land_utils.dart' as land_utils;
import 'package:server/database.dart';
import 'package:server/meta/meta_deck_analytics_support.dart';
import 'package:server/meta/meta_deck_card_list_support.dart';
import 'package:server/meta/meta_deck_format_support.dart';

const _defaultArtifactDir =
    'test/artifacts/aggressive_candidate_quality_2026-05-05';
const _deterministicRoleSource = 'deterministic_heuristic_v1';

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

  final config = _Config(
    apply: apply,
    artifactDir: Directory(
      _readArg(args, '--artifact-dir=') ?? _defaultArtifactDir,
    ),
    minEvidence: int.tryParse(_readArg(args, '--min-evidence=') ?? '') ?? 3,
    maxRows: int.tryParse(_readArg(args, '--max-rows=') ?? '') ?? 5000,
  );

  await config.artifactDir.create(recursive: true);

  final db = Database();
  await db.connect();
  if (!db.isConnected) {
    throw StateError('Falha ao conectar ao banco para extrair meta signals.');
  }
  final pool = db.connection;
  final startedAt = DateTime.now().toUtc();

  try {
    final preCounts = await _loadCounts(pool);
    if (apply) await _ensureCandidateQualitySchema(pool);

    final cards = await _loadCards(pool);
    final roles = await _loadBestRoleRows(pool);
    final tagConfidence = await _loadFunctionTagConfidence(pool);
    final legalStatuses = await _loadCommanderLegalStatuses(pool);
    final rejectionPenalties = await _loadRejectionPenalties(pool);
    final metaDecks = await _loadMetaDecks(pool);
    final externalDecks = await _loadTrustedExternalCandidates(pool);
    final referenceProfiles = await _loadCommanderReferenceProfiles(pool);

    final aggregates = <String, _SignalAggregate>{};
    final packagePairs = <String, _PackageAggregate>{};
    final coverage = _CoverageAccumulator();

    _collectMetaDeckSignals(
      decks: metaDecks,
      cards: cards,
      roles: roles,
      legalStatuses: legalStatuses,
      aggregates: aggregates,
      packagePairs: packagePairs,
      coverage: coverage,
      minEvidence: config.minEvidence,
    );
    _collectExternalCandidateSignals(
      decks: externalDecks,
      cards: cards,
      roles: roles,
      legalStatuses: legalStatuses,
      aggregates: aggregates,
      packagePairs: packagePairs,
      coverage: coverage,
    );

    final signalRows = _buildCommanderSignalRows(
      aggregates: aggregates.values,
      roles: roles,
      tagConfidence: tagConfidence,
      rejectionPenalties: rejectionPenalties,
      minEvidence: config.minEvidence,
      maxRows: config.maxRows,
    );
    final roleScoreRows = _buildMetaRoleScoreRows(signalRows);
    final selectedShells = _selectRepresentativeShells(signalRows);
    final signalArtifact = _buildSignalArtifact(
      signalRows: signalRows,
      selectedShells: selectedShells,
    );
    final packageArtifact = _buildPackageArtifact(
      packagePairs: packagePairs.values,
      selectedShells: selectedShells,
      minEvidence: config.minEvidence,
    );
    final replacementArtifact = buildRoleReplacementExamples(
      _buildRejectedExamples(rejectionPenalties, cards, roles),
      signalRows,
      limit: 16,
    );
    final budgetArtifact = _buildBudgetPremiumArtifact(
      signalRows: signalRows,
      selectedShells: selectedShells,
    );
    final referenceArtifact = _buildReferenceProfileArtifact(
      referenceProfiles: referenceProfiles,
      selectedShells: selectedShells,
    );

    final staleBefore = {
      'commander_card_synergy':
          await _countStaleCommanderSignalRows(pool, signalRows),
      'card_role_scores': await _countStaleRoleScoreRows(pool, roleScoreRows),
    };

    var upsertedSynergies = 0;
    var upsertedRoleScores = 0;
    var prunedSynergies = 0;
    var prunedRoleScores = 0;
    if (apply) {
      upsertedSynergies = await _upsertCommanderSignalRows(pool, signalRows);
      upsertedRoleScores = await _upsertRoleScoreRows(pool, roleScoreRows);
      prunedSynergies = await _pruneStaleCommanderSignalRows(pool, signalRows);
      prunedRoleScores = await _pruneStaleRoleScoreRows(pool, roleScoreRows);
    }

    final postCounts = await _loadCounts(pool);
    final summary = {
      'schema_version': 'aggressive_candidate_quality_v2_stage2',
      'source': aggressiveCandidateMetaSignalSource,
      'mode': dryRun ? 'dry_run' : 'apply',
      'started_at': startedAt.toIso8601String(),
      'finished_at': DateTime.now().toUtc().toIso8601String(),
      'db_mutations': apply,
      'artifact_dir': config.artifactDir.path,
      'pre_counts': preCounts,
      'post_counts': postCounts,
      'meta_decks_scanned': metaDecks.length,
      'trusted_external_candidates_scanned': externalDecks.length,
      'commander_reference_profiles_scanned': referenceProfiles.length,
      'commander_signal_rows_planned': signalRows.length,
      'role_score_rows_planned': roleScoreRows.length,
      'upserted_commander_signal_rows': upsertedSynergies,
      'upserted_role_score_rows': upsertedRoleScores,
      'stale_generated_rows_before_apply': staleBefore,
      'pruned_stale_commander_signal_rows': prunedSynergies,
      'pruned_stale_role_score_rows': prunedRoleScores,
      'coverage': coverage.toJson(),
      'selected_shells': selectedShells,
      'guardrails': const [
        'dry-run is default; apply requires explicit --apply',
        'writes only source=aggressive_meta_signal_v1 rows in metadata tables',
        'candidate rows require Commander legality legal/restricted/null',
        'candidate color identity must be subset of resolved commander identity',
        'unknown commander identity is reported and not persisted',
        'signals are advisory candidate pools, never forced swaps',
      ],
      'not_proven': const [
        'event date freshness is not proven; local created_at/updated_at is used',
        'EDHREC commander_reference_profiles are enrichment only, not cEDH proof',
        'web interpretation was not used in this command',
      ],
    };

    await _writeJson(
        '${config.artifactDir.path}/summary_${summary['mode']}.json', summary);
    await _writeJson(
        '${config.artifactDir.path}/coverage_summary.json', coverage.toJson());
    await _writeJson(
        '${config.artifactDir.path}/candidate_signals.json', signalArtifact);
    await _writeJson(
        '${config.artifactDir.path}/package_clusters.json', packageArtifact);
    await _writeJson(
      '${config.artifactDir.path}/role_replacements.json',
      replacementArtifact,
    );
    await _writeJson(
      '${config.artifactDir.path}/budget_premium_alternatives.json',
      budgetArtifact,
    );
    await _writeJson(
      '${config.artifactDir.path}/commander_profile_enrichment.json',
      referenceArtifact,
    );
    await _writeCsv(
      '${config.artifactDir.path}/commander_signal_rows.csv',
      signalRows.take(1000).toList(),
      const [
        'shell_label',
        'subformat',
        'card_name',
        'role',
        'score',
        'evidence_count',
        'confidence',
        'budget_tier',
        'bracket_scope',
      ],
    );
    await _writeSummaryMarkdown(
      '${config.artifactDir.path}/summary_${summary['mode']}.md',
      summary,
    );

    stdout.writeln(apply
        ? '[OK] Aggressive candidate meta signals aplicados.'
        : '[OK] Aggressive candidate meta signals dry-run concluido.');
    stdout.writeln('  - Artefatos: ${config.artifactDir.path}');
    stdout.writeln('  - Commander signal rows: ${signalRows.length}');
    stdout.writeln('  - Role score rows: ${roleScoreRows.length}');
  } finally {
    await db.close();
  }
}

void _printUsage() {
  stdout.writeln('''
candidate_quality_meta_signals.dart - Extrai sinais meta/sinergia para candidate pools aggressive

Uso:
  dart run bin/candidate_quality_meta_signals.dart --dry-run
  dart run bin/candidate_quality_meta_signals.dart --apply

Opcoes:
  --dry-run               Gera artefatos sem alterar banco (default)
  --apply                 Persiste rows source=aggressive_meta_signal_v1
  --artifact-dir=<path>   Diretorio de artefatos
  --min-evidence=<N>      Evidencia minima por commander/card/role (default: 3)
  --max-rows=<N>          Limite de commander_card_synergy rows (default: 5000)
''');
}

class _Config {
  const _Config({
    required this.apply,
    required this.artifactDir,
    required this.minEvidence,
    required this.maxRows,
  });

  final bool apply;
  final Directory artifactDir;
  final int minEvidence;
  final int maxRows;
}

class _CardRecord {
  const _CardRecord({
    required this.id,
    required this.name,
    required this.typeLine,
    required this.oracleText,
    required this.manaCost,
    required this.colors,
    required this.colorIdentity,
    required this.priceUsd,
    required this.priceUsdFoil,
  });

  final String id;
  final String name;
  final String typeLine;
  final String oracleText;
  final String manaCost;
  final List<String> colors;
  final List<String> colorIdentity;
  final Object? priceUsd;
  final Object? priceUsdFoil;

  Set<String> get resolvedIdentity => resolveCandidateQualityIdentity(
        colorIdentity: colorIdentity,
        colors: colors,
        oracleText: oracleText,
        manaCost: manaCost,
      );

  String get budgetTier => inferCandidateBudgetTier(
        priceUsd: priceUsd,
        priceUsdFoil: priceUsdFoil,
      );

  Object? get referencePrice => priceUsd ?? priceUsdFoil;
}

class _RoleRow {
  const _RoleRow({
    required this.cardId,
    required this.role,
    required this.score,
    required this.bracketScope,
    required this.budgetTier,
  });

  final String cardId;
  final String role;
  final int score;
  final String bracketScope;
  final String budgetTier;
}

class _DeckRecord {
  const _DeckRecord({
    required this.format,
    required this.subformat,
    required this.source,
    required this.commanderName,
    required this.partnerCommanderName,
    required this.shellLabel,
    required this.strategyArchetype,
    required this.cardList,
    required this.seenAt,
    required this.isExternal,
  });

  final String format;
  final String subformat;
  final String source;
  final String commanderName;
  final String partnerCommanderName;
  final String shellLabel;
  final String strategyArchetype;
  final String cardList;
  final DateTime? seenAt;
  final bool isExternal;

  String get normalizedShellLabel {
    final explicit = shellLabel.trim();
    if (explicit.isNotEmpty && explicit.toLowerCase() != 'unknown') {
      return explicit;
    }
    final commander = commanderName.trim();
    final partner = partnerCommanderName.trim();
    if (partner.isEmpty) return commander;
    return '$commander + $partner';
  }
}

class _SignalAggregate {
  _SignalAggregate({
    required this.shellLabel,
    required this.commanderName,
    required this.partnerCommanderName,
    required this.subformat,
    required this.strategyArchetype,
    required this.commanderIdentity,
    required this.card,
    required this.role,
  });

  final String shellLabel;
  final String commanderName;
  final String partnerCommanderName;
  final String subformat;
  final String strategyArchetype;
  final Set<String> commanderIdentity;
  final _CardRecord card;
  final String role;
  final Set<String> sourceCategories = <String>{};
  int evidenceCount = 0;
  int deckCount = 0;
  DateTime? latestSeenAt;
  bool commanderIdentityResolved = true;

  void addEvidence({
    required String source,
    required int quantity,
    required DateTime? seenAt,
  }) {
    sourceCategories.add(source);
    evidenceCount += quantity <= 0 ? 1 : quantity;
    deckCount += 1;
    if (seenAt != null &&
        (latestSeenAt == null || seenAt.isAfter(latestSeenAt!))) {
      latestSeenAt = seenAt;
    }
  }
}

class _PackageAggregate {
  _PackageAggregate({
    required this.shellLabel,
    required this.subformat,
    required this.cardA,
    required this.cardB,
  });

  final String shellLabel;
  final String subformat;
  final String cardA;
  final String cardB;
  int evidenceCount = 0;
  DateTime? latestSeenAt;

  void add(DateTime? seenAt) {
    evidenceCount += 1;
    if (seenAt != null &&
        (latestSeenAt == null || seenAt.isAfter(latestSeenAt!))) {
      latestSeenAt = seenAt;
    }
  }
}

class _CoverageAccumulator {
  int metaDecks = 0;
  int trustedExternalCandidates = 0;
  int commanderDecksWithResolvedIdentity = 0;
  int commanderDecksWithUnknownIdentity = 0;
  int commanderDecksWithSignals = 0;
  final byFormat = <String, int>{};
  final bySubformat = <String, int>{};
  final bySourceFormat = <String, int>{};
  final byColorIdentity = <String, int>{};
  final byStrategy = <String, int>{};
  final unknownCommanderLabels = <String, int>{};

  void addDeck({
    required _DeckRecord deck,
    required Set<String> commanderIdentity,
    required int signalCardCount,
  }) {
    if (deck.isExternal) {
      trustedExternalCandidates += 1;
    } else {
      metaDecks += 1;
    }
    _inc(byFormat, deck.format);
    _inc(bySubformat, deck.subformat);
    _inc(bySourceFormat, '${deck.source}|${deck.format}');
    _inc(byStrategy, _safeLabel(deck.strategyArchetype));
    if (commanderIdentity.isEmpty) {
      commanderDecksWithUnknownIdentity += 1;
      _inc(unknownCommanderLabels, deck.normalizedShellLabel);
    } else {
      commanderDecksWithResolvedIdentity += 1;
      _inc(byColorIdentity, _identityLabel(commanderIdentity));
    }
    if (signalCardCount > 0) commanderDecksWithSignals += 1;
  }

  Map<String, dynamic> toJson() {
    return {
      'meta_decks_commander_scanned': metaDecks,
      'trusted_external_candidates_scanned': trustedExternalCandidates,
      'commander_decks_with_resolved_identity':
          commanderDecksWithResolvedIdentity,
      'commander_decks_with_unknown_identity':
          commanderDecksWithUnknownIdentity,
      'commander_decks_with_candidate_signals': commanderDecksWithSignals,
      'by_format': _sortedCounts(byFormat),
      'by_subformat': _sortedCounts(bySubformat),
      'by_source_format': _sortedCounts(bySourceFormat),
      'by_color_identity': _sortedCounts(byColorIdentity),
      'by_strategy': _sortedCounts(byStrategy),
      'unknown_commander_labels': _sortedCounts(unknownCommanderLabels),
    };
  }
}

Future<Map<String, int>> _loadCounts(Pool pool) async {
  final tables = [
    'meta_decks',
    'external_commander_meta_candidates',
    'commander_reference_profiles',
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

Future<Map<String, _CardRecord>> _loadCards(Pool pool) async {
  final rows = await pool.execute('''
SELECT DISTINCT ON (LOWER(name))
  id::text,
  name,
  COALESCE(type_line, '') AS type_line,
  COALESCE(oracle_text, '') AS oracle_text,
  COALESCE(mana_cost, '') AS mana_cost,
  COALESCE(colors, ARRAY[]::text[]) AS colors,
  COALESCE(color_identity, ARRAY[]::text[]) AS color_identity,
  price_usd,
  price_usd_foil
FROM cards
WHERE name IS NOT NULL
ORDER BY LOWER(name), set_code ASC NULLS LAST, id ASC
''');

  return {
    for (final row in rows)
      normalizeCandidateQualityKey((row[1] as String?) ?? ''): _CardRecord(
        id: row[0] as String,
        name: (row[1] as String?) ?? '',
        typeLine: (row[2] as String?) ?? '',
        oracleText: (row[3] as String?) ?? '',
        manaCost: (row[4] as String?) ?? '',
        colors:
            (row[5] as List?)?.map((e) => e.toString()).toList() ?? const [],
        colorIdentity:
            (row[6] as List?)?.map((e) => e.toString()).toList() ?? const [],
        priceUsd: row[7],
        priceUsdFoil: row[8],
      )
  };
}

Future<Map<String, List<_RoleRow>>> _loadBestRoleRows(Pool pool) async {
  if (!await _hasTable(pool, 'card_role_scores')) return {};
  final rows = await pool.execute(
    Sql.named('''
SELECT card_id::text, role, score, bracket_scope, budget_tier
FROM card_role_scores
WHERE source = @source
'''),
    parameters: {'source': _deterministicRoleSource},
  );

  final byCard = <String, Map<String, _RoleRow>>{};
  for (final row in rows) {
    final cardId = row[0] as String;
    final role = (row[1] as String?) ?? '';
    if (role.isEmpty || !aggressiveCandidateTrackedRoles.contains(role)) {
      continue;
    }
    final candidate = _RoleRow(
      cardId: cardId,
      role: role,
      score: (row[2] as int?) ?? 0,
      bracketScope: (row[3] as String?) ?? 'any',
      budgetTier: (row[4] as String?) ?? 'unknown',
    );
    final roles = byCard.putIfAbsent(cardId, () => <String, _RoleRow>{});
    final current = roles[role];
    if (current == null || candidate.score > current.score) {
      roles[role] = candidate;
    }
  }

  return {
    for (final entry in byCard.entries) entry.key: entry.value.values.toList()
  };
}

Future<Map<String, double>> _loadFunctionTagConfidence(Pool pool) async {
  if (!await _hasTable(pool, 'card_function_tags')) return {};
  final rows = await pool.execute(
    Sql.named('''
SELECT card_id::text, tag, MAX(confidence)::float
FROM card_function_tags
WHERE source = @source
GROUP BY card_id, tag
'''),
    parameters: {'source': _deterministicRoleSource},
  );
  return {
    for (final row in rows)
      '${row[0]}|${normalizeCandidateQualityRole((row[1] as String?) ?? '')}':
          ((row[2] as num?) ?? 0).toDouble()
  };
}

Future<Map<String, String>> _loadCommanderLegalStatuses(Pool pool) async {
  if (!await _hasTable(pool, 'card_legalities')) return {};
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

Future<Map<String, int>> _loadRejectionPenalties(Pool pool) async {
  if (!await _hasTable(pool, 'optimize_rejection_penalties')) return {};
  final rows = await pool.execute('''
SELECT card_name_normalized, MAX(penalty)::int
FROM optimize_rejection_penalties
GROUP BY card_name_normalized
''');
  return {
    for (final row in rows) (row[0] as String?) ?? '': (row[1] as int?) ?? 0
  };
}

Future<List<_DeckRecord>> _loadMetaDecks(Pool pool) async {
  if (!await _hasTable(pool, 'meta_decks')) return const [];
  final rows = await pool.execute('''
SELECT
  format,
  source_url,
  archetype,
  commander_name,
  partner_commander_name,
  shell_label,
  strategy_archetype,
  card_list,
  created_at
FROM meta_decks
WHERE format IN ('EDH', 'cEDH')
  AND card_list IS NOT NULL
  AND TRIM(card_list) <> ''
  AND commander_name IS NOT NULL
  AND TRIM(commander_name) <> ''
''');

  return rows.map((row) {
    final format = ((row[0] as String?) ?? '').trim();
    final sourceUrl = row[1] as String?;
    final cardList = (row[7] as String?) ?? '';
    final context = resolveMetaDeckAnalyticsContext(
      format: format,
      sourceUrl: sourceUrl,
      rawArchetype: row[2] as String?,
      commanderName: row[3] as String?,
      partnerCommanderName: row[4] as String?,
      shellLabel: row[5] as String?,
      strategyArchetype: row[6] as String?,
      cardList: cardList,
    );
    return _DeckRecord(
      format: format,
      subformat: context.commanderSubformat ?? 'commander',
      source: context.source,
      commanderName: ((row[3] as String?) ?? '').trim(),
      partnerCommanderName: ((row[4] as String?) ?? '').trim(),
      shellLabel: ((row[5] as String?) ?? '').trim(),
      strategyArchetype: ((row[6] as String?) ?? '').trim(),
      cardList: cardList,
      seenAt: row[8] is DateTime ? row[8] as DateTime : null,
      isExternal: false,
    );
  }).toList(growable: false);
}

Future<List<_DeckRecord>> _loadTrustedExternalCandidates(Pool pool) async {
  if (!await _hasTable(pool, 'external_commander_meta_candidates')) {
    return const [];
  }
  final rows = await pool.execute('''
SELECT
  source_name,
  source_host,
  deck_name,
  commander_name,
  partner_commander_name,
  subformat,
  archetype,
  card_list,
  validation_status,
  legal_status,
  COALESCE(promoted_to_meta_decks_at, updated_at, created_at) AS seen_at
FROM external_commander_meta_candidates
WHERE card_list IS NOT NULL
  AND TRIM(card_list) <> ''
''');

  return rows.where((row) {
    return isExternalCommanderCandidateTrusted(
      validationStatus: row[8] as String?,
      legalStatus: row[9] as String?,
      subformat: row[5] as String?,
    );
  }).map((row) {
    final subformat = normalizeCommanderMetaScope(
      row[5] as String?,
      fallback: 'competitive_commander',
    );
    return _DeckRecord(
      format:
          legacyMetaDeckFormatCodeForCommanderSubformat(subformat) ?? 'cEDH',
      subformat: subformat,
      source: 'external:${((row[0] as String?) ?? 'unknown').trim()}',
      commanderName: ((row[3] as String?) ?? '').trim(),
      partnerCommanderName: ((row[4] as String?) ?? '').trim(),
      shellLabel: '',
      strategyArchetype: ((row[6] as String?) ?? '').trim(),
      cardList: (row[7] as String?) ?? '',
      seenAt: row[10] is DateTime ? row[10] as DateTime : null,
      isExternal: true,
    );
  }).toList(growable: false);
}

Future<List<Map<String, dynamic>>> _loadCommanderReferenceProfiles(
  Pool pool,
) async {
  if (!await _hasTable(pool, 'commander_reference_profiles')) return const [];
  final rows = await pool.execute('''
SELECT commander_name, source, deck_count, profile_json, updated_at
FROM commander_reference_profiles
ORDER BY updated_at DESC NULLS LAST, commander_name ASC
''');
  return rows.map((row) {
    final profile = row[3];
    return {
      'commander_name': row[0],
      'source': row[1],
      'deck_count': row[2],
      'updated_at': _dateToIso(row[4]),
      'profile_json': profile is Map
          ? Map<String, dynamic>.from(profile)
          : <String, dynamic>{},
    };
  }).toList(growable: false);
}

void _collectMetaDeckSignals({
  required List<_DeckRecord> decks,
  required Map<String, _CardRecord> cards,
  required Map<String, List<_RoleRow>> roles,
  required Map<String, String> legalStatuses,
  required Map<String, _SignalAggregate> aggregates,
  required Map<String, _PackageAggregate> packagePairs,
  required _CoverageAccumulator coverage,
  required int minEvidence,
}) {
  for (final deck in decks) {
    _collectDeckSignals(
      deck: deck,
      cards: cards,
      roles: roles,
      legalStatuses: legalStatuses,
      aggregates: aggregates,
      packagePairs: packagePairs,
      coverage: coverage,
    );
  }
}

void _collectExternalCandidateSignals({
  required List<_DeckRecord> decks,
  required Map<String, _CardRecord> cards,
  required Map<String, List<_RoleRow>> roles,
  required Map<String, String> legalStatuses,
  required Map<String, _SignalAggregate> aggregates,
  required Map<String, _PackageAggregate> packagePairs,
  required _CoverageAccumulator coverage,
}) {
  for (final deck in decks) {
    _collectDeckSignals(
      deck: deck,
      cards: cards,
      roles: roles,
      legalStatuses: legalStatuses,
      aggregates: aggregates,
      packagePairs: packagePairs,
      coverage: coverage,
    );
  }
}

void _collectDeckSignals({
  required _DeckRecord deck,
  required Map<String, _CardRecord> cards,
  required Map<String, List<_RoleRow>> roles,
  required Map<String, String> legalStatuses,
  required Map<String, _SignalAggregate> aggregates,
  required Map<String, _PackageAggregate> packagePairs,
  required _CoverageAccumulator coverage,
}) {
  final commander = cards[normalizeCandidateQualityKey(deck.commanderName)];
  final partner =
      cards[normalizeCandidateQualityKey(deck.partnerCommanderName)];
  final commanderIdentity = <String>{
    ...?commander?.resolvedIdentity,
    ...?partner?.resolvedIdentity,
  };
  final commanderKeys = {
    normalizeCandidateQualityKey(deck.commanderName),
    normalizeCandidateQualityKey(deck.partnerCommanderName),
  }..remove('');

  final parsed = parseMetaDeckCardList(
    cardList: deck.cardList,
    format: deck.format,
  );
  final packageCards = <String>{};
  var signalCardCount = 0;

  for (final entry in parsed.effectiveCards.entries) {
    final normalizedCard = normalizeCandidateQualityKey(entry.key);
    if (commanderKeys.contains(normalizedCard)) continue;
    final card = cards[normalizedCard];
    if (card == null) continue;
    if (land_utils.isLandTypeLine(card.typeLine)) continue;
    final status = legalStatuses[card.id];
    if (!isCommanderCandidateLegalityAllowed(status)) continue;
    final roleRows = roles[card.id] ?? const <_RoleRow>[];
    if (roleRows.isEmpty) continue;
    if (!colorIdentityFits(
      cardIdentity: card.resolvedIdentity,
      commanderIdentity: commanderIdentity,
    )) {
      continue;
    }

    for (final role in roleRows) {
      final key = [
        normalizeCandidateQualityKey(deck.normalizedShellLabel),
        card.id,
        role.role,
        deck.subformat,
      ].join('|');
      final aggregate = aggregates.putIfAbsent(
        key,
        () => _SignalAggregate(
          shellLabel: deck.normalizedShellLabel,
          commanderName: deck.commanderName,
          partnerCommanderName: deck.partnerCommanderName,
          subformat: deck.subformat,
          strategyArchetype: deck.strategyArchetype,
          commanderIdentity: commanderIdentity,
          card: card,
          role: role.role,
        ),
      );
      aggregate.commanderIdentityResolved = commanderIdentity.isNotEmpty;
      aggregate.addEvidence(
        source: deck.source,
        quantity: entry.value,
        seenAt: deck.seenAt,
      );
      signalCardCount += 1;
      packageCards.add(card.name);
    }
  }

  _collectPackagePairs(
    shellLabel: deck.normalizedShellLabel,
    subformat: deck.subformat,
    cardNames: packageCards,
    seenAt: deck.seenAt,
    packagePairs: packagePairs,
  );
  coverage.addDeck(
    deck: deck,
    commanderIdentity: commanderIdentity,
    signalCardCount: signalCardCount,
  );
}

void _collectPackagePairs({
  required String shellLabel,
  required String subformat,
  required Set<String> cardNames,
  required DateTime? seenAt,
  required Map<String, _PackageAggregate> packagePairs,
}) {
  final names = cardNames.toList()..sort();
  final limited = names.take(32).toList(growable: false);
  for (var i = 0; i < limited.length; i++) {
    for (var j = i + 1; j < limited.length; j++) {
      final key = [
        normalizeCandidateQualityKey(shellLabel),
        subformat,
        normalizeCandidateQualityKey(limited[i]),
        normalizeCandidateQualityKey(limited[j]),
      ].join('|');
      packagePairs
          .putIfAbsent(
            key,
            () => _PackageAggregate(
              shellLabel: shellLabel,
              subformat: subformat,
              cardA: limited[i],
              cardB: limited[j],
            ),
          )
          .add(seenAt);
    }
  }
}

List<Map<String, dynamic>> _buildCommanderSignalRows({
  required Iterable<_SignalAggregate> aggregates,
  required Map<String, List<_RoleRow>> roles,
  required Map<String, double> tagConfidence,
  required Map<String, int> rejectionPenalties,
  required int minEvidence,
  required int maxRows,
}) {
  final rows = <Map<String, dynamic>>[];
  for (final aggregate in aggregates) {
    if (aggregate.evidenceCount < minEvidence) continue;
    if (!aggregate.commanderIdentityResolved) continue;
    final roleRow = (roles[aggregate.card.id] ?? const <_RoleRow>[])
        .where((row) => row.role == aggregate.role)
        .fold<_RoleRow?>(null, (current, row) {
      if (current == null || row.score > current.score) return row;
      return current;
    });
    if (roleRow == null) continue;

    final freshnessDays = _freshnessDays(aggregate.latestSeenAt);
    final confidence = confidenceLabel(
      evidenceCount: aggregate.evidenceCount,
      source: aggregate.sourceCategories.join(','),
      freshnessDays: freshnessDays,
      commanderIdentityResolved: aggregate.commanderIdentityResolved,
    );
    if (confidence == 'not_proven') continue;

    final functionConfidence =
        tagConfidence['${aggregate.card.id}|${aggregate.role}'] ?? 0.5;
    final rejectionPenalty =
        rejectionPenalties[normalizeCandidateQualityKey(aggregate.card.name)] ??
            0;
    final score = scoreAggressiveMetaSignal(
      evidenceCount: aggregate.evidenceCount,
      roleScore: roleRow.score,
      functionConfidence: functionConfidence,
      subformat: aggregate.subformat,
      rejectionPenalty: rejectionPenalty,
      freshnessDays: freshnessDays,
    );
    final bracketScope = bracketScopeForMetaSignal(
      subformat: aggregate.subformat,
      existingBracketScope: roleRow.bracketScope,
      score: score,
    );
    final freshness = aggregate.latestSeenAt == null
        ? 'not_proven_local_seen_at_missing'
        : 'local_seen_at=${aggregate.latestSeenAt!.toUtc().toIso8601String()}';
    rows.add({
      'commander_name_normalized':
          normalizeCandidateQualityKey(aggregate.shellLabel),
      'commander_name': aggregate.shellLabel,
      'shell_label': aggregate.shellLabel,
      'primary_commander': aggregate.commanderName,
      'partner_commander': aggregate.partnerCommanderName,
      'subformat': aggregate.subformat,
      'strategy_archetype': aggregate.strategyArchetype,
      'commander_identity': _identityList(aggregate.commanderIdentity),
      'card_id': aggregate.card.id,
      'card_name': aggregate.card.name,
      'role': aggregate.role,
      'score': score,
      'source': aggressiveCandidateMetaSignalSource,
      'source_categories': aggregate.sourceCategories.toList()..sort(),
      'evidence_count': aggregate.evidenceCount,
      'deck_count': aggregate.deckCount,
      'confidence': confidence,
      'function_confidence':
          double.parse(functionConfidence.toStringAsFixed(3)),
      'deterministic_role_score': roleRow.score,
      'rejection_penalty': rejectionPenalty,
      'budget_tier': aggregate.card.budgetTier == 'unknown'
          ? roleRow.budgetTier
          : aggregate.card.budgetTier,
      'reference_price_usd': aggregate.card.referencePrice,
      'bracket_scope': bracketScope,
      'legal_status': 'legal_or_restricted_or_not_listed',
      'color_identity': _identityList(aggregate.card.resolvedIdentity),
      'freshness': freshness,
      'evidence': buildMetaSignalEvidence(
        source: aggregate.sourceCategories.join(','),
        subformat: aggregate.subformat,
        confidence: confidence,
        evidenceCount: aggregate.evidenceCount,
        deckCount: aggregate.deckCount,
        freshness: freshness,
      ),
    });
  }

  rows.sort((a, b) {
    final byScore = (b['score'] as int).compareTo(a['score'] as int);
    if (byScore != 0) return byScore;
    final byEvidence =
        (b['evidence_count'] as int).compareTo(a['evidence_count'] as int);
    if (byEvidence != 0) return byEvidence;
    return (a['card_name'] as String).compareTo(b['card_name'] as String);
  });
  return rows.take(maxRows).toList(growable: false);
}

List<Map<String, dynamic>> _buildMetaRoleScoreRows(
  List<Map<String, dynamic>> signalRows,
) {
  final grouped = <String, Map<String, dynamic>>{};
  for (final row in signalRows) {
    final key = [
      row['card_id'],
      row['role'],
      row['subformat'],
      row['bracket_scope'],
    ].join('|');
    final existing = grouped[key];
    if (existing == null) {
      grouped[key] = {
        'card_id': row['card_id'],
        'card_name': row['card_name'],
        'role': row['role'],
        'score': row['score'],
        'format': 'commander',
        'subformat': row['subformat'],
        'bracket_scope': row['bracket_scope'],
        'budget_tier': row['budget_tier'],
        'source': aggressiveCandidateMetaSignalSource,
        'evidence_count': row['evidence_count'],
        'confidence': row['confidence'],
        'evidence': row['evidence'],
      };
      continue;
    }
    existing['score'] = ((existing['score'] as int) > (row['score'] as int))
        ? existing['score']
        : row['score'];
    existing['evidence_count'] =
        (existing['evidence_count'] as int) + (row['evidence_count'] as int);
    existing['evidence'] =
        'source=$aggressiveCandidateMetaSignalSource;subformat=${row['subformat']};evidence_count=${existing['evidence_count']};forced_swap=false';
  }
  final output = grouped.values.toList()
    ..sort((a, b) {
      final byScore = (b['score'] as int).compareTo(a['score'] as int);
      if (byScore != 0) return byScore;
      return (a['card_name'] as String).compareTo(b['card_name'] as String);
    });
  return output;
}

List<String> _selectRepresentativeShells(
    List<Map<String, dynamic>> signalRows) {
  const preferred = [
    'Kinnan, Bonder Prodigy',
    'Kraum, Ludevic\'s Opus',
    'Thrasios, Triton Hero',
    'Spider-Man 2099',
  ];
  final available = <String>{};
  final counts = <String, int>{};
  for (final row in signalRows) {
    final shell = row['shell_label'] as String;
    available.add(shell);
    counts[shell] = (counts[shell] ?? 0) + 1;
  }
  final selected = <String>[];
  for (final shell in preferred) {
    final match = available.firstWhere(
      (candidate) =>
          normalizeCandidateQualityKey(candidate)
              .contains(normalizeCandidateQualityKey(shell)) ||
          normalizeCandidateQualityKey(shell)
              .contains(normalizeCandidateQualityKey(candidate)),
      orElse: () => '',
    );
    if (match.isNotEmpty && !selected.contains(match)) selected.add(match);
  }
  final byCount = counts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  for (final entry in byCount) {
    if (selected.length >= 4) break;
    if (!selected.contains(entry.key)) selected.add(entry.key);
  }
  return selected.take(4).toList(growable: false);
}

List<Map<String, dynamic>> _buildSignalArtifact({
  required List<Map<String, dynamic>> signalRows,
  required List<String> selectedShells,
}) {
  final output = <Map<String, dynamic>>[];
  for (final shell in selectedShells) {
    final shellRows =
        signalRows.where((row) => row['shell_label'] == shell).toList();
    if (shellRows.isEmpty) continue;
    final byRole = <String, List<Map<String, dynamic>>>{};
    for (final row in shellRows) {
      byRole.putIfAbsent(row['role'] as String, () => []).add(row);
    }
    final roles = <String, dynamic>{};
    for (final entry in byRole.entries) {
      final rows = entry.value
        ..sort((a, b) {
          final byScore = (b['score'] as int).compareTo(a['score'] as int);
          if (byScore != 0) return byScore;
          return (b['evidence_count'] as int)
              .compareTo(a['evidence_count'] as int);
        });
      roles[entry.key] = rows.take(8).map(_publicSignalRow).toList();
    }
    output.add({
      'shell_label': shell,
      'subformat': shellRows.first['subformat'],
      'commander_identity': shellRows.first['commander_identity'],
      'strategy_archetype': shellRows.first['strategy_archetype'],
      'signal_row_count': shellRows.length,
      'top_cards_by_role': roles,
      'guardrails': const [
        'legal_status already filtered to legal/restricted/not-listed',
        'color_identity is subset of commander_identity',
        'source/confidence/evidence_count must be consumed as advisory',
      ],
    });
  }
  return output;
}

Map<String, dynamic> _publicSignalRow(Map<String, dynamic> row) {
  return {
    'card_name': row['card_name'],
    'role': row['role'],
    'score': row['score'],
    'evidence_count': row['evidence_count'],
    'deck_count': row['deck_count'],
    'confidence': row['confidence'],
    'source_categories': row['source_categories'],
    'budget_tier': row['budget_tier'],
    'reference_price_usd': row['reference_price_usd'],
    'bracket_scope': row['bracket_scope'],
    'color_identity': row['color_identity'],
    'freshness': row['freshness'],
  };
}

List<Map<String, dynamic>> _buildPackageArtifact({
  required Iterable<_PackageAggregate> packagePairs,
  required List<String> selectedShells,
  required int minEvidence,
}) {
  final selected = selectedShells.toSet();
  final rows = packagePairs
      .where((pair) =>
          selected.contains(pair.shellLabel) &&
          pair.evidenceCount >= minEvidence)
      .map((pair) {
    final confidence = confidenceLabel(
      evidenceCount: pair.evidenceCount,
      source: pair.subformat,
      freshnessDays: _freshnessDays(pair.latestSeenAt),
    );
    return {
      'shell_label': pair.shellLabel,
      'subformat': pair.subformat,
      'cards': [pair.cardA, pair.cardB],
      'evidence_count': pair.evidenceCount,
      'confidence': confidence,
      'why':
          'cards co-occur in accepted local meta decks for this shell; package is advisory and not a forced swap',
      'freshness': pair.latestSeenAt == null
          ? 'not_proven_local_seen_at_missing'
          : 'local_seen_at=${pair.latestSeenAt!.toUtc().toIso8601String()}',
    };
  }).toList()
    ..sort((a, b) {
      final byEvidence =
          (b['evidence_count'] as int).compareTo(a['evidence_count'] as int);
      if (byEvidence != 0) return byEvidence;
      return (a['shell_label'] as String).compareTo(b['shell_label'] as String);
    });
  return rows.take(80).toList(growable: false);
}

List<Map<String, dynamic>> _buildRejectedExamples(
  Map<String, int> penalties,
  Map<String, _CardRecord> cards,
  Map<String, List<_RoleRow>> roles,
) {
  final output = <Map<String, dynamic>>[];
  final ordered = penalties.entries.where((entry) => entry.value > 0).toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  for (final entry in ordered) {
    final card = cards[entry.key];
    if (card == null) continue;
    if (land_utils.isLandTypeLine(card.typeLine)) continue;
    final roleRows = roles[card.id] ?? const <_RoleRow>[];
    if (roleRows.isEmpty) continue;
    final bestRole = roleRows.reduce((a, b) => a.score >= b.score ? a : b);
    output.add({
      'card_name': card.name,
      'role': bestRole.role,
      'reason': 'historical_quality_penalty=${entry.value}',
    });
    if (output.length >= 40) break;
  }
  return output;
}

List<Map<String, dynamic>> _buildBudgetPremiumArtifact({
  required List<Map<String, dynamic>> signalRows,
  required List<String> selectedShells,
}) {
  final output = <Map<String, dynamic>>[];
  for (final shell in selectedShells) {
    final rows = signalRows.where((row) => row['shell_label'] == shell);
    final byRole = <String, List<Map<String, dynamic>>>{};
    for (final row in rows) {
      byRole.putIfAbsent(row['role'] as String, () => []).add(row);
    }
    for (final entry in byRole.entries) {
      final budget = entry.value
          .where((row) =>
              row['budget_tier'] == 'budget' ||
              row['budget_tier'] == 'accessible')
          .take(4)
          .map(_publicSignalRow)
          .toList();
      final premium = entry.value
          .where((row) =>
              row['budget_tier'] == 'premium' ||
              row['budget_tier'] == 'expensive')
          .take(4)
          .map(_publicSignalRow)
          .toList();
      output.add({
        'shell_label': shell,
        'role': entry.key,
        'budget_or_accessible': budget,
        'premium_or_expensive': premium,
        'price_gap': budget.isEmpty && premium.isEmpty
            ? 'not_proven_price_data_sparse'
            : null,
      });
    }
  }
  return output;
}

List<Map<String, dynamic>> _buildReferenceProfileArtifact({
  required List<Map<String, dynamic>> referenceProfiles,
  required List<String> selectedShells,
}) {
  final profilesByName = {
    for (final profile in referenceProfiles)
      normalizeCandidateQualityKey(profile['commander_name']?.toString() ?? ''):
          profile
  };
  final output = <Map<String, dynamic>>[];
  for (final shell in selectedShells) {
    final commander = shell.split('+').first.trim();
    final profile = profilesByName[normalizeCandidateQualityKey(commander)];
    if (profile == null) {
      output.add({
        'shell_label': shell,
        'profile_status': 'not_proven',
        'reason': 'no commander_reference_profiles row for primary commander',
      });
      continue;
    }
    final payload = profile['profile_json'] as Map<String, dynamic>;
    final topCards = (payload['top_cards'] as List?)
            ?.whereType<Map>()
            .take(12)
            .map((entry) => Map<String, dynamic>.from(entry))
            .toList() ??
        const <Map<String, dynamic>>[];
    output.add({
      'shell_label': shell,
      'profile_status': 'enrichment_only',
      'source': profile['source'],
      'deck_count': profile['deck_count'],
      'updated_at': profile['updated_at'],
      'top_cards_preview': topCards,
      'not_cedh_proof': true,
    });
  }
  return output;
}

Future<void> _ensureCandidateQualitySchema(Pool pool) async {
  for (final statement in candidateQualitySchemaStatements) {
    await pool.execute(statement);
  }
  for (final statement in candidateQualityIndexStatements) {
    await pool.execute(statement);
  }
  await pool.execute(optimizeCandidateQualitySummaryViewStatement);
  await pool.execute(cardIntelligenceSnapshotViewStatement);
}

Future<int> _upsertCommanderSignalRows(
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

Future<int> _upsertRoleScoreRows(
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

Future<int> _countStaleCommanderSignalRows(
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
      'source': aggressiveCandidateMetaSignalSource
    },
  );
  return (result.first[0] as int?) ?? 0;
}

Future<int> _countStaleRoleScoreRows(
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
      'source': aggressiveCandidateMetaSignalSource
    },
  );
  return (result.first[0] as int?) ?? 0;
}

Future<int> _pruneStaleCommanderSignalRows(
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
      'source': aggressiveCandidateMetaSignalSource
    },
  );
  return (result.first[0] as int?) ?? 0;
}

Future<int> _pruneStaleRoleScoreRows(
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
      'source': aggressiveCandidateMetaSignalSource
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

String? _readArg(List<String> args, String prefix) {
  for (final arg in args) {
    if (arg.startsWith(prefix)) return arg.substring(prefix.length);
  }
  return null;
}

void _inc(Map<String, int> counts, String rawKey) {
  final key = _safeLabel(rawKey);
  counts[key] = (counts[key] ?? 0) + 1;
}

String _safeLabel(String? value) {
  final normalized = value?.trim();
  return normalized == null || normalized.isEmpty ? 'unknown' : normalized;
}

String _identityLabel(Set<String> identity) {
  final list = _identityList(identity);
  return list.isEmpty ? 'C' : list.join('');
}

List<String> _identityList(Set<String> identity) {
  return identity.toList()..sort(_compareColor);
}

int _compareColor(String a, String b) {
  const order = ['W', 'U', 'B', 'R', 'G'];
  final ai = order.indexOf(a);
  final bi = order.indexOf(b);
  if (ai == -1 || bi == -1) return a.compareTo(b);
  return ai.compareTo(bi);
}

Map<String, int> _sortedCounts(Map<String, int> counts) {
  return Map.fromEntries(
    counts.entries.toList()
      ..sort((a, b) {
        final byCount = b.value.compareTo(a.value);
        if (byCount != 0) return byCount;
        return a.key.compareTo(b.key);
      }),
  );
}

int? _freshnessDays(DateTime? value) {
  if (value == null) return null;
  return DateTime.now().toUtc().difference(value.toUtc()).inDays;
}

String? _dateToIso(Object? value) {
  return value is DateTime ? value.toUtc().toIso8601String() : null;
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
  final coverage = summary['coverage'] as Map<String, dynamic>;
  final buffer = StringBuffer()
    ..writeln('# Aggressive Candidate Quality v2 Stage 2 - ${summary['mode']}')
    ..writeln()
    ..writeln('- Source: `${summary['source']}`')
    ..writeln('- DB mutations: `${summary['db_mutations']}`')
    ..writeln('- Meta decks scanned: `${summary['meta_decks_scanned']}`')
    ..writeln(
      '- Trusted external candidates scanned: `${summary['trusted_external_candidates_scanned']}`',
    )
    ..writeln(
      '- Commander signal rows planned: `${summary['commander_signal_rows_planned']}`',
    )
    ..writeln(
      '- Role score rows planned: `${summary['role_score_rows_planned']}`',
    )
    ..writeln()
    ..writeln('## Coverage')
    ..writeln()
    ..writeln(
      '- Resolved commander identity decks: `${coverage['commander_decks_with_resolved_identity']}`',
    )
    ..writeln(
      '- Unknown commander identity decks: `${coverage['commander_decks_with_unknown_identity']}`',
    )
    ..writeln()
    ..writeln('## Selected shells')
    ..writeln()
    ..writeln('| Shell |')
    ..writeln('|---|');
  for (final shell in (summary['selected_shells'] as List)) {
    buffer.writeln('| $shell |');
  }
  await File(path).writeAsString(buffer.toString());
}
