import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:postgres/postgres.dart';

import '../color_identity.dart';
import '../import_card_lookup_service.dart';
import 'commander_reference_profile_support.dart';

const commanderReferenceCardStatsTable = 'commander_reference_card_stats';

class CommanderReferenceCardStat {
  const CommanderReferenceCardStat({
    required this.commanderName,
    required this.commanderNameNormalized,
    required this.cardName,
    required this.cardNameNormalized,
    required this.packageKey,
    required this.role,
    required this.score,
    required this.confidence,
    required this.confidenceRank,
    required this.source,
    required this.evidenceCount,
    required this.unresolved,
    this.cardId,
    this.updatedAt,
  });

  final String commanderName;
  final String commanderNameNormalized;
  final String cardName;
  final String cardNameNormalized;
  final String? cardId;
  final String packageKey;
  final String role;
  final double score;
  final String confidence;
  final int confidenceRank;
  final String source;
  final int evidenceCount;
  final bool unresolved;
  final DateTime? updatedAt;

  Map<String, dynamic> toJson() => {
    'commander_name': commanderName,
    'card_name': cardName,
    if (cardId != null) 'card_id': cardId,
    'package_key': packageKey,
    'role': role,
    'score': score,
    'confidence': confidence,
    'source': source,
    'evidence_count': evidenceCount,
    'unresolved': unresolved,
    if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
  };
}

class CommanderReferenceCardStatsResolution {
  const CommanderReferenceCardStatsResolution({
    required this.stats,
    required this.unresolvedCardNames,
    required this.offColorCardNames,
  });

  final List<CommanderReferenceCardStat> stats;
  final List<String> unresolvedCardNames;
  final List<String> offColorCardNames;

  int get resolvedCount => stats.where((stat) => !stat.unresolved).length;

  Map<String, dynamic> toJson() => {
    'resolved_count': resolvedCount,
    'unresolved_count': unresolvedCardNames.length,
    'unresolved_reference_cards': unresolvedCardNames,
    'off_color_count': offColorCardNames.length,
    'off_color_reference_cards': offColorCardNames,
    'package_coverage': packageCoverage,
  };

  Map<String, Map<String, int>> get packageCoverage {
    final coverage = <String, Map<String, int>>{};
    for (final stat in stats) {
      final entry = coverage.putIfAbsent(
        stat.packageKey,
        () => {'resolved': 0, 'unresolved': 0},
      );
      entry[stat.unresolved ? 'unresolved' : 'resolved'] =
          (entry[stat.unresolved ? 'unresolved' : 'resolved'] ?? 0) + 1;
    }
    return coverage;
  }
}

class CommanderReferenceCommanderCardResolution {
  const CommanderReferenceCommanderCardResolution({
    required this.commanderName,
    required this.resolved,
    this.cardId,
    this.cardName,
  });

  final String commanderName;
  final bool resolved;
  final String? cardId;
  final String? cardName;

  Map<String, dynamic> toJson() => {
    'commander_name': commanderName,
    'resolved': resolved,
    if (cardId != null) 'card_id': cardId,
    if (cardName != null) 'card_name': cardName,
  };
}

class CommanderReferenceCardStatsLoadResult {
  const CommanderReferenceCardStatsLoadResult({
    required this.tableAvailable,
    required this.stats,
    required this.unresolvedCardNames,
  });

  final bool tableAvailable;
  final List<CommanderReferenceCardStat> stats;
  final List<String> unresolvedCardNames;
}

class CommanderReferenceArchetypeStatsLoadResult {
  const CommanderReferenceArchetypeStatsLoadResult({
    required this.tableAvailable,
    required this.stats,
    required this.sourceCommanderNames,
    required this.commanderColorIdentity,
  });

  final bool tableAvailable;
  final List<CommanderReferenceCardStat> stats;
  final List<String> sourceCommanderNames;
  final List<String> commanderColorIdentity;
}

class ReferenceGeneratedDeckEvaluation {
  const ReferenceGeneratedDeckEvaluation({
    required this.classification,
    required this.counts,
    required this.roleCoverage,
    required this.cards,
  });

  final String classification;
  final Map<String, int> counts;
  final Map<String, int> roleCoverage;
  final List<Map<String, dynamic>> cards;

  Map<String, dynamic> toJson() => {
    'classification': classification,
    'counts': counts,
    'role_coverage': roleCoverage,
    'cards': cards,
  };
}

String normalizeCommanderReferenceCardName(String value) =>
    normalizeCommanderReferenceName(value);

List<String> commanderReferenceCardLookupAliases(String cardName) {
  final aliases = <String>{normalizeCommanderReferenceCardName(cardName)};
  final parts = cardName.split(RegExp(r'\s*//\s*'));
  if (parts.length > 1) {
    aliases.add(normalizeCommanderReferenceCardName(parts.first));
  }
  return aliases.where((alias) => alias.isNotEmpty).toList(growable: false);
}

CommanderReferenceCommanderCardResolution
findResolvedCommanderReferenceCommanderCard({
  required String commanderName,
  required Map<String, Map<String, dynamic>> resolvedCardsByName,
}) {
  final commander = commanderName.trim();
  if (commander.isEmpty) {
    return const CommanderReferenceCommanderCardResolution(
      commanderName: '',
      resolved: false,
    );
  }

  final target = normalizeCommanderReferenceCardName(commander);
  for (final entry in resolvedCardsByName.entries) {
    final key = normalizeCommanderReferenceCardName(entry.key);
    final resolvedName = entry.value['name']?.toString().trim() ?? '';
    final resolvedNameNormalized = normalizeCommanderReferenceCardName(
      resolvedName,
    );
    if (key != target && resolvedNameNormalized != target) continue;

    final cardId = entry.value['id']?.toString().trim();
    if (cardId == null || cardId.isEmpty) {
      return CommanderReferenceCommanderCardResolution(
        commanderName: commander,
        resolved: false,
        cardName: resolvedName.isEmpty ? null : resolvedName,
      );
    }

    return CommanderReferenceCommanderCardResolution(
      commanderName: commander,
      resolved: true,
      cardId: cardId,
      cardName: resolvedName.isEmpty ? commander : resolvedName,
    );
  }

  return CommanderReferenceCommanderCardResolution(
    commanderName: commander,
    resolved: false,
  );
}

