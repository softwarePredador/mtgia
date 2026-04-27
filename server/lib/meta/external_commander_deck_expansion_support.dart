import 'dart:convert';

import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;

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

Future<Map<String, dynamic>> buildEdhTop16ExpansionArtifact({
  required String sourceUrl,
  required int targetValid,
  required int maxStanding,
  http.Client? client,
}) async {
  if (targetValid <= 0) {
    throw ArgumentError('targetValid precisa ser maior que zero.');
  }
  if (maxStanding <= 0) {
    throw ArgumentError('maxStanding precisa ser maior que zero.');
  }
  if (maxStanding < targetValid) {
    throw ArgumentError('maxStanding precisa ser >= targetValid.');
  }

  final tournamentId = edhTop16TournamentIdFromUrl(sourceUrl);
  final graphqlPayload = await fetchEdhTop16TournamentPayload(
    tournamentId: tournamentId,
    limit: maxStanding,
    client: client,
  );
  final entries = parseEdhTop16TournamentEntries(graphqlPayload);

  final results = <Map<String, dynamic>>[];
  var expandedCount = 0;
  for (final entry in entries.take(maxStanding)) {
    if (expandedCount >= targetValid) {
      break;
    }
    final result = await expandEdhTop16TournamentEntry(
      tournamentUrl: sourceUrl,
      tournamentId: tournamentId,
      entry: entry,
      client: client,
    );
    results.add(result);
    if (result['expansion_status'] == 'expanded') {
      expandedCount++;
    }
  }

  final rejectedCount = results.length - expandedCount;
  final goalReached = expandedCount >= targetValid;
  final candidates = results
      .where((result) => result['expansion_status'] == 'expanded')
      .map((result) => result['candidate'])
      .whereType<Map<String, dynamic>>()
      .toList(growable: false);

  return <String, dynamic>{
    'generated_at': DateTime.now().toUtc().toIso8601String(),
    'mode': 'dry_run',
    'source_name': 'EDHTop16',
    'source_url': sourceUrl,
    'event_tid': tournamentId,
    'expansion_path': const <String>[
      'edhtop16_graphql',
      'topdeck_deck_page',
    ],
    'target_valid_count': targetValid,
    'max_standing_scanned': maxStanding,
    'entries_available': entries.length,
    'attempted_count': results.length,
    'goal_reached': goalReached,
    'stop_reason': goalReached ? 'target_valid_reached' : 'entries_exhausted',
    'expanded_count': expandedCount,
    'rejected_count': rejectedCount,
    'candidates': candidates,
    'results': results,
  };
}

Future<Map<String, dynamic>> fetchEdhTop16TournamentPayload({
  required String tournamentId,
  required int limit,
  http.Client? client,
}) async {
  const query = r'''
query($tid: String!, $maxStanding: Int!) {
  tournament(TID: $tid) {
    TID
    name
    size
    entries(maxStanding: $maxStanding) {
      standing
      decklist
      player { name }
      commander { name }
    }
  }
}
''';

  final ownedClient = client ?? http.Client();
  try {
    final response = await ownedClient
        .post(
          Uri.parse('https://edhtop16.com/api/graphql'),
          headers: const <String, String>{
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode(<String, dynamic>{
            'query': query,
            'variables': <String, dynamic>{
              'tid': tournamentId,
              'maxStanding': limit,
            },
          }),
        )
        .timeout(const Duration(seconds: 25));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        'EDHTop16 GraphQL falhou: HTTP ${response.statusCode} '
        '${response.body.substring(0, response.body.length.clamp(0, 200))}',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Resposta GraphQL nao e objeto JSON.');
    }
    if (decoded['errors'] != null) {
      throw StateError(
          'EDHTop16 GraphQL retornou errors: ${decoded['errors']}');
    }
    return decoded;
  } finally {
    if (client == null) {
      ownedClient.close();
    }
  }
}

