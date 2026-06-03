import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

import '../../../lib/ai/commander_learned_deck_support.dart';
import '../../../lib/ai/commander_reference_profile_support.dart';
import '../../../lib/generated_deck_validation_service.dart';
import '../../../lib/http_responses.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return methodNotAllowed();
  }

  final commander =
      (context.request.uri.queryParameters['commander'] ?? '').trim();
  if (commander.isEmpty) {
    return badRequest('Query parameter commander is required.');
  }

  try {
    final pool = context.read<Pool>();
    final learnedDeck = await _loadActiveLearnedDeck(
      pool: pool,
      commanderName: commander,
    );
    if (learnedDeck == null) {
      return Response.json(body: {
        'commander': commander,
        'available': false,
        'message':
            'Nenhum deck aprendido ativo encontrado para esse comandante.',
      });
    }

    final recommendedDeck = await _buildRecommendedDeck(
      pool: pool,
      learnedDeck: learnedDeck,
    );
    return Response.json(body: {
      'commander': learnedDeck.commanderName,
      'available': true,
      'source': 'pg_commander_learned_decks',
      'promoted_deck': _promotedDeckSummary(learnedDeck),
      'recommended_deck': recommendedDeck,
    });
  } catch (error) {
    return internalServerError(
      'Failed to load commander learning deck.',
      details: error,
    );
  }
}