Future<CommanderReferenceCommanderCardResolution>
resolveCommanderReferenceCommanderCard(
  Pool pool,
  Map<String, dynamic> profile,
) async {
  final commanderName =
      (profile['commander'] ?? profile['commander_name'] ?? '')
          .toString()
          .trim();
  if (commanderName.isEmpty) {
    return const CommanderReferenceCommanderCardResolution(
      commanderName: '',
      resolved: false,
    );
  }

  final resolved = await resolveImportCardNames(pool, [
    {'name': commanderName},
  ], preferredFormat: 'commander');

  return findResolvedCommanderReferenceCommanderCard(
    commanderName: commanderName,
    resolvedCardsByName: resolved,
  );
}

List<CommanderReferenceCardStat> buildLoreholdReferenceCardStatsFromProfile({
  required Map<String, dynamic> profile,
  required Map<String, Map<String, dynamic>> resolvedCardsByName,
}) {
  return buildCommanderReferenceCardStatsFromProfile(
    profile: profile,
    resolvedCardsByName: resolvedCardsByName,
  );
}

List<CommanderReferenceCardStat> buildCommanderReferenceCardStatsFromProfile({
  required Map<String, dynamic> profile,
  required Map<String, Map<String, dynamic>> resolvedCardsByName,
}) {
  final expectedPackages = profile['expected_packages'];
  if (expectedPackages is! Map) return const [];

  final commanderName =
      (profile['commander'] ?? profile['commander_name'] ?? '')
          .toString()
          .trim();
  if (commanderName.isEmpty) return const [];

  final source =
      profile['source']?.toString().trim().isNotEmpty == true
          ? profile['source'].toString().trim()
          : loreholdReferenceProfileSource;
  final evidenceCount = _sourceCount(profile).clamp(1, 999);
  final stats = <CommanderReferenceCardStat>[];

  final entries =
      expectedPackages.entries.toList()
        ..sort((a, b) => a.key.toString().compareTo(b.key.toString()));
  for (final entry in entries) {
    final packageKey = entry.key.toString().trim();
    final role = _roleForPackage(packageKey);
    final confidence = _confidenceForPackage(packageKey);
    final confidenceRank = commanderReferenceConfidenceRank(confidence);
    final score = _scoreForPackage(packageKey);
    final cards = entry.value is List ? entry.value as List : const [];

    for (final rawCard in cards) {
      final cardName = rawCard.toString().trim();
      if (cardName.isEmpty) continue;
      final normalized = normalizeCommanderReferenceCardName(cardName);
      final resolved = _findResolvedReferenceCard(
        cardName: cardName,
        resolvedCardsByName: resolvedCardsByName,
      );

      stats.add(
        CommanderReferenceCardStat(
          commanderName: commanderName,
          commanderNameNormalized: normalizeCommanderReferenceName(
            commanderName,
          ),
          cardName: cardName,
          cardNameNormalized: normalized,
          cardId: resolved?['id']?.toString(),
          packageKey: packageKey,
          role: role,
          score: score,
          confidence: confidence,
          confidenceRank: confidenceRank,
          source: source,
          evidenceCount: evidenceCount,
          unresolved: resolved == null,
        ),
      );
    }
  }

  return stats;
}

Future<CommanderReferenceCardStatsResolution> resolveLoreholdReferenceCardStats(
  Pool pool,
  Map<String, dynamic> profile,
) async {
  return resolveCommanderReferenceCardStats(pool, profile);
}

Future<CommanderReferenceCardStatsResolution>
resolveCommanderReferenceCardStats(
  Pool pool,
  Map<String, dynamic> profile,
) async {
  final names = <String>{};
  final expectedPackages = profile['expected_packages'];
  if (expectedPackages is Map) {
    for (final value in expectedPackages.values) {
      if (value is! List) continue;
      for (final rawCard in value) {
        final cardName = rawCard.toString().trim();
        if (cardName.isEmpty) continue;
        names.add(cardName);
        for (final alias in commanderReferenceCardLookupAliases(cardName)) {
          names.add(alias);
        }
      }
    }
  }

  final resolved =
      names.isEmpty
          ? <String, Map<String, dynamic>>{}
          : await resolveImportCardNames(pool, [
            for (final name in names) {'name': name},
          ], preferredFormat: 'commander');

  final stats = buildCommanderReferenceCardStatsFromProfile(
    profile: profile,
    resolvedCardsByName: resolved.map(
      (key, value) => MapEntry(normalizeCommanderReferenceCardName(key), value),
    ),
  );
  final unresolved =
      stats
          .where((stat) => stat.unresolved)
          .map((stat) => stat.cardName)
          .toSet()
          .toList()
        ..sort();
  final offColor = findOffColorCommanderReferenceCards(
    profile: profile,
    stats: stats,
    resolvedCardsByName: resolved.map(
      (key, value) => MapEntry(normalizeCommanderReferenceCardName(key), value),
    ),
  );

  return CommanderReferenceCardStatsResolution(
    stats: stats,
    unresolvedCardNames: unresolved,
    offColorCardNames: offColor,
  );
}

