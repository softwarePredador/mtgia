import 'dart:async';

import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

import '../../lib/deck_schema_support.dart';
import '../../lib/deck_validation_state_support.dart';
import '../../lib/deck_card_name_resolution_support.dart';
import '../../lib/deck_format_support.dart';
import '../../lib/deck_readiness_contract.dart';
import '../../lib/deck_request_support.dart';
import '../../lib/commander_bracket.dart';
import '../../lib/deck_rules_service.dart';
import '../../lib/http_responses.dart';
import '../../lib/logger.dart';
import '../../lib/observability.dart';
import '../../lib/scryfall_image_url.dart';
import '../../lib/ai/deck_learning_event_support.dart';

Future<Response> onRequest(RequestContext context) async {
  // Este arquivo vai lidar com diferentes métodos HTTP para a rota /decks
  if (context.request.method == HttpMethod.post) {
    return _createDeck(context);
  }

  // Futuramente, podemos adicionar o método GET para listar os decks do usuário
  if (context.request.method == HttpMethod.get) {
    return _listDecks(context);
  }

  return methodNotAllowed();
}

/// Lista os decks do usuário autenticado.
Future<Response> _listDecks(RequestContext context) async {
  Log.d('📥 [GET /decks] Iniciando listagem de decks...');

  try {
    final userId = context.read<String>();
    Log.d('👤 User ID identificado: $userId');

    final conn = context.read<Pool>();
    Log.d('🔌 Conexão com banco obtida.');

    Log.d('🔍 Executando query SELECT...');
    final hasMeta = await hasDeckMetaColumns(conn);
    final hasPricing = await hasDeckPricingColumns(conn);
    final hasPricingSource = await hasDeckPricingSourceColumn(conn);
    final hasValidationState = await hasDeckValidationStateColumns(conn);
    final baseSql =
        hasMeta
            ? (hasPricing
                ? '''
        SELECT 
          d.id, 
          d.name, 
          d.format, 
          d.description, 
          d.archetype,
          d.bracket,
          d.synergy_score, 
          d.is_public,
          d.pricing_currency,
          d.pricing_total,
          d.pricing_missing_cards,
          ${hasPricingSource ? 'd.pricing_source' : 'NULL::text AS pricing_source'},
          d.pricing_updated_at,
          d.created_at,
          cmd.commander_name,
          cmd.commander_image_url,
          COALESCE(SUM(dc.quantity), 0)::int as card_count
        FROM decks d
        LEFT JOIN LATERAL (
          SELECT 
            c.name as commander_name,
            c.image_url as commander_image_url
          FROM deck_cards dc_cmd
          JOIN cards c ON c.id = dc_cmd.card_id
          WHERE dc_cmd.deck_id = d.id
            AND dc_cmd.is_commander = true
          LIMIT 1
        ) cmd ON true
        LEFT JOIN deck_cards dc ON d.id = dc.deck_id
        WHERE d.user_id = @userId
        GROUP BY d.id, cmd.commander_name, cmd.commander_image_url
        ORDER BY d.created_at DESC
      '''
                : '''
        SELECT 
          d.id, 
          d.name, 
          d.format, 
          d.description, 
          d.archetype,
          d.bracket,
          d.synergy_score, 
          d.is_public,
          NULL::text as pricing_currency,
          NULL::numeric as pricing_total,
          0::int as pricing_missing_cards,
          NULL::text as pricing_source,
          NULL::timestamptz as pricing_updated_at,
          d.created_at,
          cmd.commander_name,
          cmd.commander_image_url,
          COALESCE(SUM(dc.quantity), 0)::int as card_count
        FROM decks d
        LEFT JOIN LATERAL (
          SELECT 
            c.name as commander_name,
            c.image_url as commander_image_url
          FROM deck_cards dc_cmd
          JOIN cards c ON c.id = dc_cmd.card_id
          WHERE dc_cmd.deck_id = d.id
            AND dc_cmd.is_commander = true
          LIMIT 1
        ) cmd ON true
        LEFT JOIN deck_cards dc ON d.id = dc.deck_id
        WHERE d.user_id = @userId
        GROUP BY d.id, cmd.commander_name, cmd.commander_image_url
        ORDER BY d.created_at DESC
      ''')
            : (hasPricing
                ? '''
        SELECT 
          d.id, 
          d.name, 
          d.format, 
          d.description, 
          NULL::text as archetype,
          NULL::int as bracket,
          d.synergy_score, 
          d.is_public,
          d.pricing_currency,
          d.pricing_total,
          d.pricing_missing_cards,
          ${hasPricingSource ? 'd.pricing_source' : 'NULL::text AS pricing_source'},
          d.pricing_updated_at,
          d.created_at,
          cmd.commander_name,
          cmd.commander_image_url,
          COALESCE(SUM(dc.quantity), 0)::int as card_count
        FROM decks d
        LEFT JOIN LATERAL (
          SELECT 
            c.name as commander_name,
            c.image_url as commander_image_url
          FROM deck_cards dc_cmd
          JOIN cards c ON c.id = dc_cmd.card_id
          WHERE dc_cmd.deck_id = d.id
            AND dc_cmd.is_commander = true
          LIMIT 1
        ) cmd ON true
        LEFT JOIN deck_cards dc ON d.id = dc.deck_id
        WHERE d.user_id = @userId
        GROUP BY d.id, cmd.commander_name, cmd.commander_image_url
        ORDER BY d.created_at DESC
      '''
                : '''
        SELECT 
          d.id, 
          d.name, 
          d.format, 
          d.description, 
          NULL::text as archetype,
          NULL::int as bracket,
          d.synergy_score, 
          d.is_public,
          NULL::text as pricing_currency,
          NULL::numeric as pricing_total,
          0::int as pricing_missing_cards,
          NULL::text as pricing_source,
          NULL::timestamptz as pricing_updated_at,
          d.created_at,
          cmd.commander_name,
          cmd.commander_image_url,
          COALESCE(SUM(dc.quantity), 0)::int as card_count
        FROM decks d
        LEFT JOIN LATERAL (
          SELECT 
            c.name as commander_name,
            c.image_url as commander_image_url
          FROM deck_cards dc_cmd
          JOIN cards c ON c.id = dc_cmd.card_id
          WHERE dc_cmd.deck_id = d.id
            AND dc_cmd.is_commander = true
          LIMIT 1
        ) cmd ON true
        LEFT JOIN deck_cards dc ON d.id = dc.deck_id
        WHERE d.user_id = @userId
        GROUP BY d.id, cmd.commander_name, cmd.commander_image_url
        ORDER BY d.created_at DESC
      ''');
    final validationColumns =
        hasValidationState
            ? '''
          d.validation_state,
          d.validation_reasons,
          d.validation_updated_at,
        '''
            : '''
          'unknown'::text AS validation_state,
          '["validation_not_recorded"]'::jsonb AS validation_reasons,
          NULL::timestamptz AS validation_updated_at,
        ''';
    final sql = baseSql.replaceAll(
      'd.is_public,',
      'd.is_public,$validationColumns',
    );

    final result = await conn.execute(
      Sql.named(sql),
      parameters: {'userId': userId},
    );
    Log.d('✅ Query executada. Encontrados ${result.length} decks.');

    final decks =
        result.map((row) {
          final map = row.toColumnMap();
          if (map['created_at'] is DateTime) {
            map['created_at'] =
                (map['created_at'] as DateTime).toIso8601String();
          }
          if (map['pricing_updated_at'] is DateTime) {
            map['pricing_updated_at'] =
                (map['pricing_updated_at'] as DateTime).toIso8601String();
          }
          if (map['validation_updated_at'] is DateTime) {
            map['validation_updated_at'] =
                (map['validation_updated_at'] as DateTime).toIso8601String();
          }
          map['commander_image_url'] = normalizeScryfallImageUrl(
            map['commander_image_url']?.toString(),
          );
          // PostgreSQL DECIMAL retorna String, converter para double
          final rawPricingTotal = map['pricing_total'];
          if (rawPricingTotal is String) {
            map['pricing_total'] = double.tryParse(rawPricingTotal);
          } else if (rawPricingTotal is num) {
            map['pricing_total'] = rawPricingTotal.toDouble();
          }
          return exposeDeckValidationState(map);
        }).toList();

    // ── Fetch color identity for each deck (batch) ──────────────
    if (decks.isNotEmpty) {
      try {
        final colorResult = await conn.execute(
          Sql.named('''
            SELECT
              dc.deck_id::text,
              array_agg(DISTINCT unnested ORDER BY unnested) AS color_identity
            FROM deck_cards dc
            JOIN cards c ON c.id = dc.card_id
            CROSS JOIN LATERAL unnest(COALESCE(c.color_identity, '{}')) AS unnested
            WHERE dc.deck_id = ANY(
              SELECT id FROM decks WHERE user_id = @userId
            )
            GROUP BY dc.deck_id
          '''),
          parameters: {'userId': userId},
        );
        final colorMap = <String, List<String>>{};
        for (final row in colorResult) {
          final m = row.toColumnMap();
          final deckId = m['deck_id']?.toString() ?? '';
          final colors = m['color_identity'];
          if (colors is List) {
            colorMap[deckId] = colors.map((e) => e.toString()).toList();
          }
        }
        for (final deck in decks) {
          final deckId = deck['id']?.toString() ?? '';
          deck['color_identity'] = colorMap[deckId] ?? <String>[];
          deck['color_identity_known'] = true;
        }
      } catch (e) {
        Log.e('⚠️ Falha ao buscar color_identity: $e');
        // Non-critical — continue without color identity
        for (final deck in decks) {
          deck['color_identity'] = <String>[];
          deck['color_identity_known'] = false;
        }
      }
    }

    Log.d('📤 Retornando resposta JSON.');
    return Response.json(body: decks);
  } catch (e, stackTrace) {
    Log.e('❌ Erro crítico em _listDecks: $e');
    Log.e('Stack trace: $stackTrace');
    await captureRouteException(
      context,
      e,
      stackTrace: stackTrace,
      tags: const {'route': 'decks_list'},
    );
    return internalServerError('Failed to list decks');
  }
}

