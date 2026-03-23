#!/usr/bin/env dart
// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dotenv/dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:postgres/postgres.dart';

import '../lib/color_identity.dart';
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

const _pairedCommanderSeparator = ' + ';

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
  final commanders = _resolveCommanders(env['VALIDATION_COMMANDERS']);
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
    final builderUserId = await _loadBuilderUserId(db.connection);
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

    for (final commanderSpec in commanders) {
      final commanderStopwatch = Stopwatch()..start();
      if (existingLabels.contains(commanderSpec.label.toLowerCase())) {
        skipped.add('${commanderSpec.label} (já existe no corpus)');
        continue;
      }

      print('');
      print('=== Bootstrap ${commanderSpec.label} ===');
      print('STEP | load_commander_catalog');
      final commanderInfos = <_CommanderInfo>[];
      var missingCommander = false;
      for (final commander in commanderSpec.commanders) {
        final commanderInfo = await _loadCommanderInfo(db.connection, commander);
        if (commanderInfo == null) {
          skipped.add('${commanderSpec.label} ($commander ausente no catálogo)');
          print('SKIP | comandante ausente no catálogo: $commander');
          missingCommander = true;
          break;
        }
        commanderInfos.add(commanderInfo);
      }
      if (missingCommander) {
        continue;
      }
      print('OK   | load_commander_catalog (${commanderStopwatch.elapsedMilliseconds}ms)');

      print('STEP | fetch_commander_reference');
      final references = <Map<String, dynamic>>[];
      var missingReference = false;
      for (final commander in commanderSpec.commanders) {
        final reference = await _fetchCommanderReference(
          apiBaseUrl: apiBaseUrl,
          token: token,
          commander: commander,
        );
        if (reference == null) {
          skipped.add('${commanderSpec.label} ($commander sem commander-reference)');
          print('SKIP | commander-reference indisponível: $commander');
          missingReference = true;
          break;
        }
        references.add(reference);
      }
      if (missingReference) {
        continue;
      }
      print('OK   | fetch_commander_reference (${commanderStopwatch.elapsedMilliseconds}ms)');

      print('STEP | build_create_payload');
      final deckPayload = await _buildCreateDeckPayload(
        pool: db.connection,
        commanders: commanderInfos,
        commanderColors: _mergeCommanderColors(commanderInfos),
        references: references,
      );
      if (deckPayload == null) {
        skipped.add(
          '${commanderSpec.label} (não foi possível montar 100 cartas válidas)',
        );
        print('SKIP | montagem insuficiente');
        continue;
      }
      print('OK   | build_create_payload (${commanderStopwatch.elapsedMilliseconds}ms)');

      if (dryRun) {
        print(
          'DRY-RUN | cartas=${(deckPayload['cards'] as List).length} | land_target=${deckPayload['target_land_count']}',
        );
        created.add('${commanderSpec.label} (dry-run)');
        continue;
      }

      late final String deckId;
      try {
        print('STEP | create_deck');
        deckId = await _createDeck(
          apiBaseUrl: apiBaseUrl,
          token: token,
          deckLabel: commanderSpec.label,
          payload: deckPayload,
        );
        print('OK   | create_deck (${commanderStopwatch.elapsedMilliseconds}ms)');
      } on TimeoutException {
        print('WARN | create_deck timeout, tentando fallback direto no banco');
        deckId = await _createDeckDirectInDb(
          pool: db.connection,
          userId: builderUserId,
          deckLabel: commanderSpec.label,
          payload: deckPayload,
        );
        print(
          'OK   | create_deck_db_fallback (${commanderStopwatch.elapsedMilliseconds}ms)',
        );
      } on StateError catch (e) {
        skipped.add('${commanderSpec.label} (${e.message})');
        print('SKIP | create_deck error: ${e.message}');
        continue;
      }

      late final int validateStatus;
      try {
        print('STEP | validate_deck');
        validateStatus = await _validateDeck(
          apiBaseUrl: apiBaseUrl,
          token: token,
          deckId: deckId,
        );
        print('OK   | validate_deck (${commanderStopwatch.elapsedMilliseconds}ms)');
      } on TimeoutException {
        skipped.add('${commanderSpec.label} (validate_deck timeout)');
        print('SKIP | validate_deck timeout');
        continue;
      }
      if (validateStatus != 200) {
        skipped.add('${commanderSpec.label} (validate=$validateStatus)');
        print('SKIP | validate=$validateStatus');
        continue;
      }

      decks.add({
        'deck_id': deckId,
        'label': commanderSpec.label,
        'note':
            'Auto-seeded from commander-reference on 2026-03-18. Expected flow pending stabilization.',
      });
      created.add('${commanderSpec.label} | $deckId');
      print(
        'CRIADO | $deckId | validate=200 | total=${commanderStopwatch.elapsedMilliseconds}ms',
      );
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

List<_CommanderSeedSpec> _resolveCommanders(String? raw) {
  final configured = (raw ?? '')
      .split(RegExp(r'[;\n]+'))
      .map((entry) => entry.trim())
      .where((entry) => entry.isNotEmpty)
      .toList();
  final entries = configured.isEmpty ? _defaultCommanders : configured;
  return entries.map(_parseCommanderSeedSpec).toList();
}

_CommanderSeedSpec _parseCommanderSeedSpec(String raw) {
  final normalized = raw.trim();
  final commanders = normalized
      .split(_pairedCommanderSeparator)
      .map((entry) => entry.trim())
      .where((entry) => entry.isNotEmpty)
      .toList();
  return _CommanderSeedSpec(
    label: commanders.join(_pairedCommanderSeparator),
    commanders: commanders,
  );
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

Future<String> _loadBuilderUserId(Pool pool) async {
  final result = await pool.execute(
    Sql.named('''
      SELECT id::text
      FROM users
      WHERE LOWER(email) = LOWER(@email)
      LIMIT 1
    '''),
    parameters: {'email': _builderEmail},
  );
  if (result.isEmpty) {
    throw StateError('Usuário builder não encontrado no banco.');
  }
  return result.first[0] as String;
}

Future<_CommanderInfo?> _loadCommanderInfo(Pool pool, String commander) async {
  final result = await pool.execute(
    Sql.named('''
      SELECT
        id::text,
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
    cardId: result.first[0] as String,
    name: result.first[1] as String,
    colorIdentity:
        (result.first[2] as List?)?.cast<String>() ?? const <String>[],
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
  required List<_CommanderInfo> commanders,
  required List<String> commanderColors,
  required List<Map<String, dynamic>> references,
}) async {
  final targetLandCandidates = <int>[];
  for (final reference in references) {
    final profile = reference['commander_profile'] is Map
        ? (reference['commander_profile'] as Map).cast<String, dynamic>()
        : const <String, dynamic>{};
    final recommendedStructure = profile['recommended_structure'] is Map
        ? (profile['recommended_structure'] as Map).cast<String, dynamic>()
        : const <String, dynamic>{};
    final averageTypeDistribution = profile['average_type_distribution'] is Map
        ? (profile['average_type_distribution'] as Map).cast<String, dynamic>()
        : const <String, dynamic>{};
    final lands = (recommendedStructure['lands'] as num?)?.toInt() ??
        (averageTypeDistribution['land'] as num?)?.toInt();
    if (lands != null && lands > 0) {
      targetLandCandidates.add(lands);
    }
  }

  final targetLandCount =
      targetLandCandidates.isEmpty ? 36 : targetLandCandidates.reduce((a, b) => a > b ? a : b);

  final seedEntries = <_ReferenceCard>[
    for (final reference in references) ..._seedEntriesFromReference(reference),
  ];

  final commanderNamesLower = commanders
      .map((commander) => commander.name.trim().toLowerCase())
      .where((name) => name.isNotEmpty)
      .toSet();
  final uniqueSeedNames = <String>{};
  final normalizedSeed = <_ReferenceCard>[];
  for (final seed in seedEntries) {
    final lower = seed.name.trim().toLowerCase();
    if (lower.isEmpty || commanderNamesLower.contains(lower)) continue;
    if (!uniqueSeedNames.add(lower)) continue;
    normalizedSeed.add(seed);
  }

  if (normalizedSeed.isEmpty) return null;

  final cardCatalog = await _loadCardCatalog(
    pool,
    normalizedSeed.map((seed) => seed.name).toList(),
  );
  if (cardCatalog.isEmpty) return null;
  final basicLandCatalog = await _loadCardCatalog(
    pool,
    _buildBasicLandNames(
      commanderColors: commanderColors,
      count: commanderColors.isEmpty ? 1 : commanderColors.length,
    ).toSet().toList(),
  );

  final desiredSpellCount = 100 - commanders.length - targetLandCount;
  final chosenNames = <String>{...commanderNamesLower};
  final spellCards = <Map<String, dynamic>>[];
  final landCards = <Map<String, dynamic>>[];

  for (final seed in normalizedSeed) {
    final card = cardCatalog[seed.name.toLowerCase()];
    if (card == null) continue;
    final nameLower = (card['name'] as String).toLowerCase();
    if (chosenNames.contains(nameLower)) continue;
    if (!_isCardWithinCommanderIdentity(card, commanderColors)) continue;
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
    final extraReferences = <_ReferenceCard>[
      for (final reference in references) ..._parseSeedCards(reference['reference_cards']),
    ];
    for (final seed in extraReferences) {
      final card = cardCatalog[seed.name.toLowerCase()];
      if (card == null) continue;
      final nameLower = (card['name'] as String).toLowerCase();
      if (chosenNames.contains(nameLower)) continue;
      if (!_isCardWithinCommanderIdentity(card, commanderColors)) continue;
      final typeLine = (card['type_line'] as String).toLowerCase();
      if (typeLine.contains('land')) continue;
      chosenNames.add(nameLower);
      spellCards.add(card);
      if (spellCards.length >= desiredSpellCount) break;
    }
  }

  if (spellCards.isEmpty) return null;

  final cards = <Map<String, dynamic>>[
    for (final commander in commanders)
      {
        'card_id': commander.cardId,
        'name': commander.name,
        'quantity': 1,
        'is_commander': true,
      },
  ];
  for (final card in spellCards.take(desiredSpellCount)) {
    cards.add({
      'card_id': card['card_id'],
      'name': card['name'],
      'quantity': 1,
    });
  }
  for (final card in landCards.take(targetLandCount)) {
    cards.add({
      'card_id': card['card_id'],
      'name': card['name'],
      'quantity': 1,
    });
  }

  final currentLandCount = cards
          .where((card) => _looksLikeLandName(card['name']?.toString() ?? ''))
          .length +
      landCards.length;

  final landNamesToAdd = _buildBasicLandNames(
    commanderColors: commanderColors,
    count: targetLandCount - landCards.length,
  );
  for (final land in landNamesToAdd) {
    final card = basicLandCatalog[land.toLowerCase()];
    if (card == null) {
      return null;
    }
    cards.add({
      'card_id': card['card_id'],
      'name': card['name'],
      'quantity': 1,
    });
  }

  final totalCards = cards.fold<int>(
    0,
    (sum, card) => sum + ((card['quantity'] as int?) ?? 1),
  );
  if (totalCards != 100) {
    return null;
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
        id::text,
        name,
        type_line,
        COALESCE(oracle_text, '') AS oracle_text,
        COALESCE(color_identity, colors, ARRAY[]::text[]) AS color_identity
      FROM cards
      WHERE LOWER(name) = ANY(@names)
      ORDER BY LOWER(name), id
    '''),
    parameters: {'names': lowered},
  );

  final catalog = <String, Map<String, dynamic>>{};
  for (final row in result) {
    final name = row[1] as String? ?? '';
    if (name.isEmpty) continue;
    catalog[name.toLowerCase()] = {
      'card_id': row[0] as String? ?? '',
      'name': row[1] as String? ?? '',
      'type_line': row[2] as String? ?? '',
      'oracle_text': row[3] as String? ?? '',
      'color_identity': (row[4] as List?)?.cast<String>() ?? const <String>[],
    };
  }
  return catalog;
}

bool _isCardWithinCommanderIdentity(
  Map<String, dynamic> card,
  List<String> commanderColors,
) {
  final allowedColors =
      commanderColors.map((color) => color.toUpperCase()).toSet();
  final cardIdentity = resolveCardColorIdentity(
    colorIdentity:
        (card['color_identity'] as List?)?.cast<String>() ?? const <String>[],
    oracleText: card['oracle_text']?.toString(),
  );
  return cardIdentity.every(allowedColors.contains);
}

Future<String> _createDeck({
  required String apiBaseUrl,
  required String token,
  required String deckLabel,
  required Map<String, dynamic> payload,
}) async {
  final response = await http.post(
        Uri.parse('$apiBaseUrl/decks'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'name': 'Corpus Seed - $deckLabel',
          'format': 'commander',
          'description':
              'Auto-seeded from commander-reference on 2026-03-18 for regression corpus.',
          'cards': payload['cards'],
        }),
      ).timeout(const Duration(seconds: 45));

  if (response.statusCode != 200 && response.statusCode != 201) {
    throw StateError(
      'Falha ao criar deck para $deckLabel: ${response.statusCode} ${response.body}',
    );
  }
  final body = jsonDecode(response.body) as Map<String, dynamic>;
  final deckId = body['id']?.toString() ?? '';
  if (deckId.isEmpty) {
    throw StateError('Deck criado sem id para $deckLabel.');
  }
  return deckId;
}

Future<String> _createDeckDirectInDb({
  required Pool pool,
  required String userId,
  required String deckLabel,
  required Map<String, dynamic> payload,
}) async {
  final cards = (payload['cards'] as List?)?.cast<Map<String, dynamic>>() ??
      const <Map<String, dynamic>>[];
  if (cards.isEmpty) {
    throw StateError('Payload sem cartas para fallback direto no banco.');
  }

  final deckId = await pool.runTx((session) async {
    final deckResult = await session.execute(
      Sql.named('''
        INSERT INTO decks (user_id, name, format, description, is_public)
        VALUES (@userId, @name, @format, @description, FALSE)
        RETURNING id::text
      '''),
      parameters: {
        'userId': userId,
        'name': 'Corpus Seed - $deckLabel',
        'format': 'commander',
        'description':
            'Auto-seeded via direct-db fallback from commander-reference on 2026-03-23 for regression corpus.',
      },
    );
    final createdDeckId = deckResult.first[0] as String;

    final insertSql = Sql.named('''
      INSERT INTO deck_cards (deck_id, card_id, quantity, is_commander)
      VALUES (@deckId, @cardId, @quantity, @isCommander)
    ''');

    for (final card in cards) {
      final cardId = card['card_id']?.toString() ?? '';
      final quantity = (card['quantity'] as int?) ?? 1;
      final isCommander = card['is_commander'] == true;
      if (cardId.isEmpty || quantity <= 0) {
        throw StateError('Carta inválida no payload de fallback direto.');
      }
      await session.execute(
        insertSql,
        parameters: {
          'deckId': createdDeckId,
          'cardId': cardId,
          'quantity': quantity,
          'isCommander': isCommander,
        },
      );
    }

    return createdDeckId;
  });

  return deckId;
}

List<_ReferenceCard> _seedEntriesFromReference(Map<String, dynamic> reference) {
  final profile = reference['commander_profile'] is Map
      ? (reference['commander_profile'] as Map).cast<String, dynamic>()
      : const <String, dynamic>{};
  return <_ReferenceCard>[
    ..._parseSeedCards(profile['average_deck_seed']),
    ..._parseSeedCards(reference['reference_cards']),
  ];
}

List<String> _mergeCommanderColors(List<_CommanderInfo> commanders) {
  final colors = <String>{};
  for (final commander in commanders) {
    colors.addAll(commander.colorIdentity.map((color) => color.toUpperCase()));
  }
  return colors.toList()..sort();
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
      ).timeout(const Duration(seconds: 45));
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
  final colors = commanderColors.isEmpty ? const ['C'] : commanderColors;
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

List<Map<String, dynamic>> _compactCreateCards(
    List<Map<String, dynamic>> cards) {
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
        if (card['card_id'] != null) 'card_id': card['card_id'],
        'quantity': quantity,
        if (isCommander) 'is_commander': true,
      };
      continue;
    }

    byName[lower] = {
      ...existing,
      if (existing['card_id'] == null && card['card_id'] != null)
        'card_id': card['card_id'],
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
    required this.cardId,
    required this.name,
    required this.colorIdentity,
  });

  final String cardId;
  final String name;
  final List<String> colorIdentity;
}

class _CommanderSeedSpec {
  _CommanderSeedSpec({
    required this.label,
    required this.commanders,
  });

  final String label;
  final List<String> commanders;
}