List<String> findOffColorCommanderReferenceCards({
  required Map<String, dynamic> profile,
  required List<CommanderReferenceCardStat> stats,
  required Map<String, Map<String, dynamic>> resolvedCardsByName,
}) {
  final commanderIdentity = _profileColorIdentity(profile);
  final offColor = <String>{};
  for (final stat in stats) {
    if (stat.unresolved) continue;
    final resolved = _findResolvedReferenceCard(
      cardName: stat.cardName,
      resolvedCardsByName: resolvedCardsByName,
    );
    final identity = resolveCardColorIdentity(
      colorIdentity:
          resolved?['color_identity'] == null
              ? null
              : _metadataStringIterable(resolved?['color_identity']),
      colors: _metadataStringIterable(resolved?['colors']),
      oracleText: resolved?['oracle_text']?.toString(),
      manaCost: resolved?['mana_cost']?.toString(),
    );
    if (!isWithinCommanderIdentity(
      cardIdentity: identity,
      commanderIdentity: commanderIdentity,
    )) {
      offColor.add(stat.cardName);
    }
  }
  return offColor.toList()..sort();
}

Future<void> ensureCommanderReferenceCardStatsTable(Pool pool) async {
  await pool.execute('''
    CREATE TABLE IF NOT EXISTS commander_reference_card_stats (
      commander_name TEXT NOT NULL,
      commander_name_normalized TEXT NOT NULL,
      card_name TEXT NOT NULL,
      card_name_normalized TEXT NOT NULL,
      card_id UUID REFERENCES cards(id) ON DELETE SET NULL,
      package_key TEXT NOT NULL,
      role TEXT NOT NULL,
      score NUMERIC NOT NULL,
      confidence TEXT NOT NULL,
      confidence_rank SMALLINT NOT NULL,
      source TEXT NOT NULL,
      evidence_count INTEGER NOT NULL DEFAULT 1,
      unresolved BOOLEAN NOT NULL DEFAULT FALSE,
      updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      PRIMARY KEY (
        commander_name_normalized,
        card_name_normalized,
        package_key
      )
    )
  ''');
  await pool.execute('''
    CREATE INDEX IF NOT EXISTS idx_commander_reference_card_stats_hot
    ON commander_reference_card_stats (
      commander_name_normalized,
      confidence_rank DESC,
      score DESC
    )
    WHERE unresolved = FALSE
  ''');
  await pool.execute('''
    CREATE INDEX IF NOT EXISTS idx_commander_reference_card_stats_unresolved
    ON commander_reference_card_stats (
      commander_name_normalized,
      unresolved,
      card_name_normalized
    )
  ''');
}

Future<void> upsertCommanderReferenceCardStats(
  Pool pool,
  List<CommanderReferenceCardStat> stats,
) async {
  for (final stat in stats) {
    await pool.execute(
      Sql.named('''
        INSERT INTO commander_reference_card_stats (
          commander_name,
          commander_name_normalized,
          card_name,
          card_name_normalized,
          card_id,
          package_key,
          role,
          score,
          confidence,
          confidence_rank,
          source,
          evidence_count,
          unresolved,
          updated_at
        ) VALUES (
          @commander_name,
          @commander_name_normalized,
          @card_name,
          @card_name_normalized,
          CAST(@card_id AS uuid),
          @package_key,
          @role,
          @score,
          @confidence,
          @confidence_rank,
          @source,
          @evidence_count,
          @unresolved,
          NOW()
        )
        ON CONFLICT (
          commander_name_normalized,
          card_name_normalized,
          package_key
        )
        DO UPDATE SET
          commander_name = EXCLUDED.commander_name,
          card_name = EXCLUDED.card_name,
          card_id = EXCLUDED.card_id,
          role = EXCLUDED.role,
          score = EXCLUDED.score,
          confidence = EXCLUDED.confidence,
          confidence_rank = EXCLUDED.confidence_rank,
          source = EXCLUDED.source,
          evidence_count = EXCLUDED.evidence_count,
          unresolved = EXCLUDED.unresolved,
          updated_at = NOW()
      '''),
      parameters: {
        'commander_name': stat.commanderName,
        'commander_name_normalized': stat.commanderNameNormalized,
        'card_name': stat.cardName,
        'card_name_normalized': stat.cardNameNormalized,
        'card_id': stat.cardId,
        'package_key': stat.packageKey,
        'role': stat.role,
        'score': stat.score,
        'confidence': stat.confidence,
        'confidence_rank': stat.confidenceRank,
        'source': stat.source,
        'evidence_count': stat.evidenceCount,
        'unresolved': stat.unresolved,
      },
    );
  }
}