/// Cria um novo deck para o usuário autenticado.
Future<Response> _createDeck(RequestContext context) async {
  final stopwatch = Stopwatch()..start();
  // 1. Obter o ID do usuário (injetado pelo middleware de autenticação)
  final userId = context.read<String>();

  late final Map<String, dynamic> body;
  late final String name;
  late final String format;
  late final String? description;
  late final String? archetype;
  late final int? bracket;
  late final bool isPublic;
  late final List<dynamic> cards;
  late final List<Map<String, dynamic>> rawCardObjects;
  try {
    body = requireJsonObject(await context.request.json());
    name = requireNonEmptyString(body, 'name');
    final rawFormat = requireNonEmptyString(body, 'format');
    final supportedFormat = normalizeSupportedDeckFormat(rawFormat);
    if (supportedFormat == null) {
      throw DeckRequestException(unsupportedDeckFormatMessage(rawFormat));
    }
    format = supportedFormat;
    description = readOptionalString(body, 'description');
    archetype = readOptionalString(body, 'archetype', trim: true);
    final bracketResult = parseCommanderBracket(body['bracket']);
    if (bracketResult.error != null) {
      throw DeckRequestException(bracketResult.error!);
    }
    bracket = bracketResult.value;
    isPublic = readOptionalBool(body, 'is_public') ?? false;
    cards = readOptionalList(body, 'cards') ?? const <dynamic>[];
    rawCardObjects = requireObjectList(cards);
    validateNoUnsupportedDeckSections(cards: rawCardObjects);
  } on FormatException catch (e) {
    return badRequest('Invalid JSON body: ${e.message}');
  } on DeckRequestException catch (e) {
    return badRequest(e.message);
  } on DeckRulesException catch (e) {
    return badRequest(e.message);
  }

  final conn = context.read<Pool>();
  final hasMeta = await hasDeckMetaColumns(conn);
  final hasValidationState = await hasDeckValidationStateColumns(conn);

  // 3. Usar uma transação para garantir a consistência dos dados
  try {
    final newDeck = await conn.runTx((session) async {
      // Insere o deck e obtém o ID gerado
      final deckResult = await session.execute(
        Sql.named(
          hasMeta
              ? 'INSERT INTO decks (user_id, name, format, description, archetype, bracket, is_public) VALUES (@userId, @name, @format, @desc, @archetype, @bracket, @isPublic) RETURNING id, name, format, archetype, bracket, is_public, created_at'
              : 'INSERT INTO decks (user_id, name, format, description, is_public) VALUES (@userId, @name, @format, @desc, @isPublic) RETURNING id, name, format, is_public, created_at',
        ),
        parameters: {
          'userId': userId,
          'name': name,
          'format': format,
          'desc': description,
          'isPublic': isPublic,
          if (hasMeta) 'archetype': archetype,
          if (hasMeta) 'bracket': bracket,
        },
      );

      final deckMap = deckResult.first.toColumnMap();
      if (deckMap['created_at'] is DateTime) {
        deckMap['created_at'] =
            (deckMap['created_at'] as DateTime).toIso8601String();
      }
      if (!hasMeta) {
        deckMap['archetype'] = null;
        deckMap['bracket'] = null;
      }

      final newDeckId = deckMap['id'];

      // Resolver card_id quando veio "name" e agregar num formato único
      final parsedCards = <Map<String, dynamic>>[];
      final unresolvedNames =
          rawCardObjects
              .where(
                (card) => (card['card_id']?.toString().trim() ?? '').isEmpty,
              )
              .map((card) => card['name']?.toString().trim() ?? '')
              .where((name) => name.isNotEmpty)
              .toSet();
      final resolvedCardIds = await resolveDeckCardIdsByName(
        session: session,
        names: unresolvedNames,
        preferredFormat: format,
      );

      for (final card in rawCardObjects) {
        var cardId = readOptionalString(card, 'card_id', trim: true);
        final cardName = readOptionalString(card, 'name', trim: true);
        final quantity = requirePositiveInteger(card, 'quantity');
        final isCommander = readOptionalBool(card, 'is_commander') ?? false;

        if ((cardId == null || cardId.isEmpty) &&
            (cardName == null || cardName.isEmpty)) {
          throw const DeckRequestException(
            'Each card must have a card_id or name.',
          );
        }

        if (cardId == null || cardId.isEmpty) {
          cardId = resolvedCardIds[cardName!];
          if (cardId == null || cardId.isEmpty) {
            throw DeckRequestException('Card not found: $cardName');
          }
        }

        parsedCards.add({
          'card_id': cardId,
          'quantity': quantity,
          'is_commander': isCommander,
        });
      }

      final cardsById = <String, Map<String, dynamic>>{};
      for (final card in parsedCards) {
        final cardId = card['card_id'] as String;
        final existing = cardsById[cardId];
        if (existing == null) {
          cardsById[cardId] = Map<String, dynamic>.from(card);
          continue;
        }

        final mergedIsCommander =
            existing['is_commander'] == true || card['is_commander'] == true;
        cardsById[cardId] = {
          'card_id': cardId,
          'quantity':
              mergedIsCommander
                  ? 1
                  : (existing['quantity'] as int) + (card['quantity'] as int),
          'is_commander': mergedIsCommander,
        };
      }
      final normalizedCards = cardsById.values.toList(growable: false);

      print(
        '[DECK_CREATE_TIMING] normalized_cards=${normalizedCards.length} elapsed_ms=${stopwatch.elapsedMilliseconds}',
      );

      await DeckRulesService(
        session,
      ).validateAndThrow(format: format, cards: normalizedCards, strict: false);
      String? strictValidationError;
      var strictValidationPassed = false;
      try {
        await DeckRulesService(session).validateAndThrow(
          format: format,
          cards: normalizedCards,
          strict: true,
        );
        strictValidationPassed = true;
      } on DeckRulesException catch (error) {
        strictValidationError = error.message;
      }
      final readiness = buildDeckReadinessContract(
        format: format,
        cardCount: normalizedCards.fold<int>(
          0,
          (sum, card) => sum + (card['quantity'] as int),
        ),
        hasCommander: normalizedCards.any(
          (card) => card['is_commander'] == true,
        ),
        strictValidationPassed: strictValidationPassed,
        strictValidationError: strictValidationError,
      );
      print(
        '[DECK_CREATE_TIMING] validate_rules_done elapsed_ms=${stopwatch.elapsedMilliseconds}',
      );

      if (normalizedCards.isNotEmpty) {
        final values = <String>[];
        final params = <String, dynamic>{'deckId': newDeckId};

        for (var i = 0; i < normalizedCards.length; i++) {
          final card = normalizedCards[i];
          final pId = 'cardId$i';
          final pQty = 'quantity$i';
          final pCommander = 'isCommander$i';

          values.add('(@deckId, @$pId, @$pQty, @$pCommander)');
          params[pId] = card['card_id'];
          params[pQty] = card['quantity'];
          params[pCommander] = card['is_commander'] ?? false;
        }

        final cardInsertSql = '''
          INSERT INTO deck_cards (deck_id, card_id, quantity, is_commander)
          VALUES ${values.join(', ')}
        ''';
        await session.execute(Sql.named(cardInsertSql), parameters: params);
      }

      print(
        '[DECK_CREATE_TIMING] insert_cards_done elapsed_ms=${stopwatch.elapsedMilliseconds}',
      );

      if (hasValidationState) {
        final validationResult = await session.execute(
          Sql.named('''
            UPDATE decks
            SET validation_state = @validationState,
                validation_reasons = CAST(@validationReasons AS jsonb),
                validation_updated_at = CURRENT_TIMESTAMP
            WHERE id = @deckId
            RETURNING validation_state,
                      validation_reasons,
                      validation_updated_at
          '''),
          parameters: {
            'deckId': newDeckId,
            'validationState': readiness['state'],
            'validationReasons': encodeDeckValidationReasons(
              readiness['review_reasons'] as List<String>,
            ),
          },
        );
        deckMap.addAll(validationResult.first.toColumnMap());
        if (deckMap['validation_updated_at'] is DateTime) {
          deckMap['validation_updated_at'] =
              (deckMap['validation_updated_at'] as DateTime).toIso8601String();
        }
      } else {
        deckMap
          ..['validation_state'] = deckValidationStateUnknown
          ..['validation_reasons'] = const [deckValidationReasonNotRecorded];
      }

      return exposeDeckValidationState(deckMap);
    });

    final productLearningEnabled = shouldWriteProductLearning();
    if (productLearningEnabled) {
      unawaited(
        _logDeckCreateLearning(
          pool: conn,
          deckId: newDeck['id'].toString(),
          deckName: name,
          format: format,
          rawCards: cards,
        ),
      );
    } else {
      newDeck['e2e_validation'] = const {
        'isolated_runtime': true,
        'product_learning_writes_suppressed': true,
      };
      Log.d(
        'Deck learning writes suppressed for isolated E2E deck '
        '${newDeck['id']}.',
      );
    }

    return Response.json(body: newDeck);
  } on DeckRulesException catch (e) {
    print('[ERROR] Failed to create deck: $e');
    return badRequest(e.message);
  } on DeckRequestException catch (e) {
    print('[ERROR] Invalid create deck request: $e');
    return badRequest(e.message);
  } catch (e, stackTrace) {
    print('[ERROR] Failed to create deck: $e');
    await captureRouteException(
      context,
      e,
      stackTrace: stackTrace,
      tags: const {'route': 'decks_create'},
      extras: {'format': format, 'cards_count': cards.length},
    );
    return internalServerError('Failed to create deck');
  }
}

