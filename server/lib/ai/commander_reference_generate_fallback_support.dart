import 'commander_reference_card_stats_support.dart';
import 'commander_reference_deck_corpus_support.dart';
import 'commander_learned_deck_support.dart';
import 'commander_reference_profile_support.dart';
import '../color_identity.dart';

const deterministicReferenceDeckSourcePrecedence = [
  'active_learned_deck',
  'reference_card_stats',
  'reference_corpus_packages',
  'profile_expected_packages',
  'usage_hot_cards',
  'deterministic_fallback',
];

class ReferenceGeneratedCardsIdentityFilterResult {
  const ReferenceGeneratedCardsIdentityFilterResult({
    required this.cards,
    required this.removedOffColorNames,
    this.removedUnresolvedNames = const [],
  });

  final List<Map<String, dynamic>> cards;
  final List<String> removedOffColorNames;
  final List<String> removedUnresolvedNames;

  int get removedOffColorCount => removedOffColorNames.length;
  int get removedUnresolvedCount => removedUnresolvedNames.length;
}

class DeterministicReferenceDeckCardProvenance {
  const DeterministicReferenceDeckCardProvenance({
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

class DeterministicReferenceDeckBuildResult {
  const DeterministicReferenceDeckBuildResult({
    required this.deck,
    required this.cardProvenance,
    required this.sourceMixCounts,
    required this.sourceUsageCounts,
    required this.mainDeckQuantity,
    required this.distinctCardCount,
    required this.basicLandQuantity,
    required this.builtInFallbackEnabled,
    required this.builtInFallbackUsedCount,
    required this.builtInFallbackOnlyCount,
    required this.builtInFallbackOnlySample,
  });

  final Map<String, dynamic> deck;
  final List<DeterministicReferenceDeckCardProvenance> cardProvenance;
  final Map<String, int> sourceMixCounts;
  final Map<String, int> sourceUsageCounts;
  final int mainDeckQuantity;
  final int distinctCardCount;
  final int basicLandQuantity;
  final bool builtInFallbackEnabled;
  final int builtInFallbackUsedCount;
  final int builtInFallbackOnlyCount;
  final List<String> builtInFallbackOnlySample;

  Map<String, dynamic> toDiagnosticsJson({int sampleLimit = 10}) => {
        'source_precedence': deterministicReferenceDeckSourcePrecedence,
        'main_deck_quantity': mainDeckQuantity,
        'distinct_card_count': distinctCardCount,
        'basic_land_quantity': basicLandQuantity,
        'built_in_fallback_enabled': builtInFallbackEnabled,
        'built_in_fallback_used_count': builtInFallbackUsedCount,
        'built_in_fallback_only_count': builtInFallbackOnlyCount,
        'built_in_fallback_only_sample':
            builtInFallbackOnlySample.take(sampleLimit).toList(growable: false),
        'source_mix_counts': sourceMixCounts,
        'source_usage_counts': sourceUsageCounts,
        'card_provenance_sample': cardProvenance
            .take(sampleLimit)
            .map((entry) => entry.toJson())
            .toList(growable: false),
      };
}

ReferenceGeneratedCardsIdentityFilterResult
    filterReferenceGeneratedCardsByCommanderIdentity({
  required Map<String, dynamic> profile,
  required String commanderName,
  required List<Map<String, dynamic>> cards,
  required Map<String, Map<String, dynamic>> resolvedCardsByName,
}) {
  final commanderIdentity = _profileColorIdentity(profile).toSet();
  if (commanderIdentity.isEmpty) {
    return ReferenceGeneratedCardsIdentityFilterResult(
      cards: cards.map(Map<String, dynamic>.from).toList(growable: false),
      removedOffColorNames: const [],
      removedUnresolvedNames: const [],
    );
  }

  final filtered = <Map<String, dynamic>>[];
  final removedOffColor = <String>{};
  final removedUnresolved = <String>{};
  final normalizedCommander =
      normalizeCommanderReferenceCardName(commanderName);

  for (final card in cards) {
    final name = card['name']?.toString().trim() ?? '';
    if (name.isEmpty) continue;
    if (normalizeCommanderReferenceCardName(name) == normalizedCommander) {
      continue;
    }

    final resolved = _findResolvedCard(name, resolvedCardsByName);
    if (resolved == null) {
      removedUnresolved.add(name);
      continue;
    }

    final identity = resolveCardColorIdentity(
      colorIdentity: _metadataStringIterable(resolved['color_identity']),
      colors: _metadataStringIterable(resolved['colors']),
      oracleText: resolved['oracle_text']?.toString(),
      manaCost: resolved['mana_cost']?.toString(),
    );
    if (!isWithinCommanderIdentity(
      cardIdentity: identity,
      commanderIdentity: commanderIdentity,
    )) {
      removedOffColor.add(name);
      continue;
    }
    filtered.add(Map<String, dynamic>.from(card));
  }

  return ReferenceGeneratedCardsIdentityFilterResult(
    cards: filtered,
    removedOffColorNames: removedOffColor.toList()..sort(),
    removedUnresolvedNames: removedUnresolved.toList()..sort(),
  );
}

Map<String, dynamic> buildDeterministicReferenceDeck({
  required Map<String, dynamic> profile,
  List<CommanderReferenceCardStat> referenceCardStats = const [],
  CommanderReferenceDeckCorpusGuidance? referenceDeckCorpusGuidance,
  CommanderLearnedDeckInput? activeLearnedDeck,
  List<String> promotedLearnedCardNames = const [],
  List<String> usageHotCardNames = const [],
  int targetMainQuantity = 99,
}) =>
    buildDeterministicReferenceDeckResult(
      profile: profile,
      referenceCardStats: referenceCardStats,
      referenceDeckCorpusGuidance: referenceDeckCorpusGuidance,
      activeLearnedDeck: activeLearnedDeck,
      promotedLearnedCardNames: promotedLearnedCardNames,
      usageHotCardNames: usageHotCardNames,
      targetMainQuantity: targetMainQuantity,
    ).deck;

DeterministicReferenceDeckBuildResult buildDeterministicReferenceDeckResult({
  required Map<String, dynamic> profile,
  List<CommanderReferenceCardStat> referenceCardStats = const [],
  CommanderReferenceDeckCorpusGuidance? referenceDeckCorpusGuidance,
  CommanderLearnedDeckInput? activeLearnedDeck,
  List<String> promotedLearnedCardNames = const [],
  List<String> usageHotCardNames = const [],
  int targetMainQuantity = 99,
}) {
  final commanderName =
      (profile['commander'] ?? profile['commander_name'] ?? '')
          .toString()
          .trim();
  final orderedCardNames = <String>[];
  final seen = <String>{};
  final quantitiesByName = <String, int>{};
  final displayNameByName = <String, String>{};
  final sourceLabelsByName = <String, Set<String>>{};
  final avoidedExampleNames = _profileAvoidExampleNames(profile);
  final builtInFallbackEnabled =
      isLoreholdCommanderReferenceCandidate(commanderName);

  void addCard(
    String? rawName,
    String source, {
    int quantity = 1,
    bool allowBasicLand = false,
  }) {
    final name = rawName?.trim();
    if (name == null || name.isEmpty || quantity <= 0) return;
    final normalizedName = normalizeCommanderReferenceCardName(name);
    if (normalizedName == normalizeCommanderReferenceCardName(commanderName)) {
      return;
    }
    if (avoidedExampleNames.contains(normalizedName)) {
      return;
    }
    final isBasicLand = basicLandNames.contains(normalizedName);
    if (isBasicLand && !allowBasicLand) {
      return;
    }
    sourceLabelsByName
        .putIfAbsent(normalizedName, () => <String>{})
        .add(source);
    displayNameByName.putIfAbsent(normalizedName, () => name);
    if (seen.add(normalizedName)) {
      orderedCardNames.add(normalizedName);
      quantitiesByName[normalizedName] = 0;
    }
    if (isBasicLand) {
      quantitiesByName[normalizedName] =
          (quantitiesByName[normalizedName] ?? 0) + quantity;
      return;
    }
    if ((quantitiesByName[normalizedName] ?? 0) <= 0) {
      quantitiesByName[normalizedName] = 1;
    }
  }

  if (activeLearnedDeck != null) {
    for (final card in activeLearnedDeck.cards) {
      addCard(
        card.name,
        'active_learned_deck',
        quantity: card.quantity,
        allowBasicLand: true,
      );
    }
  } else {
    for (final rawName in promotedLearnedCardNames) {
      addCard(rawName, 'active_learned_deck');
    }
  }

  final stats = referenceCardStats.where((stat) => !stat.unresolved).toList()
    ..sort((a, b) {
      final packageCompare = _fallbackPackagePriority(a.packageKey, a.role)
          .compareTo(_fallbackPackagePriority(b.packageKey, b.role));
      if (packageCompare != 0) return packageCompare;
      final scoreCompare = b.score.compareTo(a.score);
      if (scoreCompare != 0) return scoreCompare;
      return a.cardName.compareTo(b.cardName);
    });
  for (final stat in stats) {
    addCard(stat.cardName, 'reference_card_stats');
  }

  final corpusPackages = referenceDeckCorpusGuidance?.packages;
  for (final package in [
    if (corpusPackages != null) corpusPackages.corePackage,
    if (corpusPackages != null) corpusPackages.themePackage,
    if (corpusPackages != null) corpusPackages.supportPackage,
  ]) {
    for (final card in package) {
      addCard(card['card_name']?.toString(), 'reference_corpus_packages');
    }
  }

  final expectedPackages = profile['expected_packages'];
  if (expectedPackages is Map) {
    final entries = expectedPackages.entries.toList()
      ..sort((a, b) {
        final priorityCompare = _fallbackPackagePriority(
          a.key.toString(),
          a.key.toString(),
        ).compareTo(
          _fallbackPackagePriority(
            b.key.toString(),
            b.key.toString(),
          ),
        );
        if (priorityCompare != 0) return priorityCompare;
        return a.key.toString().compareTo(b.key.toString());
      });
    for (final entry in entries) {
      if (entry.value is! List) continue;
      for (final rawCard in entry.value as List) {
        addCard(rawCard.toString(), 'profile_expected_packages');
      }
    }
  }

  for (final rawName in usageHotCardNames) {
    addCard(rawName, 'usage_hot_cards');
  }

  if (builtInFallbackEnabled) {
    for (final name in loreholdDeterministicReferenceFallbackCards) {
      final normalizedName = normalizeCommanderReferenceCardName(name);
      if ((sourceLabelsByName[normalizedName] ?? const <String>{}).isNotEmpty) {
        continue;
      }
      addCard(name, 'deterministic_fallback');
    }
  }

  final cappedCards = <Map<String, dynamic>>[];
  var cappedMainQuantity = 0;
  for (final normalizedName in orderedCardNames) {
    if (cappedMainQuantity >= targetMainQuantity) break;
    final quantity = quantitiesByName[normalizedName] ?? 0;
    if (quantity <= 0) continue;
    final remaining = targetMainQuantity - cappedMainQuantity;
    final appliedQuantity = quantity > remaining ? remaining : quantity;
    cappedCards.add({
      'name': displayNameByName[normalizedName] ?? normalizedName,
      'quantity': appliedQuantity,
    });
    cappedMainQuantity += appliedQuantity;
  }
  final colors = _profileColorIdentity(profile);
  final basics = _buildBasicLandFallbackCards(
    total: targetMainQuantity - cappedMainQuantity,
    colors: colors.isEmpty ? const ['W'] : colors,
  );
  final provenance = <DeterministicReferenceDeckCardProvenance>[];
  final sourceMixCounts = <String, int>{};
  final sourceUsageCounts = <String, int>{};
  final builtInFallbackOnlyNames = <String>[];

  for (final card in cappedCards) {
    final name = card['name']?.toString() ?? '';
    final normalizedName = normalizeCommanderReferenceCardName(name);
    final sources = (sourceLabelsByName[normalizedName] ?? const <String>{})
        .toList(growable: false)
      ..sort();
    provenance.add(
      DeterministicReferenceDeckCardProvenance(
        cardName: name,
        sources: sources,
      ),
    );
    final mixKey = sources.join(' + ');
    sourceMixCounts[mixKey] = (sourceMixCounts[mixKey] ?? 0) + 1;
    for (final source in sources) {
      sourceUsageCounts[source] = (sourceUsageCounts[source] ?? 0) + 1;
    }
    if (sources.length == 1 && sources.first == 'deterministic_fallback') {
      builtInFallbackOnlyNames.add(name);
    }
  }

  final basicLandQuantity = basics.fold<int>(
    0,
    (total, card) => total + ((card['quantity'] as int?) ?? 0),
  );
  final deck = {
    'commander': {
      'name': commanderName.isEmpty ? 'Isamaru, Hound of Konda' : commanderName
    },
    'cards': [
      ...cappedCards,
      ...basics,
    ],
  };

  return DeterministicReferenceDeckBuildResult(
    deck: deck,
    cardProvenance: provenance,
    sourceMixCounts: sourceMixCounts,
    sourceUsageCounts: sourceUsageCounts,
    mainDeckQuantity: cappedMainQuantity + basicLandQuantity,
    distinctCardCount: cappedCards.length + basics.length,
    basicLandQuantity: basicLandQuantity,
    builtInFallbackEnabled: builtInFallbackEnabled,
    builtInFallbackUsedCount: provenance
        .where((entry) => entry.sources.contains('deterministic_fallback'))
        .length,
    builtInFallbackOnlyCount: builtInFallbackOnlyNames.length,
    builtInFallbackOnlySample:
        builtInFallbackOnlyNames.take(12).toList(growable: false),
  );
}

const loreholdDeterministicReferenceFallbackCards = [
  'Sol Ring',
  'Arcane Signet',
  'Boros Signet',
  'Talisman of Conviction',
  'Mind Stone',
  'Fellwar Stone',
  "Wayfarer's Bauble",
  'Thought Vessel',
  "Commander's Sphere",
  'Marble Diamond',
  'Fire Diamond',
  "Sensei's Divining Top",
  'Scroll Rack',
  'Library of Leng',
  'Brainstone',
  'Temple Bell',
  'Victory Chimes',
  'Faithless Looting',
  'Thrill of Possibility',
  'Big Score',
  'Unexpected Windfall',
  'Seize the Spoils',
  'Reckless Impulse',
  "Wrenn's Resolve",
  'Light Up the Stage',
  'Esper Sentinel',
  'Tocasia\'s Welcome',
  'Swords to Plowshares',
  'Path to Exile',
  'Generous Gift',
  'Chaos Warp',
  'Wear // Tear',
  'Blasphemous Act',
  'Austere Command',
  'Terminus',
  'Bonfire of the Damned',
  'Storm-Kiln Artist',
  'Monastery Mentor',
  'Young Pyromancer',
  'Primal Amulet // Primal Wellspring',
  "Pyromancer's Goggles",
  'Double Vision',
  "Sunbird's Invocation",
  'Arcane Bombardment',
  "Chandra, Hope's Beacon",
  'Approach of the Second Sun',
  'Storm Herd',
  'Rise of the Eldrazi',
  'Soulfire Eruption',
  'Apex of Power',
  'Volcanic Vision',
  'Creative Technique',
  'Dance with Calamity',
  'Call Forth the Tempest',
  "Brass's Bounty",
  'Hit the Mother Lode',
  "Mizzix's Mastery",
  'Boros Charm',
  'Swiftfoot Boots',
  'Lightning Greaves',
  'Teferi\'s Protection',
  'Reconstruct History',
];

int _fallbackPackagePriority(String packageKey, String role) {
  final normalized = '${packageKey.toLowerCase()} ${role.toLowerCase()}';
  if (normalized.contains('topdeck') || normalized.contains('miracle')) {
    return 0;
  }
  if (normalized.contains('big_spell') ||
      normalized.contains('haymaker') ||
      normalized.contains('payoff') ||
      normalized.contains('win_condition')) {
    return 1;
  }
  if (normalized.contains('ritual') ||
      normalized.contains('treasure') ||
      normalized.contains('spellslinger')) {
    return 2;
  }
  if (normalized.contains('interaction') ||
      normalized.contains('wipe') ||
      normalized.contains('reset') ||
      normalized.contains('protection')) {
    return 3;
  }
  if (normalized.contains('ramp') || normalized.contains('draw')) return 4;
  if (normalized.contains('recursion')) return 5;
  return 6;
}

List<String> _profileColorIdentity(Map<String, dynamic> profile) {
  final raw = profile['color_identity'];
  if (raw is! Iterable) return const [];
  final colors = raw
      .map((color) => color.toString().trim().toUpperCase())
      .where((color) => color.isNotEmpty)
      .toSet()
      .toList()
    ..sort();
  return colors;
}

List<Map<String, dynamic>> _buildBasicLandFallbackCards({
  required int total,
  required List<String> colors,
}) {
  if (total <= 0) return const [];

  const colorToBasic = <String, String>{
    'W': 'Plains',
    'U': 'Island',
    'B': 'Swamp',
    'R': 'Mountain',
    'G': 'Forest',
  };
  final basics = <String>[];
  for (final color in colors) {
    final land = colorToBasic[color.toUpperCase()];
    if (land != null) basics.add(land);
  }

  if (basics.isEmpty) basics.add('Wastes');

  final per = (total / basics.length).floor();
  final cards = <Map<String, dynamic>>[];
  for (final land in basics) {
    cards.add({'name': land, 'quantity': per});
  }

  var current =
      cards.fold<int>(0, (sum, card) => sum + (card['quantity'] as int));
  var i = 0;
  while (current < total) {
    cards[i % basics.length]['quantity'] =
        (cards[i % basics.length]['quantity'] as int) + 1;
    current++;
    i++;
  }

  return cards;
}

Map<String, dynamic>? _findResolvedCard(
  String cardName,
  Map<String, Map<String, dynamic>> resolvedCardsByName,
) {
  final aliases = commanderReferenceCardLookupAliases(cardName);
  for (final alias in aliases) {
    final direct = resolvedCardsByName[alias];
    if (direct != null) return direct;
  }
  final normalized = normalizeCommanderReferenceCardName(cardName);
  for (final entry in resolvedCardsByName.entries) {
    if (normalizeCommanderReferenceCardName(entry.key) == normalized) {
      return entry.value;
    }
    final resolvedName = entry.value['name']?.toString();
    if (resolvedName != null &&
        normalizeCommanderReferenceCardName(resolvedName) == normalized) {
      return entry.value;
    }
  }
  return null;
}

Iterable<String> _metadataStringIterable(dynamic raw) {
  if (raw == null) return const <String>[];
  if (raw is Iterable) return raw.map((value) => value.toString());
  return [raw.toString()];
}

Set<String> _profileAvoidExampleNames(Map<String, dynamic> profile) {
  final raw = profile['avoid_patterns'];
  if (raw is! Iterable) return const {};
  final names = <String>{};
  for (final item in raw) {
    if (item is! Map) continue;
    final examples = item['examples'];
    if (examples is! Iterable) continue;
    for (final rawExample in examples) {
      final name = normalizeCommanderReferenceCardName(rawExample.toString());
      if (name.isNotEmpty) names.add(name);
    }
  }
  return names;
}
