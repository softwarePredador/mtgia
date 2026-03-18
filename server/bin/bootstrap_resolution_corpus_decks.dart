#!/usr/bin/env dart
// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:dotenv/dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:postgres/postgres.dart';

import '../lib/database.dart';

const _defaultApiBaseUrl = 'http://127.0.0.1:8080';
const _defaultCorpusPath = 'test/fixtures/optimization_resolution_corpus.json';
const _builderEmail = 'corpus.builder@example.com';
const _builderPassword = 'CorpusBuild123';
const _builderUsername = 'corpus_builder';
const _defaultCommanders = <String>[
  "Atraxa, Praetors' Voice",
  'Muldrotha, the Gravetide',
  "Sythis, Harvest's Hand",
  'Isshin, Two Heavens as One',
  'Krenko, Mob Boss',
  'Urza, Lord High Artificer',
  'Edgar Markov',
];

class _ReferenceCard {
  _ReferenceCard({
    required this.name,
    this.quantity = 1,
  });

  final String name;
  final int quantity;
}

Future<void> main(List<String> args) async {
  final env = DotEnv(includePlatformEnvironment: true, quiet: true)..load();
  final apiBaseUrl = env['TEST_API_BASE_URL'] ?? _defaultApiBaseUrl;
  final corpusPath = (env['VALIDATION_CORPUS_PATH'] ?? '').trim().isNotEmpty
      ? env['VALIDATION_CORPUS_PATH']!.trim()
      : _defaultCorpusPath;
  final dryRun = args.contains('--dry-run');

  final db = Database();
  await db.connect();
  if (!db.isConnected) {
    stderr.writeln('Falha ao conectar ao banco.');
    exitCode = 1;
    return;
  }

  try {
    final token = await _getOrCreateToken(apiBaseUrl);
    final corpusFile = File(corpusPath);
    if (!corpusFile.existsSync()) {
      stderr.writeln('Corpus não encontrado em $corpusPath');
      exitCode = 2;
      return;
    }

    final corpusRoot = _loadCorpus(corpusFile);
    final decks = (corpusRoot['decks'] as List).cast<Map<String, dynamic>>();
    final existingLabels = decks
        .map((entry) => (entry['label']?.toString() ?? '').toLowerCase())
        .where((value) => value.isNotEmpty)
        .toSet();

    final created = <String>[];
    final skipped = <String>[];

    for (final commander in _defaultCommanders) {
      if (existingLabels.contains(commander.toLowerCase())) {
        skipped.add('$commander (já existe no corpus)');
        continue;
      }

      print('');
      print('=== Bootstrap $commander ===');
      final commanderInfo = await _loadCommanderInfo(db.connection, commander);
      if (commanderInfo == null) {
        skipped.add('$commander (comandante não encontrado no catálogo)');
        print('SKIP | comandante ausente no catálogo');
        continue;
      }

      final reference = await _fetchCommanderReference(
        apiBaseUrl: apiBaseUrl,
        token: token,
        commander: commander,
      );
      if (reference == null) {
        skipped.add('$commander (commander-reference indisponível)');
        print('SKIP | commander-reference indisponível');
        continue;
      }

      final deckPayload = await _buildCreateDeckPayload(
        pool: db.connection,
        commander: commander,
        commanderColors: commanderInfo.colorIdentity,
        reference: reference,
      );
      if (deckPayload == null) {
        skipped.add('$commander (não foi possível montar 100 cartas válidas)');
        print('SKIP | montagem insuficiente');
        continue;
      }

      if (dryRun) {
        print(
          'DRY-RUN | cartas=${(deckPayload['cards'] as List).length} | land_target=${deckPayload['target_land_count']}',
        );
        created.add('$commander (dry-run)');
        continue;
      }

      final deckId = await _createDeck(
        apiBaseUrl: apiBaseUrl,
        token: token,
        commander: commander,
        payload: deckPayload,
      );
      final validateStatus = await _validateDeck(
        apiBaseUrl: apiBaseUrl,
        token: token,
        deckId: deckId,
      );
      if (validateStatus != 200) {
        skipped.add('$commander (validate=$validateStatus)');
        print('SKIP | validate=$validateStatus');
        continue;
      }

      decks.add({
        'deck_id': deckId,
        'label': commander,
        'note':
            'Auto-seeded from commander-reference on 2026-03-18. Expected flow pending stabilization.',
      });
      created.add('$commander | $deckId');
      print('CRIADO | $deckId | validate=200');
    }

    if (!dryRun) {
      corpusRoot['decks'] = decks;
      corpusFile.writeAsStringSync(
        '${const JsonEncoder.withIndent('  ').convert(corpusRoot)}\n',
      );
    }

    print('');
    print('=== RESUMO BOOTSTRAP ===');
    print('Criados: ${created.length}');
    for (final item in created) {
      print('- $item');
    }
    print('Ignorados: ${skipped.length}');
    for (final item in skipped) {
      print('- $item');
    }
  } finally {
    await db.close();
  }
}