Future<CommanderReferenceCardStatsLoadResult>
loadUsableCommanderReferenceCardStats({
  required Pool pool,
  required String? commanderName,
  String minimumConfidence = 'medium',
}) async {
  final commander = commanderName?.trim();
  if (commander == null || commander.isEmpty) {
    return const CommanderReferenceCardStatsLoadResult(
      tableAvailable: false,
      stats: [],
      unresolvedCardNames: [],
    );
  }

  try {
    final minRank = commanderReferenceConfidenceRank(minimumConfidence);
    final commanderNormalized = normalizeCommanderReferenceName(commander);
    final result = await pool.execute(
      Sql.named('''
        SELECT
          commander_name,
          commander_name_normalized,
          card_name,
          card_name_normalized,
          card_id::text,
          package_key,
          role,
          score,
          confidence,
          confidence_rank,
          source,
          evidence_count,
          unresolved,
          updated_at
        FROM commander_reference_card_stats
        WHERE commander_name_normalized = @commander
          AND confidence_rank >= @minimum_rank
        ORDER BY unresolved ASC, score DESC, package_key ASC, card_name ASC
      '''),
      parameters: {'commander': commanderNormalized, 'minimum_rank': minRank},
    );

    final allStats = result
        .map((row) => _cardStatFromRow(row.toColumnMap()))
        .toList(growable: false);
    final usableStats = allStats
        .where((stat) => !stat.unresolved)
        .toList(growable: false);
    final unresolved =
        allStats
            .where((stat) => stat.unresolved)
            .map((stat) => stat.cardName)
            .toSet()
            .toList()
          ..sort();

    return CommanderReferenceCardStatsLoadResult(
      tableAvailable: true,
      stats: usableStats,
      unresolvedCardNames: unresolved,
    );
  } catch (error) {
    if (_isUndefinedTableError(error)) {
      return const CommanderReferenceCardStatsLoadResult(
        tableAvailable: false,
        stats: [],
        unresolvedCardNames: [],
      );
    }
    rethrow;
  }
}

Future<CommanderReferenceArchetypeStatsLoadResult>
loadCompatibleCommanderReferenceArchetypeStats({
  required Pool pool,
  required String? commanderName,
  required String prompt,
  String minimumConfidence = 'medium',
  int limit = 48,
}) async {
  final commander = commanderName?.trim();
  if (commander == null || commander.isEmpty) {
    return const CommanderReferenceArchetypeStatsLoadResult(
      tableAvailable: false,
      stats: [],
      sourceCommanderNames: [],
      commanderColorIdentity: [],
    );
  }

  final commanderIdentity = await _resolveCommanderReferenceTargetIdentity(
    pool: pool,
    commanderName: commander,
  );
  if (commanderIdentity == null) {
    return const CommanderReferenceArchetypeStatsLoadResult(
      tableAvailable: true,
      stats: [],
      sourceCommanderNames: [],
      commanderColorIdentity: [],
    );
  }

  try {
    final minRank = commanderReferenceConfidenceRank(minimumConfidence);
    final result = await pool.execute(
      Sql.named('''
        SELECT
          s.commander_name,
          s.commander_name_normalized,
          s.card_name,
          s.card_name_normalized,
          s.card_id::text,
          s.package_key,
          s.role,
          s.score,
          s.confidence,
          s.confidence_rank,
          s.source,
          s.evidence_count,
          s.unresolved,
          s.updated_at,
          p.profile_json
        FROM commander_reference_card_stats s
        JOIN commander_reference_profiles p
          ON p.commander_name = s.commander_name
        WHERE s.unresolved = FALSE
          AND s.confidence_rank >= @minimum_rank
        ORDER BY s.confidence_rank DESC, s.score DESC, s.package_key ASC
        LIMIT 600
      '''),
      parameters: {'minimum_rank': minRank},
    );

    final promptTokens = _referenceArchetypePromptTokens(prompt);
    final sourceCommanders = <String>{};
    final selected = <CommanderReferenceCardStat>[];
    final seen = <String>{};

    for (final row in result) {
      final map = row.toColumnMap();
      final sourceProfile = _decodeJsonMap(map['profile_json']);
      if (sourceProfile == null ||
          !isReferenceProfileConfidenceUsable(sourceProfile['confidence'])) {
        continue;
      }
      final sourceIdentity = _profileColorIdentity(sourceProfile);
      if (!isWithinCommanderIdentity(
        cardIdentity: sourceIdentity,
        commanderIdentity: commanderIdentity,
      )) {
        continue;
      }

      final sourceStat = _cardStatFromRow(map);
      if (!_referenceArchetypeMatchesPrompt(
        stat: sourceStat,
        profile: sourceProfile,
        promptTokens: promptTokens,
      )) {
        continue;
      }
      final key = '${sourceStat.cardNameNormalized}:${sourceStat.packageKey}';
      if (!seen.add(key)) continue;

      final sourceCommander = sourceStat.commanderName;
      sourceCommanders.add(sourceCommander);
      selected.add(
        CommanderReferenceCardStat(
          commanderName: commander,
          commanderNameNormalized: normalizeCommanderReferenceName(commander),
          cardName: sourceStat.cardName,
          cardNameNormalized: sourceStat.cardNameNormalized,
          cardId: sourceStat.cardId,
          packageKey: sourceStat.packageKey,
          role: sourceStat.role,
          score: (sourceStat.score * 0.72).clamp(1, 100).toDouble(),
          confidence: _downgradeArchetypeConfidence(sourceStat.confidence),
          confidenceRank: commanderReferenceConfidenceRank(
            _downgradeArchetypeConfidence(sourceStat.confidence),
          ),
          source: 'archetype_reference_reuse_v1:$sourceCommander',
          evidenceCount: sourceStat.evidenceCount,
          unresolved: false,
          updatedAt: sourceStat.updatedAt,
        ),
      );
      if (selected.length >= limit) break;
    }

    return CommanderReferenceArchetypeStatsLoadResult(
      tableAvailable: true,
      stats: selected,
      sourceCommanderNames: sourceCommanders.toList()..sort(),
      commanderColorIdentity: commanderIdentity.toList()..sort(),
    );
  } catch (error) {
    if (_isUndefinedTableError(error)) {
      return CommanderReferenceArchetypeStatsLoadResult(
        tableAvailable: false,
        stats: const [],
        sourceCommanderNames: const [],
        commanderColorIdentity: commanderIdentity.toList()..sort(),
      );
    }
    rethrow;
  }
}

