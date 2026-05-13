import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:postgres/postgres.dart';

import '../color_identity.dart';
import '../import_card_lookup_service.dart';
import 'commander_reference_card_stats_support.dart';

const commanderReferenceDecksTable = 'commander_reference_decks';
const commanderReferenceDeckCardsTable = 'commander_reference_deck_cards';
const commanderReferenceDeckAnalysisTable = 'commander_reference_deck_analysis';
const commanderReferenceDeckCorpusPromptPolicyVersion =
    'reference_deck_corpus_v4';

const basicLandNames = {
  'plains',
  'island',
  'swamp',
  'mountain',
  'forest',
  'wastes',
  'snow-covered plains',
  'snow-covered island',
  'snow-covered swamp',
  'snow-covered mountain',
  'snow-covered forest',
};

class CommanderReferenceDeckCardInput {
  const CommanderReferenceDeckCardInput({
    required this.name,
    required this.quantity,
    required this.board,
  });

  final String name;
  final int quantity;
  final String board;

  Map<String, dynamic> toJson() => {
        'name': name,
        'quantity': quantity,
        'board': board,
      };
}

class CommanderReferenceDeckInput {
  const CommanderReferenceDeckInput({
    required this.commanderName,
    required this.sourceDeckKey,
    required this.source,
    required this.sourceUrl,
    required this.powerLane,
    required this.theme,
    required this.cards,
  });

  final String commanderName;
  final String sourceDeckKey;
  final String source;
  final String sourceUrl;
  final String powerLane;
  final String theme;
  final List<CommanderReferenceDeckCardInput> cards;

  Map<String, dynamic> toJson() => {
        'commander_name': commanderName,
        'source_deck_key': sourceDeckKey,
        'source': source,
        'source_url': sourceUrl,
        'power_lane': powerLane,
        'theme': theme,
        'cards': cards.map((card) => card.toJson()).toList(),
      };
}

class CommanderReferenceDeckAnalysis {
  const CommanderReferenceDeckAnalysis({
    required this.deck,
    required this.commanderResolved,
    required this.commanderCardId,
    required this.commanderCardName,
    required this.mainQuantity,
    required this.commanderQuantity,
    required this.resolvedCount,
    required this.unresolvedCardNames,
    required this.offColorCardNames,
    required this.singletonViolations,
    required this.roleSummary,
    required this.accepted,
    required this.rejectionReasons,
    required this.cardRows,
  });

  final CommanderReferenceDeckInput deck;
  final bool commanderResolved;
  final String? commanderCardId;
  final String? commanderCardName;
  final int mainQuantity;
  final int commanderQuantity;
  final int resolvedCount;
  final List<String> unresolvedCardNames;
  final List<String> offColorCardNames;
  final Map<String, int> singletonViolations;
  final Map<String, int> roleSummary;
  final bool accepted;
  final List<String> rejectionReasons;
  final List<Map<String, dynamic>> cardRows;

  Map<String, dynamic> toJson() => {
        'source_deck_key': deck.sourceDeckKey,
        'commander_name': deck.commanderName,
        'source': deck.source,
        'source_url': deck.sourceUrl,
        'power_lane': deck.powerLane,
        'theme': deck.theme,
        'commander_card_resolution': {
          'resolved': commanderResolved,
          if (commanderCardId != null) 'card_id': commanderCardId,
          if (commanderCardName != null) 'card_name': commanderCardName,
        },
        'main_quantity': mainQuantity,
        'commander_quantity': commanderQuantity,
        'resolved_count': resolvedCount,
        'unresolved_count': unresolvedCardNames.length,
        'unresolved_card_names': unresolvedCardNames,
        'off_color_count': offColorCardNames.length,
        'off_color_card_names': offColorCardNames,
        'singleton_violations': singletonViolations,
        'role_summary': roleSummary,
        'accepted': accepted,
        'rejection_reasons': rejectionReasons,
      };
}

class CommanderReferenceCorpusSummary {
  const CommanderReferenceCorpusSummary({
    required this.commanderName,
    required this.deckCount,
    required this.acceptedDeckCount,
    required this.averageRoleCounts,
    required this.topCards,
    required this.themeCounts,
  });

  final String commanderName;
  final int deckCount;
  final int acceptedDeckCount;
  final Map<String, double> averageRoleCounts;
  final List<Map<String, dynamic>> topCards;
  final Map<String, int> themeCounts;

  Map<String, dynamic> toJson() => {
        'commander_name': commanderName,
        'deck_count': deckCount,
        'accepted_deck_count': acceptedDeckCount,
        'average_role_counts': averageRoleCounts,
        'top_cards': topCards,
        'theme_counts': themeCounts,
      };
}

class CommanderReferenceDeckCorpusGuidance {
  const CommanderReferenceDeckCorpusGuidance({
    required this.commanderName,
    required this.source,
    required this.deckCount,
    required this.acceptedDeckCount,
    required this.averageRoleCounts,
    required this.topCards,
    required this.themeCounts,
  });

  final String commanderName;
  final String source;
  final int deckCount;
  final int acceptedDeckCount;
  final Map<String, double> averageRoleCounts;
  final List<Map<String, dynamic>> topCards;
  final Map<String, int> themeCounts;

  bool get isUsable => acceptedDeckCount > 0;
  CommanderReferenceCorpusPackages get packages =>
      buildCommanderReferenceCorpusPackages(this);

  Map<String, dynamic> toDiagnostics() => {
        'reference_deck_corpus_used': isUsable,
        'reference_deck_corpus_source': source,
        'reference_deck_count': deckCount,
        'accepted_reference_deck_count': acceptedDeckCount,
        'average_role_counts': averageRoleCounts,
        'top_card_count': topCards.length,
        'top_cards': topCards
            .take(16)
            .map(
              (card) => {
                'card_name': card['card_name']?.toString(),
                'deck_count': _intValue(card['deck_count']),
                'role': card['role']?.toString(),
              },
            )
            .toList(growable: false),
        'theme_counts': themeCounts,
        'corpus_package_counts': packages.counts,
        'corpus_packages': packages.toDiagnostics(),
      };
}

class CommanderReferenceCorpusPackages {
  const CommanderReferenceCorpusPackages({
    required this.corePackage,
    required this.themePackage,
    required this.supportPackage,
    required this.optionalContextual,
  });