Future<void> _logDeckCreateLearning({
  required Pool pool,
  required String deckId,
  required String deckName,
  required String format,
  required List<dynamic> rawCards,
}) async {
  try {
    final learningCards = await _resolveLearningCardsForEvents(pool, rawCards);
    final commanderCard = learningCards.firstWhere(
      (card) => card['is_commander'] == true,
      orElse: () => const <String, dynamic>{},
    );
    final commanderName = commanderCard['name']?.toString();
    final cardQuantityTotal = learningCardQuantityTotal(learningCards);
    final commanderQuantity = learningCards
        .where((card) => card['is_commander'] == true)
        .fold<int>(0, (sum, card) => sum + learningCardQuantityTotal([card]));
    final eventData = <String, dynamic>{
      'deck_name': deckName,
      'cards_quantity_total': cardQuantityTotal,
      'commander_quantity': commanderQuantity,
      'main_quantity': cardQuantityTotal - commanderQuantity,
      'cards':
          learningCards
              .map(
                (card) => {
                  'name':
                      card['name']?.toString() ?? card['card_id']?.toString(),
                  'quantity': card['quantity'],
                  'is_commander': card['is_commander'] == true,
                },
              )
              .toList(),
    };

    if (commanderName != null && commanderName.isNotEmpty) {
      await recordUserCreatedDeckLearning(
        pool: pool,
        deckId: deckId,
        commanderName: commanderName,
        format: format,
        cardCount: cardQuantityTotal,
        cards: learningCards,
        eventData: eventData,
      );
    } else {
      await logDeckLearningEvent(
        pool: pool,
        deckId: deckId,
        format: format,
        cardCount: cardQuantityTotal,
        source: 'user_created',
        eventData: eventData,
      );
    }
  } catch (error) {
    Log.e('⚠️ Falha ao registrar aprendizado do deck $deckId: $error');
  }
}

Future<List<Map<String, dynamic>>> _resolveLearningCardsForEvents(
  Pool pool,
  List<dynamic> rawCards,
) async {
  final cards = <Map<String, dynamic>>[];
  for (final rawCard in rawCards) {
    if (rawCard is! Map) continue;
    final card = <String, dynamic>{
      'quantity': rawCard['quantity'],
      'is_commander': rawCard['is_commander'] == true,
    };
    final rawName = rawCard['name']?.toString().trim();
    if (rawName != null && rawName.isNotEmpty) {
      card['name'] = rawName;
      cards.add(card);
      continue;
    }
    final cardId = rawCard['card_id']?.toString().trim();
    if (cardId == null || cardId.isEmpty) {
      cards.add(card);
      continue;
    }
    card['card_id'] = cardId;
    try {
      final result = await pool.execute(
        Sql.named('SELECT name FROM cards WHERE id = @cardId::uuid LIMIT 1'),
        parameters: {'cardId': cardId},
      );
      if (result.isNotEmpty) {
        card['name'] = result.first[0]?.toString();
      }
    } catch (_) {}
    cards.add(card);
  }
  return cards;
}