String? commanderReferenceCardStatsCacheVersion(
  List<CommanderReferenceCardStat> stats,
) {
  final usable =
      stats.where((stat) => !stat.unresolved).toList()..sort((a, b) {
        final packageCompare = a.packageKey.compareTo(b.packageKey);
        if (packageCompare != 0) return packageCompare;
        return a.cardNameNormalized.compareTo(b.cardNameNormalized);
      });
  if (usable.isEmpty) return null;

  final material = jsonEncode([
    for (final stat in usable)
      {
        'card': stat.cardNameNormalized,
        'card_id': stat.cardId,
        'package': stat.packageKey,
        'role': stat.role,
        'score': stat.score,
        'confidence': stat.confidence,
        'source': stat.source,
        'evidence_count': stat.evidenceCount,
      },
  ]);
  return 'reference_card_stats_v1:${sha256.convert(utf8.encode(material)).toString().substring(0, 12)}';
}

String buildCommanderReferenceCardStatsPrompt(
  List<CommanderReferenceCardStat> stats, {
  bool compact = false,
  Set<String> priorityCardNames = const {},
}) {
  final priorityNames =
      priorityCardNames
          .map(normalizeCommanderReferenceCardName)
          .where((name) => name.isNotEmpty)
          .toSet();
  final usable =
      stats.where((stat) => !stat.unresolved).toList()..sort((a, b) {
        final packageCompare = a.packageKey.compareTo(b.packageKey);
        if (packageCompare != 0) return packageCompare;
        final aPriority = priorityNames.contains(a.cardNameNormalized) ? 0 : 1;
        final bPriority = priorityNames.contains(b.cardNameNormalized) ? 0 : 1;
        final priorityCompare = aPriority.compareTo(bPriority);
        if (priorityCompare != 0) return priorityCompare;
        final scoreCompare = b.score.compareTo(a.score);
        if (scoreCompare != 0) return scoreCompare;
        return a.cardName.compareTo(b.cardName);
      });
  if (usable.isEmpty) return '';

  final byPackage = <String, List<CommanderReferenceCardStat>>{};
  for (final stat in usable) {
    byPackage.putIfAbsent(stat.packageKey, () => []).add(stat);
  }

  final maxCardsPerPackage = compact ? 6 : 12;
  final packageLines = byPackage.entries
      .map((entry) {
        final cards = entry.value
            .take(maxCardsPerPackage)
            .map(
              (stat) =>
                  '${stat.cardName} [${stat.role}, score ${stat.score.toStringAsFixed(0)}]',
            )
            .join(', ');
        return '- ${entry.key}: $cards';
      })
      .join('\n');

  final commanderName = usable.first.commanderName;
  final modeLine =
      compact
          ? 'Compact mode: package lists are capped because corpus core_package is strong; corpus core cards remain the primary signal.'
          : 'Full mode: package lists provide expanded candidate guidance.';
  return '''
Reference card stats v1 active for $commanderName:
$packageLines
$modeLine
Use these normalized card stats as on-theme candidate pool and structured guidance when legal, bracket-appropriate and functional. Do not force every card; validation and deck balance remain mandatory.
''';
}

String buildCommanderReferenceArchetypeStatsPrompt({
  required String commanderName,
  required List<CommanderReferenceCardStat> stats,
  required List<String> sourceCommanderNames,
}) {
  final usable =
      stats.where((stat) => !stat.unresolved).toList()..sort((a, b) {
        final packageCompare = a.packageKey.compareTo(b.packageKey);
        if (packageCompare != 0) return packageCompare;
        final scoreCompare = b.score.compareTo(a.score);
        if (scoreCompare != 0) return scoreCompare;
        return a.cardName.compareTo(b.cardName);
      });
  if (usable.isEmpty) return '';

  final byPackage = <String, List<CommanderReferenceCardStat>>{};
  for (final stat in usable) {
    byPackage.putIfAbsent(stat.packageKey, () => []).add(stat);
  }

  final packageLines = byPackage.entries
      .map((entry) {
        final cards = entry.value
            .take(10)
            .map((stat) => '${stat.cardName} [${stat.role}]')
            .join(', ');
        return '- ${entry.key}: $cards';
      })
      .join('\n');
  final sources = sourceCommanderNames.take(5).join(', ');

  return '''
Archetype reference package reuse active for $commanderName:
- Derived from approved commander profiles: $sources.
- Confidence is lower than an exact commander profile; use these as similar-archetype candidate packages, not as a decklist to copy.
$packageLines
Only use cards that are legal, color-identity compliant, bracket-appropriate and coherent with this commander's own text. Prefer exact commander profile data if available.
''';
}

Map<String, dynamic> buildCommanderReferenceCardStatsDiagnostics({
  required List<CommanderReferenceCardStat> stats,
  required List<String> unresolvedCardNames,
}) {
  final packageKeys =
      stats.map((stat) => stat.packageKey).toSet().toList()..sort();
  return {
    'reference_card_stats_used': stats.isNotEmpty,
    'on_theme_candidate_count': stats.length,
    'unresolved_reference_cards': unresolvedCardNames,
    'package_keys': packageKeys,
  };
}

Map<String, dynamic> buildCommanderReferenceArchetypeStatsDiagnostics({
  required List<CommanderReferenceCardStat> stats,
  required List<String> sourceCommanderNames,
  required List<String> commanderColorIdentity,
}) {
  final packageKeys =
      stats.map((stat) => stat.packageKey).toSet().toList()..sort();
  return {
    'reference_profile_used': false,
    'reference_card_stats_used': false,
    'archetype_reference_used': stats.isNotEmpty,
    'archetype_candidate_count': stats.length,
    'archetype_package_keys': packageKeys,
    'archetype_source_commanders': sourceCommanderNames,
    'archetype_commander_color_identity': commanderColorIdentity,
    'archetype_confidence': stats.isEmpty ? 'not_proven' : 'medium_low',
  };
}

