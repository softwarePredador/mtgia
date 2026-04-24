import 'meta_deck_card_list_support.dart';

class CommanderShellMetadata {
  const CommanderShellMetadata({
    this.commanderName,
    this.partnerCommanderName,
    this.shellLabel,
    this.strategyArchetype,
  });

  final String? commanderName;
  final String? partnerCommanderName;
  final String? shellLabel;
  final String? strategyArchetype;

  bool get hasCommanderShell =>
      (commanderName?.trim().isNotEmpty ?? false) ||
      (partnerCommanderName?.trim().isNotEmpty ?? false) ||
      (shellLabel?.trim().isNotEmpty ?? false);
}

CommanderShellMetadata deriveCommanderShellMetadata({
  required String format,
  required String cardList,
  String? rawArchetype,
}) {
  if (!isCommanderMetaFormat(format)) {
    return const CommanderShellMetadata();
  }

  final parsedCardList = parseMetaDeckCardList(
    cardList: cardList,
    format: format,
  );
  final commanders = _extractCommanderNames(
    sideboard: parsedCardList.sideboard,
    rawArchetype: rawArchetype,
  );

  final commanderName = commanders.isNotEmpty ? commanders.first : null;
  final partnerCommanderName = commanders.length > 1 ? commanders[1] : null;
  final shellLabel = _buildShellLabel(
    commanderName: commanderName,
    partnerCommanderName: partnerCommanderName,
    fallback: rawArchetype,
  );
  final strategyArchetype = parsedCardList.effectiveCards.isEmpty
      ? null
      : inferCommanderStrategyArchetypeFromCardNames(
          parsedCardList.effectiveCards.keys,
        );

  return CommanderShellMetadata(
    commanderName: commanderName,
    partnerCommanderName: partnerCommanderName,
    shellLabel: shellLabel,
    strategyArchetype: strategyArchetype,
  );
}

CommanderShellMetadata resolveCommanderShellMetadata({
  required String format,
  required String cardList,
  String? rawArchetype,
  String? commanderName,
  String? partnerCommanderName,
  String? shellLabel,
  String? strategyArchetype,
}) {
  final derived = deriveCommanderShellMetadata(
    format: format,
    cardList: cardList,
    rawArchetype: rawArchetype,
  );

  return CommanderShellMetadata(
    commanderName: _firstNonBlank(commanderName, derived.commanderName),
    partnerCommanderName:
        _firstNonBlank(partnerCommanderName, derived.partnerCommanderName),
    shellLabel: _firstNonBlank(shellLabel, derived.shellLabel),
    strategyArchetype:
        _firstNonBlank(strategyArchetype, derived.strategyArchetype),
  );
}

bool metaDeckNeedsCommanderShellRefresh({
  required String format,
  required CommanderShellMetadata expected,
  String? commanderName,
  String? partnerCommanderName,
  String? shellLabel,
  String? strategyArchetype,
}) {
  if (!isCommanderMetaFormat(format)) return false;

  return _normalizedNullable(commanderName) !=
          _normalizedNullable(expected.commanderName) ||
      _normalizedNullable(partnerCommanderName) !=
          _normalizedNullable(expected.partnerCommanderName) ||
      _normalizedNullable(shellLabel) != _normalizedNullable(expected.shellLabel) ||
      _normalizedNullable(strategyArchetype) !=
          _normalizedNullable(expected.strategyArchetype);
}

