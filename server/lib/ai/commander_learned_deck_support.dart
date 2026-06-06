class CommanderLearnedDeckInput {
  CommanderLearnedDeckInput({
    required this.commanderName,
    required this.deckName,
    required this.sourceSystem,
    required this.sourceRef,
    required this.cardList,
    required this.cardCount,
    this.sourceUrl,
    this.archetype,
    this.score,
    this.winconPrimary,
    this.winconBackup,
    this.legalStatus,
    this.notes,
    this.metadata = const <String, dynamic>{},
    this.isActive = true,
    this.promotedAt,
    this.updatedAt,
  });

  final String commanderName;
  final String deckName;
  final String sourceSystem;
  final String sourceRef;
  final String? sourceUrl;
  final String? archetype;
  final String cardList;
  final int cardCount;
  final double? score;
  final String? winconPrimary;
  final String? winconBackup;
  final String? legalStatus;
  final String? notes;
  final Map<String, dynamic> metadata;
  final bool isActive;
  final DateTime? promotedAt;
  final DateTime? updatedAt;

  late final List<CommanderLearnedDeckCard> cards =
      parseCommanderLearnedDeckCards(cardList);
}

class CommanderLearnedDeckCard {
  const CommanderLearnedDeckCard({
    required this.name,
    required this.quantity,
  });

  final String name;
  final int quantity;
}

List<CommanderLearnedDeckCard> parseCommanderLearnedDeckCards(String cardList) {
  final cards = <CommanderLearnedDeckCard>[];
  final byName = <String, int>{};

  for (final rawLine in cardList.split(RegExp(r'\r?\n'))) {
    final line = rawLine.trim();
    if (line.isEmpty || line.startsWith('#')) continue;

    final parsed = _parseCardLine(line);
    if (parsed == null) continue;
    byName[parsed.name] = (byName[parsed.name] ?? 0) + parsed.quantity;
  }

  for (final entry in byName.entries) {
    cards.add(
      CommanderLearnedDeckCard(
        name: entry.key,
        quantity: entry.value,
      ),
    );
  }
  return cards;
}

CommanderLearnedDeckCard? _parseCardLine(String line) {
  final withoutBullet = line.replaceFirst(RegExp(r'^[-*]\s+'), '').trim();
  final match = RegExp(r'^(\d+)\s+(.+)$').firstMatch(withoutBullet);
  if (match != null) {
    final quantity = int.tryParse(match.group(1) ?? '') ?? 0;
    final name = _cleanCardName(match.group(2) ?? '');
    if (quantity > 0 && name.isNotEmpty) {
      return CommanderLearnedDeckCard(name: name, quantity: quantity);
    }
  }

  final name = _cleanCardName(withoutBullet);
  if (name.isEmpty) return null;
  return CommanderLearnedDeckCard(name: name, quantity: 1);
}

String _cleanCardName(String value) {
  var name = value.trim();
  name = name.replaceFirst(RegExp(r'\s+\[[^\]]+\]$'), '');
  name = name.replaceFirst(RegExp(r'\s+\([A-Z0-9]{2,5}\)\s*\d*\s*$'), '');
  name = name.replaceFirst(RegExp(r'\s+#.*$'), '');
  return name.trim();
}