  final List<Map<String, dynamic>> corePackage;
  final List<Map<String, dynamic>> themePackage;
  final List<Map<String, dynamic>> supportPackage;
  final List<Map<String, dynamic>> optionalContextual;

  Map<String, int> get counts => {
        'core_package': corePackage.length,
        'theme_package': themePackage.length,
        'support_package': supportPackage.length,
        'optional_contextual': optionalContextual.length,
      };

  Map<String, dynamic> toDiagnostics() => {
        'core_package': _packageDiagnostics(corePackage, limit: 12),
        'theme_package': _packageDiagnostics(themePackage, limit: 12),
        'support_package': _packageDiagnostics(supportPackage, limit: 12),
        'optional_contextual': _packageDiagnostics(
          optionalContextual,
          limit: 8,
        ),
      };

  Map<String, dynamic> toCacheMaterial() => {
        'core_package': _packageDiagnostics(corePackage, limit: 24),
        'theme_package': _packageDiagnostics(themePackage, limit: 24),
        'support_package': _packageDiagnostics(supportPackage, limit: 24),
        'optional_contextual': _packageDiagnostics(
          optionalContextual,
          limit: 24,
        ),
      };
}

String normalizeCommanderReferenceDeckText(String value) =>
    normalizeCommanderReferenceCardName(value);

String buildReferenceDeckKey({
  required String commanderName,
  required String source,
  required String sourceUrl,
}) {
  final raw = jsonEncode({
    'commander': normalizeCommanderReferenceDeckText(commanderName),
    'source': normalizeCommanderReferenceDeckText(source),
    'url': sourceUrl.trim(),
  });
  return sha256.convert(utf8.encode(raw)).toString().substring(0, 24);
}

CommanderReferenceDeckInput parseCommanderReferenceDeckInput(
  Map<String, dynamic> payload,
) {
  final commanderName =
      (payload['commander'] ?? payload['commander_name'] ?? '')
          .toString()
          .trim();
  if (commanderName.isEmpty) {
    throw ArgumentError('reference deck precisa conter commander.');
  }

  final source =
      (payload['source'] ?? 'manual_reference_deck_v1').toString().trim();
  final sourceUrl =
      (payload['source_url'] ?? payload['url'] ?? '').toString().trim();
  final key = (payload['source_deck_key'] ?? payload['deck_key'] ?? '')
      .toString()
      .trim();
  final rawCards = payload['cards'];
  if (rawCards is! List) {
    throw ArgumentError('reference deck precisa conter cards[].');
  }

  final cards = rawCards.map((raw) {
    if (raw is! Map) {
      throw ArgumentError('cada card precisa ser objeto JSON.');
    }
    final name = raw['name']?.toString().trim() ?? '';
    if (name.isEmpty) throw ArgumentError('card sem name.');
    final quantity = int.tryParse('${raw['quantity'] ?? 1}') ?? 1;
    if (quantity < 1) {
      throw ArgumentError('quantity invalida para $name.');
    }
    final board = normalizeCommanderReferenceDeckText(
      raw['board']?.toString().trim().isNotEmpty == true
          ? raw['board'].toString()
          : (raw['is_commander'] == true ? 'commander' : 'main'),
    );
    return CommanderReferenceDeckCardInput(
      name: name,
      quantity: quantity,
      board: board == 'command zone' ? 'commander' : board,
    );
  }).toList(growable: false);

  return CommanderReferenceDeckInput(
    commanderName: commanderName,
    sourceDeckKey: key.isNotEmpty
        ? key
        : buildReferenceDeckKey(
            commanderName: commanderName,
            source: source,
            sourceUrl: sourceUrl,
          ),
    source: source.isEmpty ? 'manual_reference_deck_v1' : source,
    sourceUrl: sourceUrl,
    powerLane: (payload['power_lane'] ?? 'unknown').toString().trim(),
    theme: (payload['theme'] ?? 'unknown').toString().trim(),
    cards: cards,
  );
}

List<CommanderReferenceDeckInput> parseCommanderReferenceDeckCorpus(
  Map<String, dynamic> payload,
) {
  final commander = (payload['commander'] ?? payload['commander_name'] ?? '')
      .toString()
      .trim();
  final decks = payload['decks'];
  if (decks is List) {
    return decks.map((raw) {
      if (raw is! Map) throw ArgumentError('decks[] precisa ser objeto JSON.');
      final copy = raw.cast<String, dynamic>();
      copy.putIfAbsent('commander', () => commander);
      return parseCommanderReferenceDeckInput(copy);
    }).toList(growable: false);
  }
  return [parseCommanderReferenceDeckInput(payload)];
}

Future<List<CommanderReferenceDeckAnalysis>> analyzeCommanderReferenceDecks({
  required Pool pool,
  required List<CommanderReferenceDeckInput> decks,
}) async {
  final names = <String>{};
  for (final deck in decks) {
    names.add(deck.commanderName);
    for (final card in deck.cards) {
      names.add(card.name);
    }
  }
  final resolved = await resolveImportCardNames(
    pool,
    names.map((name) => {'name': name}).toList(growable: false),
    preferredFormat: 'commander',
  );
  return decks
      .map((deck) => analyzeCommanderReferenceDeck(
            deck: deck,
            resolvedCardsByName: resolved,
          ))
      .toList(growable: false);
}

Future<CommanderReferenceDeckCorpusGuidance?>
    loadCommanderReferenceDeckCorpusGuidance({
  required Pool pool,
  required String? commanderName,
}) async {
  final commander = commanderName?.trim();
  if (commander == null || commander.isEmpty) return null;

  final result = await pool.execute(
    Sql.named('''
      SELECT
        commander_name,
        source,
        deck_count,
        accepted_deck_count,
        average_role_counts,
        top_cards,
        theme_counts
      FROM commander_reference_deck_analysis
      WHERE commander_name_normalized = @commander
        AND accepted_deck_count > 0
      ORDER BY accepted_deck_count DESC, updated_at DESC
      LIMIT 1
    '''),
    parameters: {
      'commander': normalizeCommanderReferenceDeckText(commander),
    },
  );
  if (result.isEmpty) return null;

  final row = result.first;
  final topCards = _jsonList(row[5])
      .whereType<Map>()
      .map((value) => value.cast<String, dynamic>())
      .toList(growable: false);

  final guidance = CommanderReferenceDeckCorpusGuidance(
    commanderName: row[0]?.toString() ?? commander,
    source: row[1]?.toString() ?? 'commander_reference_deck_corpus_v1',
    deckCount: _intValue(row[2]),
    acceptedDeckCount: _intValue(row[3]),
    averageRoleCounts: _jsonMap(row[4]).map(
      (key, value) => MapEntry(key, _doubleValue(value)),
    ),
    topCards: topCards,
    themeCounts: _jsonMap(row[6]).map(
      (key, value) => MapEntry(key, _intValue(value)),
    ),
  );
  return guidance.isUsable ? guidance : null;
}

