import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;
import 'package:postgres/postgres.dart';

import '../../../lib/ai/commander_reference_card_stats_support.dart';
import '../../../lib/ai/commander_reference_deck_corpus_support.dart';
import '../../../lib/ai/commander_reference_generate_fallback_support.dart';
import '../../../lib/ai/commander_reference_helpers.dart';
import '../../../lib/ai/commander_reference_profile_support.dart';
import '../../../lib/ai/commander_reference_readiness_support.dart';
import '../../../lib/ai/commander_learned_deck_support.dart';
import '../../../lib/ai/deck_learning_event_support.dart';
import '../../../lib/ai/edhrec_service.dart';
import '../../../lib/basic_land_utils.dart' as basic_lands;
import '../../../lib/generated_deck_validation_service.dart';
import '../../../lib/http_responses.dart';
import '../../../lib/meta/meta_deck_card_list_support.dart';
import '../../../lib/meta/meta_deck_format_support.dart';
import '../../../lib/meta/mtgtop8_meta_support.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return methodNotAllowed();
  }

  try {
    final uri = context.request.uri;
    final commander = (uri.queryParameters['commander'] ?? '').trim();
    final limitRaw = uri.queryParameters['limit'];
    final limit = (int.tryParse(limitRaw ?? '') ?? 40).clamp(5, 200);
    final refresh = (uri.queryParameters['refresh'] ?? '').toLowerCase();
    final shouldRefresh =
        refresh == '1' || refresh == 'true' || refresh == 'yes';
    final includeLearning = _truthyQueryFlag(
      uri.queryParameters['learning'] ??
          uri.queryParameters['include_learning'],
    );
    final includeLearningDeck = includeLearning ||
        _truthyQueryFlag(
          uri.queryParameters['include_deck'] ??
              uri.queryParameters['learning_deck'],
        );
    final requestedMetaScope = normalizeCommanderMetaScope(
      uri.queryParameters['subformat'] ?? uri.queryParameters['scope'],
    );
    final commanderFormats =
        metaDeckFormatCodesForCommanderScope(requestedMetaScope);

    if (commander.isEmpty) {
      return badRequest('Query parameter commander is required.');
    }

    final pool = context.read<Pool>();
    await _ensureCommanderProfileCacheTable(pool);
    final cachedProfile = await _loadCommanderProfileCache(
      pool: pool,
      commander: commander,
    );
    final commanderLearning = includeLearning
        ? await _buildCommanderLearningPayload(
            pool: pool,
            commander: commander,
            limit: limit,
            includeDeck: includeLearningDeck,
          )
        : null;

    Map<String, dynamic>? refreshSummary;
    if (shouldRefresh) {
      refreshSummary = await _refreshCommanderFromMtgTop8(
        pool: pool,
        commander: commander,
      );
    }

    var decks = await pool.execute(
      Sql.named('''
        SELECT
          id::text,
          format,
          archetype,
          commander_name,
          partner_commander_name,
          shell_label,
          strategy_archetype,
          source_url,
          placement,
          card_list
        FROM meta_decks
        WHERE format = ANY(@formats)
          AND (
            LOWER(commander_name) = LOWER(@commanderExact)
            OR LOWER(partner_commander_name) = LOWER(@commanderExact)
            OR shell_label ILIKE @commanderPattern
            OR card_list ILIKE @commanderPattern
          )
        ORDER BY created_at DESC
        LIMIT 200
      '''),
      parameters: {
        'formats': TypedValue(Type.textArray, commanderFormats),
        'commanderExact': commander.replaceAll('%', '').trim(),
        'commanderPattern': '%${commander.replaceAll('%', '')}%',
      },
    );

    if (decks.isEmpty) {
      final commanderToken = commander.split(',').first.trim();
      if (commanderToken.isNotEmpty) {
        decks = await pool.execute(
          Sql.named('''
            SELECT
              id::text,
              format,
              archetype,
              commander_name,
              partner_commander_name,
              shell_label,
              strategy_archetype,
              source_url,
              placement,
              card_list
            FROM meta_decks
            WHERE format = ANY(@formats)
              AND (
                shell_label ILIKE @archetypePattern
                OR archetype ILIKE @archetypePattern
              )
            ORDER BY created_at DESC
            LIMIT 200
          '''),
          parameters: {
            'formats': TypedValue(Type.textArray, commanderFormats),
            'archetypePattern': '%${commanderToken.replaceAll('%', '')}%',
          },
        );
      }
    }

    if (decks.isEmpty) {
      final needsCacheUpgrade = cachedProfile != null &&
          !_hasExtendedCommanderReferenceBase(cachedProfile);

      final edhrecProfile =
          (shouldRefresh || cachedProfile == null || needsCacheUpgrade)
              ? await _buildAndPersistEdhrecProfile(
                  pool: pool,
                  commander: commander,
                )
              : cachedProfile;

      if (edhrecProfile != null) {
        final edhrecCards = (edhrecProfile['top_cards'] as List?)
                ?.whereType<Map>()
                .map((e) => e.cast<String, dynamic>())
                .toList() ??
            const <Map<String, dynamic>>[];

        return Response.json(body: {
          'commander': commander,
          'meta_decks_found': 0,
          'reference_cards': edhrecCards
              .take(limit)
              .map((c) => {
                    'name': c['name'],
                    'total_copies': 0,
                    'appears_in_decks': c['num_decks'] ?? 0,
                    'usage_rate': c['inclusion'] ?? 0.0,
                    'synergy': c['synergy'] ?? 0.0,
                    'category': c['category'] ?? 'other',
                  })
              .toList(),
          'sample_decks': const <Map<String, dynamic>>[],
          'model': {
            'type': 'commander_reference_profile',
            'source': 'edhrec',
            'generated_from_meta_decks': 0,
            'generated_from_edhrec': true,
            'meta_scope': requestedMetaScope,
            'top_non_basic_cards': edhrecCards
                .map((e) => e['name'])
                .whereType<String>()
                .take(limit)
                .toList(),
          },
          'meta_scope': _buildMetaScopePayload(requestedMetaScope),
          'commander_profile': edhrecProfile,
          if (commanderLearning != null)
            'commander_learning': commanderLearning,
          if (refreshSummary != null) 'refresh': refreshSummary,
        });
      }

      List<dynamic> fallback = const [];
      try {
        fallback = await pool.execute(
          Sql.named('''
            SELECT card_name, usage_count, meta_deck_count
            FROM card_meta_insights
            WHERE @commander = ANY(common_commanders)
            ORDER BY meta_deck_count DESC, usage_count DESC, card_name ASC
            LIMIT @limit
          '''),
          parameters: {
            'commander': commander,
            'limit': limit,
          },
        );
      } catch (_) {
        fallback = const [];
      }

      if (fallback.isEmpty) {
        return Response.json(body: {
          'commander': commander,
          'meta_decks_found': 0,
          'reference_cards': <Map<String, dynamic>>[],
          'sample_decks': <Map<String, dynamic>>[],
          'message':
              'Nenhum deck competitivo encontrado para esse comandante no acervo atual.',
          'meta_scope': _buildMetaScopePayload(requestedMetaScope),
          if (cachedProfile != null) 'commander_profile': cachedProfile,
          if (commanderLearning != null)
            'commander_learning': commanderLearning,
        });
      }

      final cards = fallback.map((row) {
        final name = (row[0] as String?) ?? '';
        final usage = (row[1] as int?) ?? 0;
        final metaCount = (row[2] as int?) ?? 0;
        return {
          'name': name,
          'total_copies': usage,
          'appears_in_decks': metaCount,
          'usage_rate': 0.0,
        };
      }).toList();

      return Response.json(body: {
        'commander': commander,
        'meta_decks_found': 0,
        'reference_cards': cards,
        'sample_decks': <Map<String, dynamic>>[],
        'model': {
          'type': 'commander_competitive_reference',
          'generated_from_meta_decks': 0,
          'generated_from_card_meta_insights': true,
          'meta_scope': requestedMetaScope,
          'top_non_basic_cards': cards.map((e) => e['name']).toList(),
        },
        'meta_scope': _buildMetaScopePayload(requestedMetaScope),
        if (cachedProfile != null) 'commander_profile': cachedProfile,
        if (commanderLearning != null) 'commander_learning': commanderLearning,
        if (refreshSummary != null) 'refresh': refreshSummary,
      });
    }

    final commanderLower = commander.toLowerCase();
    final counts = <String, int>{};
    final deckAppearances = <String, int>{};
    final sampleDecks = <Map<String, dynamic>>[];
    final metaScopeBreakdown = <String, int>{};

    for (final row in decks) {
      final deckId = row[0] as String;
      final storedFormat = (row[1] as String?) ?? '';
      final archetype = (row[2] as String?) ?? 'unknown';
      final commanderName = (row[3] as String?) ?? '';
      final partnerCommanderName = (row[4] as String?) ?? '';
      final shellLabel = (row[5] as String?) ?? '';
      final strategyArchetype = (row[6] as String?) ?? '';
      final sourceUrl = (row[7] as String?) ?? '';
      final placement = (row[8] as String?) ?? '';
      final rawList = (row[9] as String?) ?? '';
      final formatDescriptor = describeMetaDeckFormat(storedFormat);
      final subformatKey = formatDescriptor.commanderSubformat ??
          formatDescriptor.storedFormatCode;
      metaScopeBreakdown[subformatKey] =
          (metaScopeBreakdown[subformatKey] ?? 0) + 1;

      if (sampleDecks.length < 10) {
        sampleDecks.add({
          'id': deckId,
          'format_code': formatDescriptor.storedFormatCode,
          'format_label': formatDescriptor.label,
          'subformat': formatDescriptor.commanderSubformat,
          'archetype': archetype,
          'commander_name': commanderName.isEmpty ? null : commanderName,
          'partner_commander_name':
              partnerCommanderName.isEmpty ? null : partnerCommanderName,
          'shell_label': shellLabel.isEmpty ? null : shellLabel,
          'strategy_archetype':
              strategyArchetype.isEmpty ? null : strategyArchetype,
          'source_url': sourceUrl,
          'placement': placement,
        });
      }

      final seenInDeck = <String>{};
      final parsedDeck = parseMetaDeckCardList(
        cardList: rawList,
        format: storedFormat,
      );

      for (final entry in parsedDeck.mainboard.entries) {
        final name = entry.key;
        final lower = name.toLowerCase();
        if (lower == commanderLower || basic_lands.isBasicLandName(lower)) {
          continue;
        }

        counts[name] = (counts[name] ?? 0) + entry.value;
        if (!seenInDeck.contains(lower)) {
          deckAppearances[name] = (deckAppearances[name] ?? 0) + 1;
          seenInDeck.add(lower);
        }
      }
    }

    final totalDecks = decks.length;
    final sorted = counts.entries.toList()
      ..sort((a, b) {
        final byCount = b.value.compareTo(a.value);
        if (byCount != 0) return byCount;
        return a.key.compareTo(b.key);
      });

    final references = sorted.take(limit).map((e) {
      final appearances = deckAppearances[e.key] ?? 0;
      final usageRate = totalDecks > 0 ? appearances / totalDecks : 0.0;
      return {
        'name': e.key,
        'total_copies': e.value,
        'appears_in_decks': appearances,
        'usage_rate': double.parse(usageRate.toStringAsFixed(3)),
      };
    }).toList();

    return Response.json(body: {
      'commander': commander,
      'meta_decks_found': totalDecks,
      'reference_cards': references,
      'sample_decks': sampleDecks,
      'model': {
        'type': 'commander_competitive_reference',
        'generated_from_meta_decks': totalDecks,
        'meta_scope': requestedMetaScope,
        'top_non_basic_cards': references.map((e) => e['name']).toList(),
      },
      'meta_scope': _buildMetaScopePayload(requestedMetaScope),
      'meta_scope_breakdown': metaScopeBreakdown,
      if (cachedProfile != null) 'commander_profile': cachedProfile,
      if (commanderLearning != null) 'commander_learning': commanderLearning,
      if (refreshSummary != null) 'refresh': refreshSummary,
    });
  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {
        'error': 'Failed to build commander reference model.',
        'details': e.toString(),
      },
    );
  }
}