Future<CommanderLearnedDeckInput?> _loadActiveLearnedDeck({
  required Pool pool,
  required String commanderName,
}) async {
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
          promoted_at
        FROM commander_learned_decks
        WHERE commander_name_normalized = @commander
          AND is_active = TRUE
        ORDER BY promoted_at DESC NULLS LAST, updated_at DESC
        LIMIT 1
      '''),
      parameters: {
        'commander': normalizeCommanderReferenceName(commanderName),
      },
    );
    if (result.isEmpty) return null;
    final row = result.first;
    return CommanderLearnedDeckInput(
      commanderName: row[0]?.toString() ?? commanderName,
      deckName: row[1]?.toString() ?? commanderName,
      sourceSystem: row[2]?.toString() ?? 'unknown',
      sourceRef: row[3]?.toString() ?? 'unknown',
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
    );
  } catch (error) {
    if (_isUndefinedLearnedDeckTableError(error)) return null;
    rethrow;
  }
}

Future<Map<String, dynamic>> _buildRecommendedDeck({
  required Pool pool,
  required CommanderLearnedDeckInput learnedDeck,
}) async {
  final commanderName = learnedDeck.commanderName;
  final normalizedCommander = normalizeCommanderReferenceName(commanderName);
  final deckEntries = learnedDeck.cards;
  final mainCards = deckEntries
      .where((card) =>
          normalizeCommanderReferenceName(card.name) != normalizedCommander)
      .map((card) => {'name': card.name, 'quantity': card.quantity})
      .toList(growable: false);
  final metadataByName = await _loadCardMetadataByName(
    pool: pool,
    names: deckEntries.map((card) => card.name),
  );
  final decklist = deckEntries.map((card) {
    final metadata = metadataByName[normalizeCommanderReferenceName(card.name)];
    final isCommander =
        normalizeCommanderReferenceName(card.name) == normalizedCommander;
    return {
      'name': card.name,
      'quantity': card.quantity,
      'is_commander': isCommander,
      if (metadata?['id'] != null) 'card_id': metadata!['id'],
      if (metadata?['name'] != null && metadata!['name'] != card.name)
        'canonical_name': metadata['name'],
      if (metadata?['type_line'] != null) 'type_line': metadata!['type_line'],
      'commander_legal_status': metadata?['commander_legal_status'],
    };
  }).toList(growable: false);

  final validation = await GeneratedDeckValidationService(
    PostgresGeneratedDeckRepository(pool, preferredFormat: 'commander'),
  ).validate(
    format: 'commander',
    cards: _canonicalValidationCards(mainCards, metadataByName),
    commanderName: commanderName,
  );
  final mainDecklist = decklist
      .where((card) => card['is_commander'] != true)
      .toList(growable: false);

  return {
    'source': 'promoted_learned_deck_pg',
    'source_system': learnedDeck.sourceSystem,
    'source_ref': learnedDeck.sourceRef,
    'deck_name': learnedDeck.deckName,
    'archetype': learnedDeck.archetype,
    'score': learnedDeck.score,
    'commander': {
      'name': commanderName,
      'commander_legal_status': metadataByName[normalizedCommander]
          ?['commander_legal_status'],
    },
    'total_cards_including_commander': decklist.fold<int>(
      0,
      (sum, card) => sum + _intValue(card['quantity']),
    ),
    'main_quantity': mainDecklist.fold<int>(
      0,
      (sum, card) => sum + _intValue(card['quantity']),
    ),
    'decklist': decklist,
    'cards': mainDecklist,
    'legality': _summarizeLegalities(decklist, validation.validationSummary()),
    'validation': validation.validationSummary(),
    'metadata': learnedDeck.metadata,
  };
}

Map<String, dynamic> _promotedDeckSummary(CommanderLearnedDeckInput deck) => {
      'commander': deck.commanderName,
      'deck_name': deck.deckName,
      'source_system': deck.sourceSystem,
      'source_ref': deck.sourceRef,
      'source_url': deck.sourceUrl,
      'archetype': deck.archetype,
      'card_count': deck.cardCount,
      'score': deck.score,
      'legal_status': deck.legalStatus,
      'promoted_at': deck.promotedAt?.toIso8601String(),
      'metadata': deck.metadata,
    };

Future<Map<String, Map<String, dynamic>>> _loadCardMetadataByName({
  required Pool pool,
  required Iterable<String> names,
}) async {
  final normalizedNames =
      names.map((name) => name.trim()).where((name) => name.isNotEmpty).toSet();
  if (normalizedNames.isEmpty) return const {};

  final result = await pool.execute(
    Sql.named('''
      WITH input_names AS (
        SELECT unnest(@names::text[]) AS input_name
      )
      SELECT DISTINCT ON (input_names.input_name)
        input_names.input_name,
        c.id::text,
        c.name,
        c.type_line,
        c.image_url,
        cl.status
      FROM input_names
      JOIN cards c
        ON LOWER(c.name) = input_names.input_name
        OR LOWER(SPLIT_PART(c.name, ' // ', 1)) = input_names.input_name
        OR LOWER(REPLACE(c.name, ' // ', '/')) = input_names.input_name
      LEFT JOIN card_legalities cl
        ON cl.card_id = c.id
       AND cl.format = 'commander'
      ORDER BY input_names.input_name,
        CASE
          WHEN cl.status = 'legal' THEN 0
          WHEN cl.status = 'restricted' THEN 1
          WHEN cl.status IS NULL THEN 2
          ELSE 3
        END,
        c.id::text
    '''),
    parameters: {
      'names': TypedValue(
        Type.textArray,
        normalizedNames.map((name) => name.toLowerCase()).toList(),
      ),
    },
  );

  return {
    for (final row in result) ..._metadataAliasesFromRow(row),
  };
}

Map<String, Map<String, dynamic>> _metadataAliasesFromRow(ResultRow row) {
  final inputName = row[0]?.toString() ?? '';
  final canonicalName = row[2]?.toString() ?? '';
  final metadata = {
    'id': row[1]?.toString(),
    'name': canonicalName,
    'type_line': row[3]?.toString(),
    'image_url': row[4]?.toString(),
    'commander_legal_status': row[5]?.toString(),
  };
  return {
    if (inputName.trim().isNotEmpty)
      normalizeCommanderReferenceName(inputName): metadata,
    if (canonicalName.trim().isNotEmpty)
      normalizeCommanderReferenceName(canonicalName): metadata,
  };
}

List<Map<String, dynamic>> _canonicalValidationCards(
  List<Map<String, dynamic>> cards,
  Map<String, Map<String, dynamic>> metadataByName,
) {
  return cards.map((card) {
    final name = card['name']?.toString().trim() ?? '';
    final metadata = metadataByName[normalizeCommanderReferenceName(name)];
    final canonicalName = metadata?['name']?.toString().trim();
    return {
      'name': canonicalName != null && canonicalName.isNotEmpty
          ? canonicalName
          : name,
      'quantity': _intValue(card['quantity']).clamp(1, 99),
    };
  }).toList(growable: false);
}

Map<String, dynamic> _summarizeLegalities(
  List<Map<String, dynamic>> cards,
  Map<String, dynamic> validation,
) {
  final banned = <String>[];
  final unknown = <String>[];
  for (final card in cards) {
    final name = card['name']?.toString() ?? '';
    final status = card['commander_legal_status']?.toString().toLowerCase();
    if (status == 'banned') banned.add(name);
    if (status == null || status.isEmpty) unknown.add(name);
  }
  return {
    'format': 'commander',
    'is_valid': validation['is_valid'] == true,
    'banned_cards': banned,
    'unknown_legality_cards': unknown,
    'invalid_cards': validation['invalid_cards'] ?? const <String>[],
    'errors': validation['errors'] ?? const <String>[],
  };
}

Map<String, dynamic> _jsonObject(Object? value) {
  if (value is Map<String, dynamic>) return Map<String, dynamic>.from(value);
  if (value is Map) return value.cast<String, dynamic>();
  return const <String, dynamic>{};
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

DateTime? _dateTimeValue(Object? value) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty) return null;
  return DateTime.tryParse(text);
}

bool _isUndefinedLearnedDeckTableError(Object error) {
  final text = error.toString().toLowerCase();
  return text.contains('commander_learned_decks') &&
      (text.contains('does not exist') ||
          text.contains('undefined_table') ||
          text.contains('42p01'));
}