String? commanderReferenceDeckCorpusCacheVersion(
  CommanderReferenceDeckCorpusGuidance? guidance,
) {
  if (guidance == null || !guidance.isUsable) return null;
  final packages = guidance.packages;
  final material = jsonEncode({
    'source': guidance.source,
    'prompt_policy': commanderReferenceDeckCorpusPromptPolicyVersion,
    'commander': normalizeCommanderReferenceDeckText(guidance.commanderName),
    'accepted_deck_count': guidance.acceptedDeckCount,
    'average_role_counts': guidance.averageRoleCounts,
    'top_cards': guidance.topCards
        .take(24)
        .map(
          (card) => {
            'name': card['card_name']?.toString(),
            'deck_count': _intValue(card['deck_count']),
            'role': card['role']?.toString(),
          },
        )
        .toList(growable: false),
    'packages': packages.toCacheMaterial(),
    'theme_counts': guidance.themeCounts,
  });
  return '$commanderReferenceDeckCorpusPromptPolicyVersion:${sha256.convert(utf8.encode(material)).toString().substring(0, 12)}';
}

String buildCommanderReferenceDeckCorpusPrompt(
  CommanderReferenceDeckCorpusGuidance? guidance,
) {
  if (guidance == null || !guidance.isUsable) return '';
  final packages = guidance.packages;
  final compact = shouldUseCompactCommanderReferenceCorpusPrompt(guidance);
  final roleLines = guidance.averageRoleCounts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  final roles = roleLines
      .where((entry) => entry.key != 'lands')
      .take(compact ? 4 : 6)
      .map((entry) => '- ${entry.key}: ${entry.value.toStringAsFixed(1)} avg')
      .join('\n');
  final core = _formatCorpusPackagePromptLine(
    'core_package',
    packages.corePackage,
    acceptedDeckCount: guidance.acceptedDeckCount,
    limit: compact ? 14 : 12,
    maxLands: 2,
  );
  final theme = _formatCorpusPackagePromptLine(
    'theme_package',
    packages.themePackage,
    acceptedDeckCount: guidance.acceptedDeckCount,
    limit: compact ? 3 : 6,
    maxLands: 0,
  );
  final support = _formatCorpusPackagePromptLine(
    'support_package',
    packages.supportPackage,
    acceptedDeckCount: guidance.acceptedDeckCount,
    limit: compact ? 3 : 5,
    maxLands: 0,
  );
  final compactLine = compact
      ? '- Compact prompt mode active: core_package is complete enough; do not request optional_contextual or broad top-card bulk.'
      : '- Standard prompt mode active: use compact aggregate package lists only.';

  return '''
Reference deck corpus v4 active for ${guidance.commanderName}:
- Corpus size: ${guidance.acceptedDeckCount} accepted public reference decks.
- Use this as aggregate structure only, not as a decklist to copy.
- Average nonland role shape, top signals only:
$roles
- Package priority:
$core
$theme
$support
$compactLine
- First look at nonland core_package engines, setup, payoffs and ramp before theme/support. Core lands are mana-base options only; do not overfill basics.
- optional_contextual is excluded from the prompt and remains diagnostics-only; use it only to fill genuine curve/function gaps.
- Prefer core cards that fit role balance, then theme, then support. Keep final deck coherent and legal; do not force every recurrent card.
''';
}

bool shouldUseCompactCommanderReferenceCorpusPrompt(
  CommanderReferenceDeckCorpusGuidance? guidance,
) {
  if (guidance == null || !guidance.isUsable) return false;
  final packages = guidance.packages;
  return guidance.acceptedDeckCount >= 3 && packages.corePackage.length >= 24;
}

Set<String> commanderReferenceCorpusCoreCardNames(
  CommanderReferenceDeckCorpusGuidance? guidance,
) {
  if (guidance == null || !guidance.isUsable) return const {};
  return guidance.packages.corePackage
      .map((card) => card['card_name']?.toString().trim() ?? '')
      .where((name) => name.isNotEmpty)
      .toSet();
}

CommanderReferenceCorpusPackages buildCommanderReferenceCorpusPackages(
  CommanderReferenceDeckCorpusGuidance guidance,
) {
  final core = <Map<String, dynamic>>[];
  final theme = <Map<String, dynamic>>[];
  final support = <Map<String, dynamic>>[];
  final optional = <Map<String, dynamic>>[];
  final seen = <String>{};
  final sorted = guidance.topCards
      .map((card) => Map<String, dynamic>.from(card))
      .where(
          (card) => (card['card_name']?.toString().trim().isNotEmpty ?? false))
      .toList(growable: false)
    ..sort(_compareCorpusCards);
  final coreThreshold = _corePackageDeckCountThreshold(
    guidance.acceptedDeckCount,
  );

  for (final card in sorted) {
    final normalized = normalizeCommanderReferenceDeckText(
        card['card_name']?.toString() ?? '');
    if (normalized.isEmpty || !seen.add(normalized)) continue;

    final role = card['role']?.toString().trim().toLowerCase() ?? '';
    final deckCount = _intValue(card['deck_count']);
    if (deckCount >= coreThreshold) {
      core.add(card);
    } else if (_themeCorpusRoles.contains(role)) {
      theme.add(card);
    } else if (_supportCorpusRoles.contains(role)) {
      support.add(card);
    } else {
      optional.add(card);
    }
  }

  return CommanderReferenceCorpusPackages(
    corePackage: core,
    themePackage: theme,
    supportPackage: support,
    optionalContextual: optional,
  );
}

const _themeCorpusRoles = {
  'miracle_topdeck',
  'big_spell_payoff',
  'spellslinger',
  'exile_value',
  'ritual_treasure',
  'recursion',
  'win_condition',
};

