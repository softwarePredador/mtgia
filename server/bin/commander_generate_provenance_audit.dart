import 'dart:convert';
import 'dart:io';

import 'package:server/ai/commander_learned_deck_support.dart';
import 'package:server/ai/commander_reference_card_stats_support.dart';
import 'package:server/ai/commander_reference_deck_corpus_support.dart';
import 'package:server/ai/commander_reference_generate_fallback_support.dart';
import 'package:server/ai/commander_reference_profile_support.dart';
import 'package:server/ai/deck_learning_event_support.dart';
import 'package:server/database.dart';
import 'package:postgres/postgres.dart';

const _defaultCommander = loreholdReferenceCommanderName;
const _defaultArtifactDir =
    'test/artifacts/commander_generate_provenance_2026-06-16';

typedef NameSetMap = Map<String, Set<String>>;

class SourceOverlapSummary {
  const SourceOverlapSummary({
    required this.key,
    required this.count,
    required this.sample,
  });

  final String key;
  final int count;
  final List<String> sample;

  Map<String, dynamic> toJson() => {
        'key': key,
        'count': count,
        'sample': sample,
      };
}

class DeterministicDeckSourceEntry {
  const DeterministicDeckSourceEntry({
    required this.cardName,
    required this.sources,
  });

  final String cardName;
  final List<String> sources;

  Map<String, dynamic> toJson() => {
        'card_name': cardName,
        'sources': sources,
      };
}

String normalizeAuditName(String value) =>
    normalizeCommanderReferenceCardName(value);

Set<String> normalizeNameSet(Iterable<String> values) =>
    values.map(normalizeAuditName).where((value) => value.isNotEmpty).toSet();

Map<String, String> buildCanonicalNameMap(Iterable<String> values) {
  final map = <String, String>{};
  for (final value in values) {
    final trimmed = value.trim();
    final normalized = normalizeAuditName(trimmed);
    if (trimmed.isEmpty || normalized.isEmpty) continue;
    map.putIfAbsent(normalized, () => trimmed);
  }
  return map;
}

SourceOverlapSummary buildOverlapSummary({
  required String key,
  required Set<String> names,
  required Map<String, String> canonicalNames,
  int sampleLimit = 12,
}) {
  final sorted = names.toList()..sort();
  return SourceOverlapSummary(
    key: key,
    count: sorted.length,
    sample: sorted
        .take(sampleLimit)
        .map((name) => canonicalNames[name] ?? name)
        .toList(growable: false),
  );
}

List<SourceOverlapSummary> buildSourceOverlapMatrix({
  required NameSetMap sourceSets,
  required Map<String, String> canonicalNames,
  int sampleLimit = 10,
}) {
  final allNames = <String>{};
  for (final set in sourceSets.values) {
    allNames.addAll(set);
  }

  final buckets = <String, Set<String>>{};
  for (final name in allNames) {
    final sources = sourceSets.entries
        .where((entry) => entry.value.contains(name))
        .map((entry) => entry.key)
        .toList()
      ..sort();
    final key = sources.join(' + ');
    buckets.putIfAbsent(key, () => <String>{}).add(name);
  }

  final summaries = buckets.entries
      .map(
        (entry) => buildOverlapSummary(
          key: entry.key,
          names: entry.value,
          canonicalNames: canonicalNames,
          sampleLimit: sampleLimit,
        ),
      )
      .toList(growable: false)
    ..sort((a, b) => b.count.compareTo(a.count));
  return summaries;
}

List<DeterministicDeckSourceEntry> classifyDeterministicDeckSources({
  required Iterable<String> deckCardNames,
  required NameSetMap sourceSets,
  required Map<String, String> canonicalNames,
}) {
  final entries = <DeterministicDeckSourceEntry>[];
  for (final normalizedName in normalizeNameSet(deckCardNames)) {
    final sources = sourceSets.entries
        .where((entry) => entry.value.contains(normalizedName))
        .map((entry) => entry.key)
        .toList()
      ..sort();
    entries.add(
      DeterministicDeckSourceEntry(
        cardName: canonicalNames[normalizedName] ?? normalizedName,
        sources: sources,
      ),
    );
  }
  entries.sort((a, b) => a.cardName.compareTo(b.cardName));
  return entries;
}