bool _truthyQueryFlag(String? raw) {
  final value = raw?.trim().toLowerCase();
  return value == '1' || value == 'true' || value == 'yes';
}

Future<Map<String, dynamic>?> _buildCommanderLearningPayload({
  required Pool pool,
  required String commander,
  required int limit,
  required bool includeDeck,
}) async {
  final profile = await loadUsableCommanderReferenceProfile(
    pool: pool,
    commanderName: commander,
  );
  final statsLoad = await loadUsableCommanderReferenceCardStats(
    pool: pool,
    commanderName: commander,
  );
  final corpus = await loadCommanderReferenceDeckCorpusGuidance(
    pool: pool,
    commanderName: commander,
  );
  final promotedLearnedDeck = await _loadPromotedCommanderLearnedDeck(
    pool: pool,
    commanderName: commander,
  );

  if (profile == null &&
      statsLoad.stats.isEmpty &&
      corpus == null &&
      promotedLearnedDeck == null) {
    return null;
  }

  Map<String, dynamic>? readiness;
  try {
    readiness = (await buildCommanderReferenceReadinessScorecard(
      pool: pool,
      commanderName: commander,
    ))
        .toJson();
  } catch (error) {
    readiness = {
      'status': 'unavailable',
      'error': error.runtimeType.toString(),
    };
  }

  final learningDeck = includeDeck
      ? promotedLearnedDeck != null
          ? await _buildPromotedCommanderLearningDeck(
              pool: pool,
              learnedDeck: promotedLearnedDeck,
              stats: statsLoad.stats,
              corpus: corpus,
            )
          : profile != null
              ? await _buildReferenceLearningDeck(
                  pool: pool,
                  profile: profile,
                  stats: statsLoad.stats,
                  corpus: corpus,
                )
              : null
      : null;

  final winConditions = _buildCommanderLearningWinConditions(
    stats: statsLoad.stats,
    corpus: corpus,
    deckCards: learningDeck?['cards'] as List?,
  );

  return {
    'available': true,
    'source': 'pg_commander_reference',
    'model': {
      'type': 'commander_learning_reference',
      'runtime_dependency': 'postgres',
      'hermes_runtime_dependency': false,
      'deck_included': learningDeck != null,
    },
    if (promotedLearnedDeck != null)
      'promoted_deck': _promotedLearnedDeckSummary(promotedLearnedDeck),
    if (profile != null)
      'profile': {
        'commander': profile['commander'] ?? profile['commander_name'],
        'version': commanderReferenceProfileCacheVersion(profile),
        'source': profile['source'],
        'confidence': normalizeCommanderReferenceConfidence(
          profile['confidence'],
        ),
        'source_count': intValue(profile['source_count']),
        'themes': _themeNames(profile).take(8).toList(growable: false),
        'role_targets': profile['role_targets'],
      },
    'card_stats': {
      'count': statsLoad.stats.length,
      'unresolved_reference_cards': statsLoad.unresolvedCardNames,
      'cache_version': commanderReferenceCardStatsCacheVersion(statsLoad.stats),
      'top_cards': statsLoad.stats
          .take(limit)
          .map((stat) => stat.toJson())
          .toList(growable: false),
    },
    if (corpus != null) 'deck_corpus': corpus.toDiagnostics(),
    'win_conditions': winConditions,
    'readiness': readiness,
    if (!includeDeck)
      'deck_note':
          'Pass learning=1&include_deck=1 to include the deterministic reference decklist.',
    if (learningDeck != null) 'recommended_deck': learningDeck,
    'usage': await _loadUsageStatsSafe(pool: pool, commanderName: commander),
  };
}

