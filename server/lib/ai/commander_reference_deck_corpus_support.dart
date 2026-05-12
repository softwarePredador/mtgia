import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:postgres/postgres.dart';

import '../color_identity.dart';
import '../import_card_lookup_service.dart';
import 'commander_reference_card_stats_support.dart';

const commanderReferenceDecksTable = 'commander_reference_decks';
const commanderReferenceDeckCardsTable = 'commander_reference_deck_cards';
const commanderReferenceDeckAnalysisTable = 'commander_reference_deck_analysis';

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
  final material = jsonEncode({
    'source': guidance.source,
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
    'theme_counts': guidance.themeCounts,
  });
  return 'reference_deck_corpus_v1:${sha256.convert(utf8.encode(material)).toString().substring(0, 12)}';
}

String buildCommanderReferenceDeckCorpusPrompt(
  CommanderReferenceDeckCorpusGuidance? guidance,
) {
  if (guidance == null || !guidance.isUsable) return '';
  final roleLines = guidance.averageRoleCounts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  final roles = roleLines
      .take(10)
      .map((entry) => '- ${entry.key}: ${entry.value.toStringAsFixed(1)} avg')
      .join('\n');
  final recurrentCards = guidance.topCards
      .take(18)
      .map((card) {
        final name = card['card_name']?.toString();
        final deckCount = _intValue(card['deck_count']);
        final role = card['role']?.toString();
        if (name == null || name.isEmpty) return null;
        return '$name${role == null || role.isEmpty ? '' : ' [$role]'} ($deckCount/${guidance.acceptedDeckCount})';
      })
      .whereType<String>()
      .join(', ');

  return '''
Reference deck corpus v1 active for ${guidance.commanderName}:
- Corpus size: ${guidance.acceptedDeckCount} accepted public reference decks.
- Use this as aggregate structure only, not as a decklist to copy.
- Average role shape:
$roles
- Recurrent package/card signals: $recurrentCards.
- Keep final deck coherent and legal; do not force every recurrent card.
''';
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
  if (oracle.contains('destroy target') ||
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
    for (final row in analysis.cardRows) {
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
          ) VALUES (
            @source_deck_key,
            @board,
            @card_name,
            @card_name_normalized,
            CAST(@card_id AS uuid),
            @quantity,
            @role,
            @unresolved,
            @off_color,
            NOW()
          )
        '''),
        parameters: row,
      );
    }
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
