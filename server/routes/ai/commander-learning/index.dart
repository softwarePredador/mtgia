import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

import '../../../lib/ai/commander_learned_deck_support.dart';
import '../../../lib/ai/commander_reference_helpers.dart';
import '../../../lib/ai/commander_reference_profile_support.dart';
import '../../../lib/generated_deck_validation_service.dart';
import '../../../lib/http_responses.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return methodNotAllowed();
  }

  final commander =
      (context.request.uri.queryParameters['commander'] ?? '').trim();

  try {
    final pool = context.read<Pool>();
    if (commander.isEmpty) {
      final activeDecks = await _loadActiveLearnedDecks(pool);
      return Response.json(body: {
        'available': activeDecks.isNotEmpty,
        'source': 'pg_commander_learned_decks',
        'count': activeDecks.length,
        'commanders': activeDecks.map(_promotedDeckSummary).toList(),
      });
    }

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
          promoted_at,
          updated_at
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
    return _learnedDeckFromRow(row, fallbackCommanderName: commanderName);
  } catch (error) {
    if (isUndefinedLearnedDeckTableError(error)) return null;
    rethrow;
  }
}

Future<List<CommanderLearnedDeckInput>> _loadActiveLearnedDecks(
  Pool pool,
) async {
  try {
    final result = await pool.execute('''
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
      WHERE is_active = TRUE
      ORDER BY commander_name ASC, promoted_at DESC NULLS LAST, updated_at DESC
    ''');
    return result
        .map((row) => _learnedDeckFromRow(row))
        .toList(growable: false);
  } catch (error) {
    if (isUndefinedLearnedDeckTableError(error)) return const [];
    rethrow;
  }
}

CommanderLearnedDeckInput _learnedDeckFromRow(
  ResultRow row, {
  String fallbackCommanderName = '',
}) {
  final commanderName = row[0]?.toString() ?? fallbackCommanderName;
  return CommanderLearnedDeckInput(
    commanderName: commanderName,
    deckName: row[1]?.toString() ?? commanderName,
    sourceSystem: row[2]?.toString() ?? 'unknown',
    sourceRef: row[3]?.toString() ?? 'unknown',
    sourceUrl: row[4]?.toString(),
    archetype: row[5]?.toString(),
    cardList: row[6]?.toString() ?? '',
    cardCount: intValue(row[7]),
    score: nullableDouble(row[8]),
    winconPrimary: row[9]?.toString(),
    winconBackup: row[10]?.toString(),
    legalStatus: row[11]?.toString(),
    notes: row[12]?.toString(),
    metadata: jsonObject(row[13]),
    isActive: row[14] == true,
    promotedAt: dateTimeValue(row[15]),
    updatedAt: dateTimeValue(row[16]),
  );
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
  final metadataByName = await loadCardMetadataByName(
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
    cards: canonicalValidationCards(mainCards, metadataByName),
    commanderName: commanderName,
  );
  final mainDecklist = decklist
      .where((card) => card['is_commander'] != true)
      .toList(growable: false);
  final validationSummary = validation.validationSummary();
  final legality = summarizeLegalities(decklist, validationSummary);

  return {
    'source': 'promoted_learned_deck_pg',
    'source_system': learnedDeck.sourceSystem,
    'source_ref': learnedDeck.sourceRef,
    'deck_name': learnedDeck.deckName,
    'archetype': learnedDeck.archetype,
    'score': learnedDeck.score,
    'source_confidence': _sourceConfidence(
      learnedDeck: learnedDeck,
      legality: legality,
      validation: validationSummary,
    ),
    'last_synced_at': learnedDeck.updatedAt?.toIso8601String(),
    'win_conditions': _winConditions(learnedDeck),
    'role_summary': _roleSummary(learnedDeck),
    'commander': {
      'name': commanderName,
      'commander_legal_status': metadataByName[normalizedCommander]
          ?['commander_legal_status'],
    },
    'total_cards_including_commander': decklist.fold<int>(
      0,
      (sum, card) => sum + intValue(card['quantity']),
    ),
    'main_quantity': mainDecklist.fold<int>(
      0,
      (sum, card) => sum + intValue(card['quantity']),
    ),
    'decklist': decklist,
    'cards': mainDecklist,
    'legality': legality,
    'validation': validationSummary,
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
      'last_synced_at': deck.updatedAt?.toIso8601String(),
      'win_conditions': _winConditions(deck),
      'role_summary': _roleSummary(deck),
      'metadata': deck.metadata,
    };

List<Map<String, dynamic>> _winConditions(CommanderLearnedDeckInput deck) {
  final wincons = <Map<String, dynamic>>[];
  final primary = deck.winconPrimary?.trim();
  if (primary != null && primary.isNotEmpty) {
    wincons.add({'name': primary, 'priority': 'primary'});
  }
  final backup = deck.winconBackup?.trim();
  if (backup != null && backup.isNotEmpty) {
    final parts = backup.split(RegExp(r'\s*;\s*'));
    for (final part in parts) {
      final name = part.trim();
      if (name.isEmpty) continue;
      wincons.add({'name': name, 'priority': 'backup'});
    }
  }
  return wincons;
}

Map<String, int> _roleSummary(CommanderLearnedDeckInput deck) {
  final metadata = deck.metadata;
  final keys = {
    'lands': 'total_lands',
    'ramp': 'ramp_count',
    'draw': 'draw_count',
    'removal': 'removal_count',
    'tutor': 'tutor_count',
    'board_wipe': 'board_wipe_count',
    'protection': 'protection_count',
    'recursion': 'recursion_count',
    'wincon': 'wincon_count',
    'engine': 'engine_count',
  };
  return {
    for (final entry in keys.entries)
      if (intValue(metadata[entry.value]) > 0)
        entry.key: intValue(metadata[entry.value]),
  };
}

String _sourceConfidence({
  required CommanderLearnedDeckInput learnedDeck,
  required Map<String, dynamic> legality,
  required Map<String, dynamic> validation,
}) {
  final legalStatus = learnedDeck.legalStatus?.trim().toLowerCase() ?? '';
  final explicitlyLegal =
      legalStatus == 'legal' || legalStatus == 'commander_legal';
  final isValid = validation['is_valid'] == true;
  final banned = legality['banned_cards'];
  final unknown = legality['unknown_legality_cards'];
  final noBanned = banned is List && banned.isEmpty;
  final noUnknown = unknown is List && unknown.isEmpty;
  if (isValid && noBanned && noUnknown && explicitlyLegal) {
    return 'high';
  }
  if (isValid && noBanned) return 'medium';
  return 'low';
}