Map<String, dynamic> _loadCorpus(File file) {
  final decoded = jsonDecode(file.readAsStringSync());
  if (decoded is Map<String, dynamic> && decoded['decks'] is List) {
    return {
      ...decoded,
      'decks': (decoded['decks'] as List)
          .whereType<Map>()
          .map((entry) => entry.cast<String, dynamic>())
          .toList(),
    };
  }
  throw StateError('Corpus inválido em ${file.path}.');
}

Future<String> _getOrCreateToken(String apiBaseUrl) async {
  Future<http.Response> login() {
    return http.post(
      Uri.parse('$apiBaseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': _builderEmail,
        'password': _builderPassword,
      }),
    );
  }

  var response = await login();
  if (response.statusCode != 200) {
    await http.post(
      Uri.parse('$apiBaseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': _builderEmail,
        'password': _builderPassword,
        'username': _builderUsername,
      }),
    );
    response = await login();
  }

  if (response.statusCode != 200) {
    throw StateError('Falha ao autenticar usuário builder: ${response.body}');
  }

  final body = jsonDecode(response.body) as Map<String, dynamic>;
  final token = body['token']?.toString() ?? '';
  if (token.isEmpty) {
    throw StateError('Token ausente no login do usuário builder.');
  }
  return token;
}

Future<_CommanderInfo?> _loadCommanderInfo(Pool pool, String commander) async {
  final result = await pool.execute(
    Sql.named('''
      SELECT
        name,
        COALESCE(color_identity, colors, ARRAY[]::text[]) AS color_identity
      FROM cards
      WHERE LOWER(name) = LOWER(@commander)
      LIMIT 1
    '''),
    parameters: {'commander': commander},
  );
  if (result.isEmpty) return null;
  return _CommanderInfo(
    name: result.first[0] as String,
    colorIdentity: (result.first[1] as List?)?.cast<String>() ?? const <String>[],
  );
}

Future<Map<String, dynamic>?> _fetchCommanderReference({
  required String apiBaseUrl,
  required String token,
  required String commander,
}) async {
  final response = await http.get(
    Uri.parse(
      '$apiBaseUrl/ai/commander-reference?commander=${Uri.encodeQueryComponent(commander)}&limit=120',
    ),
    headers: {'Authorization': 'Bearer $token'},
  );

  if (response.statusCode != 200) return null;
  final body = jsonDecode(response.body) as Map<String, dynamic>;
  return body;
}