const _supportCorpusRoles = {
  'tutor',
  'ramp',
  'interaction',
  'interaction_and_resets',
  'board_wipe',
  'draw_value',
  'protection',
  'creature',
};

int _corePackageDeckCountThreshold(int acceptedDeckCount) {
  if (acceptedDeckCount <= 1) return 1;
  final threshold = (acceptedDeckCount * 0.8).ceil();
  return threshold < 2 ? 2 : threshold;
}

int _compareCorpusCards(Map<String, dynamic> a, Map<String, dynamic> b) {
  final deckCountCompare =
      _intValue(b['deck_count']).compareTo(_intValue(a['deck_count']));
  if (deckCountCompare != 0) return deckCountCompare;
  final quantityCompare =
      _intValue(b['total_quantity']).compareTo(_intValue(a['total_quantity']));
  if (quantityCompare != 0) return quantityCompare;
  return (a['card_name']?.toString() ?? '')
      .compareTo(b['card_name']?.toString() ?? '');
}

List<Map<String, dynamic>> _packageDiagnostics(
  List<Map<String, dynamic>> cards, {
  required int limit,
}) {
  return cards
      .take(limit)
      .map(
        (card) => {
          'card_name': card['card_name']?.toString(),
          'deck_count': _intValue(card['deck_count']),
          'role': card['role']?.toString(),
        },
      )
      .toList(growable: false);
}

String _formatCorpusPackagePromptLine(
  String label,
  List<Map<String, dynamic>> cards, {
  required int acceptedDeckCount,
  required int limit,
  required int maxLands,
}) {
  if (cards.isEmpty) return '- $label: not_proven';
  final formatted = _promptOrderedCorpusCards(
    cards,
    limit: limit,
    maxLands: maxLands,
  )
      .take(limit)
      .map((card) {
        final name = card['card_name']?.toString().trim();
        if (name == null || name.isEmpty) return null;
        final role = card['role']?.toString().trim();
        final deckCount = _intValue(card['deck_count']);
        final roleSuffix = role == null || role.isEmpty ? '' : ' [$role]';
        return '$name$roleSuffix ($deckCount/$acceptedDeckCount)';
      })
      .whereType<String>()
      .join(', ');
  return '- $label: $formatted';
}

List<Map<String, dynamic>> _promptOrderedCorpusCards(
  List<Map<String, dynamic>> cards, {
  required int limit,
  required int maxLands,
}) {
  if (limit <= 0) return const [];
  final sorted = cards.map((card) => Map<String, dynamic>.from(card)).toList()
    ..sort(_compareCorpusCardsForPrompt);
  final nonLands = sorted
      .where((card) => card['role']?.toString().toLowerCase() != 'lands')
      .toList(growable: false);
  final lands = sorted
      .where((card) => card['role']?.toString().toLowerCase() == 'lands')
      .toList(growable: false);
  if (maxLands <= 0) return nonLands.take(limit).toList(growable: false);

  final nonLandBudget = (limit - maxLands).clamp(0, limit);
  final selected = <Map<String, dynamic>>[
    ...nonLands.take(nonLandBudget),
    ...lands.take(limit - nonLandBudget),
  ];
  if (selected.length < limit) {
    final selectedNames = selected
        .map((card) => normalizeCommanderReferenceDeckText(
            card['card_name']?.toString() ?? ''))
        .toSet();
    selected.addAll(
      nonLands.where((card) {
        final name = normalizeCommanderReferenceDeckText(
          card['card_name']?.toString() ?? '',
        );
        return name.isNotEmpty && !selectedNames.contains(name);
      }).take(limit - selected.length),
    );
  }
  return selected.take(limit).toList(growable: false);
}

int _compareCorpusCardsForPrompt(
    Map<String, dynamic> a, Map<String, dynamic> b) {
  final roleCompare = _corpusPromptRolePriority(a['role']?.toString() ?? '')
      .compareTo(_corpusPromptRolePriority(b['role']?.toString() ?? ''));
  if (roleCompare != 0) return roleCompare;
  final deckCountCompare =
      _intValue(b['deck_count']).compareTo(_intValue(a['deck_count']));
  if (deckCountCompare != 0) return deckCountCompare;
  final quantityCompare =
      _intValue(b['total_quantity']).compareTo(_intValue(a['total_quantity']));
  if (quantityCompare != 0) return quantityCompare;
  return (a['card_name']?.toString() ?? '')
      .compareTo(b['card_name']?.toString() ?? '');
}

int _corpusPromptRolePriority(String role) {
  return switch (role.trim().toLowerCase()) {
    'miracle_topdeck' => 0,
    'big_spell_payoff' => 1,
    'spellslinger' || 'ritual_treasure' => 2,
    'tutor' || 'exile_value' || 'draw_value' => 3,
    'ramp' => 4,
    'interaction' ||
    'interaction_and_resets' ||
    'board_wipe' ||
    'protection' =>
      5,
    'recursion' => 6,
    'win_condition' || 'creature' => 7,
    'lands' => 9,
    _ => 8,
  };
}

