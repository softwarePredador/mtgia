import 'commander_reference_card_stats_support.dart';
import 'commander_reference_deck_corpus_support.dart';
import 'commander_reference_profile_support.dart';
import '../color_identity.dart';

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
  int targetMainQuantity = 99,
}) {
  final commanderName =
      (profile['commander'] ?? profile['commander_name'] ?? '')
          .toString()
          .trim();
  final nonLands = <String>[];
  final seen = <String>{};
  final avoidedExampleNames = _profileAvoidExampleNames(profile);

  void addCard(String? rawName) {
    final name = rawName?.trim();
    if (name == null || name.isEmpty) return;
    final normalizedName = normalizeCommanderReferenceCardName(name);
    if (normalizedName == normalizeCommanderReferenceCardName(commanderName)) {
      return;
    }
    if (avoidedExampleNames.contains(normalizedName)) {
      return;
    }
    if (basicLandNames.contains(normalizedName)) {
      return;
    }
    if (!seen.add(normalizedName)) return;
    nonLands.add(name);
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
    addCard(stat.cardName);
  }

  final corpusPackages = referenceDeckCorpusGuidance?.packages;
  for (final package in [
    if (corpusPackages != null) corpusPackages.corePackage,
    if (corpusPackages != null) corpusPackages.themePackage,
    if (corpusPackages != null) corpusPackages.supportPackage,
  ]) {
    for (final card in package) {
      addCard(card['card_name']?.toString());
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
        addCard(rawCard.toString());
      }
    }
  }

  if (isLoreholdCommanderReferenceCandidate(commanderName)) {
    for (final name in loreholdDeterministicReferenceFallbackCards) {
      addCard(name);
    }
  }

  final cappedNonLands = nonLands.take(targetMainQuantity).toList();
  final colors = _profileColorIdentity(profile);
  final basics = _buildBasicLandFallbackCards(
    total: targetMainQuantity - cappedNonLands.length,
    colors: colors.isEmpty ? const ['W'] : colors,
  );

  return {
    'commander': {
      'name': commanderName.isEmpty ? 'Isamaru, Hound of Konda' : commanderName
    },
    'cards': [
      for (final name in cappedNonLands) {'name': name, 'quantity': 1},
      ...basics,
    ],
  };
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