Future<void> main(List<String> args) async {
  if (args.contains('--help') || args.contains('-h')) {
    _printUsage();
    return;
  }

  final commander = _readArg(args, '--commander=')?.trim().isNotEmpty == true
      ? _readArg(args, '--commander=')!.trim()
      : _defaultCommander;
  final artifactDir =
      Directory(_readArg(args, '--artifact-dir=') ?? _defaultArtifactDir);
  await artifactDir.create(recursive: true);

  final database = Database();
  await database.connect();
  final startedAt = DateTime.now().toUtc();

  try {
    final pool = database.connection;
    final profileRow = await _loadRawProfileRow(pool, commander);
    final usableProfile = await loadUsableCommanderReferenceProfile(
      pool: pool,
      commanderName: commander,
    );
    final statsLoad = await loadUsableCommanderReferenceCardStats(
      pool: pool,
      commanderName: commander,
    );
    final corpus = await loadCommanderReferenceDeckCorpusGuidance(
      pool: pool,
      commanderName: commander,
    );
    final usageHotCards = await loadUsageHotCards(
      pool: pool,
      commanderName: commander,
      limit: 50,
    );
    final activeLearnedDeck = await _loadActiveLearnedDeck(pool, commander);
    final learningSnapshot = await _loadLearningSnapshot(pool, commander);

    final profileExpectedCards = _expectedPackageCardNames(profileRow?.profile);
    final statsNames = statsLoad.stats.map((stat) => stat.cardName).toList();
    final corpusPackageNames = _corpusPackageCardNames(corpus);
    final usageNames = usageHotCards
        .map((row) => row['canonical_name']?.toString() ?? '')
        .where((value) => value.trim().isNotEmpty)
        .toList(growable: false);
    final learnedNames =
        activeLearnedDeck?.cards.map((card) => card.name).toList() ?? const [];
    final fallbackNames = isLoreholdCommanderReferenceCandidate(commander)
        ? loreholdDeterministicReferenceFallbackCards
        : const <String>[];

    final deterministicDeckResult = usableProfile == null
        ? null
        : buildDeterministicReferenceDeckResult(
            profile: usableProfile,
            referenceCardStats: statsLoad.stats,
            referenceDeckCorpusGuidance: corpus,
            activeLearnedDeck: activeLearnedDeck,
            promotedLearnedCardNames: learnedNames,
            usageHotCardNames: usageHotCardCanonicalNames(usageHotCards),
          );
    final deterministicDeck = deterministicDeckResult?.deck;
    final deterministicDeckCards = deterministicDeck == null
        ? const <String>[]
        : (deterministicDeck['cards'] as List)
            .whereType<Map>()
            .map((card) => card['name']?.toString() ?? '')
            .where((name) => name.trim().isNotEmpty)
            .toList(growable: false);
    final deterministicDeckMainQuantity =
        deterministicDeckResult?.mainDeckQuantity ?? 0;

    final canonicalNames = <String, String>{}
      ..addAll(buildCanonicalNameMap(profileExpectedCards))
      ..addAll(buildCanonicalNameMap(statsNames))
      ..addAll(buildCanonicalNameMap(corpusPackageNames))
      ..addAll(buildCanonicalNameMap(usageNames))
      ..addAll(buildCanonicalNameMap(learnedNames))
      ..addAll(buildCanonicalNameMap(fallbackNames))
      ..addAll(buildCanonicalNameMap(deterministicDeckCards));

    final sourceSets = <String, Set<String>>{
      'profile_expected_packages': normalizeNameSet(profileExpectedCards),
      'reference_card_stats': normalizeNameSet(statsNames),
      'reference_corpus_packages': normalizeNameSet(corpusPackageNames),
      'usage_hot_cards': normalizeNameSet(usageNames),
      'active_learned_deck': normalizeNameSet(learnedNames),
      'deterministic_fallback': normalizeNameSet(fallbackNames),
    };

    final overlapMatrix = buildSourceOverlapMatrix(
      sourceSets: sourceSets,
      canonicalNames: canonicalNames,
    );
    final deterministicOwnership = deterministicDeckResult == null
        ? classifyDeterministicDeckSources(
            deckCardNames: deterministicDeckCards,
            sourceSets: sourceSets,
            canonicalNames: canonicalNames,
          )
        : deterministicDeckResult.cardProvenance
            .map(
              (entry) => DeterministicDeckSourceEntry(
                cardName: entry.cardName,
                sources: entry.sources,
              ),
            )
            .toList(growable: false);

    final summary = {
      'status': 'PASS_WITH_RISKS',
      'mode': 'read_only_provenance_audit',
      'db_mutations': false,
      'started_at': startedAt.toIso8601String(),
      'finished_at': DateTime.now().toUtc().toIso8601String(),
      'commander_name': commander,
      'artifact_dir': artifactDir.path,
      'generator_truth': {
        'learned_deck_route_is_parallel_product_channel': true,
        'ai_generate_reads_learned_decks_directly': learnedNames.isNotEmpty,
        'backend_ownership': [
          'commander_reference_profiles',
          'commander_reference_card_stats',
          'commander_reference_deck_analysis',
          'commander_card_usage',
          if (learnedNames.isNotEmpty) 'commander_learned_decks',
          if (isLoreholdCommanderReferenceCandidate(commander))
            'loreholdDeterministicReferenceFallbackCards',
        ],
      },
      'profile': {
        'row_exists': profileRow != null,
        'row_source': profileRow?.source,
        'row_updated_at': profileRow?.updatedAt?.toIso8601String(),
        'row_confidence': profileRow?.profile['confidence'],
        'row_source_count': profileRow?.profile['source_count'],
        'usable': usableProfile != null,
        'usable_confidence': usableProfile?['confidence'],
        'usable_source_count': usableProfile?['source_count'],
        'usable_runtime_origin': usableProfile?['runtime_profile_origin'],
        'usable_runtime_reason': usableProfile?['runtime_profile_reason'],
      },
      'reference_card_stats': {
        'table_available': statsLoad.tableAvailable,
        'usable_count': statsLoad.stats.length,
        'unresolved_count': statsLoad.unresolvedCardNames.length,
        'package_counts': _packageCounts(statsLoad.stats),
        'role_counts': _roleCounts(statsLoad.stats),
        'top_sample': statsLoad.stats
            .take(16)
            .map(
              (stat) => {
                'card_name': stat.cardName,
                'package_key': stat.packageKey,
                'role': stat.role,
                'score': stat.score,
                'source': stat.source,
              },
            )
            .toList(growable: false),
      },
      'reference_corpus': {
        'available': corpus != null,
        'source': corpus?.source,
        'deck_count': corpus?.deckCount ?? 0,
        'accepted_deck_count': corpus?.acceptedDeckCount ?? 0,
        'package_counts': corpus?.packages.counts ?? const {},
      },
      'usage_hot_cards': {
        'count': usageHotCards.length,
        'total_usage_count': usageHotCards.fold<int>(
          0,
          (sum, row) => sum + ((row['usage_count'] as int?) ?? 0),
        ),
        'top_sample': usageHotCards.take(16).toList(growable: false),
      },
      'active_learned_deck': {
        'exists': activeLearnedDeck != null,
        if (activeLearnedDeck != null) ...{
          'deck_name': activeLearnedDeck.deckName,
          'source_system': activeLearnedDeck.sourceSystem,
          'source_ref': activeLearnedDeck.sourceRef,
          'score': activeLearnedDeck.score,
          'legal_status': activeLearnedDeck.legalStatus,
          'card_count': activeLearnedDeck.cardCount,
          'cards_sample': activeLearnedDeck.cards
              .take(20)
              .map((card) => card.toJson())
              .toList(growable: false),
        },
      },
      'learning_snapshot': learningSnapshot,
      'deterministic_fallback': {
        'enabled_for_commander':
            isLoreholdCommanderReferenceCandidate(commander),
        'count': fallbackNames.length,
        'sample': fallbackNames.take(20).toList(growable: false),
      },
      'source_overlap_matrix':
          overlapMatrix.map((entry) => entry.toJson()).toList(),
      'deterministic_deck': {
        'built': deterministicDeck != null,
        'commander': deterministicDeck?['commander'],
        'main_count': deterministicDeckMainQuantity,
        'distinct_card_count': deterministicDeckCards.length,
        'runtime_build_diagnostics':
            deterministicDeckResult?.toDiagnosticsJson(sampleLimit: 12),
        'source_mix_counts': _sourceMixCounts(deterministicOwnership),
        'cards': deterministicOwnership
            .map((entry) => entry.toJson())
            .toList(growable: false),
      },
      'gaps': _buildGaps(
        usableProfile: usableProfile,
        statsLoad: statsLoad,
        corpus: corpus,
        usageHotCards: usageHotCards,
        activeLearnedDeck: activeLearnedDeck,
        deterministicOwnership: deterministicOwnership,
      ),
      'safety': {
        'no_db_mutations': true,
        'no_secrets_recorded': true,
        'no_full_private_payloads': true,
      },
    };
    final profileSummary = summary['profile'] as Map<String, dynamic>;
    final statsSummary =
        summary['reference_card_stats'] as Map<String, dynamic>;
    final corpusSummary = summary['reference_corpus'] as Map<String, dynamic>;
    final usageSummary = summary['usage_hot_cards'] as Map<String, dynamic>;
    final learnedSummary =
        summary['active_learned_deck'] as Map<String, dynamic>;
    final deterministicSummary =
        summary['deterministic_deck'] as Map<String, dynamic>;

    final outputPath =
        '${artifactDir.path}/commander_generate_provenance_summary.json';
    await _writeJson(outputPath, summary);
    print(
      jsonEncode({
        'status': summary['status'],
        'commander_name': commander,
        'artifact': outputPath,
        'profile_usable': profileSummary['usable'],
        'stats_count': statsSummary['usable_count'],
        'corpus_accepted_deck_count': corpusSummary['accepted_deck_count'],
        'usage_hot_cards_count': usageSummary['count'],
        'active_learned_deck_exists': learnedSummary['exists'],
        'deterministic_main_count': deterministicSummary['main_count'],
        'deterministic_distinct_card_count':
            deterministicSummary['distinct_card_count'],
      }),
    );
  } finally {
    await database.close();
  }
}