Map<String, dynamic>? evaluateGeneratedDeckAgainstReferenceCorpusPackages({
  required Map<String, dynamic> generatedDeck,
  required CommanderReferenceDeckCorpusGuidance? guidance,
}) {
  if (guidance == null || !guidance.isUsable) return null;
  final packages = guidance.packages;
  final generatedNames = <String, int>{};
  final cards = generatedDeck['cards'] is List
      ? (generatedDeck['cards'] as List)
      : const <dynamic>[];
  for (final rawCard in cards) {
    if (rawCard is! Map) continue;
    final name = rawCard['name']?.toString().trim() ?? '';
    if (name.isEmpty) continue;
    final quantityRaw = rawCard['quantity'];
    final quantity = quantityRaw is int
        ? quantityRaw
        : int.tryParse(quantityRaw?.toString() ?? '') ?? 1;
    final normalized = normalizeCommanderReferenceDeckText(name);
    if (normalized.isEmpty) continue;
    generatedNames[normalized] = (generatedNames[normalized] ?? 0) + quantity;
  }

  final packageCoverage = {
    'core_package': _evaluateCorpusPackageCoverage(
      packages.corePackage,
      generatedNames,
    ),
    'theme_package': _evaluateCorpusPackageCoverage(
      packages.themePackage,
      generatedNames,
    ),
    'support_package': _evaluateCorpusPackageCoverage(
      packages.supportPackage,
      generatedNames,
    ),
    'optional_contextual': _evaluateCorpusPackageCoverage(
      packages.optionalContextual,
      generatedNames,
    ),
  };
  final core = packageCoverage['core_package']!;
  final roleCoverage = <String, int>{};
  for (final coverage in packageCoverage.values) {
    final matchedCards = coverage['matched_cards'];
    if (matchedCards is! List) continue;
    for (final rawCard in matchedCards) {
      if (rawCard is! Map) continue;
      final role = rawCard['role']?.toString().trim();
      if (role == null || role.isEmpty) continue;
      roleCoverage[role] = (roleCoverage[role] ?? 0) +
          (rawCard['quantity'] is int ? rawCard['quantity'] as int : 1);
    }
  }
  return {
    'policy_version': commanderReferenceDeckCorpusPromptPolicyVersion,
    'core_package_available': core['available'],
    'core_package_matched': core['matched'],
    'core_package_coverage_ratio': core['coverage_ratio'],
    'package_coverage': packageCoverage,
    'role_coverage': roleCoverage,
  };
}

Map<String, dynamic> _evaluateCorpusPackageCoverage(
  List<Map<String, dynamic>> package,
  Map<String, int> generatedNames,
) {
  final available = package.length;
  final matched = <Map<String, dynamic>>[];
  final missed = <Map<String, dynamic>>[];
  for (final card in package) {
    final name = card['card_name']?.toString().trim() ?? '';
    if (name.isEmpty) continue;
    final normalized = normalizeCommanderReferenceDeckText(name);
    final quantity = generatedNames[normalized];
    final item = {
      'card_name': name,
      'role': card['role']?.toString(),
      'deck_count': _intValue(card['deck_count']),
      if (quantity != null && quantity > 0) 'quantity': quantity,
    };
    if (quantity != null && quantity > 0) {
      matched.add(item);
    } else {
      missed.add(item);
    }
  }

  final matchedCount = matched.length;
  return {
    'available': available,
    'matched': matchedCount,
    'coverage_ratio': available == 0
        ? 0.0
        : double.parse((matchedCount / available).toStringAsFixed(4)),
    'matched_cards': matched.take(12).toList(growable: false),
    'missed_top_cards': missed.take(12).toList(growable: false),
  };
}

CommanderReferenceDeckAnalysis analyzeCommanderReferenceDeck({
  required CommanderReferenceDeckInput deck,
  required Map<String, Map<String, dynamic>> resolvedCardsByName,
}) {
  final commanderResolution = findResolvedCommanderReferenceCommanderCard(
    commanderName: deck.commanderName,
    resolvedCardsByName: resolvedCardsByName,
  );
  final commanderIdentity = _cardIdentity(
    resolvedCardsByName[
        normalizeCommanderReferenceDeckText(deck.commanderName)],
  );
  final mainCards = deck.cards
      .where((card) => card.board != 'commander')
      .toList(growable: false);
  final commanderCards = deck.cards
      .where((card) => card.board == 'commander')
      .toList(growable: false);

  final unresolved = <String>{};
  final offColor = <String>{};
  final singleton = <String, int>{};
  final roleSummary = <String, int>{};
  final cardRows = <Map<String, dynamic>>[];
  var resolvedCount = 0;

  for (final card in deck.cards) {
    final normalized = normalizeCommanderReferenceDeckText(card.name);
    final metadata = resolvedCardsByName[normalized];
    final unresolvedCard = metadata == null;
    final identity = _cardIdentity(metadata);
    final offColorCard = !unresolvedCard &&
        !isWithinCommanderIdentity(
          cardIdentity: identity,
          commanderIdentity: commanderIdentity,
        );
    if (unresolvedCard) {
      unresolved.add(card.name);
    } else {
      resolvedCount += 1;
    }
    if (offColorCard) offColor.add(card.name);
    if (card.board != 'commander' &&
        card.quantity > 1 &&
        !basicLandNames.contains(normalized)) {
      singleton[card.name] = card.quantity;
    }
    final role = classifyCommanderReferenceDeckCardRole(card.name, metadata);
    roleSummary[role] = (roleSummary[role] ?? 0) + card.quantity;
    cardRows.add({
      'source_deck_key': deck.sourceDeckKey,
      'board': card.board,
      'card_name': card.name,
      'card_name_normalized': normalized,
      'card_id': metadata?['id']?.toString(),
      'quantity': card.quantity,
      'role': role,
      'unresolved': unresolvedCard,
      'off_color': offColorCard,
    });
  }

  final mainQuantity = mainCards.fold<int>(
    0,
    (total, card) => total + card.quantity,
  );
  final commanderQuantity = commanderCards.fold<int>(
    0,
    (total, card) => total + card.quantity,
  );

  final rejectionReasons = <String>[
    if (!commanderResolution.resolved) 'commander_unresolved',
    if (commanderQuantity != 1) 'commander_quantity_not_one',
    if (mainQuantity != 99) 'main_quantity_not_99',
    if (unresolved.isNotEmpty) 'unresolved_cards',
    if (offColor.isNotEmpty) 'off_color_cards',
    if (singleton.isNotEmpty) 'singleton_violations',
  ];

  return CommanderReferenceDeckAnalysis(
    deck: deck,
    commanderResolved: commanderResolution.resolved,
    commanderCardId: commanderResolution.cardId,
    commanderCardName: commanderResolution.cardName,
    mainQuantity: mainQuantity,
    commanderQuantity: commanderQuantity,
    resolvedCount: resolvedCount,
    unresolvedCardNames: unresolved.toList()..sort(),
    offColorCardNames: offColor.toList()..sort(),
    singletonViolations: singleton,
    roleSummary: roleSummary,
    accepted: rejectionReasons.isEmpty,
    rejectionReasons: rejectionReasons,
    cardRows: cardRows,
  );
}

