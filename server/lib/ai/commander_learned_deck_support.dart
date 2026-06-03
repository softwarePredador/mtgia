import 'dart:convert';

import 'package:postgres/postgres.dart';

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

List<CommanderLearnedDeckCardLine> parseCommanderLearnedDeckCardList(
  String cardList,
) {
  final cards = <CommanderLearnedDeckCardLine>[];
  for (final rawLine in cardList.split(RegExp(r'\r?\n'))) {
    final line = rawLine.trim();
    if (line.isEmpty) continue;
    final match = RegExp(r'^(\d+)\s+(.+)$').firstMatch(line);
    if (match == null) {
      cards.add(CommanderLearnedDeckCardLine(name: line, quantity: 1));
      continue;
    }
    cards.add(
      CommanderLearnedDeckCardLine(
        name: match.group(2)!.trim(),
        quantity: int.tryParse(match.group(1)!) ?? 1,
      ),
    );
  }
  return cards;
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
      'metadata': jsonEncode(input.metadata),
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