Future<Map<String, dynamic>> expandEdhTop16TournamentEntry({
  required String tournamentUrl,
  required String tournamentId,
  required EdhTop16TournamentEntry entry,
  http.Client? client,
}) async {
  final deckUri = Uri.tryParse(entry.decklistUrl);
  if (deckUri == null ||
      deckUri.host.toLowerCase().replaceFirst('www.', '') != 'topdeck.gg' ||
      !deckUri.path.startsWith('/deck/')) {
    return rejectedEdhTop16TournamentEntry(
      entry,
      'decklist_not_topdeck_deck_page',
    );
  }

  final ownedClient = client ?? http.Client();
  try {
    final response = await ownedClient.get(
      deckUri,
      headers: const <String, String>{'Accept': 'text/html'},
    ).timeout(const Duration(seconds: 25));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return rejectedEdhTop16TournamentEntry(
        entry,
        'topdeck_http_${response.statusCode}',
      );
    }

    final expandedDeck = parseTopDeckDeckObjectFromHtml(response.body);
    if (expandedDeck.commanderCount <= 0) {
      return rejectedEdhTop16TournamentEntry(entry, 'missing_commanders');
    }
    if (expandedDeck.totalCards != 100) {
      return rejectedEdhTop16TournamentEntry(
        entry,
        'invalid_total_cards_${expandedDeck.totalCards}',
      );
    }

    return <String, dynamic>{
      'expansion_status': 'expanded',
      'source_name': 'EDHTop16',
      'source_url': tournamentUrl,
      'event_tid': tournamentId,
      'standing': entry.standing,
      'player_name': entry.playerName,
      'deck_url': entry.decklistUrl,
      'commanders': expandedDeck.commanderNames,
      'mainboard_count': expandedDeck.mainboardCount,
      'commander_count': expandedDeck.commanderCount,
      'total_cards': expandedDeck.totalCards,
      'card_list': expandedDeck.cardList,
      'candidate': buildExternalCommanderCandidateFromExpansion(
        tournamentUrl: tournamentUrl,
        tournamentId: tournamentId,
        entry: entry,
        expandedDeck: expandedDeck,
      ),
    };
  } on FormatException catch (error) {
    final message = error.message.toLowerCase();
    if (message.contains('deckobj')) {
      return rejectedEdhTop16TournamentEntry(entry, 'topdeck_deckobj_missing');
    }
    return rejectedEdhTop16TournamentEntry(entry, 'topdeck_parse_error');
  } catch (error) {
    return rejectedEdhTop16TournamentEntry(
      entry,
      'exception_${error.runtimeType}',
    );
  } finally {
    if (client == null) {
      ownedClient.close();
    }
  }
}

Map<String, dynamic> rejectedEdhTop16TournamentEntry(
  EdhTop16TournamentEntry entry,
  String reason,
) {
  return <String, dynamic>{
    'expansion_status': 'rejected',
    'rejection_reason': reason,
    'standing': entry.standing,
    'player_name': entry.playerName,
    'deck_url': entry.decklistUrl,
  };
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
  final deckFromObject = _tryParseEmbeddedTopDeckDeckObject(html);
  if (deckFromObject != null) return deckFromObject;

  final deckFromClipboard = _tryParseTopDeckCopyDecklist(html);
  if (deckFromClipboard != null) return deckFromClipboard;

  final deckFromRenderedHtml = _tryParseRenderedTopDeckDeck(html);
  if (deckFromRenderedHtml != null) return deckFromRenderedHtml;

  throw const FormatException(
    'TopDeck deck page nao contem const deckObj nem decklist renderizada.',
  );
}

