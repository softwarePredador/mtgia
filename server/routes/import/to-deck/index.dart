import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';
import '../../../lib/basic_land_utils.dart' as basic_lands;
import '../../../lib/deck_rules_service.dart';
import '../../../lib/import_card_lookup_service.dart';
import '../../../lib/import_list_service.dart';
import '../../../lib/import_to_deck_merge_support.dart';
import '../../../lib/http_responses.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method == HttpMethod.post) {
    return _importToDeck(context);
  }
  return methodNotAllowed();
}

/// Importa uma lista de cartas para um deck EXISTENTE
Future<Response> _importToDeck(RequestContext context) async {
  final userId = context.read<String>();
  final pool = context.read<Pool>();

  final body = await context.request.json();
  final deckId = body['deck_id'] as String?;
  final rawList = body['list'];
  final replaceAll = body['replace_all'] == true;

  if (deckId == null || rawList == null) {
    return badRequest('Fields deck_id and list are required.');
  }

  // Verifica se o deck pertence ao usuário
  final deckCheck = await pool.execute(
    Sql.named(
        'SELECT id, format FROM decks WHERE id = @id AND user_id = @userId'),
    parameters: {'id': deckId, 'userId': userId},
  );

  if (deckCheck.isEmpty) {
    return notFound('Deck not found or access denied.');
  }

  final format = deckCheck.first[1] as String;
  final normalizedFormat = format.trim().toLowerCase();

  final unsupportedRawSections = unsupportedRawDeckSectionLabels(rawList);
  if (unsupportedRawSections.isNotEmpty) {
    return badRequest(
      unsupportedDeckSectionsMessage(unsupportedRawSections),
      details: {'unsupported_section_lines': unsupportedRawSections},
    );
  }

  late final List<String> lines;
  try {
    lines = normalizeImportLines(rawList);
  } on FormatException catch (e) {
    return badRequest(e.message);
  }

  final cardsToInsert = <Map<String, dynamic>>[];
  final notFoundCards = <String>[];
  final warnings = <String>[];
  final localizedMatches = <Map<String, dynamic>>[];
  final localizedMatchKeys = <String>{};

  final parseResult = parseImportLines(lines);
  final parsedItems = parseResult.parsedItems;
  notFoundCards.addAll(parseResult.invalidLines);
  if (parseResult.unsupportedSectionLines.isNotEmpty) {
    return badRequest(
      unsupportedDeckSectionsMessage(parseResult.unsupportedSectionLines),
      details: {
        'unsupported_section_lines': parseResult.unsupportedSectionLines,
      },
    );
  }

  // 2) Resolve nomes em lote (exato + clean + split fallback)
  final foundCardsMap = await resolveImportCardNames(
    pool,
    parsedItems,
    preferredFormat: normalizedFormat,
  );

  // 5. Montagem da lista final
  for (final item in parsedItems) {
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

      cardsToInsert.add({
        'card_id': cardData['id'],
        'quantity': item['quantity'],
        'is_commander': item['isCommanderTag'] ?? false,
        'name': cardData['name'],
        'type_line': cardData['type_line'],
      });
    } else {
      if (!notFoundCards.contains(item['line'])) {
        notFoundCards.add(item['line']);
      }
    }
  }

  if (cardsToInsert.isEmpty) {
    return badRequest('No valid cards found in the list.', details: {
      'not_found_lines': notFoundCards,
      'localized_matches': localizedMatches,
      'localized_matches_count': localizedMatches.length,
      'hint':
          'Confira formato das linhas (ex: "1 Sol Ring"). Nomes localizados dependem da tabela card_localized_names sincronizada.',
    });
  }

  // 6. Validação de regras
  final limit =
      (normalizedFormat == 'commander' || normalizedFormat == 'brawl') ? 1 : 4;

  // Agrupa cartas por card_id para evitar duplicatas
  final cardMap = <String, Map<String, dynamic>>{};
  for (final card in cardsToInsert) {
    final cardId = card['card_id'] as String;
    final existing = cardMap[cardId];
    if (existing == null) {
      cardMap[cardId] = Map<String, dynamic>.from(card);
      continue;
    }

    existing['quantity'] =
        (existing['quantity'] as int) + (card['quantity'] as int);
    if (card['is_commander'] == true) {
      existing['is_commander'] = true;
    }
  }

  final consolidatedCards = cardMap.values.toList();

  // Warnings com quantidades consolidadas (por NOME, para suportar múltiplas edições)
  warnings.clear();
  final copiesByName = <String, Map<String, dynamic>>{};

  for (final card in consolidatedCards) {
    final name = (card['name'] as String).trim();
    final typeLine = card['type_line'] as String;
    final quantity = card['quantity'] as int;
    final isCommander = card['is_commander'] == true;

    final isBasicLand = basic_lands.isBasicLandCard(
      name: name,
      typeLine: typeLine,
    );

    if (isCommander || isBasicLand) continue;

    final key = name.toLowerCase();
    final existing = copiesByName[key];
    if (existing == null) {
      copiesByName[key] = {'name': name, 'qty': quantity};
    } else {
      copiesByName[key] = {
        'name': existing['name'] as String,
        'qty': (existing['qty'] as int) + quantity,
      };
    }
  }

  for (final entry in copiesByName.values) {
    final name = entry['name'] as String;
    final qty = entry['qty'] as int;
    if (qty > limit) {
      warnings.add('$name: $qty cópias (limite $limit)');
    }
  }

  try {
    var commanderPreserved = false;
    var commanderDetected =
        consolidatedCards.any((card) => card['is_commander'] == true);
    var finalTotalCards = sumImportToDeckQuantities(consolidatedCards);
    await pool.runTx((session) async {
      final existingCards = <Map<String, dynamic>>[];

      if (!replaceAll) {
        final existingResult = await session.execute(
          Sql.named('''
            SELECT card_id::text, quantity::int, is_commander, condition
            FROM deck_cards
            WHERE deck_id = @deckId
          '''),
          parameters: {'deckId': deckId},
        );

        for (final row in existingResult) {
          final cardId = row[0] as String;
          existingCards.add({
            'card_id': cardId,
            'quantity': row[1] as int,
            'is_commander': row[2] as bool? ?? false,
            'condition': row[3] as String? ?? 'NM',
          });
        }
      } else if ((normalizedFormat == 'commander' ||
              normalizedFormat == 'brawl') &&
          !commanderDetected) {
        final existingCommanderResult = await session.execute(
          Sql.named('''
            SELECT card_id::text, quantity::int, is_commander, condition
            FROM deck_cards
            WHERE deck_id = @deckId AND is_commander = TRUE
          '''),
          parameters: {'deckId': deckId},
        );

        for (final row in existingCommanderResult) {
          existingCards.add({
            'card_id': row[0] as String,
            'quantity': row[1] as int,
            'is_commander': row[2] as bool? ?? false,
            'condition': row[3] as String? ?? 'NM',
          });
        }
        commanderPreserved = existingCommanderResult.isNotEmpty;
        commanderDetected = commanderPreserved;
      }

      final mergeResult = mergeImportToDeckCards(
        importedCards: consolidatedCards,
        existingCards: existingCards,
        commanderPreserved: commanderPreserved,
      );
      final validatedCards = mergeResult.cards;
      finalTotalCards = mergeResult.totalCards;
      commanderDetected = mergeResult.commanderDetected;
      commanderPreserved = mergeResult.commanderPreserved;

      await DeckRulesService(session).validateAndThrow(
        format: normalizedFormat,
        cards: validatedCards,
        strict: false,
      );

      await session.execute(
        Sql.named('DELETE FROM deck_cards WHERE deck_id = @deckId'),
        parameters: {'deckId': deckId},
      );

      if (validatedCards.isNotEmpty) {
        final values = <String>[];
        final params = <String, dynamic>{'deckId': deckId};

        for (var i = 0; i < validatedCards.length; i++) {
          final card = validatedCards[i];
          final pId = 'c$i';
          final pQty = 'q$i';
          final pCmd = 'cmd$i';
          final pCond = 'cond$i';

          values.add('(@deckId, @$pId, @$pQty, @$pCmd, @$pCond)');
          params[pId] = card['card_id'];
          params[pQty] = card['quantity'];
          params[pCmd] = card['is_commander'] ?? false;
          params[pCond] = card['condition'] ?? 'NM';
        }

        final sql = '''
          INSERT INTO deck_cards (deck_id, card_id, quantity, is_commander, condition)
          VALUES ${values.join(', ')}
        ''';
        await session.execute(Sql.named(sql), parameters: params);
      }
    });

    return Response.json(
      body: buildImportToDeckSuccessBody(
        deckId: deckId,
        normalizedFormat: normalizedFormat,
        importedCards: consolidatedCards,
        totalCards: finalTotalCards,
        notFoundLines: notFoundCards,
        localizedMatches: localizedMatches,
        warnings: warnings,
        commanderDetected: commanderDetected,
        commanderPreserved: commanderPreserved,
      ),
    );
  } on DeckRulesException catch (e) {
    return badRequest(e.message);
  } catch (e) {
    print('[ERROR] Failed to import cards: $e');
    return internalServerError('Failed to import cards');
  }
}