Future<void> _writeJson(String path, Map<String, dynamic> payload) async {
  const encoder = JsonEncoder.withIndent('  ');
  await File(path).writeAsString('${encoder.convert(payload)}\n');
}

String? _readArg(List<String> args, String prefix) {
  for (final arg in args) {
    if (arg.startsWith(prefix)) return arg.substring(prefix.length);
  }
  return null;
}

void _printUsage() {
  print('''
Usage:
  dart run bin/commander_generate_provenance_audit.dart
  dart run bin/commander_generate_provenance_audit.dart --commander="Lorehold, the Historian"
  dart run bin/commander_generate_provenance_audit.dart --commander="Lorehold, the Historian" --artifact-dir=test/artifacts/...

Read-only provenance audit for /ai/generate ownership and deterministic source mix.
''');
}

class _RawProfileRow {
  const _RawProfileRow({
    required this.source,
    required this.updatedAt,
    required this.profile,
  });

  final String source;
  final DateTime? updatedAt;
  final Map<String, dynamic> profile;
}

Future<_RawProfileRow?> _loadRawProfileRow(Pool pool, String commander) async {
  final result = await pool.execute(
    Sql.named('''
      SELECT source, updated_at, profile_json
      FROM commander_reference_profiles
      WHERE LOWER(commander_name) = LOWER(@commander)
      LIMIT 1
    '''),
    parameters: {'commander': commander},
  );
  if (result.isEmpty) return null;
  final row = result.first;
  final rawProfile = row[2];
  final profile = rawProfile is Map<String, dynamic>
      ? Map<String, dynamic>.from(rawProfile)
      : rawProfile is Map
          ? rawProfile.cast<String, dynamic>()
          : jsonDecode(rawProfile.toString()) as Map<String, dynamic>;
  return _RawProfileRow(
    source: row[0]?.toString() ?? 'unknown',
    updatedAt: row[1] is DateTime ? row[1] as DateTime : null,
    profile: profile,
  );
}