ExpandedTopDeckDeck? _tryParseEmbeddedTopDeckDeckObject(String html) {
  const startMarker = 'const deckObj = ';
  final start = html.indexOf(startMarker);
  if (start < 0) return null;

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

ExpandedTopDeckDeck? _tryParseTopDeckCopyDecklist(String html) {
  const startMarker = 'const decklistContent = `';
  final start = html.indexOf(startMarker);
  if (start < 0) return null;

  final contentStart = start + startMarker.length;
  final contentEnd = _findTemplateLiteralEnd(html, contentStart);
  final decklistContent = html.substring(contentStart, contentEnd);
  final importedFrom = _extractImportedFrom(html);
  return _parseTopDeckDeckFromDecklistText(
    decklistContent,
    importedFrom: importedFrom,
  );
}

ExpandedTopDeckDeck? _tryParseRenderedTopDeckDeck(String html) {
  final document = html_parser.parse(html);
  final commanderLines = document
      .querySelectorAll('.commanders-sidebar .card-name-text')
      .map((node) => _normalizeDeckText(node.text))
      .where((line) => line.isNotEmpty)
      .toList(growable: false);
  final mainboardLines = document
      .querySelectorAll('.deck-main .text-list-item .card-name-text')
      .map((node) => _normalizeDeckText(node.text))
      .where((line) => line.isNotEmpty)
      .toList(growable: false);
  if (commanderLines.isEmpty || mainboardLines.isEmpty) return null;

  final decklistContent = [
    '~~Commanders~~',
    ...commanderLines,
    '',
    '~~Mainboard~~',
    ...mainboardLines,
  ].join('\n');
  return _parseTopDeckDeckFromDecklistText(
    decklistContent,
    importedFrom: _extractImportedFrom(html),
  );
}

ExpandedTopDeckDeck _parseTopDeckDeckFromDecklistText(
  String decklistContent, {
  String? importedFrom,
}) {
  final commanders = <ExpandedDeckCard>[];
  final mainboard = <ExpandedDeckCard>[];
  var section = 'unknown';

  for (final rawLine in decklistContent.split('\n')) {
    final line = rawLine.trim();
    if (line.isEmpty) continue;

    final normalizedSection = _normalizeDeckSection(line);
    if (normalizedSection != null) {
      section = normalizedSection;
      continue;
    }

    final parsedCard = _parseExpandedDeckCardFromText(line);
    if (parsedCard == null) continue;

    if (section == 'commanders') {
      commanders.add(parsedCard);
    } else if (section == 'mainboard') {
      mainboard.add(parsedCard);
    }
  }

  if (commanders.isEmpty || mainboard.isEmpty) {
    throw const FormatException(
      'TopDeck decklistContent nao contem sections Commanders/Mainboard validas.',
    );
  }

  final allCards = <ExpandedDeckCard>[...commanders, ...mainboard];
  final cardList =
      allCards.map((card) => '${card.quantity} ${card.name}').join('\n').trim();

  return ExpandedTopDeckDeck(
    commanders: commanders,
    mainboard: mainboard,
    cardList: cardList,
    importedFrom: importedFrom,
  );
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

int _findTemplateLiteralEnd(String value, int startIndex) {
  var escaping = false;

  for (var i = startIndex; i < value.length; i++) {
    final char = value[i];
    if (escaping) {
      escaping = false;
      continue;
    }
    if (char == r'\') {
      escaping = true;
      continue;
    }
    if (char == '`') return i;
  }

  throw const FormatException(
    'TopDeck decklistContent nao terminou corretamente.',
  );
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

ExpandedDeckCard? _parseExpandedDeckCardFromText(String line) {
  final match = RegExp(r'^(\d+)\s+(.+)$').firstMatch(line);
  if (match == null) return null;

  final quantity = int.tryParse(match.group(1) ?? '') ?? 0;
  final name = match.group(2)?.trim() ?? '';
  if (quantity <= 0 || name.isEmpty) return null;

  return ExpandedDeckCard(name: name, quantity: quantity);
}

String? _normalizeDeckSection(String line) {
  if (!line.startsWith('~~') || !line.endsWith('~~')) return null;
  final normalized = line.replaceAll('~', '').trim().toLowerCase();
  if (normalized.contains('commander')) return 'commanders';
  if (normalized.contains('mainboard') || normalized == 'deck') {
    return 'mainboard';
  }
  return 'ignore';
}

String _normalizeDeckText(String raw) {
  return raw.replaceAll(RegExp(r'\s+'), ' ').trim();
}

String? _extractImportedFrom(String html) {
  final importedFromMatch = RegExp(
    r'href="(https://(?:www\.)?moxfield\.com/decks/[^"]+)"',
    caseSensitive: false,
  ).firstMatch(html);
  final importedFrom = importedFromMatch?.group(1)?.trim();
  if (importedFrom != null && importedFrom.isNotEmpty) {
    return importedFrom;
  }

  return null;
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
