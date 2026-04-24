const commanderMetaFormats = {'EDH', 'cEDH'};

class ParsedMetaDeckCardList {
  ParsedMetaDeckCardList({
    required this.mainboard,
    required this.sideboard,
    required this.effectiveCards,
    required this.includesSideboardAsCommanderZone,
  });

  final Map<String, int> mainboard;
  final Map<String, int> sideboard;
  final Map<String, int> effectiveCards;
  final bool includesSideboardAsCommanderZone;

  int get mainboardTotal => _sumQuantities(mainboard);
  int get sideboardTotal => _sumQuantities(sideboard);
  int get effectiveTotal => _sumQuantities(effectiveCards);
}

ParsedMetaDeckCardList parseMetaDeckCardList({
  required String cardList,
  required String format,
}) {
  final mainboard = <String, int>{};
  final sideboard = <String, int>{};
  var inSideboard = false;

  for (final rawLine in cardList.split('\n')) {
    final line = rawLine.trim();
    if (line.isEmpty) continue;

    if (line.toLowerCase().contains('sideboard')) {
      inSideboard = true;
      continue;
    }

    final entry = parseMetaDeckCardLine(line);
    if (entry == null) continue;

    final target = inSideboard ? sideboard : mainboard;
    target[entry.name] = (target[entry.name] ?? 0) + entry.quantity;
  }

  final includesSideboardAsCommanderZone = isCommanderMetaFormat(format);
  final effectiveCards = <String, int>{...mainboard};
  if (includesSideboardAsCommanderZone) {
    for (final entry in sideboard.entries) {
      effectiveCards[entry.key] =
          (effectiveCards[entry.key] ?? 0) + entry.value;
    }
  }

  return ParsedMetaDeckCardList(
    mainboard: mainboard,
    sideboard: sideboard,
    effectiveCards: effectiveCards,
    includesSideboardAsCommanderZone: includesSideboardAsCommanderZone,
  );
}

bool isCommanderMetaFormat(String format) {
  return commanderMetaFormats.contains(format.trim());
}

ParsedMetaDeckCardEntry? parseMetaDeckCardLine(String line) {
  final match = RegExp(r'^(\d+)x?\s+(.+)$').firstMatch(line.trim());
  if (match == null) return null;

  final quantity = int.tryParse(match.group(1) ?? '0') ?? 0;
  if (quantity <= 0) return null;

  final name = normalizeMetaDeckCardName(match.group(2) ?? '');
  if (name.isEmpty) return null;

  return ParsedMetaDeckCardEntry(name: name, quantity: quantity);
}

String normalizeMetaDeckCardName(String value) {
  return value.replaceAll(RegExp(r'\s*\([^)]+\)\s*$'), '').trim();
}

int _sumQuantities(Map<String, int> cards) {
  return cards.values.fold<int>(0, (sum, quantity) => sum + quantity);
}

class ParsedMetaDeckCardEntry {
  ParsedMetaDeckCardEntry({required this.name, required this.quantity});

  final String name;
  final int quantity;
}