Future<CommanderLearnedDeckInput?> _loadActiveLearnedDeck(
  Pool pool,
  String commander,
) async {
  final result = await pool.execute(
    Sql.named('''
      SELECT
        commander_name,
        deck_name,
        source_system,
        source_ref,
        source_url,
        archetype,
        card_list,
        card_count,
        score,
        wincon_primary,
        wincon_backup,
        legal_status,
        notes,
        metadata,
        is_active,
        promoted_at,
        updated_at
      FROM commander_learned_decks
      WHERE LOWER(commander_name) = LOWER(@commander)
        AND is_active = TRUE
      ORDER BY score DESC NULLS LAST, promoted_at DESC NULLS LAST, updated_at DESC
      LIMIT 10
    '''),
    parameters: {'commander': commander},
  );
  for (final row in result) {
    final candidate = CommanderLearnedDeckInput(
      commanderName: row[0]?.toString() ?? commander,
      deckName: row[1]?.toString() ?? commander,
      sourceSystem: row[2]?.toString() ?? 'unknown',
      sourceRef: row[3]?.toString() ?? 'unknown',
      sourceUrl: row[4]?.toString(),
      archetype: row[5]?.toString(),
      cardList: row[6]?.toString() ?? '',
      cardCount: int.tryParse(row[7]?.toString() ?? '') ?? 0,
      score: double.tryParse(row[8]?.toString() ?? ''),
      winconPrimary: row[9]?.toString(),
      winconBackup: row[10]?.toString(),
      legalStatus: row[11]?.toString(),
      notes: row[12]?.toString(),
      metadata: row[13] is Map<String, dynamic>
          ? Map<String, dynamic>.from(row[13] as Map<String, dynamic>)
          : row[13] is Map
              ? (row[13] as Map).cast<String, dynamic>()
              : const <String, dynamic>{},
      isActive: row[14] == true,
      promotedAt: row[15] is DateTime ? row[15] as DateTime : null,
      updatedAt: row[16] is DateTime ? row[16] as DateTime : null,
    );
    if (isCompleteCommanderLearnedDeckInput(candidate)) {
      return candidate;
    }
  }
  return null;
}