Future<Map<String, Map<String, dynamic>>> loadReferenceEvaluationCardMetadata({
  required Pool pool,
  required Iterable<String> cardNames,
}) async {
  final names =
      cardNames
          .map((name) => name.trim())
          .where((name) => name.isNotEmpty)
          .toSet();
  if (names.isEmpty) return const {};
  final resolved = await resolveImportCardNames(pool, [
    for (final name in names) {'name': name},
  ], preferredFormat: 'commander');
  return resolved.map(
    (key, value) => MapEntry(normalizeCommanderReferenceCardName(key), value),
  );
}

ReferenceGeneratedDeckEvaluation evaluateGeneratedDeckAgainstReferenceStats({
  required Map<String, dynamic> generatedDeck,
  required Map<String, dynamic>? profile,
  required List<CommanderReferenceCardStat> stats,
  required Map<String, Map<String, dynamic>> cardMetadataByName,
}) {
  final commanderIdentity = _profileColorIdentity(profile);
  final statsByName = {
    for (final stat in stats)
      if (!stat.unresolved) stat.cardNameNormalized: stat,
  };
  final avoidNames = _avoidPatternCardNames(profile);
  final counts = <String, int>{
    'on_theme': 0,
    'generic': 0,
    'questionable': 0,
    'off_theme': 0,
  };
  final roleCoverage = <String, int>{};
  final classifiedCards = <Map<String, dynamic>>[];

  final cards =
      generatedDeck['cards'] is List
          ? (generatedDeck['cards'] as List)
          : const <dynamic>[];

  for (final rawCard in cards) {
    if (rawCard is! Map) continue;
    final name = rawCard['name']?.toString().trim() ?? '';
    if (name.isEmpty) continue;
    final quantityRaw = rawCard['quantity'];
    final quantity =
        quantityRaw is int
            ? quantityRaw
            : int.tryParse(quantityRaw?.toString() ?? '') ?? 1;
    final normalized = normalizeCommanderReferenceCardName(name);
    final stat = statsByName[normalized];
    final metadata = cardMetadataByName[normalized];
    final classification = _classifyReferenceGeneratedCard(
      name: name,
      normalizedName: normalized,
      stat: stat,
      metadata: metadata,
      avoidNames: avoidNames,
      commanderIdentity: commanderIdentity,
    );
    counts[classification] = (counts[classification] ?? 0) + quantity;
    final role = stat?.role ?? _genericRoleForCard(name, metadata);
    if (role != null) {
      roleCoverage[role] = (roleCoverage[role] ?? 0) + quantity;
    }
    classifiedCards.add({
      'name': name,
      'quantity': quantity,
      'classification': classification,
      if (role != null) 'role': role,
      'reason':
          stat != null
              ? 'matched_reference_card_stats'
              : _referenceClassificationReason(classification),
    });
  }

  final overall = _overallReferenceClassification(counts, stats.length);
  return ReferenceGeneratedDeckEvaluation(
    classification: overall,
    counts: counts,
    roleCoverage: roleCoverage,
    cards: classifiedCards,
  );
}

Map<String, dynamic>? _findResolvedReferenceCard({
  required String cardName,
  required Map<String, Map<String, dynamic>> resolvedCardsByName,
}) {
  for (final alias in commanderReferenceCardLookupAliases(cardName)) {
    final resolved = resolvedCardsByName[alias];
    if (resolved != null) return resolved;
  }
  return null;
}

CommanderReferenceCardStat _cardStatFromRow(Map<String, dynamic> row) {
  final scoreRaw = row['score'];
  final updatedAtRaw = row['updated_at'];
  return CommanderReferenceCardStat(
    commanderName: row['commander_name']?.toString() ?? '',
    commanderNameNormalized: row['commander_name_normalized']?.toString() ?? '',
    cardName: row['card_name']?.toString() ?? '',
    cardNameNormalized: row['card_name_normalized']?.toString() ?? '',
    cardId: row['card_id']?.toString(),
    packageKey: row['package_key']?.toString() ?? '',
    role: row['role']?.toString() ?? '',
    score:
        scoreRaw is num
            ? scoreRaw.toDouble()
            : double.tryParse(scoreRaw?.toString() ?? '') ?? 0,
    confidence: row['confidence']?.toString() ?? 'not_proven',
    confidenceRank:
        row['confidence_rank'] is int
            ? row['confidence_rank'] as int
            : int.tryParse(row['confidence_rank']?.toString() ?? '') ?? 0,
    source: row['source']?.toString() ?? '',
    evidenceCount:
        row['evidence_count'] is int
            ? row['evidence_count'] as int
            : int.tryParse(row['evidence_count']?.toString() ?? '') ?? 1,
    unresolved: row['unresolved'] == true,
    updatedAt: updatedAtRaw is DateTime ? updatedAtRaw : null,
  );
}

String _roleForPackage(String packageKey) {
  return switch (packageKey) {
    'topdeck_and_miracle_setup' => 'topdeck_miracle_setup',
    'mana_ramp_foundation' => 'mana_rocks_treasure_ramp',
    'draw_rummage_foundation' => 'draw_rummage_opponent_turn_draw',
    'miracle_payoffs_expensive_spells' => 'miracle_haymakers',
    'interaction_and_resets' => 'interaction_and_resets',
    'protection_and_equipment' => 'protection',
    'spell_payoff_copy_package' => 'spell_payoffs_copy_engines',
    _ => packageKey,
  };
}

