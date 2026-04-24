import 'dart:convert';

class EdhTop16TournamentEntry {
  const EdhTop16TournamentEntry({
    required this.standing,
    required this.decklistUrl,
    required this.playerName,
    required this.commanderLabel,
  });

  final int? standing;
  final String decklistUrl;
  final String? playerName;
  final String? commanderLabel;
}

class ExpandedTopDeckDeck {
  const ExpandedTopDeckDeck({
    required this.commanders,
    required this.mainboard,
    required this.cardList,
    required this.importedFrom,
  });

  final List<ExpandedDeckCard> commanders;
  final List<ExpandedDeckCard> mainboard;
  final String cardList;
  final String? importedFrom;

  int get commanderCount => _sumCards(commanders);
  int get mainboardCount => _sumCards(mainboard);
  int get totalCards => commanderCount + mainboardCount;
  List<String> get commanderNames =>
      commanders.map((card) => card.name).toList();
}

class ExpandedDeckCard {
  const ExpandedDeckCard({required this.name, required this.quantity});

  final String name;
  final int quantity;
}

String edhTop16TournamentIdFromUrl(String sourceUrl) {
  final uri = Uri.parse(sourceUrl);
  final segments = uri.pathSegments;
  final tournamentIndex = segments.indexOf('tournament');
  if (tournamentIndex < 0 || tournamentIndex + 1 >= segments.length) {
    throw FormatException(
      'URL EDHTop16 precisa seguir /tournament/<slug>: $sourceUrl',
    );
  }
  final tid = segments[tournamentIndex + 1].trim();
  if (tid.isEmpty) {
    throw FormatException('TID EDHTop16 vazio em: $sourceUrl');
  }
  return tid;
}

List<EdhTop16TournamentEntry> parseEdhTop16TournamentEntries(
  Map<String, dynamic> graphqlPayload,
) {
  final tournament = (graphqlPayload['data'] as Map?)?['tournament'] as Map?;
  final rawEntries = tournament?['entries'] as List?;
  if (rawEntries == null) return const <EdhTop16TournamentEntry>[];

  return rawEntries
      .whereType<Map>()
      .map((entry) {
        final decklistUrl = entry['decklist']?.toString().trim() ?? '';
        if (decklistUrl.isEmpty) return null;

        return EdhTop16TournamentEntry(
          standing: _intOrNull(entry['standing']),
          decklistUrl: decklistUrl,
          playerName: _nestedString(entry, 'player', 'name'),
          commanderLabel: _nestedString(entry, 'commander', 'name'),
        );
      })
      .whereType<EdhTop16TournamentEntry>()
      .toList(growable: false);
}

ExpandedTopDeckDeck parseTopDeckDeckObjectFromHtml(String html) {
  const startMarker = 'const deckObj = ';
  final start = html.indexOf(startMarker);
  if (start < 0) {
    throw const FormatException('TopDeck deck page nao contem const deckObj.');
  }

  final jsonStart = html.indexOf('{', start + startMarker.length);
  if (jsonStart < 0) {
    throw const FormatException('TopDeck deckObj nao contem objeto JSON.');
  }
  final jsonEnd = _findBalancedJsonObjectEnd(html, jsonStart);
  final decoded = jsonDecode(html.substring(jsonStart, jsonEnd + 1));
  if (decoded is! Map<String, dynamic>) {
    throw const FormatException('TopDeck deckObj nao e objeto JSON.');
  }
  return parseTopDeckDeckObject(decoded);
}

int _findBalancedJsonObjectEnd(String value, int startIndex) {
  var depth = 0;
  var inString = false;
  var escaping = false;

  for (var i = startIndex; i < value.length; i++) {
    final char = value[i];

    if (inString) {
      if (escaping) {
        escaping = false;
      } else if (char == r'\') {
        escaping = true;
      } else if (char == '"') {
        inString = false;
      }
      continue;
    }

    if (char == '"') {
      inString = true;
      continue;
    }
    if (char == '{') {
      depth++;
      continue;
    }
    if (char == '}') {
      depth--;
      if (depth == 0) return i;
      if (depth < 0) break;
    }
  }

  throw const FormatException(
      'TopDeck deckObj JSON nao terminou corretamente.');
}