Future<Map<String, dynamic>?> _buildCreateDeckPayload({
  required Pool pool,
  required String commander,
  required List<String> commanderColors,
  required Map<String, dynamic> reference,
}) async {
  final profile = reference['commander_profile'] is Map
      ? (reference['commander_profile'] as Map).cast<String, dynamic>()
      : const <String, dynamic>{};
  final recommendedStructure = profile['recommended_structure'] is Map
      ? (profile['recommended_structure'] as Map).cast<String, dynamic>()
      : const <String, dynamic>{};
  final averageTypeDistribution = profile['average_type_distribution'] is Map
      ? (profile['average_type_distribution'] as Map).cast<String, dynamic>()
      : const <String, dynamic>{};

  final targetLandCount =
      (recommendedStructure['lands'] as num?)?.toInt() ??
          (averageTypeDistribution['land'] as num?)?.toInt() ??
          36;

  final seedEntries = <_ReferenceCard>[
    ..._parseSeedCards(profile['average_deck_seed']),
    ..._parseSeedCards(reference['reference_cards']),
  ];

  final uniqueSeedNames = <String>{};
  final normalizedSeed = <_ReferenceCard>[];
  for (final seed in seedEntries) {
    final lower = seed.name.trim().toLowerCase();
    if (lower.isEmpty || lower == commander.toLowerCase()) continue;
    if (!uniqueSeedNames.add(lower)) continue;
    normalizedSeed.add(seed);
  }

  if (normalizedSeed.isEmpty) return null;

  final cardCatalog = await _loadCardCatalog(
    pool,
    normalizedSeed.map((seed) => seed.name).toList(),
  );
  if (cardCatalog.isEmpty) return null;

  final desiredSpellCount = 99 - targetLandCount;
  final chosenNames = <String>{commander.toLowerCase()};
  final spellCards = <Map<String, dynamic>>[];
  final landCards = <Map<String, dynamic>>[];

  for (final seed in normalizedSeed) {
    final card = cardCatalog[seed.name.toLowerCase()];
    if (card == null) continue;
    final nameLower = (card['name'] as String).toLowerCase();
    if (chosenNames.contains(nameLower)) continue;
    final typeLine = (card['type_line'] as String).toLowerCase();
    if (_isBasicLand(typeLine, nameLower)) continue;
    chosenNames.add(nameLower);
    if (typeLine.contains('land')) {
      if (landCards.length < targetLandCount) {
        landCards.add(card);
      }
    } else if (spellCards.length < desiredSpellCount) {
      spellCards.add(card);
    }
    if (spellCards.length >= desiredSpellCount &&
        landCards.length >= targetLandCount) {
      break;
    }
  }

  if (spellCards.length < desiredSpellCount) {
    final extraReferences = _parseSeedCards(reference['reference_cards']);
    for (final seed in extraReferences) {
      final card = cardCatalog[seed.name.toLowerCase()];
      if (card == null) continue;
      final nameLower = (card['name'] as String).toLowerCase();
      if (chosenNames.contains(nameLower)) continue;
      final typeLine = (card['type_line'] as String).toLowerCase();
      if (typeLine.contains('land')) continue;
      chosenNames.add(nameLower);
      spellCards.add(card);
      if (spellCards.length >= desiredSpellCount) break;
    }
  }

  if (spellCards.isEmpty) return null;

  final cards = <Map<String, dynamic>>[
    {
      'name': commander,
      'quantity': 1,
      'is_commander': true,
    },
  ];
  for (final card in spellCards.take(desiredSpellCount)) {
    cards.add({'name': card['name'], 'quantity': 1});
  }
  for (final card in landCards.take(targetLandCount)) {
    cards.add({'name': card['name'], 'quantity': 1});
  }

  final currentLandCount =
      cards.where((card) => _looksLikeLandName(card['name']?.toString() ?? '')).length +
          landCards.length;

  final landNamesToAdd = _buildBasicLandNames(
    commanderColors: commanderColors,
    count: targetLandCount - landCards.length,
  );
  for (final land in landNamesToAdd) {
    cards.add({'name': land, 'quantity': 1});
  }

  while (cards.length < 100) {
    final filler = _buildBasicLandNames(
      commanderColors: commanderColors,
      count: 1,
    );
    cards.add({'name': filler.first, 'quantity': 1});
  }

  if (cards.length > 100) {
    cards.removeRange(100, cards.length);
  }

  final compactedCards = _compactCreateCards(cards);

  final total = compactedCards.fold<int>(
    0,
    (sum, card) => sum + ((card['quantity'] as int?) ?? 1),
  );
  if (total != 100) return null;

  return {
    'cards': compactedCards,
    'target_land_count': targetLandCount,
    'current_land_seed_count': currentLandCount,
  };
}

List<_ReferenceCard> _parseSeedCards(dynamic raw) {
  if (raw is! List) return const <_ReferenceCard>[];
  return raw
      .whereType<Map>()
      .map((entry) {
        final map = entry.cast<String, dynamic>();
        return _ReferenceCard(
          name: map['name']?.toString() ?? '',
          quantity: (map['quantity'] as num?)?.toInt() ?? 1,
        );
      })
      .where((entry) => entry.name.trim().isNotEmpty)
      .toList();
}