String _confidenceForPackage(String packageKey) {
  return switch (packageKey) {
    'topdeck_and_miracle_setup' => 'high',
    'mana_ramp_foundation' => 'high',
    'draw_rummage_foundation' => 'medium_high',
    'miracle_payoffs_expensive_spells' => 'medium_high',
    'interaction_and_resets' => 'medium_high',
    'protection_and_equipment' => 'medium_high',
    'spell_payoff_copy_package' => 'medium',
    _ => 'medium',
  };
}

double _scoreForPackage(String packageKey) {
  return switch (packageKey) {
    'topdeck_and_miracle_setup' => 94,
    'mana_ramp_foundation' => 90,
    'draw_rummage_foundation' => 87,
    'miracle_payoffs_expensive_spells' => 88,
    'interaction_and_resets' => 86,
    'protection_and_equipment' => 85,
    'spell_payoff_copy_package' => 84,
    _ => 75,
  };
}

int _sourceCount(Map<String, dynamic> profile) {
  final raw = profile['source_count'];
  if (raw is int) return raw;
  if (raw is num) return raw.toInt();
  return int.tryParse(raw?.toString() ?? '') ?? 1;
}

Set<String> _avoidPatternCardNames(Map<String, dynamic>? profile) {
  final avoid = profile?['avoid_patterns'];
  if (avoid is! List) return const {};
  final names = <String>{};
  for (final item in avoid) {
    if (item is! Map || item['examples'] is! List) continue;
    for (final rawName in item['examples'] as List) {
      names.add(normalizeCommanderReferenceCardName(rawName.toString()));
    }
  }
  return names;
}

String _classifyReferenceGeneratedCard({
  required String name,
  required String normalizedName,
  required CommanderReferenceCardStat? stat,
  required Map<String, dynamic>? metadata,
  required Set<String> avoidNames,
  required Set<String> commanderIdentity,
}) {
  if (stat != null) return 'on_theme';
  if (avoidNames.contains(normalizedName)) return 'off_theme';
  if (_isOffThemeBasicLand(normalizedName)) return 'off_theme';

  final identity = _metadataColorIdentity(metadata);
  if (!isWithinCommanderIdentity(
    cardIdentity: identity,
    commanderIdentity: commanderIdentity,
  )) {
    return 'off_theme';
  }

  if (_isGenericLoreholdSupport(name, metadata)) return 'generic';
  return 'questionable';
}

Set<String> _profileColorIdentity(Map<String, dynamic>? profile) {
  final raw = profile?['color_identity'];
  if (raw is! Iterable) return const {};
  return raw
      .map((color) => color.toString().trim().toUpperCase())
      .where((color) => color.isNotEmpty)
      .toSet();
}

Set<String> _metadataColorIdentity(Map<String, dynamic>? metadata) {
  final raw = metadata?['color_identity'];
  if (raw is Iterable) {
    return raw.map((value) => value.toString().trim().toUpperCase()).toSet();
  }
  return const {};
}

Iterable<String> _metadataStringIterable(Object? value) {
  if (value is Iterable) {
    return value.map((item) => item.toString());
  }
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? const <String>[] : [text];
}

bool _isOffThemeBasicLand(String normalizedName) {
  return normalizedName == 'island' ||
      normalizedName == 'swamp' ||
      normalizedName == 'forest' ||
      normalizedName.startsWith('snow-covered island') ||
      normalizedName.startsWith('snow-covered swamp') ||
      normalizedName.startsWith('snow-covered forest');
}

bool _isGenericLoreholdSupport(String name, Map<String, dynamic>? metadata) {
  final normalized = normalizeCommanderReferenceCardName(name);
  if (normalized == 'plains' ||
      normalized == 'mountain' ||
      normalized == 'wastes') {
    return true;
  }
  const knownGeneric = {
    'sol ring',
    'arcane signet',
    'boros signet',
    'talisman of conviction',
    'mind stone',
    'fellwar stone',
    "wayfarer's bauble",
    'thought vessel',
    "commander's sphere",
    'marble diamond',
    'fire diamond',
    'faithless looting',
    'thrill of possibility',
    'big score',
    'unexpected windfall',
    'seize the spoils',
    'reckless impulse',
    "wrenn's resolve",
    'light up the stage',
    'esper sentinel',
    "tocasia's welcome",
    'generous gift',
    'chaos warp',
    'wear // tear',
    'boros charm',
    'swiftfoot boots',
    'lightning greaves',
    "teferi's protection",
    'reconstruct history',
  };
  if (knownGeneric.contains(normalized)) return true;

  final typeLine = metadata?['type_line']?.toString().toLowerCase() ?? '';
  final oracle = metadata?['oracle_text']?.toString().toLowerCase() ?? '';
  final artifactRampName = RegExp(
    r'(signet|talisman|stone|diamond|sphere|bauble|vessel|sol ring)',
  );
  if (typeLine.contains('artifact') && artifactRampName.hasMatch(normalized)) {
    return true;
  }
  if ((typeLine.contains('instant') || typeLine.contains('sorcery')) &&
      (oracle.contains('draw') ||
          oracle.contains('discard') ||
          oracle.contains('destroy') ||
          oracle.contains('exile') ||
          oracle.contains('damage') ||
          oracle.contains('create'))) {
    return true;
  }
  return false;
}