CommanderReferenceCorpusSummary summarizeCommanderReferenceDeckCorpus(
  List<CommanderReferenceDeckAnalysis> analyses,
) {
  if (analyses.isEmpty) {
    return const CommanderReferenceCorpusSummary(
      commanderName: '',
      deckCount: 0,
      acceptedDeckCount: 0,
      averageRoleCounts: {},
      topCards: [],
      themeCounts: {},
    );
  }
  final commander = analyses.first.deck.commanderName;
  final accepted = analyses.where((analysis) => analysis.accepted).toList();
  final roleTotals = <String, int>{};
  final cardTotals = <String, Map<String, dynamic>>{};
  final themeCounts = <String, int>{};
  for (final analysis in accepted) {
    themeCounts[analysis.deck.theme] =
        (themeCounts[analysis.deck.theme] ?? 0) + 1;
    for (final entry in analysis.roleSummary.entries) {
      roleTotals[entry.key] = (roleTotals[entry.key] ?? 0) + entry.value;
    }
    for (final row in analysis.cardRows) {
      if (row['board'] == 'commander' || row['unresolved'] == true) continue;
      final key = row['card_name_normalized']?.toString() ?? '';
      if (key.isEmpty || basicLandNames.contains(key)) continue;
      final item = cardTotals.putIfAbsent(
          key,
          () => {
                'card_name': row['card_name'],
                'deck_count': 0,
                'total_quantity': 0,
                'role': row['role'],
              });
      item['deck_count'] = (item['deck_count'] as int) + 1;
      item['total_quantity'] =
          (item['total_quantity'] as int) + (row['quantity'] as int);
    }
  }
  final denominator = accepted.isEmpty ? 1 : accepted.length;
  final topCards = cardTotals.values.toList()
    ..sort((a, b) {
      final deckCountCompare =
          (b['deck_count'] as int).compareTo(a['deck_count'] as int);
      if (deckCountCompare != 0) return deckCountCompare;
      return (b['total_quantity'] as int).compareTo(a['total_quantity'] as int);
    });
  return CommanderReferenceCorpusSummary(
    commanderName: commander,
    deckCount: analyses.length,
    acceptedDeckCount: accepted.length,
    averageRoleCounts: {
      for (final entry in roleTotals.entries)
        entry.key: double.parse((entry.value / denominator).toStringAsFixed(2)),
    },
    topCards: topCards
        .take(40)
        .map((item) => Map<String, dynamic>.from(item))
        .toList(),
    themeCounts: themeCounts,
  );
}

String classifyCommanderReferenceDeckCardRole(
  String cardName,
  Map<String, dynamic>? metadata,
) {
  final normalized = normalizeCommanderReferenceDeckText(cardName);
  final typeLine = metadata?['type_line']?.toString().toLowerCase() ?? '';
  final oracle = metadata?['oracle_text']?.toString().toLowerCase() ?? '';
  if (typeLine.contains('land')) return 'lands';
  if (_containsAny(normalized, const [
    'deflecting swat',
    'bolt bend',
    'teferi s protection',
    'teferi\'s protection',
    'flawless maneuver',
    'boros charm',
  ])) {
    return 'protection';
  }
  if (_containsAny(normalized, const [
        'enlightened tutor',
        'gamble',
        'idyllic tutor',
        'imperial recruiter',
        'goblin engineer',
      ]) ||
      oracle.contains('search your library') &&
          !oracle.contains('basic land')) {
    return 'tutor';
  }
  if (_containsAny(normalized, const [
    'apex of power',
    'dance with calamity',
    'hit the mother lode',
    'improvisation capstone',
    'rise of the eldrazi',
    'soulfire eruption',
    'worldfire',
    'storm herd',
    'call forth the tempest',
    'volcanic vision',
    'insurrection',
    'invincible hymn',
    'deploy to the front',
    'gideon s phalanx',
  ])) {
    return 'big_spell_payoff';
  }
  if (_containsAny(normalized, const [
        'sensei s divining top',
        'sensei\'s divining top',
        'scroll rack',
        'galvanoth',
        'primal amulet',
        'dragon s rage channeler',
        'dragon\'s rage channeler',
        'library of leng',
        'hidden retreat',
      ]) ||
      oracle.contains('look at the top') ||
      oracle.contains('reveal the top') ||
      oracle.contains('from the top of your library') ||
      oracle.contains('the first card you draw')) {
    return 'miracle_topdeck';
  }
  if ((oracle.contains('without paying') &&
          (oracle.contains('mana value') || oracle.contains('discover'))) ||
      oracle.contains('mana value 7 or greater')) {
    return 'big_spell_payoff';
  }
  if (_containsAny(normalized, const [
        'arcane bombardment',
        'double vision',
        'dualcaster mage',
        'reverberate',
        'twinflame',
        'mizzix s mastery',
        'storm kiln artist',
        'aetherflux reservoir',
        'grinding station',
      ]) ||
      oracle.contains('copy target instant') ||
      oracle.contains('copy target sorcery') ||
      oracle.contains('whenever you cast or copy') ||
      oracle.contains('whenever you cast an instant') ||
      oracle.contains('whenever you cast a sorcery') ||
      oracle.contains('storm')) {
    return 'spellslinger';
  }
  if (_containsAny(normalized, const [
        'underworld breach',
        'sevinne s reclamation',
        'reconstruct history',
        'sun titan',
        'restore balance',
        'restoration seminar',
      ]) ||
      oracle.contains('from your graveyard') ||
      oracle.contains('return target') && oracle.contains('graveyard') ||
      oracle.contains('escape')) {
    return 'recursion';
  }
  if (_containsAny(normalized, const [
        'jeska s will',
        'jeska\'s will',
        'brass s bounty',
        'big score',
        'unexpected windfall',
        'seize the spoils',
        'strike it rich',
        'descent into avernus',
        'mana geyser',
        'desperate ritual',
        'pyretic ritual',
        'rite of flame',
        'seething song',
        'simian spirit guide',
        'lion s eye diamond',
        'lion\'s eye diamond',
        'lotus petal',
      ]) ||
      oracle.contains('create a treasure token') ||
      oracle.contains('create two treasure tokens') ||
      oracle.contains('add {r}{r}') ||
      oracle.contains('add {r}{r}{r}') ||
      oracle.contains('add one mana for each')) {
    return 'ritual_treasure';
  }
  if (_containsAny(normalized, const [
        'monument to endurance',
        'naktamun lorespinner',
        'wheel of fortune',
        'wheel of fate',
        'reforge the soul',
        'valakut awakening',
        'faithless looting',
        'surly badgersaur',
        'bender s waterskin',
        'bender\'s waterskin',
      ]) ||
      oracle.contains('exile the top') ||
      oracle.contains('you may play that card') ||
      oracle.contains('you may cast that card') ||
      oracle.contains('discard') && oracle.contains('draw')) {
    return 'exile_value';
  }
  if (_containsAny(normalized, const ['sol ring', 'signet', 'talisman']) ||
      oracle.contains('add {') ||
      oracle.contains('treasure token') ||
      oracle.contains('search your library for a basic land')) {
    return 'ramp';
  }
  if (oracle.contains('draw a card') ||
      oracle.contains('draw cards') ||
      oracle.contains('look at the top')) {
    return 'draw_value';
  }
  if (oracle.contains('indestructible') ||
      oracle.contains('hexproof') ||
      oracle.contains('protection from') ||
      oracle.contains('prevent all damage')) {
    return 'protection';
  }
  if (oracle.contains('destroy all') ||
      oracle.contains('exile all') ||
      oracle.contains('deals ') && oracle.contains('to each creature')) {
    return 'board_wipe';
  }
  if (_containsAny(normalized, const [
        'redirect lightning',
        'pyroblast',
        'red elemental blast',
        'wear // tear',
      ]) ||
      oracle.contains('destroy target') ||
      oracle.contains('exile target') ||
      oracle.contains('counter target') ||
      oracle.contains('deals ') && oracle.contains('any target')) {
    return 'interaction';
  }
  if (oracle.contains('you win the game') ||
      oracle.contains('each opponent loses') ||
      oracle.contains('double') ||
      oracle.contains('whenever you cast')) {
    return 'win_condition';
  }
  if (typeLine.contains('creature')) return 'creature';
  return 'other';
}