Future<Map<String, dynamic>> _loadUsageStatsSafe({
  required Pool pool,
  required String commanderName,
}) async {
  try {
    final hotCards = await loadUsageHotCards(
      pool: pool,
      commanderName: commanderName,
      limit: 20,
    );
    return {
      'available': true,
      'hot_cards': hotCards,
      'total_users':
          hotCards.fold<int>(0, (sum, c) => sum + intValue(c['usage_count'])),
    };
  } catch (_) {
    return {'available': false, 'hot_cards': const <Map<String, dynamic>>[]};
  }
}

Future<Map<String, dynamic>?> _loadPromotedCommanderLearnedDeck({
  required Pool pool,
  required String commanderName,
}) async {
  try {
    final result = await pool.execute(
      Sql.named('''
        SELECT
          id::text,
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
        LIMIT 10
      '''),
      parameters: {
        'commander': normalizeCommanderReferenceName(commanderName),
      },
    );
    if (result.isEmpty) return null;
    for (final row in result) {
      final learnedDeck = {
        'id': row[0]?.toString(),
        'commander_name': row[1]?.toString(),
        'deck_name': row[2]?.toString(),
        'source_system': row[3]?.toString(),
        'source_ref': row[4]?.toString(),
        'source_url': row[5]?.toString(),
        'archetype': row[6]?.toString(),
        'card_list': row[7]?.toString() ?? '',
        'card_count': intValue(row[8]),
        'score': _doubleValue(row[9]),
        'wincon_primary': row[10]?.toString(),
        'wincon_backup': row[11]?.toString(),
        'legal_status': row[12]?.toString(),
        'notes': row[13]?.toString(),
        'metadata': jsonObject(row[14]),
        'is_active': row[15] == true,
        'promoted_at': row[16]?.toString(),
        'updated_at': row[17]?.toString(),
      };
      final input = parseCommanderLearnedDeckInput(learnedDeck);
      if (isCompleteCommanderLearnedDeckInput(input)) {
        return learnedDeck;
      }
    }
    return null;
  } catch (error) {
    if (isUndefinedLearnedDeckTableError(error)) return null;
    rethrow;
  }
}