Future<Map<String, dynamic>?> _loadLearningSnapshot(
  Pool pool,
  String commander,
) async {
  try {
    final result = await pool.execute(
      Sql.named('''
        SELECT
          active_learned_deck_count,
          best_learned_score,
          usage_card_rows,
          total_usage_count,
          synergy_rows,
          best_synergy_score,
          source_coverage
        FROM commander_learning_snapshot
        WHERE commander_name_normalized = @commander
        LIMIT 1
      '''),
      parameters: {'commander': normalizeCommanderReferenceName(commander)},
    );
    if (result.isEmpty) return null;
    final row = result.first;
    return {
      'active_learned_deck_count': row[0],
      'best_learned_score': row[1],
      'usage_card_rows': row[2],
      'total_usage_count': row[3],
      'synergy_rows': row[4],
      'best_synergy_score': row[5],
      'source_coverage': row[6] is Map<String, dynamic>
          ? Map<String, dynamic>.from(row[6] as Map<String, dynamic>)
          : row[6] is Map
              ? (row[6] as Map).cast<String, dynamic>()
              : null,
    };
  } catch (_) {
    return null;
  }
}

List<String> _expectedPackageCardNames(Map<String, dynamic>? profile) {
  if (profile == null) return const [];
  final raw = profile['expected_packages'];
  if (raw is! Map) return const [];
  final names = <String>[];
  for (final entry in raw.entries) {
    final value = entry.value;
    if (value is! Iterable) continue;
    for (final rawCard in value) {
      final name = rawCard.toString().trim();
      if (name.isNotEmpty) names.add(name);
    }
  }
  return names;
}