Future<void> ensureCommanderReferenceDeckCorpusTables(Pool pool) async {
  await pool.execute('''
    CREATE TABLE IF NOT EXISTS commander_reference_decks (
      source_deck_key TEXT PRIMARY KEY,
      commander_name TEXT NOT NULL,
      commander_name_normalized TEXT NOT NULL,
      source TEXT NOT NULL,
      source_url TEXT,
      power_lane TEXT,
      theme TEXT,
      deck_hash TEXT NOT NULL,
      main_quantity INTEGER NOT NULL,
      commander_quantity INTEGER NOT NULL,
      resolved_count INTEGER NOT NULL,
      unresolved_count INTEGER NOT NULL,
      off_color_count INTEGER NOT NULL,
      singleton_violations JSONB NOT NULL DEFAULT '{}'::jsonb,
      role_summary JSONB NOT NULL DEFAULT '{}'::jsonb,
      accepted BOOLEAN NOT NULL DEFAULT FALSE,
      rejection_reasons JSONB NOT NULL DEFAULT '[]'::jsonb,
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    )
  ''');
  await pool.execute('''
    CREATE TABLE IF NOT EXISTS commander_reference_deck_cards (
      source_deck_key TEXT NOT NULL REFERENCES commander_reference_decks(source_deck_key) ON DELETE CASCADE,
      board TEXT NOT NULL,
      card_name TEXT NOT NULL,
      card_name_normalized TEXT NOT NULL,
      card_id UUID REFERENCES cards(id) ON DELETE SET NULL,
      quantity INTEGER NOT NULL,
      role TEXT NOT NULL,
      unresolved BOOLEAN NOT NULL DEFAULT FALSE,
      off_color BOOLEAN NOT NULL DEFAULT FALSE,
      updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      PRIMARY KEY (source_deck_key, board, card_name_normalized)
    )
  ''');
  await pool.execute('''
    CREATE TABLE IF NOT EXISTS commander_reference_deck_analysis (
      commander_name_normalized TEXT NOT NULL,
      source TEXT NOT NULL,
      commander_name TEXT NOT NULL,
      deck_count INTEGER NOT NULL,
      accepted_deck_count INTEGER NOT NULL,
      average_role_counts JSONB NOT NULL DEFAULT '{}'::jsonb,
      top_cards JSONB NOT NULL DEFAULT '[]'::jsonb,
      theme_counts JSONB NOT NULL DEFAULT '{}'::jsonb,
      updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      PRIMARY KEY (commander_name_normalized, source)
    )
  ''');
  await pool.execute('''
    CREATE INDEX IF NOT EXISTS idx_commander_reference_decks_lookup
    ON commander_reference_decks (commander_name_normalized, accepted, updated_at DESC)
  ''');
  await pool.execute('''
    CREATE INDEX IF NOT EXISTS idx_commander_reference_deck_cards_hot
    ON commander_reference_deck_cards (card_name_normalized, role, unresolved, off_color)
  ''');
}

