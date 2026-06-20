import 'dart:convert';

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
      final activeDecks = await _loadActiveLearnedDeckSummaries(pool);
      return Response.json(body: {
        'available': activeDecks.isNotEmpty,
        'source': 'pg_commander_learned_deck_summary',
        'count': activeDecks.length,
        'commanders': activeDecks,
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

    final roleMetadataResult =
        await canonicalizeCommanderLearnedDeckMetadataWithStatus(
      pool,
      learnedDeck,
    );
    final roleMetadata = roleMetadataResult.metadata;
    final recommendedDeck = await _buildRecommendedDeck(
      pool: pool,
      learnedDeck: learnedDeck,
      roleMetadata: roleMetadata,
      roleSummarySource: roleMetadataResult.source,
      roleSummaryFallbackReason: roleMetadataResult.fallbackReason,
    );
    return Response.json(body: {
      'commander': learnedDeck.commanderName,
      'available': true,
      'source': 'pg_commander_learned_decks',
      'promoted_deck': _promotedDeckSummary(
        learnedDeck,
        roleMetadata: roleMetadata,
        roleSummarySource: roleMetadataResult.source,
        roleSummaryFallbackReason: roleMetadataResult.fallbackReason,
      ),
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

Future<List<Map<String, dynamic>>> _loadActiveLearnedDeckSummaries(
  Pool pool,
) async {
  try {
    final result = await pool.execute('''
      WITH active AS (
        SELECT
          commander_name_normalized,
          commander_name,
          deck_name,
          source_system,
          source_ref,
          source_url,
          archetype,
          card_count,
          score,
          legal_status,
          promoted_at,
          updated_at
        FROM commander_learned_decks
        WHERE is_active = TRUE
      ),
      aggregate AS (
        SELECT
          commander_name_normalized,
          COUNT(*)::int AS active_learned_deck_count,
          ARRAY_REMOVE(ARRAY_AGG(DISTINCT archetype ORDER BY archetype), NULL)
            AS learned_archetypes
        FROM active
        GROUP BY commander_name_normalized
      ),
      primary_deck AS (
        SELECT DISTINCT ON (commander_name_normalized)
          commander_name_normalized,
          commander_name,
          deck_name,
          source_system,
          source_ref,
          source_url,
          archetype,
          card_count,
          score,
          legal_status,
          promoted_at,
          updated_at
        FROM active
        ORDER BY commander_name_normalized,
          score DESC NULLS LAST,
          promoted_at DESC NULLS LAST,
          updated_at DESC
      )
      SELECT
        primary_deck.commander_name,
        primary_deck.deck_name,
        primary_deck.source_system,
        primary_deck.source_ref,
        primary_deck.source_url,
        primary_deck.archetype,
        primary_deck.card_count,
        primary_deck.score,
        primary_deck.legal_status,
        primary_deck.promoted_at,
        primary_deck.updated_at,
        aggregate.active_learned_deck_count,
        aggregate.learned_archetypes
      FROM primary_deck
      JOIN aggregate
        ON aggregate.commander_name_normalized =
          primary_deck.commander_name_normalized
      ORDER BY primary_deck.commander_name ASC
    ''');

    return result.map((row) {
      final archetypes = _stringList(row[12]);
      return <String, dynamic>{
        'commander': row[0]?.toString(),
        'deck_name': row[1]?.toString(),
        'source_system': row[2]?.toString(),
        'source_ref': row[3]?.toString(),
        'source_url': row[4]?.toString(),
        'archetype': row[5]?.toString() ??
            (archetypes.isEmpty ? null : archetypes.first),
        'card_count': intValue(row[6]),
        'score': nullableDouble(row[7]),
        'legal_status': row[8]?.toString(),
        'promoted_at': row[9]?.toString(),
        'last_synced_at': row[10]?.toString(),
        'active_learned_deck_count': intValue(row[11]),
        'learned_archetypes': archetypes,
      };
    }).toList(growable: false);
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
  required Map<String, dynamic> roleMetadata,
  required String roleSummarySource,
  required String? roleSummaryFallbackReason,
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
  final decklist = buildCommanderLearnedDeckResponseDecklist(
    learnedDeck: learnedDeck,
    metadataByName: metadataByName,
  );

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
    'role_summary': _roleSummaryFromMetadata(roleMetadata),
    'role_summary_source': roleSummarySource,
    if (roleSummaryFallbackReason != null)
      'role_summary_fallback_reason': roleSummaryFallbackReason,
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
  };
}

Map<String, dynamic> _promotedDeckSummary(
  CommanderLearnedDeckInput deck, {
  required Map<String, dynamic> roleMetadata,
  required String roleSummarySource,
  required String? roleSummaryFallbackReason,
}) =>
    {
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
      'role_summary': _roleSummaryFromMetadata(roleMetadata),
      'role_summary_source': roleSummarySource,
      if (roleSummaryFallbackReason != null)
        'role_summary_fallback_reason': roleSummaryFallbackReason,
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

Map<String, int> _roleSummaryFromMetadata(Map<String, dynamic> metadata) {
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

List<String> _stringList(Object? value) {
  if (value is List) {
    return value
        .map((entry) => entry?.toString().trim() ?? '')
        .where((entry) => entry.isNotEmpty)
        .toList(growable: false);
  }
  final text = value?.toString().trim();
  if (text != null && text.isNotEmpty && text != 'null') {
    try {
      final decoded = jsonDecode(text);
      if (decoded is List) {
        return decoded
            .map((entry) => entry?.toString().trim() ?? '')
            .where((entry) => entry.isNotEmpty)
            .toList(growable: false);
      }
    } catch (_) {}
    final normalized = text.startsWith('{') && text.endsWith('}')
        ? text.substring(1, text.length - 1)
        : text;
    return normalized
        .split(RegExp(r'\s*,\s*'))
        .map((entry) => entry.trim())
        .where((entry) => entry.isNotEmpty)
        .toList(growable: false);
  }
  return const <String>[];
}