String? _genericRoleForCard(String name, Map<String, dynamic>? metadata) {
  final normalized = normalizeCommanderReferenceCardName(name);
  if (normalized == 'plains' ||
      normalized == 'mountain' ||
      normalized == 'wastes') {
    return 'lands';
  }
  if (RegExp(
    r'(signet|talisman|stone|diamond|sphere|bauble|vessel|sol ring)',
  ).hasMatch(normalized)) {
    return 'mana_rocks_treasure_ramp';
  }
  final oracle = metadata?['oracle_text']?.toString().toLowerCase() ?? '';
  if (oracle.contains('draw') || oracle.contains('discard')) {
    return 'draw_rummage_opponent_turn_draw';
  }
  if (oracle.contains('destroy') || oracle.contains('exile')) {
    return 'spot_interaction';
  }
  return null;
}

Future<Set<String>?> _resolveCommanderReferenceTargetIdentity({
  required Pool pool,
  required String commanderName,
}) async {
  final resolved = await resolveImportCardNames(pool, [
    {'name': commanderName},
  ], preferredFormat: 'commander');
  Map<String, dynamic>? card;
  for (final entry in resolved.entries) {
    if (normalizeCommanderReferenceCardName(entry.key) ==
        normalizeCommanderReferenceCardName(commanderName)) {
      card = entry.value;
      break;
    }
  }
  if (card == null && resolved.values.isNotEmpty) {
    card = resolved.values.first;
  }
  if (card == null) return null;

  return resolveCardColorIdentity(
    colorIdentity:
        card['color_identity'] == null
            ? null
            : _metadataStringIterable(card['color_identity']),
    colors: _metadataStringIterable(card['colors']),
    oracleText: card['oracle_text']?.toString(),
    manaCost: card['mana_cost']?.toString(),
  );
}

Set<String> _referenceArchetypePromptTokens(String prompt) {
  final normalized = prompt.toLowerCase();
  final tokens =
      normalized
          .split(RegExp(r'[^a-z0-9]+'))
          .map((token) => token.trim())
          .where((token) => token.length >= 4)
          .toSet();
  if (normalized.contains('big spell')) tokens.add('big_spells');
  if (normalized.contains('magia grande') ||
      normalized.contains('magias grandes')) {
    tokens.add('big_spells');
  }
  if (normalized.contains('spell copy')) tokens.add('copy');
  if (normalized.contains('copiar magia') ||
      normalized.contains('copia magia')) {
    tokens.add('copy');
  }
  if (normalized.contains('topdeck')) tokens.add('topdeck');
  if (normalized.contains('topo do grimorio') ||
      normalized.contains('topo do grimório')) {
    tokens.add('topdeck');
  }
  if (normalized.contains('miracle')) tokens.add('miracle');
  if (normalized.contains('milagre')) tokens.add('miracle');
  if (normalized.contains('spellslinger')) tokens.add('spellslinger');
  if (normalized.contains('muitas magias') ||
      normalized.contains('instants e sorceries') ||
      normalized.contains('instantaneas e feiticos') ||
      normalized.contains('instantâneas e feitiços')) {
    tokens.add('spellslinger');
  }
  return tokens;
}

bool _referenceArchetypeMatchesPrompt({
  required CommanderReferenceCardStat stat,
  required Map<String, dynamic> profile,
  required Set<String> promptTokens,
}) {
  if (promptTokens.isEmpty) return true;
  final haystack = <String>[
    stat.packageKey,
    stat.role,
    stat.cardName,
    for (final theme in _themeNamesFromProfile(profile)) theme,
  ].join(' ').toLowerCase().replaceAll('_', ' ');
  final compactHaystack = haystack.replaceAll(' ', '_');
  return promptTokens.any(
    (token) => haystack.contains(token) || compactHaystack.contains(token),
  );
}

Iterable<String> _themeNamesFromProfile(Map<String, dynamic> profile) sync* {
  final themes = profile['themes'];
  if (themes is! Iterable) return;
  for (final theme in themes) {
    if (theme is Map && theme['name'] != null) {
      yield theme['name'].toString();
    } else {
      yield theme.toString();
    }
  }
}

String _downgradeArchetypeConfidence(String confidence) {
  final rank = commanderReferenceConfidenceRank(confidence);
  if (rank >= commanderReferenceConfidenceRank('high')) return 'medium';
  if (rank >= commanderReferenceConfidenceRank('medium_high')) return 'medium';
  return 'medium_low';
}

Map<String, dynamic>? _decodeJsonMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.cast<String, dynamic>();
  if (value is String && value.trim().isNotEmpty) {
    final decoded = jsonDecode(value);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return decoded.cast<String, dynamic>();
  }
  return null;
}

String _referenceClassificationReason(String classification) {
  return switch (classification) {
    'generic' => 'legal_generic_support_or_mana_base',
    'off_theme' => 'outside_lorehold_reference_or_color_identity',
    'questionable' => 'no_reference_stats_or_generic_role_match',
    _ => 'reference_evaluator',
  };
}

String _overallReferenceClassification(
  Map<String, int> counts,
  int statsCount,
) {
  final offTheme = counts['off_theme'] ?? 0;
  if (offTheme > 0) return 'off_theme';
  final onTheme = counts['on_theme'] ?? 0;
  final generic = counts['generic'] ?? 0;
  final questionable = counts['questionable'] ?? 0;
  final onThemeThreshold =
      statsCount <= 0 ? 0 : (statsCount / 4).ceil().clamp(4, 10);
  if (onTheme >= onThemeThreshold && questionable <= generic + onTheme) {
    return 'on_theme';
  }
  if (questionable > onTheme + generic) return 'questionable';
  return 'generic';
}

bool _isUndefinedTableError(Object error) {
  final text = error.toString().toLowerCase();
  return text.contains('42p01') ||
      text.contains('undefined_table') ||
      (text.contains('does not exist') &&
          (text.contains('commander_reference_card_stats') ||
              text.contains('commander_reference_profiles')));
}