Future<void> upsertCommanderReferenceDeckCorpus(
  Pool pool,
  List<CommanderReferenceDeckAnalysis> analyses,
) async {
  for (final analysis in analyses) {
    await pool.execute(
      Sql.named('''
        INSERT INTO commander_reference_decks (
          source_deck_key,
          commander_name,
          commander_name_normalized,
          source,
          source_url,
          power_lane,
          theme,
          deck_hash,
          main_quantity,
          commander_quantity,
          resolved_count,
          unresolved_count,
          off_color_count,
          singleton_violations,
          role_summary,
          accepted,
          rejection_reasons,
          updated_at
        ) VALUES (
          @source_deck_key,
          @commander_name,
          @commander_name_normalized,
          @source,
          @source_url,
          @power_lane,
          @theme,
          @deck_hash,
          @main_quantity,
          @commander_quantity,
          @resolved_count,
          @unresolved_count,
          @off_color_count,
          @singleton_violations::jsonb,
          @role_summary::jsonb,
          @accepted,
          @rejection_reasons::jsonb,
          NOW()
        )
        ON CONFLICT (source_deck_key)
        DO UPDATE SET
          commander_name = EXCLUDED.commander_name,
          commander_name_normalized = EXCLUDED.commander_name_normalized,
          source = EXCLUDED.source,
          source_url = EXCLUDED.source_url,
          power_lane = EXCLUDED.power_lane,
          theme = EXCLUDED.theme,
          deck_hash = EXCLUDED.deck_hash,
          main_quantity = EXCLUDED.main_quantity,
          commander_quantity = EXCLUDED.commander_quantity,
          resolved_count = EXCLUDED.resolved_count,
          unresolved_count = EXCLUDED.unresolved_count,
          off_color_count = EXCLUDED.off_color_count,
          singleton_violations = EXCLUDED.singleton_violations,
          role_summary = EXCLUDED.role_summary,
          accepted = EXCLUDED.accepted,
          rejection_reasons = EXCLUDED.rejection_reasons,
          updated_at = NOW()
      '''),
      parameters: {
        'source_deck_key': analysis.deck.sourceDeckKey,
        'commander_name': analysis.deck.commanderName,
        'commander_name_normalized':
            normalizeCommanderReferenceDeckText(analysis.deck.commanderName),
        'source': analysis.deck.source,
        'source_url': analysis.deck.sourceUrl,
        'power_lane': analysis.deck.powerLane,
        'theme': analysis.deck.theme,
        'deck_hash': sha256
            .convert(utf8.encode(jsonEncode(analysis.deck.toJson())))
            .toString(),
        'main_quantity': analysis.mainQuantity,
        'commander_quantity': analysis.commanderQuantity,
        'resolved_count': analysis.resolvedCount,
        'unresolved_count': analysis.unresolvedCardNames.length,
        'off_color_count': analysis.offColorCardNames.length,
        'singleton_violations': jsonEncode(analysis.singletonViolations),
        'role_summary': jsonEncode(analysis.roleSummary),
        'accepted': analysis.accepted,
        'rejection_reasons': jsonEncode(analysis.rejectionReasons),
      },
    );
    await pool.execute(
      Sql.named(
          'DELETE FROM commander_reference_deck_cards WHERE source_deck_key = @source_deck_key'),
      parameters: {'source_deck_key': analysis.deck.sourceDeckKey},
    );
    if (analysis.cardRows.isEmpty) {
      continue;
    }
    final rowsPayload = analysis.cardRows
        .map(
          (row) => {
            ...row,
            'card_id': row['card_id']?.toString() ?? '',
          },
        )
        .toList(growable: false);
    await pool.execute(
      Sql.named('''
        INSERT INTO commander_reference_deck_cards (
          source_deck_key,
          board,
          card_name,
          card_name_normalized,
          card_id,
          quantity,
          role,
          unresolved,
          off_color,
          updated_at
        )
        SELECT
          source_deck_key,
          board,
          card_name,
          card_name_normalized,
          NULLIF(card_id, '')::uuid,
          quantity,
          role,
          unresolved,
          off_color,
          NOW()
        FROM jsonb_to_recordset(@rows::jsonb) AS row(
          source_deck_key text,
          board text,
          card_name text,
          card_name_normalized text,
          card_id text,
          quantity integer,
          role text,
          unresolved boolean,
          off_color boolean
        )
      '''),
      parameters: {'rows': jsonEncode(rowsPayload)},
    );
  }

  final byCommander = <String, List<CommanderReferenceDeckAnalysis>>{};
  for (final analysis in analyses) {
    byCommander
        .putIfAbsent(analysis.deck.commanderName, () => [])
        .add(analysis);
  }
  for (final entry in byCommander.entries) {
    final summary = summarizeCommanderReferenceDeckCorpus(entry.value);
    await pool.execute(
      Sql.named('''
        INSERT INTO commander_reference_deck_analysis (
          commander_name_normalized,
          source,
          commander_name,
          deck_count,
          accepted_deck_count,
          average_role_counts,
          top_cards,
          theme_counts,
          updated_at
        ) VALUES (
          @commander_name_normalized,
          @source,
          @commander_name,
          @deck_count,
          @accepted_deck_count,
          @average_role_counts::jsonb,
          @top_cards::jsonb,
          @theme_counts::jsonb,
          NOW()
        )
        ON CONFLICT (commander_name_normalized, source)
        DO UPDATE SET
          commander_name = EXCLUDED.commander_name,
          deck_count = EXCLUDED.deck_count,
          accepted_deck_count = EXCLUDED.accepted_deck_count,
          average_role_counts = EXCLUDED.average_role_counts,
          top_cards = EXCLUDED.top_cards,
          theme_counts = EXCLUDED.theme_counts,
          updated_at = NOW()
      '''),
      parameters: {
        'commander_name_normalized':
            normalizeCommanderReferenceDeckText(summary.commanderName),
        'source': 'commander_reference_deck_corpus_v1',
        'commander_name': summary.commanderName,
        'deck_count': summary.deckCount,
        'accepted_deck_count': summary.acceptedDeckCount,
        'average_role_counts': jsonEncode(summary.averageRoleCounts),
        'top_cards': jsonEncode(summary.topCards),
        'theme_counts': jsonEncode(summary.themeCounts),
      },
    );
  }
}

Map<String, dynamic> _jsonMap(Object? raw) {
  if (raw is Map<String, dynamic>) return raw;
  if (raw is Map) return raw.cast<String, dynamic>();
  if (raw is String && raw.trim().isNotEmpty) {
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return decoded.cast<String, dynamic>();
  }
  return const <String, dynamic>{};
}

List<dynamic> _jsonList(Object? raw) {
  if (raw is List) return raw;
  if (raw is String && raw.trim().isNotEmpty) {
    final decoded = jsonDecode(raw);
    if (decoded is List) return decoded;
  }
  return const <dynamic>[];
}

int _intValue(Object? raw) {
  if (raw is int) return raw;
  if (raw is num) return raw.toInt();
  return int.tryParse(raw?.toString() ?? '') ?? 0;
}

double _doubleValue(Object? raw) {
  if (raw is double) return raw;
  if (raw is num) return raw.toDouble();
  return double.tryParse(raw?.toString() ?? '') ?? 0;
}

Set<String> _cardIdentity(Map<String, dynamic>? metadata) {
  if (metadata == null) return <String>{};
  return resolveCardColorIdentity(
    colorIdentity: _metadataStringIterable(metadata['color_identity']),
    colors: _metadataStringIterable(metadata['colors']),
    oracleText: metadata['oracle_text']?.toString(),
    manaCost: metadata['mana_cost']?.toString(),
  );
}

Iterable<String> _metadataStringIterable(Object? value) {
  if (value is Iterable) return value.map((item) => item.toString());
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? const <String>[] : [text];
}

bool _containsAny(String value, Iterable<String> needles) =>
    needles.any(value.contains);