Future<Map<String, Map<String, dynamic>>> _loadCardCatalog(
  Pool pool,
  List<String> names,
) async {
  if (names.isEmpty) return const <String, Map<String, dynamic>>{};
  final lowered = names.map((name) => name.toLowerCase()).toSet().toList();
  final result = await pool.execute(
    Sql.named('''
      SELECT DISTINCT ON (LOWER(name))
        name,
        type_line
      FROM cards
      WHERE LOWER(name) = ANY(@names)
      ORDER BY LOWER(name), id
    '''),
    parameters: {'names': lowered},
  );

  final catalog = <String, Map<String, dynamic>>{};
  for (final row in result) {
    final name = row[0] as String? ?? '';
    if (name.isEmpty) continue;
    catalog[name.toLowerCase()] = {
      'name': name,
      'type_line': row[1] as String? ?? '',
    };
  }
  return catalog;
}

Future<String> _createDeck({
  required String apiBaseUrl,
  required String token,
  required String commander,
  required Map<String, dynamic> payload,
}) async {
  final response = await http.post(
    Uri.parse('$apiBaseUrl/decks'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: jsonEncode({
      'name': 'Corpus Seed - $commander',
      'format': 'commander',
      'description':
          'Auto-seeded from commander-reference on 2026-03-18 for regression corpus.',
      'cards': payload['cards'],
    }),
  );

  if (response.statusCode != 200 && response.statusCode != 201) {
    throw StateError(
      'Falha ao criar deck para $commander: ${response.statusCode} ${response.body}',
    );
  }
  final body = jsonDecode(response.body) as Map<String, dynamic>;
  final deckId = body['id']?.toString() ?? '';
  if (deckId.isEmpty) {
    throw StateError('Deck criado sem id para $commander.');
  }
  return deckId;
}

Future<int> _validateDeck({
  required String apiBaseUrl,
  required String token,
  required String deckId,
}) async {
  final response = await http.post(
    Uri.parse('$apiBaseUrl/decks/$deckId/validate'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: '{}',
  );
  return response.statusCode;
}

bool _isBasicLand(String typeLine, String lowerName) {
  return typeLine.toLowerCase().contains('basic') ||
      lowerName == 'plains' ||
      lowerName == 'island' ||
      lowerName == 'swamp' ||
      lowerName == 'mountain' ||
      lowerName == 'forest' ||
      lowerName == 'wastes';
}

bool _looksLikeLandName(String name) {
  final lower = name.toLowerCase();
  return lower == 'plains' ||
      lower == 'island' ||
      lower == 'swamp' ||
      lower == 'mountain' ||
      lower == 'forest' ||
      lower == 'wastes';
}

List<String> _buildBasicLandNames({
  required List<String> commanderColors,
  required int count,
}) {
  if (count <= 0) return const <String>[];
  final colors = commanderColors.isEmpty ? const ['W'] : commanderColors;
  final names = <String>[];
  for (var i = 0; i < count; i++) {
    names.add(_basicLandNameForColor(colors[i % colors.length]));
  }
  return names;
}

String _basicLandNameForColor(String color) {
  switch (color.toUpperCase()) {
    case 'W':
      return 'Plains';
    case 'U':
      return 'Island';
    case 'B':
      return 'Swamp';
    case 'R':
      return 'Mountain';
    case 'G':
      return 'Forest';
    default:
      return 'Wastes';
  }
}

List<Map<String, dynamic>> _compactCreateCards(List<Map<String, dynamic>> cards) {
  final byName = <String, Map<String, dynamic>>{};
  for (final card in cards) {
    final name = card['name']?.toString().trim() ?? '';
    if (name.isEmpty) continue;
    final lower = name.toLowerCase();
    final quantity = (card['quantity'] as int?) ?? 1;
    final isCommander = card['is_commander'] == true;
    final existing = byName[lower];
    if (existing == null) {
      byName[lower] = {
        'name': name,
        'quantity': quantity,
        if (isCommander) 'is_commander': true,
      };
      continue;
    }

    byName[lower] = {
      ...existing,
      'quantity': (existing['quantity'] as int? ?? 1) + quantity,
      if (isCommander || existing['is_commander'] == true) 'is_commander': true,
    };
  }

  return byName.values.toList()
    ..sort((a, b) {
      final commanderA = a['is_commander'] == true ? 0 : 1;
      final commanderB = b['is_commander'] == true ? 0 : 1;
      final byCommander = commanderA.compareTo(commanderB);
      if (byCommander != 0) return byCommander;
      return (a['name'] as String).compareTo(b['name'] as String);
    });
}

class _CommanderInfo {
  _CommanderInfo({
    required this.name,
    required this.colorIdentity,
  });

  final String name;
  final List<String> colorIdentity;
}
