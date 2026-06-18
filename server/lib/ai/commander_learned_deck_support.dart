import 'dart:convert';

import 'package:postgres/postgres.dart';

import 'commander_reference_helpers.dart';
import 'commander_reference_profile_support.dart';

const commanderLearnedDecksTable = 'commander_learned_decks';

class CommanderLearnedDeckCardLine {
  const CommanderLearnedDeckCardLine({
    required this.name,
    required this.quantity,
  });

  final String name;
  final int quantity;

  Map<String, dynamic> toJson() => {
        'name': name,
        'quantity': quantity,
      };
}

class CommanderLearnedDeckInput {
  const CommanderLearnedDeckInput({
    required this.commanderName,
    required this.deckName,
    required this.sourceSystem,
    required this.sourceRef,
    required this.cardList,
    required this.cardCount,
    required this.isActive,
    this.sourceUrl,
    this.archetype,
    this.score,
    this.winconPrimary,
    this.winconBackup,
    this.legalStatus,
    this.notes,
    this.metadata = const <String, dynamic>{},
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

  String get commanderNameNormalized =>
      normalizeCommanderReferenceName(commanderName);

  List<CommanderLearnedDeckCardLine> get cards =>
      parseCommanderLearnedDeckCardList(cardList);

  Map<String, dynamic> toJson() => {
        'commander_name': commanderName,
        'commander_name_normalized': commanderNameNormalized,
        'deck_name': deckName,
        'source_system': sourceSystem,
        'source_ref': sourceRef,
        if (sourceUrl != null) 'source_url': sourceUrl,
        if (archetype != null) 'archetype': archetype,
        'card_count': cardCount,
        if (score != null) 'score': score,
        if (winconPrimary != null) 'wincon_primary': winconPrimary,
        if (winconBackup != null) 'wincon_backup': winconBackup,
        if (legalStatus != null) 'legal_status': legalStatus,
        if (notes != null) 'notes': notes,
        'metadata': metadata,
        'is_active': isActive,
        if (promotedAt != null) 'promoted_at': promotedAt!.toIso8601String(),
        if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
        'cards': cards.map((card) => card.toJson()).toList(growable: false),
      };
}

class CommanderLearnedDeckValidationResult {
  const CommanderLearnedDeckValidationResult({
    required this.parsedCardCount,
    required this.declaredCardCount,
    required this.commanderQuantity,
    required this.mainQuantity,
    required this.blockers,
    required this.warnings,
  });

  final int parsedCardCount;
  final int declaredCardCount;
  final int commanderQuantity;
  final int mainQuantity;
  final List<String> blockers;
  final List<String> warnings;

  bool get ok => blockers.isEmpty;

  Map<String, dynamic> toJson() => {
        'ok': ok,
        'parsed_card_count': parsedCardCount,
        'declared_card_count': declaredCardCount,
        'commander_quantity': commanderQuantity,
        'main_quantity': mainQuantity,
        'blockers': blockers,
        'warnings': warnings,
  };
}

const Map<String, String> _learnedDeckSummaryTagToRole = {
  'board_wipe': 'board_wipe',
  'counterspell': 'removal',
  'mana_fixing': 'ramp',
  'ritual': 'ramp',
  'loot': 'draw',
  'exile_value': 'draw',
  'blink': 'protection',
  'graveyard_synergy': 'engine',
  'aristocrat_payoff': 'engine',
  'spellslinger': 'engine',
  'artifact_synergy': 'engine',
  'enchantment_synergy': 'engine',
  'sacrifice_outlet': 'engine',
  'payoff': 'engine',
  'enabler': 'engine',
  'combo_piece': 'wincon',
  'big_spell': 'wincon',
  'drain': 'wincon',
  'ramp': 'ramp',
  'draw': 'draw',
  'tutor': 'tutor',
  'removal': 'removal',
  'protection': 'protection',
  'recursion': 'recursion',
  'wincon': 'wincon',
  'engine': 'engine',
};

Map<String, int> computeCommanderLearnedDeckRoleSummary({
  required Iterable<CommanderLearnedDeckCardLine> cards,
  required String commanderNameNormalized,
  required Map<String, Set<String>> tagsByName,
  required Set<String> landNames,
}) {
  final summary = <String, int>{
    'total_lands': 0,
    'ramp_count': 0,
    'draw_count': 0,
    'removal_count': 0,
    'tutor_count': 0,
    'board_wipe_count': 0,
    'protection_count': 0,
    'recursion_count': 0,
    'wincon_count': 0,
    'engine_count': 0,
  };

  for (final card in cards) {
    final normalizedName = normalizeCommanderReferenceName(card.name);
    if (normalizedName.isEmpty || normalizedName == commanderNameNormalized) {
      continue;
    }
    final quantity = card.quantity;
    if (quantity <= 0) continue;

    final tags = tagsByName[normalizedName] ?? const <String>{};
    if (landNames.contains(normalizedName) || tags.contains('land')) {
      summary['total_lands'] = summary['total_lands']! + quantity;
      continue;
    }

    final roles = tags
        .map((tag) => _learnedDeckSummaryTagToRole[tag])
        .whereType<String>()
        .toSet();
    for (final role in roles) {
      switch (role) {
        case 'ramp':
          summary['ramp_count'] = summary['ramp_count']! + quantity;
          break;
        case 'draw':
          summary['draw_count'] = summary['draw_count']! + quantity;
          break;
        case 'removal':
          summary['removal_count'] = summary['removal_count']! + quantity;
          break;
        case 'tutor':
          summary['tutor_count'] = summary['tutor_count']! + quantity;
          break;
        case 'board_wipe':
          summary['board_wipe_count'] = summary['board_wipe_count']! + quantity;
          break;
        case 'protection':
          summary['protection_count'] =
              summary['protection_count']! + quantity;
          break;
        case 'recursion':
          summary['recursion_count'] = summary['recursion_count']! + quantity;
          break;
        case 'wincon':
          summary['wincon_count'] = summary['wincon_count']! + quantity;
          break;
        case 'engine':
          summary['engine_count'] = summary['engine_count']! + quantity;
          break;
      }
    }
  }

  return summary;
}

Future<Map<String, dynamic>> canonicalizeCommanderLearnedDeckMetadata(
  Pool pool,
  CommanderLearnedDeckInput input,
) async {
  final cards = input.cards;
  if (cards.isEmpty) return input.metadata;

  final distinctNames = <String>{};
  for (final card in cards) {
    final normalizedName = normalizeCommanderReferenceName(card.name);
    if (normalizedName.isEmpty) continue;
    distinctNames.add(normalizedName);
  }
  if (distinctNames.isEmpty) return input.metadata;

  final placeholders = <String>[];
  final parameters = <String, dynamic>{};
  var index = 0;
  for (final name in distinctNames) {
    final key = 'name$index';
    placeholders.add('(@$key)');
    parameters[key] = name;
    index += 1;
  }

  try {
    final rows = await pool.execute(
      Sql.named('''
        WITH wanted(lowered_name) AS (
          VALUES ${placeholders.join(', ')}
        ),
        card_info AS (
          SELECT
            w.lowered_name,
            COALESCE(BOOL_OR(c.type_line ILIKE '%Land%'), FALSE) AS is_land,
            COALESCE(
              ARRAY_REMOVE(ARRAY_AGG(DISTINCT LOWER(cft.tag)), NULL),
              ARRAY[]::TEXT[]
            ) AS tags
          FROM wanted w
          LEFT JOIN cards c
            ON LOWER(c.name) = w.lowered_name
          LEFT JOIN card_function_tags cft
            ON cft.card_id = c.id
          GROUP BY w.lowered_name
        )
        SELECT lowered_name, is_land, tags
        FROM card_info
      '''),
      parameters: parameters,
    );

    final tagsByName = <String, Set<String>>{};
    final landNames = <String>{};
    for (final row in rows) {
      final loweredName = row[0]?.toString() ?? '';
      if (loweredName.isEmpty) continue;
      final isLand = row[1] == true;
      if (isLand) landNames.add(loweredName);
      final rawTags = row[2];
      final tags = <String>{};
      if (rawTags is Iterable) {
        for (final value in rawTags) {
          final text = value?.toString().trim().toLowerCase();
          if (text != null && text.isNotEmpty) {
            tags.add(text);
          }
        }
      }
      if (tags.isNotEmpty) {
        tagsByName[loweredName] = tags;
      }
    }

    final summary = computeCommanderLearnedDeckRoleSummary(
      cards: cards,
      commanderNameNormalized: input.commanderNameNormalized,
      tagsByName: tagsByName,
      landNames: landNames,
    );

    return {
      ...input.metadata,
      ...summary,
    };
  } catch (_) {
    return input.metadata;
  }
}

CommanderLearnedDeckInput parseCommanderLearnedDeckInput(
  Map<String, dynamic> payload,
) {
  final hermesId =
      _intValue(payload['hermes_learned_deck_id'] ?? payload['id']);
  final sourceSystem = _stringValue(payload['source_system']) ?? 'hermes';
  final sourceRef = _stringValue(payload['source_ref']) ??
      (hermesId > 0 ? 'learned_deck:$hermesId' : null);
  if (sourceRef == null || sourceRef.isEmpty) {
    throw ArgumentError(
        'source_ref ou id/hermes_learned_deck_id e obrigatorio.');
  }

  final commanderName = _stringValue(
        payload['commander_name'] ?? payload['commander'],
      ) ??
      '';
  if (commanderName.isEmpty) {
    throw ArgumentError('commander_name/commander e obrigatorio.');
  }
  final deckName = _stringValue(payload['deck_name']) ?? commanderName;
  final cardList = _stringValue(payload['card_list']) ?? '';
  if (cardList.trim().isEmpty) {
    throw ArgumentError('card_list e obrigatorio.');
  }

  final parsedCards = parseCommanderLearnedDeckCardList(cardList);
  final explicitCardCount = _intValue(payload['card_count']);
  final cardCount = explicitCardCount > 0
      ? explicitCardCount
      : parsedCards.fold<int>(0, (sum, card) => sum + card.quantity);

  final metadata = _jsonObject(payload['metadata']);
  if (hermesId > 0)
    metadata.putIfAbsent('hermes_learned_deck_id', () => hermesId);
  final activeDeckId = _intValue(payload['hermes_active_deck_id']);
  if (activeDeckId > 0) {
    metadata.putIfAbsent('hermes_active_deck_id', () => activeDeckId);
  }

  return CommanderLearnedDeckInput(
    commanderName: commanderName,
    deckName: deckName,
    sourceSystem: sourceSystem,
    sourceRef: sourceRef,
    sourceUrl: _stringValue(payload['source_url']),
    archetype: _stringValue(payload['archetype']),
    cardList: cardList,
    cardCount: cardCount,
    score: _nullableDouble(payload['score']),
    winconPrimary: _stringValue(payload['wincon_primary']),
    winconBackup: _stringValue(payload['wincon_backup']),
    legalStatus: _stringValue(payload['legal_status']) ?? 'commander_legal',
    notes: _stringValue(payload['notes']),
    metadata: metadata,
    isActive: _boolValue(payload['is_active'], defaultValue: true),
    promotedAt: _dateTimeValue(payload['promoted_at']),
  );
}

CommanderLearnedDeckValidationResult validateCommanderLearnedDeckInput(
  CommanderLearnedDeckInput input,
) {
  final blockers = <String>[];
  final warnings = <String>[];
  final cards = input.cards;
  final normalizedCommander = input.commanderNameNormalized;
  var parsedCardCount = 0;
  var commanderQuantity = 0;
  for (final card in cards) {
    if (card.quantity <= 0) {
      blockers.add('card_list contem quantidade nao positiva: ${card.name}');
      continue;
    }
    parsedCardCount += card.quantity;
    if (normalizeCommanderReferenceName(card.name) == normalizedCommander) {
      commanderQuantity += card.quantity;
    }
  }
  final mainQuantity = parsedCardCount - commanderQuantity;
  if (input.cardCount != parsedCardCount) {
    blockers.add(
      'card_count declarado (${input.cardCount}) difere do total parseado ($parsedCardCount).',
    );
  }
  if (parsedCardCount != 100) {
    blockers.add(
        'deck Commander aprendido precisa ter 100 cartas; recebeu $parsedCardCount.');
  }
  if (commanderQuantity != 1) {
    blockers.add(
      'deck Commander aprendido precisa conter exatamente 1 comandante; recebeu $commanderQuantity.',
    );
  }
  if (mainQuantity != 99) {
    blockers
        .add('deck principal precisa ter 99 cartas; recebeu $mainQuantity.');
  }
  final legalStatus = input.legalStatus?.trim().toLowerCase();
  if (legalStatus != null &&
      legalStatus.isNotEmpty &&
      legalStatus != 'commander_legal') {
    warnings.add(
        'legal_status nao confirmado como commander_legal: ${input.legalStatus}.');
  }
  return CommanderLearnedDeckValidationResult(
    parsedCardCount: parsedCardCount,
    declaredCardCount: input.cardCount,
    commanderQuantity: commanderQuantity,
    mainQuantity: mainQuantity,
    blockers: blockers,
    warnings: warnings,
  );
}

List<CommanderLearnedDeckCardLine> parseCommanderLearnedDeckCardList(
  String cardList,
) {
  final byName = <String, int>{};
  for (final rawLine in cardList.split(RegExp(r'\r?\n'))) {
    final line = rawLine.trim();
    if (line.isEmpty || line.startsWith('#')) continue;

    final parsed = _parseCommanderLearnedDeckCardLine(line);
    if (parsed == null) continue;
    byName[parsed.name] = (byName[parsed.name] ?? 0) + parsed.quantity;
  }
  return [
    for (final entry in byName.entries)
      CommanderLearnedDeckCardLine(name: entry.key, quantity: entry.value),
  ];
}

List<CommanderLearnedDeckCardLine> parseCommanderLearnedDeckCards(
  String cardList,
) =>
    parseCommanderLearnedDeckCardList(cardList);

Future<CommanderLearnedDeckInput?> loadActiveCommanderLearnedDeck({
  required Pool pool,
  required String commanderName,
}) async {
  final commander = commanderName.trim();
  if (commander.isEmpty) return null;
  try {
    final result = await pool.execute(
      Sql.named('''
        SELECT
          commander_name,
          deck_name,
          source_system,
          source_ref,
          source_url,
          archetype,
          card_list,
          card_count,
          score,
          wincon_primary,
          wincon_backup,
          legal_status,
          notes,
          metadata,
          is_active,
          promoted_at,
          updated_at
        FROM commander_learned_decks
        WHERE commander_name_normalized = @commander
          AND is_active = TRUE
        ORDER BY promoted_at DESC NULLS LAST, updated_at DESC
        LIMIT 1
      '''),
      parameters: {
        'commander': normalizeCommanderReferenceName(commander),
      },
    );
    if (result.isEmpty) return null;
    final row = result.first;
    return CommanderLearnedDeckInput(
      commanderName: row[0]?.toString() ?? commander,
      deckName: row[1]?.toString() ?? commander,
      sourceSystem: row[2]?.toString() ?? 'hermes',
      sourceRef: row[3]?.toString() ?? 'learned_deck:unknown',
      sourceUrl: row[4]?.toString(),
      archetype: row[5]?.toString(),
      cardList: row[6]?.toString() ?? '',
      cardCount: _intValue(row[7]),
      score: _nullableDouble(row[8]),
      winconPrimary: row[9]?.toString(),
      winconBackup: row[10]?.toString(),
      legalStatus: row[11]?.toString(),
      notes: row[12]?.toString(),
      metadata: _jsonObject(row[13]),
      isActive: row[14] == true,
      promotedAt: _dateTimeValue(row[15]),
      updatedAt: _dateTimeValue(row[16]),
    );
  } catch (error) {
    if (isUndefinedLearnedDeckTableError(error)) return null;
    rethrow;
  }
}

List<String> activeCommanderLearnedDeckCardNames(
  CommanderLearnedDeckInput? deck,
) {
  if (deck == null) return const [];
  final normalizedCommander = deck.commanderNameNormalized;
  final seen = <String>{};
  final names = <String>[];
  for (final card in deck.cards) {
    final normalized = normalizeCommanderReferenceName(card.name);
    if (normalized.isEmpty || normalized == normalizedCommander) continue;
    if (!seen.add(normalized)) continue;
    names.add(card.name);
  }
  return names;
}

CommanderLearnedDeckCardLine? _parseCommanderLearnedDeckCardLine(String line) {
  final withoutBullet = line.replaceFirst(RegExp(r'^[-*]\s+'), '').trim();
  final match = RegExp(r'^(\d+)\s+(.+)$').firstMatch(withoutBullet);
  if (match != null) {
    final quantity = int.tryParse(match.group(1) ?? '') ?? 0;
    final name = _cleanCommanderLearnedDeckCardName(match.group(2) ?? '');
    if (quantity > 0 && name.isNotEmpty) {
      return CommanderLearnedDeckCardLine(name: name, quantity: quantity);
    }
  }

  final name = _cleanCommanderLearnedDeckCardName(withoutBullet);
  if (name.isEmpty) return null;
  return CommanderLearnedDeckCardLine(name: name, quantity: 1);
}

String _cleanCommanderLearnedDeckCardName(String value) {
  var name = value.trim();
  name = name.replaceFirst(RegExp(r'\s+\[[^\]]+\]$'), '');
  name = name.replaceFirst(RegExp(r'\s+\([A-Z0-9]{2,5}\)\s*\d*\s*$'), '');
  name = name.replaceFirst(RegExp(r'\s+#.*$'), '');
  return name.trim();
}

Future<void> ensureCommanderLearnedDecksTable(Pool pool) async {
  await pool.execute('''
    CREATE TABLE IF NOT EXISTS commander_learned_decks (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      commander_name TEXT NOT NULL,
      commander_name_normalized TEXT NOT NULL,
      deck_name TEXT NOT NULL,
      source_system TEXT NOT NULL,
      source_ref TEXT NOT NULL,
      source_url TEXT,
      archetype TEXT,
      card_list TEXT NOT NULL,
      card_count INTEGER NOT NULL,
      score NUMERIC,
      wincon_primary TEXT,
      wincon_backup TEXT,
      legal_status TEXT,
      notes TEXT,
      metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
      is_active BOOLEAN NOT NULL DEFAULT FALSE,
      promoted_at TIMESTAMPTZ,
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      UNIQUE (source_system, source_ref)
    )
  ''');
  await pool.execute('''
    CREATE INDEX IF NOT EXISTS idx_commander_learned_decks_active
    ON commander_learned_decks (
      commander_name_normalized,
      is_active,
      promoted_at DESC,
      updated_at DESC
    )
  ''');
}

Future<void> upsertCommanderLearnedDeck(
  Pool pool,
  CommanderLearnedDeckInput input, {
  bool deactivateOtherActive = true,
}) async {
  final metadata = await canonicalizeCommanderLearnedDeckMetadata(pool, input);

  if (input.isActive && deactivateOtherActive) {
    await pool.execute(
      Sql.named('''
        UPDATE commander_learned_decks
        SET is_active = FALSE,
            updated_at = NOW()
        WHERE commander_name_normalized = @commander
          AND is_active = TRUE
          AND (source_system, source_ref) <> (@source_system, @source_ref)
      '''),
      parameters: {
        'commander': input.commanderNameNormalized,
        'source_system': input.sourceSystem,
        'source_ref': input.sourceRef,
      },
    );
  }

  await pool.execute(
    Sql.named('''
      INSERT INTO commander_learned_decks (
        commander_name,
        commander_name_normalized,
        deck_name,
        source_system,
        source_ref,
        source_url,
        archetype,
        card_list,
        card_count,
        score,
        wincon_primary,
        wincon_backup,
        legal_status,
        notes,
        metadata,
        is_active,
        promoted_at
      ) VALUES (
        @commander_name,
        @commander_name_normalized,
        @deck_name,
        @source_system,
        @source_ref,
        @source_url,
        @archetype,
        @card_list,
        @card_count,
        @score,
        @wincon_primary,
        @wincon_backup,
        @legal_status,
        @notes,
        @metadata::jsonb,
        @is_active,
        @promoted_at
      )
      ON CONFLICT (source_system, source_ref)
      DO UPDATE SET
        commander_name = EXCLUDED.commander_name,
        commander_name_normalized = EXCLUDED.commander_name_normalized,
        deck_name = EXCLUDED.deck_name,
        source_url = EXCLUDED.source_url,
        archetype = EXCLUDED.archetype,
        card_list = EXCLUDED.card_list,
        card_count = EXCLUDED.card_count,
        score = EXCLUDED.score,
        wincon_primary = EXCLUDED.wincon_primary,
        wincon_backup = EXCLUDED.wincon_backup,
        legal_status = EXCLUDED.legal_status,
        notes = EXCLUDED.notes,
        metadata = EXCLUDED.metadata,
        is_active = EXCLUDED.is_active,
        promoted_at = EXCLUDED.promoted_at,
        updated_at = NOW()
    '''),
    parameters: {
      'commander_name': input.commanderName,
      'commander_name_normalized': input.commanderNameNormalized,
      'deck_name': input.deckName,
      'source_system': input.sourceSystem,
      'source_ref': input.sourceRef,
      'source_url': input.sourceUrl,
      'archetype': input.archetype,
      'card_list': input.cardList,
      'card_count': input.cardCount,
      'score': input.score,
      'wincon_primary': input.winconPrimary,
      'wincon_backup': input.winconBackup,
      'legal_status': input.legalStatus,
      'notes': input.notes,
      'metadata': jsonEncode(metadata),
      'is_active': input.isActive,
      'promoted_at': input.promotedAt,
    },
  );
}

String? _stringValue(Object? value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

int _intValue(Object? value) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double? _nullableDouble(Object? value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

bool _boolValue(Object? value, {required bool defaultValue}) {
  if (value == null) return defaultValue;
  if (value is bool) return value;
  final normalized = value.toString().trim().toLowerCase();
  if (normalized == '1' || normalized == 'true' || normalized == 'yes') {
    return true;
  }
  if (normalized == '0' || normalized == 'false' || normalized == 'no') {
    return false;
  }
  return defaultValue;
}

DateTime? _dateTimeValue(Object? value) {
  final text = _stringValue(value);
  if (text == null) return null;
  return DateTime.tryParse(text);
}

Map<String, dynamic> _jsonObject(Object? value) {
  if (value is Map<String, dynamic>) return Map<String, dynamic>.from(value);
  if (value is Map) return value.cast<String, dynamic>();
  if (value is String && value.trim().isNotEmpty) {
    final decoded = jsonDecode(value);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return decoded.cast<String, dynamic>();
  }
  return <String, dynamic>{};
}