String inferCommanderStrategyArchetypeFromCardNames(Iterable<String> cardNames) {
  final lower = cardNames
      .map((card) => card.toLowerCase().trim())
      .where((card) => card.isNotEmpty)
      .toSet();
  if (lower.isEmpty) return 'midrange';

  var controlScore = 0;
  var aggroScore = 0;
  var comboScore = 0;
  var midrangeScore = 0;
  var rampValueScore = 0;
  var tribalScore = 0;
  var aristocratsScore = 0;
  var tokensScore = 0;

  const controlKeywords = [
    'counterspell',
    'negate',
    'mana leak',
    'force of will',
    'force of negation',
    'cryptic command',
    'supreme verdict',
    'wrath of god',
    'damnation',
    'cyclonic rift',
    'teferi',
    'jace',
    'narset',
    'dovin\'s veto',
    'archmage\'s charm',
    'mystic confluence',
    'fierce guardianship',
  ];

  const aggroKeywords = [
    'lightning bolt',
    'goblin guide',
    'monastery swiftspear',
    'ragavan',
    'eidolon of the great revel',
    'lava spike',
    'chain lightning',
    'goblin',
    'haste',
    'sligh',
    'burn',
    'zurgo',
    'najeela',
    'winota',
  ];

  const comboKeywords = [
    'thassa\'s oracle',
    'demonic consultation',
    'tainted pact',
    'doomsday',
    'ad nauseam',
    'aetherflux reservoir',
    'isochron scepter',
    'dramatic reversal',
    'infinite',
    'thoracle',
    'underworld breach',
    'brain freeze',
    'grinding station',
    'basalt monolith',
    'rings of brighthearth',
  ];

  const rampKeywords = [
    'sol ring',
    'mana crypt',
    'arcane signet',
    'cultivate',
    'kodama\'s reach',
    'rampant growth',
    'three visits',
    'nature\'s lore',
    'signets',
    'talismans',
    'dockside extortionist',
    'smothering tithe',
  ];

  const aristocratsKeywords = [
    'blood artist',
    'zulaport cutthroat',
    'viscera seer',
    'carrion feeder',
    'phyrexian altar',
    'ashnod\'s altar',
    'grave pact',
    'dictate of erebos',
    'pitiless plunderer',
    'teysa',
    'korvold',
    'prossh',
  ];

  const tokensKeywords = [
    'anointed procession',
    'doubling season',
    'parallel lives',
    'second harvest',
    'populate',
    'divine visitation',
    'krenko',
    'adeline',
    'rabble rousing',
    'rhys the redeemed',
    'tendershoot dryad',
    'avenger of zendikar',
  ];

  const tribalKeywords = [
    'lord',
    'kindred',
    'coat of arms',
    'metallic mimic',
    'icon of ancestry',
    'vanquisher\'s banner',
    'herald\'s horn',
  ];

  for (final card in lower) {
    for (final keyword in controlKeywords) {
      if (card.contains(keyword)) controlScore += 2;
    }
    if (card.contains('counter') && !card.contains('+1/+1')) controlScore++;
    if (card.contains('wrath') || card.contains('verdict')) controlScore += 2;

    for (final keyword in aggroKeywords) {
      if (card.contains(keyword)) aggroScore += 2;
    }
    if (card.contains('bolt') || card.contains('burn')) aggroScore++;

    for (final keyword in comboKeywords) {
      if (card.contains(keyword)) comboScore += 3;
    }

    for (final keyword in rampKeywords) {
      if (card.contains(keyword)) rampValueScore++;
    }
    if (card.contains('signet') || card.contains('talisman')) {
      rampValueScore++;
    }

    for (final keyword in aristocratsKeywords) {
      if (card.contains(keyword)) aristocratsScore += 2;
    }

    for (final keyword in tokensKeywords) {
      if (card.contains(keyword)) tokensScore += 2;
    }

    for (final keyword in tribalKeywords) {
      if (card.contains(keyword)) tribalScore++;
    }
    if (card.contains('sliver') ||
        card.contains('elf') ||
        card.contains('goblin') ||
        card.contains('zombie') ||
        card.contains('dragon')) {
      tribalScore++;
    }

    if (card.contains('value') ||
        card.contains('draw') ||
        card.contains('etb') ||
        card.contains('graveyard') ||
        card.contains('recursion') ||
        card.contains('midrange')) {
      midrangeScore++;
    }
  }

  final scores = <String, int>{
    'combo': comboScore,
    'control': controlScore,
    'aggro': aggroScore,
    'ramp_value': rampValueScore,
    'aristocrats': aristocratsScore,
    'tokens': tokensScore,
    'tribal': tribalScore,
    'midrange': midrangeScore,
  };

  final best = scores.entries.toList()
    ..sort((a, b) {
      final byScore = b.value.compareTo(a.value);
      if (byScore != 0) return byScore;
      return a.key.compareTo(b.key);
    });

  if (best.isEmpty || best.first.value <= 0) {
    return 'midrange';
  }
  return best.first.key;
}

List<String> extractCommanderNamesFromShellLabel(String? rawArchetype) {
  final normalized = (rawArchetype ?? '').trim();
  if (normalized.isEmpty) return const <String>[];

  final split = normalized
      .split(RegExp(r'\s*(?:\+|&)\s*'))
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .toList(growable: false);

  if (split.isEmpty) return const <String>[];
  if (split.length == 1) return <String>[split.first];
  return split.take(2).toList(growable: false);
}

List<String> _extractCommanderNames({
  required Map<String, int> sideboard,
  required String? rawArchetype,
}) {
  final commanders = sideboard.entries
      .where((entry) => entry.key.trim().isNotEmpty && entry.value > 0)
      .map((entry) => entry.key.trim())
      .take(2)
      .toList(growable: false);
  if (commanders.isNotEmpty) return commanders;
  return extractCommanderNamesFromShellLabel(rawArchetype);
}

String? _buildShellLabel({
  required String? commanderName,
  required String? partnerCommanderName,
  required String? fallback,
}) {
  final primary = _normalizedNullable(commanderName);
  final partner = _normalizedNullable(partnerCommanderName);
  if (primary != null && partner != null) return '$primary + $partner';
  if (primary != null) return primary;
  return _normalizedNullable(fallback);
}

String? _firstNonBlank(String? preferred, String? fallback) {
  return _normalizedNullable(preferred) ?? _normalizedNullable(fallback);
}

String? _normalizedNullable(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  return trimmed;
}