List<String> _corpusPackageCardNames(
  CommanderReferenceDeckCorpusGuidance? corpus,
) {
  if (corpus == null) return const [];
  final names = <String>[];
  for (final package in [
    corpus.packages.corePackage,
    corpus.packages.themePackage,
    corpus.packages.supportPackage,
    corpus.packages.optionalContextual,
  ]) {
    for (final card in package) {
      final name = card['card_name']?.toString().trim() ?? '';
      if (name.isNotEmpty) names.add(name);
    }
  }
  return names;
}

Map<String, int> _packageCounts(List<CommanderReferenceCardStat> stats) {
  final counts = <String, int>{};
  for (final stat in stats) {
    counts[stat.packageKey] = (counts[stat.packageKey] ?? 0) + 1;
  }
  return Map.fromEntries(
    counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
  );
}

Map<String, int> _roleCounts(List<CommanderReferenceCardStat> stats) {
  final counts = <String, int>{};
  for (final stat in stats) {
    counts[stat.role] = (counts[stat.role] ?? 0) + 1;
  }
  return Map.fromEntries(
    counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
  );
}

Map<String, int> _sourceMixCounts(List<DeterministicDeckSourceEntry> entries) {
  final counts = <String, int>{};
  for (final entry in entries) {
    final key = entry.sources.join(' + ');
    counts[key] = (counts[key] ?? 0) + 1;
  }
  return Map.fromEntries(
    counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
  );
}

List<Map<String, dynamic>> _buildGaps({
  required Map<String, dynamic>? usableProfile,
  required CommanderReferenceCardStatsLoadResult statsLoad,
  required CommanderReferenceDeckCorpusGuidance? corpus,
  required List<Map<String, dynamic>> usageHotCards,
  required CommanderLearnedDeckInput? activeLearnedDeck,
  required List<DeterministicDeckSourceEntry> deterministicOwnership,
}) {
  final gaps = <Map<String, dynamic>>[];
  if (usableProfile == null) {
    gaps.add({
      'priority': 'P1',
      'code': 'profile_not_usable',
      'message':
          'O row de profile existe mas nao habilita o caminho forte do generator quando confidence/source_count nao fecham.',
    });
  }
  if (statsLoad.stats.isEmpty) {
    gaps.add({
      'priority': 'P1',
      'code': 'reference_stats_empty',
      'message':
          'Sem card stats usaveis o generator perde a camada mais explicavel por carta.',
    });
  }
  if (corpus == null || corpus.acceptedDeckCount <= 0) {
    gaps.add({
      'priority': 'P1',
      'code': 'reference_corpus_not_usable',
      'message':
          'Sem corpus aceito o builder deterministico depende mais de profile/fallback historico.',
    });
  }
  if (usageHotCards.isEmpty) {
    gaps.add({
      'priority': 'P2',
      'code': 'usage_signal_empty',
      'message':
          'Sem usage signal o generator nao aprende preferencia real de jogadores para o comandante.',
    });
  }
  if (activeLearnedDeck != null) {
    final normalizedCommander =
        normalizeAuditName(activeLearnedDeck.commanderName);
    final learnedOnlyAbsent = normalizeNameSet(
      activeLearnedDeck.cards.map((card) => card.name),
    ).where(
      (name) =>
          name != normalizedCommander &&
          deterministicOwnership.every(
            (entry) => normalizeAuditName(entry.cardName) != name,
          ),
    );
    if (learnedOnlyAbsent.isNotEmpty) {
      gaps.add({
        'priority': 'P1',
        'code': 'learned_deck_parallel_not_ranked_in_generate',
        'message':
            'Existe deck aprendido ativo, mas ele continua em canal paralelo e nao influencia diretamente o ranking interno de /ai/generate.',
        'count': learnedOnlyAbsent.length,
      });
    }
  }
  return gaps;
}