ExpandedTopDeckDeck parseTopDeckDeckObject(Map<String, dynamic> deckObj) {
  final commanders = _parseDeckCards(deckObj['Commanders']);
  final mainboard = _parseDeckCards(deckObj['Mainboard']);
  final allCards = <ExpandedDeckCard>[...commanders, ...mainboard];

  final cardList =
      allCards.map((card) => '${card.quantity} ${card.name}').join('\n').trim();

  final metadata = deckObj['metadata'];
  final importedFrom =
      metadata is Map ? metadata['importedFrom']?.toString() : null;

  return ExpandedTopDeckDeck(
    commanders: commanders,
    mainboard: mainboard,
    cardList: cardList,
    importedFrom: importedFrom,
  );
}

Map<String, dynamic> buildExternalCommanderCandidateFromExpansion({
  required String tournamentUrl,
  required String tournamentId,
  required EdhTop16TournamentEntry entry,
  required ExpandedTopDeckDeck expandedDeck,
}) {
  final standing = entry.standing;
  final commanderNames = expandedDeck.commanderNames;

  return <String, dynamic>{
    'source_name': 'EDHTop16',
    'source_url': '$tournamentUrl#standing-${standing ?? 'unknown'}',
    'deck_name': _deckNameForEntry(entry, commanderNames),
    'commander_name': commanderNames.isNotEmpty ? commanderNames.first : null,
    'partner_commander_name': commanderNames.length > 1
        ? commanderNames.sublist(1).join(' + ')
        : null,
    'format': 'commander',
    'subformat': 'competitive_commander',
    'archetype': commanderNames.isNotEmpty
        ? commanderNames.join(' + ')
        : entry.commanderLabel,
    'placement': standing?.toString(),
    'card_list': expandedDeck.cardList,
    'validation_status': 'candidate',
    'validation_notes':
        'Expanded by dry-run from EDHTop16 GraphQL -> TopDeck deck page. Commander legality not independently verified.',
    'research_payload': <String, dynamic>{
      'collection_method': 'edhtop16_graphql_topdeck_deck_page_dry_run',
      'source_context': 'edhtop16_tournament_entry',
      'source_chain': <String>['edhtop16_graphql', 'topdeck_deck_page'],
      'tournament_id': tournamentId,
      'tournament_url': tournamentUrl,
      'topdeck_deck_url': entry.decklistUrl,
      'player_name': entry.playerName,
      'standing': standing,
      'topdeck_imported_from': expandedDeck.importedFrom,
      'commander_count': expandedDeck.commanderCount,
      'mainboard_count': expandedDeck.mainboardCount,
      'total_cards': expandedDeck.totalCards,
    },
  };
}

List<ExpandedDeckCard> _parseDeckCards(dynamic raw) {
  if (raw is! List) return const <ExpandedDeckCard>[];

  return raw
      .whereType<Map>()
      .map((card) {
        final name = card['name']?.toString().trim() ?? '';
        final quantity = _intOrNull(card['count']) ?? 1;
        if (name.isEmpty || quantity <= 0) return null;
        return ExpandedDeckCard(name: name, quantity: quantity);
      })
      .whereType<ExpandedDeckCard>()
      .toList(growable: false);
}

String _deckNameForEntry(
  EdhTop16TournamentEntry entry,
  List<String> commanderNames,
) {
  if (commanderNames.isNotEmpty) return commanderNames.join(' + ');
  final label = entry.commanderLabel?.trim();
  if (label != null && label.isNotEmpty) return label;
  final player = entry.playerName?.trim();
  if (player != null && player.isNotEmpty) return '$player cEDH Deck';
  return 'EDHTop16 cEDH Deck';
}

int _sumCards(List<ExpandedDeckCard> cards) {
  return cards.fold<int>(0, (total, card) => total + card.quantity);
}

int? _intOrNull(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

String? _nestedString(Map entry, String objectKey, String fieldKey) {
  final nested = entry[objectKey];
  if (nested is! Map) return null;
  final value = nested[fieldKey]?.toString().trim();
  return value == null || value.isEmpty ? null : value;
}
