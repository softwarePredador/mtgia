import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

import '../../lib/deck_rules_service.dart';
import '../../lib/deck_import_review_contract.dart';
import '../../lib/deck_validation_state_support.dart';
import '../../lib/http_responses.dart';
import '../../lib/import_card_lookup_service.dart';
import '../../lib/import_list_service.dart';

List<Map<String, dynamic>> _consolidateCardsById(
  List<Map<String, dynamic>> cards,
) {
  final byId = <String, Map<String, dynamic>>{};
  for (final card in cards) {
    final cardId = card['card_id'] as String;
    final existing = byId[cardId];
    if (existing == null) {
      byId[cardId] = Map<String, dynamic>.from(card);
      continue;
    }

    existing['quantity'] =
        (existing['quantity'] as int) + (card['quantity'] as int);
    if (card['is_commander'] == true) {
      existing['is_commander'] = true;
    }
  }
  return byId.values.toList();
}

int _sumQuantities(List<Map<String, dynamic>> cards) =>
    cards.fold<int>(0, (sum, c) => sum + (c['quantity'] as int? ?? 0));

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method == HttpMethod.post) {
    return _importDeck(context);
  }
  return methodNotAllowed();
}

Future<Response> _importDeck(RequestContext context) async {
  final userId = context.read<String>();
  final pool = context.read<Pool>();

  final body = await context.request.json();
  final name = body['name'] as String?;
  final format = body['format'] as String?;
  final description = body['description'] as String?;
  final commanderName = body['commander'] as String?;
  final rawList = body['list'];

  if (name == null || format == null || rawList == null) {
    return badRequest('Fields name, format, and list are required.');
  }

  final normalizedFormat = format.trim().toLowerCase();

  late final List<String> lines;
  try {
    lines = normalizeImportLines(rawList);
  } on FormatException catch (e) {
    return badRequest(e.message);
  }

  final cardsToInsert = <Map<String, dynamic>>[];
  final notFoundCards = <String>[];
  final localizedMatches = <Map<String, dynamic>>[];
  final localizedMatchKeys = <String>{};

  final parseResult = parseImportLines(lines);
  final parsedItems = parseResult.parsedItems;
  if (parseResult.unsupportedSectionLines.isNotEmpty) {
    return badRequest(
      unsupportedDeckSectionsMessage(parseResult.unsupportedSectionLines),
      details: {
        'unsupported_section_lines': parseResult.unsupportedSectionLines,
      },
    );
  }
  notFoundCards.addAll(parseResult.invalidLines);

  final foundCardsMap = await resolveImportCardNames(
    pool,
    parsedItems,
    preferredFormat: normalizedFormat,
  );

  // 6. Montagem final da lista de inserção
  for (final item in parsedItems) {
    // Verifica se já foi marcado como não encontrado (ex: erro de regex)
    if (notFoundCards.contains(item['line'])) continue;

    final cardData = findResolvedImportCard(
      foundCardsMap,
      item['name'] as String,
    );

    if (cardData != null) {
      final localizedMatch = localizedImportMatchForCard(cardData, item);
      if (localizedMatch != null &&
          localizedMatchKeys.add('${localizedMatch['line']}')) {
        localizedMatches.add(localizedMatch);
      }
      final dbName = cardData['name'] as String;
      final normalizedCommanderName = commanderName?.trim().toLowerCase();
      final canonicalCommanderName =
          normalizedCommanderName == null
              ? null
              : canonicalizeImportLookupName(normalizedCommanderName);
      final localizedCommanderName =
          normalizedCommanderName == null
              ? null
              : normalizeLocalizedImportName(normalizedCommanderName);

      final isCommander =
          item['isCommanderTag'] ||
          (commanderName != null &&
              (dbName.toLowerCase() == normalizedCommanderName ||
                  dbName.toLowerCase() == canonicalCommanderName ||
                  (cardData['_localized_match'] == true &&
                      normalizeLocalizedImportName(
                            cardData['_localized_printed_name']?.toString() ??
                                '',
                          ) ==
                          localizedCommanderName)));

      cardsToInsert.add({
        'card_id': cardData['id'],
        'quantity': item['quantity'],
        'is_commander': isCommander,
        'name': dbName,
        'type_line': cardData['type_line'],
      });
    } else {
      // Se chegou até aqui e não achou, agora sim é erro
      if (!notFoundCards.contains(item['line'])) {
        notFoundCards.add(item['line']);
      }
    }
  }

  final warnings = <String>[];

  final requiresCommander =
      normalizedFormat == 'commander' || normalizedFormat == 'brawl';
  final trimmedCommanderName = commanderName?.trim();

  if (requiresCommander &&
      trimmedCommanderName != null &&
      trimmedCommanderName.isNotEmpty &&
      !cardsToInsert.any((card) => card['is_commander'] == true)) {
    final commanderLookup = await resolveImportCardNames(pool, [
      {
        'line': 'commander: $trimmedCommanderName',
        'name': trimmedCommanderName,
        'quantity': 1,
        'isCommanderTag': true,
      },
    ], preferredFormat: normalizedFormat);
    final commanderKey = trimmedCommanderName.toLowerCase();
    final cleanCommanderKey = cleanImportLookupKey(commanderKey);
    final canonicalCommanderKey = canonicalizeImportLookupName(
      cleanCommanderKey,
    );
    final commanderData =
        commanderLookup[commanderKey] ??
        commanderLookup[cleanCommanderKey] ??
        commanderLookup[canonicalCommanderKey];

    if (commanderData != null) {
      cardsToInsert.add({
        'card_id': commanderData['id'],
        'quantity': 1,
        'is_commander': true,
        'name': commanderData['name'],
        'type_line': commanderData['type_line'],
      });
    }
  }

  if (cardsToInsert.isEmpty) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {
        'error': 'No valid cards found in the list.',
        'not_found': notFoundCards,
        'localized_matches': localizedMatches,
        'localized_matches_count': localizedMatches.length,
        'hint':
            'Confira formato das linhas (ex: "1 Sol Ring"). Nomes localizados dependem da tabela card_localized_names sincronizada.',
      },
    );
  }

  final consolidatedCards = _consolidateCardsById(cardsToInsert);

  if (requiresCommander) {
    final hasCommander = consolidatedCards.any(
      (c) => c['is_commander'] == true,
    );
    if (!hasCommander) {
      warnings.add(
        'Nenhum comandante foi detectado. Marque um comandante (tag na lista ou campo "commander") para validar identidade de cor.',
      );
    }

    if (trimmedCommanderName != null && trimmedCommanderName.isNotEmpty) {
      final normalizedCommander = trimmedCommanderName.toLowerCase();
      final canonicalCommander = canonicalizeImportLookupName(
        normalizedCommander,
      );
      final matched = consolidatedCards.any((c) {
        final name = (c['name'] as String?)?.toLowerCase();
        return name == normalizedCommander || name == canonicalCommander;
      });
      if (!matched) {
        warnings.add(
          'Comandante informado ("$trimmedCommanderName") não foi encontrado no banco. O deck foi salvo como rascunho sem comandante.',
        );
      }
    }
  }

  // Garantia: commanders sempre com quantity = 1 (mantém import resiliente)
  for (final card in consolidatedCards) {
    if (card['is_commander'] == true) {
      final qty = card['quantity'] as int? ?? 1;
      if (qty != 1) {
        warnings.add(
          'Comandante "${card['name']}" estava com quantidade $qty; ajustado para 1.',
        );
        card['quantity'] = 1;
      }
    }
  }

  final hasCommander = consolidatedCards.any(
    (card) => card['is_commander'] == true,
  );
  final cardsImported = _sumQuantities(consolidatedCards);

  try {
    String? strictValidationError;
    var strictValidationPassed = false;
    late Map<String, dynamic> validation;
    final newDeck = await pool.runTx((session) async {
      final validatedCards = <Map<String, dynamic>>[
        for (final card in consolidatedCards)
          {
            'card_id': card['card_id'],
            'quantity': card['quantity'],
            'is_commander': card['is_commander'] ?? false,
          },
      ];

      await DeckRulesService(session).validateAndThrow(
        format: normalizedFormat,
        cards: validatedCards,
        strict: false,
      );

      // Import can preserve a safe but incomplete user skeleton as a draft.
      // Strict validation is a distinct readiness signal; it must never be
      // inferred only from the number of parsed or resolved cards.
      try {
        await DeckRulesService(session).validateAndThrow(
          format: normalizedFormat,
          cards: validatedCards,
          strict: true,
        );
        strictValidationPassed = true;
      } on DeckRulesException catch (error) {
        strictValidationError = error.message;
      }

      // 1. Criar o Deck
      final deckResult = await session.execute(
        Sql.named(
          'INSERT INTO decks (user_id, name, format, description) VALUES (@userId, @name, @format, @desc) RETURNING id, name, format, created_at',
        ),
        parameters: {
          'userId': userId,
          'name': name,
          'format': normalizedFormat,
          'desc': description,
        },
      );

      final newDeckId = deckResult.first.toColumnMap()['id'];

      // 2. Inserir as Cartas (Bulk Insert)
      if (validatedCards.isNotEmpty) {
        final valueStrings = <String>[];
        final params = <String, dynamic>{'deckId': newDeckId};

        for (var i = 0; i < validatedCards.length; i++) {
          final card = validatedCards[i];
          final pCardId = 'c$i';
          final pQty = 'q$i';
          final pCmdr = 'cmd$i';

          valueStrings.add('(@deckId, @$pCardId, @$pQty, @$pCmdr)');
          params[pCardId] = card['card_id'];
          params[pQty] = card['quantity'];
          params[pCmdr] = card['is_commander'] ?? false;
        }

        final sql =
            'INSERT INTO deck_cards (deck_id, card_id, quantity, is_commander) VALUES ${valueStrings.join(',')}';

        await session.execute(Sql.named(sql), parameters: params);
      }

      validation = buildDeckImportReviewContract(
        format: normalizedFormat,
        cardCount: cardsImported,
        hasCommander: hasCommander,
        strictValidationPassed: strictValidationPassed,
        notFoundLines: notFoundCards,
        warnings: warnings,
        strictValidationError: strictValidationError,
      );
      final validationState = normalizeDeckValidationState(validation['state']);
      final validationReasons = normalizeDeckValidationReasons(
        validation['review_reasons'],
      );
      final stateResult = await session.execute(
        Sql.named('''
          UPDATE decks
          SET validation_state = @validationState,
              validation_reasons = CAST(@validationReasons AS jsonb),
              validation_updated_at = CURRENT_TIMESTAMP
          WHERE id = @deckId
          RETURNING validation_state, validation_reasons, validation_updated_at
        '''),
        parameters: {
          'deckId': newDeckId,
          'validationState': validationState,
          'validationReasons': encodeDeckValidationReasons(validationReasons),
        },
      );

      final deckMap = deckResult.first.toColumnMap();
      final stateMap = stateResult.first.toColumnMap();
      deckMap.addAll(stateMap);
      if (deckMap['created_at'] is DateTime) {
        deckMap['created_at'] =
            (deckMap['created_at'] as DateTime).toIso8601String();
      }
      if (deckMap['validation_updated_at'] is DateTime) {
        deckMap['validation_updated_at'] =
            (deckMap['validation_updated_at'] as DateTime).toIso8601String();
      }
      return exposeDeckValidationState(deckMap);
    });

    final requiresReview = validation['requires_review'] == true;

    final responseBody = {
      'deck': newDeck,
      'cards_imported': cardsImported,
      'not_found_lines': notFoundCards,
      'localized_matches': localizedMatches,
      'localized_matches_count': localizedMatches.length,
      'is_partial': requiresReview,
      'deck_state': validation['state'],
      'requires_review': requiresReview,
      'validation': validation,
      'commander_detected': hasCommander,
      'missing_commander': requiresCommander && !hasCommander,
    };

    if (warnings.isNotEmpty) {
      responseBody['warnings'] = warnings;
    }

    return Response.json(body: responseBody);
  } on DeckRulesException catch (e) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {
        'error': e.message,
        'not_found': notFoundCards,
        'not_found_lines': notFoundCards,
        'localized_matches': localizedMatches,
        'localized_matches_count': localizedMatches.length,
        if (warnings.isNotEmpty) 'warnings': warnings,
      },
    );
  } catch (e) {
    print('[ERROR] Failed to import deck: $e');
    return internalServerError('Failed to import deck');
  }
}