Map<String, dynamic> _promotedLearnedDeckSummary(
  Map<String, dynamic> learnedDeck,
) {
  return {
    'id': learnedDeck['id'],
    'commander': learnedDeck['commander_name'],
    'deck_name': learnedDeck['deck_name'],
    'source_system': learnedDeck['source_system'],
    'source_ref': learnedDeck['source_ref'],
    'source_url': learnedDeck['source_url'],
    'archetype': learnedDeck['archetype'],
    'card_count': learnedDeck['card_count'],
    'score': learnedDeck['score'],
    'legal_status': learnedDeck['legal_status'],
    'promoted_at': learnedDeck['promoted_at'],
    'updated_at': learnedDeck['updated_at'],
  };
}

Future<Map<String, dynamic>> _buildPromotedCommanderLearningDeck({
  required Pool pool,
  required Map<String, dynamic> learnedDeck,
  required List<CommanderReferenceCardStat> stats,
  required CommanderReferenceDeckCorpusGuidance? corpus,
}) async {
  final commanderName = learnedDeck['commander_name']?.toString().trim() ?? '';
  final deckEntries = _parseLearnedDeckCardList(
    learnedDeck['card_list']?.toString() ?? '',
  );
  final normalizedCommander =
      normalizeCommanderReferenceCardName(commanderName);
  final mainCards = deckEntries
      .where((card) =>
          normalizeCommanderReferenceCardName(card['name']?.toString() ?? '') !=
          normalizedCommander)
      .toList(growable: false);

  final metadataByName = await loadCardMetadataByName(
    pool: pool,
    names: deckEntries.map((card) => card['name']?.toString() ?? ''),
  );
  final statsByName = {
    for (final stat in stats) stat.cardNameNormalized: stat,
  };
  final corpusRoleByName = _corpusRoleByName(corpus);
  final decklist = deckEntries.map((card) {
    final name = card['name']?.toString().trim() ?? '';
    final normalized = normalizeCommanderReferenceCardName(name);
    final stat = statsByName[normalized];
    final metadata = metadataByName[normalized];
    final corpusRole = corpusRoleByName[normalized];
    final isCommander = normalized == normalizedCommander;
    return {
      'name': name,
      'quantity': intValue(card['quantity']).clamp(1, 99),
      'is_commander': isCommander,
      if (metadata?['id'] != null) 'card_id': metadata!['id'],
      if (metadata?['name'] != null && metadata!['name'] != name)
        'canonical_name': metadata['name'],
      if (metadata?['type_line'] != null) 'type_line': metadata!['type_line'],
      'commander_legal_status': metadata?['commander_legal_status'],
      'role': isCommander
          ? 'commander'
          : stat?.role ?? corpusRole ?? _fallbackRoleForCardName(name),
      'rationale': isCommander
          ? 'Commander of the promoted learned deck.'
          : _cardRationale(
              name: name,
              stat: stat,
              corpusRole: corpusRole,
            ),
      if (stat != null) 'reference_score': stat.score,
      if (stat != null) 'reference_package': stat.packageKey,
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
  final legality = summarizeLegalities(
    decklist,
    validation.validationSummary(),
  );

  return {
    'source': 'promoted_learned_deck_pg',
    'source_system': learnedDeck['source_system'],
    'source_ref': learnedDeck['source_ref'],
    'deck_name': learnedDeck['deck_name'],
    'archetype': learnedDeck['archetype'],
    'score': learnedDeck['score'],
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
    'validation': validation.validationSummary(),
  };
}

List<Map<String, dynamic>> _parseLearnedDeckCardList(String cardList) {
  final cards = <Map<String, dynamic>>[];
  for (final rawLine in cardList.split(RegExp(r'\r?\n'))) {
    final line = rawLine.trim();
    if (line.isEmpty) continue;
    final match = RegExp(r'^(\d+)\s+(.+)$').firstMatch(line);
    if (match == null) {
      cards.add({'name': line, 'quantity': 1});
      continue;
    }
    cards.add({
      'name': match.group(2)!.trim(),
      'quantity': int.tryParse(match.group(1)!) ?? 1,
    });
  }
  return cards;
}

Future<Map<String, dynamic>> _buildReferenceLearningDeck({
  required Pool pool,
  required Map<String, dynamic> profile,
  required List<CommanderReferenceCardStat> stats,
  required CommanderReferenceDeckCorpusGuidance? corpus,
}) async {
  final rawDeck = buildDeterministicReferenceDeck(
    profile: profile,
    referenceCardStats: stats,
    referenceDeckCorpusGuidance: corpus,
  );
  final commander = rawDeck['commander'];
  final commanderName = commander is Map
      ? commander['name']?.toString().trim()
      : commander?.toString().trim();
  final cards = (rawDeck['cards'] as List?)
          ?.whereType<Map>()
          .map((card) => card.cast<String, dynamic>())
          .toList(growable: false) ??
      const <Map<String, dynamic>>[];

  final metadataByName = await loadCardMetadataByName(
    pool: pool,
    names: [
      if (commanderName != null && commanderName.isNotEmpty) commanderName,
      ...cards.map((card) => card['name']?.toString() ?? ''),
    ],
  );
  final statsByName = {
    for (final stat in stats) stat.cardNameNormalized: stat,
  };
  final corpusRoleByName = _corpusRoleByName(corpus);
  final enrichedCards = cards.map((card) {
    final name = card['name']?.toString().trim() ?? '';
    final normalized = normalizeCommanderReferenceCardName(name);
    final stat = statsByName[normalized];
    final metadata = metadataByName[normalized];
    final corpusRole = corpusRoleByName[normalized];
    return {
      'name': name,
      'quantity': intValue(card['quantity']).clamp(1, 99),
      if (metadata?['id'] != null) 'card_id': metadata!['id'],
      if (metadata?['name'] != null && metadata!['name'] != name)
        'canonical_name': metadata['name'],
      if (metadata?['type_line'] != null) 'type_line': metadata!['type_line'],
      'commander_legal_status': metadata?['commander_legal_status'],
      'role': stat?.role ?? corpusRole ?? _fallbackRoleForCardName(name),
      'rationale': _cardRationale(
        name: name,
        stat: stat,
        corpusRole: corpusRole,
      ),
      if (stat != null) 'reference_score': stat.score,
      if (stat != null) 'reference_package': stat.packageKey,
    };
  }).toList(growable: false);

  final validation = await GeneratedDeckValidationService(
    PostgresGeneratedDeckRepository(pool, preferredFormat: 'commander'),
  ).validate(
    format: 'commander',
    cards: canonicalValidationCards(cards, metadataByName),
    commanderName: commanderName,
  );
  final legality = summarizeLegalities(
    enrichedCards,
    validation.validationSummary(),
  );

  return {
    'source': 'deterministic_commander_reference_backend',
    'commander': {
      'name': commanderName,
      if (commanderName != null)
        'commander_legal_status':
            metadataByName[normalizeCommanderReferenceCardName(commanderName)]
                ?['commander_legal_status'],
    },
    'total_cards_including_commander': 1 +
        enrichedCards.fold<int>(
            0, (sum, card) => sum + intValue(card['quantity'])),
    'main_quantity': enrichedCards.fold<int>(
        0, (sum, card) => sum + intValue(card['quantity'])),
    'cards': enrichedCards,
    'legality': legality,
    'validation': validation.validationSummary(),
  };
}

Map<String, String> _corpusRoleByName(
  CommanderReferenceDeckCorpusGuidance? corpus,
) {
  if (corpus == null) return const {};
  return {
    for (final card in corpus.topCards)
      normalizeCommanderReferenceCardName(card['card_name']?.toString() ?? ''):
          card['role']?.toString() ?? 'reference_corpus_card',
  };
}

List<Map<String, dynamic>> _buildCommanderLearningWinConditions({
  required List<CommanderReferenceCardStat> stats,
  required CommanderReferenceDeckCorpusGuidance? corpus,
  required List? deckCards,
}) {
  final deckNames = deckCards
          ?.whereType<Map>()
          .map((card) => normalizeCommanderReferenceCardName(
                card['name']?.toString() ?? '',
              ))
          .toSet() ??
      const <String>{};
  final candidates = <String, Map<String, dynamic>>{};

  void add({
    required String name,
    required String role,
    required String source,
    double? score,
  }) {
    final normalized = normalizeCommanderReferenceCardName(name);
    if (normalized.isEmpty) return;
    final text = '$name $role'.toLowerCase();
    final looksLikeWincon = text.contains('win') ||
        text.contains('haymaker') ||
        text.contains('payoff') ||
        text.contains('damage') ||
        text.contains('storm') ||
        text.contains('approach') ||
        text.contains('mastery');
    if (!looksLikeWincon) return;
    candidates[normalized] = {
      'name': name,
      'role': role,
      'source': source,
      if (score != null) 'score': score,
      'present_in_recommended_deck': deckNames.contains(normalized),
    };
  }

  for (final stat in stats) {
    add(
      name: stat.cardName,
      role: stat.role,
      source: stat.source,
      score: stat.score,
    );
  }
  for (final card in corpus?.topCards ?? const <Map<String, dynamic>>[]) {
    add(
      name: card['card_name']?.toString() ?? '',
      role: card['role']?.toString() ?? 'reference_corpus_card',
      source: corpus?.source ?? 'commander_reference_deck_corpus',
      score: _doubleValue(card['deck_count']),
    );
  }

  final values = candidates.values.toList(growable: false)
    ..sort(
        (a, b) => _doubleValue(b['score']).compareTo(_doubleValue(a['score'])));
  return values.take(16).toList(growable: false);
}

String _cardRationale({
  required String name,
  required CommanderReferenceCardStat? stat,
  required String? corpusRole,
}) {
  if (stat != null) {
    return 'Matched ${stat.packageKey} as ${stat.role} from ${stat.source}.';
  }
  if (corpusRole != null && corpusRole.isNotEmpty) {
    return 'Appears in accepted commander reference corpus as $corpusRole.';
  }
  final role = _fallbackRoleForCardName(name);
  return role == 'lands'
      ? 'Basic land filler for Commander deck size and color requirements.'
      : 'Deterministic fallback card for reference deck balance.';
}

String _fallbackRoleForCardName(String name) {
  final normalized = name.trim().toLowerCase();
  if (basic_lands.isBasicLandName(normalized)) return 'lands';
  return 'support';
}

List<String> _themeNames(Map<String, dynamic> profile) {
  final rawThemes = profile['themes'];
  if (rawThemes is! List) return const [];
  return rawThemes
      .map((theme) {
        if (theme is Map && theme['name'] != null) {
          return theme['name'].toString().trim();
        }
        return theme.toString().trim();
      })
      .where((theme) => theme.isNotEmpty)
      .toList(growable: false);
}

double _doubleValue(Object? value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

Future<void> _ensureCommanderProfileCacheTable(Pool pool) async {
  await pool.execute('''
    CREATE TABLE IF NOT EXISTS commander_reference_profiles (
      commander_name TEXT PRIMARY KEY,
      source TEXT NOT NULL,
      deck_count INTEGER NOT NULL DEFAULT 0,
      profile_json JSONB NOT NULL,
      updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    )
  ''');
}

Future<Map<String, dynamic>?> _loadCommanderProfileCache({
  required Pool pool,
  required String commander,
}) async {
  final result = await pool.execute(
    Sql.named('''
      SELECT profile_json
      FROM commander_reference_profiles
      WHERE LOWER(commander_name) = LOWER(@commander)
      LIMIT 1
    '''),
    parameters: {'commander': commander},
  );

  if (result.isEmpty) return null;
  final payload = result.first[0];
  if (payload is Map<String, dynamic>)
    return Map<String, dynamic>.from(payload);
  if (payload is Map) return payload.cast<String, dynamic>();
  return null;
}

Future<Map<String, dynamic>?> _buildAndPersistEdhrecProfile({
  required Pool pool,
  required String commander,
}) async {
  final service = EdhrecService();
  final data = await service.fetchCommanderData(commander);
  if (data == null || data.topCards.isEmpty) return null;
  final averageDeck = await service.fetchAverageDeckData(commander);

  final nonLandCategories = <String, double>{};
  final topCards = <Map<String, dynamic>>[];

  for (final card in data.topCards.take(180)) {
    final category = card.category;
    final inclusion = card.inclusion <= 0 ? 0.001 : card.inclusion;
    if (category != 'lands') {
      nonLandCategories[category] =
          (nonLandCategories[category] ?? 0) + inclusion;
    }
    if (category == 'lands') continue;
    topCards.add({
      'name': card.name,
      'category': card.category,
      'synergy': double.parse(card.synergy.toStringAsFixed(4)),
      'inclusion': double.parse(card.inclusion.toStringAsFixed(4)),
      'num_decks': card.numDecks,
    });
  }

  const recommendedLands = 36;
  const totalDeckCards = 99;
  const commanderSlot = 1;
  final nonLandTarget = totalDeckCards - commanderSlot - recommendedLands;
  final averageDeckSeed = <Map<String, dynamic>>[];
  if (averageDeck != null) {
    for (final card in averageDeck.seedCards.take(180)) {
      if (basic_lands.isBasicLandName(card.name)) continue;
      final cardName = card.name.trim();
      if (cardName.isEmpty) continue;
      averageDeckSeed.add({
        'name': cardName,
        'quantity': card.quantity,
      });
    }
  }

  final categoryTargets = <String, int>{};
  final totalWeight = nonLandCategories.values.fold<double>(0, (a, b) => a + b);
  if (totalWeight > 0) {
    for (final entry in nonLandCategories.entries) {
      categoryTargets[entry.key] =
          ((entry.value / totalWeight) * nonLandTarget).round();
    }
  }

  var sumTargets = categoryTargets.values.fold<int>(0, (a, b) => a + b);
  if (sumTargets < nonLandTarget && categoryTargets.isNotEmpty) {
    final ordered = categoryTargets.entries.toList()
      ..sort((a, b) => (nonLandCategories[b.key] ?? 0)
          .compareTo(nonLandCategories[a.key] ?? 0));
    var i = 0;
    while (sumTargets < nonLandTarget) {
      final key = ordered[i % ordered.length].key;
      categoryTargets[key] = (categoryTargets[key] ?? 0) + 1;
      sumTargets++;
      i++;
    }
  }

  final profile = {
    ...buildCommanderReferenceProfilePayload(
      commanderName: commander,
      version: '',
      source: 'edhrec',
      confidence: commanderReferenceConfidenceFromDeckCount(data.deckCount),
      sourceCount: data.deckCount > 0 ? 1 : 0,
      colorIdentity: const [],
      themes: const [],
      roleTargets: const {},
      expectedPackages: const {},
      avoidPatterns: const [],
      sourceLimitNotes: const [
        'Single-source EDHREC aggregate commander page. Use with card_stats/corpus enrichment; do not treat as copied decklist evidence.',
      ],
      updatedAt: DateTime.now().toUtc(),
    ),
    'deck_count': data.deckCount,
    'themes': data.themes,
    'average_type_distribution': data.averageTypeDistribution,
    'mana_curve': data.manaCurve,
    'articles': data.articles,
    'reference_bases': {
      'provider': 'edhrec',
      'category': 'commander_only',
      'description':
          'Base específica de commander (não representa meta global cross-commander).',
      'saved_fields': [
        'average_type_distribution',
        'mana_curve',
        'articles',
        'themes',
        'top_cards',
        'average_deck_seed',
      ],
    },
    'recommended_structure': {
      'total_cards': totalDeckCards,
      'commander_slots': commanderSlot,
      'lands': recommendedLands,
      'non_lands': nonLandTarget,
      'category_targets': categoryTargets,
    },
    'average_deck_seed': averageDeckSeed,
    'top_cards': topCards.take(120).toList(),
  };

  await pool.execute(
    Sql.named('''
      INSERT INTO commander_reference_profiles (
        commander_name,
        source,
        deck_count,
        profile_json,
        updated_at
      ) VALUES (
        @commander,
        'edhrec',
        @deckCount,
        @profile::jsonb,
        NOW()
      )
      ON CONFLICT (commander_name)
      DO UPDATE SET
        source = EXCLUDED.source,
        deck_count = EXCLUDED.deck_count,
        profile_json = EXCLUDED.profile_json,
        updated_at = NOW()
    '''),
    parameters: {
      'commander': commander,
      'deckCount': data.deckCount,
      'profile': jsonEncode(profile),
    },
  );

  return profile;
}

bool _hasExtendedCommanderReferenceBase(Map<String, dynamic> profile) {
  final hasAverage = profile['average_type_distribution'] is Map;
  final hasCurve = profile['mana_curve'] is Map;
  final hasAverageDeckSeed = profile['average_deck_seed'] is List;
  final referenceBases = profile['reference_bases'];
  if (!hasAverage ||
      !hasCurve ||
      !hasAverageDeckSeed ||
      referenceBases is! Map) {
    return false;
  }
  final category = referenceBases['category']?.toString().toLowerCase();
  return category == 'commander_only';
}

Future<Map<String, dynamic>> _refreshCommanderFromMtgTop8({
  required Pool pool,
  required String commander,
}) async {
  final formats = metaDeckFormatCodesForCommanderScope('commander');

  final commanderToken = commander.split(',').first.trim().toLowerCase();
  if (commanderToken.isEmpty) {
    return {
      'enabled': true,
      'imported': 0,
      'scanned_events': 0,
      'scanned_decks': 0,
      'matched_commander': false,
    };
  }

  var imported = 0;
  var scannedEvents = 0;
  var scannedDecks = 0;
  var matchedCommander = false;

  for (final formatCode in formats) {
    final formatUrl = '$mtgTop8BaseUrl/format?f=$formatCode';
    final formatRes = await http.get(Uri.parse(formatUrl));
    if (formatRes.statusCode != 200) continue;

    final formatDoc = html_parser.parse(formatRes.body);
    final eventLinks = extractRecentMtgTop8EventPaths(formatDoc, limit: 3);

    for (final eventPath in eventLinks) {
      scannedEvents += 1;
      final eventUrl = resolveMtgTop8Url(eventPath);
      final eventRes = await http.get(Uri.parse(eventUrl));
      if (eventRes.statusCode != 200) continue;

      final eventDoc = html_parser.parse(eventRes.body);
      final rows = eventDoc.querySelectorAll('div.hover_tr').take(10).toList();

      for (final row in rows) {
        final parsedRow = parseMtgTop8EventDeckRow(
          row,
          defaultFormatCode: formatCode,
        );
        if (parsedRow == null) continue;

        scannedDecks += 1;
        final deckUrl = parsedRow.deckUrl;

        final exists = await pool.execute(
          Sql.named('SELECT 1 FROM meta_decks WHERE source_url = @url LIMIT 1'),
          parameters: {'url': deckUrl},
        );
        if (exists.isNotEmpty) continue;

        final exportUrl = '$mtgTop8BaseUrl/mtgo?d=${parsedRow.deckId}';
        final exportRes = await http.get(Uri.parse(exportUrl));
        if (exportRes.statusCode != 200) continue;

        final cardList = exportRes.body;
        if (!_deckListContainsCommander(cardList, commanderToken)) {
          continue;
        }

        matchedCommander = true;
        await pool.execute(
          Sql.named('''
            INSERT INTO meta_decks (format, archetype, source_url, card_list, placement)
            VALUES (@format, @archetype, @url, @list, @placement)
            ON CONFLICT (source_url) DO NOTHING
          '''),
          parameters: {
            'format': parsedRow.formatCode,
            'archetype': parsedRow.archetype,
            'url': deckUrl,
            'list': cardList,
            'placement': parsedRow.placement,
          },
        );

        imported += 1;
      }
    }
  }

  return {
    'enabled': true,
    'imported': imported,
    'scanned_events': scannedEvents,
    'scanned_decks': scannedDecks,
    'matched_commander': matchedCommander,
  };
}

bool _deckListContainsCommander(String cardList, String commanderToken) {
  if (cardList.trim().isEmpty || commanderToken.trim().isEmpty) return false;
  final normalized = cardList.toLowerCase();
  return normalized.contains(commanderToken);
}

Map<String, dynamic> _buildMetaScopePayload(String requestedMetaScope) {
  return {
    'requested': requestedMetaScope,
    'label': commanderMetaScopeLabel(requestedMetaScope),
    'format_codes': metaDeckFormatCodesForCommanderScope(requestedMetaScope),
    'subformats': commanderSubformatsForScope(requestedMetaScope),
    'compatibility_note':
        'MTGTop8 EDH representa Duel Commander; cEDH representa Competitive Commander.',
  };
}
