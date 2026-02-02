import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method == HttpMethod.post) {
    return _importToDeck(context);
  }
  return Response(statusCode: HttpStatus.methodNotAllowed);
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
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'error': 'Fields deck_id and list are required.'},
    );
  }

  // Verifica se o deck pertence ao usuário
  final deckCheck = await pool.execute(
    Sql.named('SELECT id, format FROM decks WHERE id = @id AND user_id = @userId'),
    parameters: {'id': deckId, 'userId': userId},
  );

  if (deckCheck.isEmpty) {
    return Response.json(
      statusCode: HttpStatus.notFound,
      body: {'error': 'Deck not found or access denied.'},
    );
  }

  final format = deckCheck.first[1] as String;

  List<String> lines = [];
  if (rawList is String) {
    lines = rawList.split('\n');
  } else if (rawList is List) {
    for (var item in rawList) {
      if (item is String) {
        lines.add(item);
      } else if (item is Map) {
        final q = item['quantity'] ?? item['amount'] ?? item['qtd'] ?? 1;
        final n = item['name'] ?? item['card_name'] ?? item['card'] ?? '';
        if (n.toString().isNotEmpty) {
          lines.add('$q $n');
        }
      }
    }
  } else {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'error': 'Field list must be a String or a List.'},
    );
  }

  // Regex para fazer o parse da linha
  final lineRegex = RegExp(r'^(\d+)x?\s+([^(]+)\s*(?:\(([\w\d]+)\))?.*$');

  final cardsToInsert = <Map<String, dynamic>>[];
  final notFoundCards = <String>[];
  final warnings = <String>[];

  final parsedItems = <Map<String, dynamic>>[];
  final namesToQuery = <String>{};

  // 1. Parse de todas as linhas
  for (var line in lines) {
    line = line.trim();
    if (line.isEmpty) continue;

    final match = lineRegex.firstMatch(line);
    if (match != null) {
      final quantity = int.parse(match.group(1)!);
      final cardName = match.group(2)!.trim();
      
      final lineLower = line.toLowerCase();
      final isCommanderTag = lineLower.contains('[commander') || 
                             lineLower.contains('*cmdr*') || 
                             lineLower.contains('!commander');

      parsedItems.add({
        'line': line,
        'name': cardName,
        'quantity': quantity,
        'isCommanderTag': isCommanderTag,
      });
      namesToQuery.add(cardName.toLowerCase());
    } else {
      notFoundCards.add(line);
    }
  }

  // 2. Busca em lote
  final foundCardsMap = <String, Map<String, dynamic>>{};
  
  if (namesToQuery.isNotEmpty) {
    final result = await pool.execute(
      Sql.named('SELECT id, name, type_line FROM cards WHERE lower(name) = ANY(@names)'),
      parameters: {'names': TypedValue(Type.textArray, namesToQuery.toList())},
    );
    for (final row in result) {
      final id = row[0] as String;
      final name = row[1] as String;
      final typeLine = row[2] as String;
      foundCardsMap[name.toLowerCase()] = {'id': id, 'name': name, 'type_line': typeLine};
    }
  }

  // 3. Fallback para nomes com números (ex: "Forest 96")
  final cleanNamesToQuery = <String>{};

  for (final item in parsedItems) {
    final nameLower = (item['name'] as String).toLowerCase();
    if (!foundCardsMap.containsKey(nameLower)) {
      final cleanName = (item['name'] as String).replaceAll(RegExp(r'\s+\d+$'), '');
      if (cleanName != item['name']) {
        item['cleanName'] = cleanName;
        cleanNamesToQuery.add(cleanName.toLowerCase());
      }
    }
  }

  if (cleanNamesToQuery.isNotEmpty) {
    final result = await pool.execute(
      Sql.named('SELECT id, name, type_line FROM cards WHERE lower(name) = ANY(@names)'),
      parameters: {'names': TypedValue(Type.textArray, cleanNamesToQuery.toList())},
    );
    for (final row in result) {
      final id = row[0] as String;
      final name = row[1] as String;
      final typeLine = row[2] as String;
      foundCardsMap[name.toLowerCase()] = {'id': id, 'name': name, 'type_line': typeLine};
    }
  }

  // 4. Fallback para Split Cards / Double-Faced
  final splitPatternsToQuery = <String>[];
  
  for (final item in parsedItems) {
     final nameKey = item['cleanName'] != null 
        ? (item['cleanName'] as String).toLowerCase() 
        : (item['name'] as String).toLowerCase();
     
     if (!foundCardsMap.containsKey(nameKey)) {
        splitPatternsToQuery.add('$nameKey // %');
     }
  }

  if (splitPatternsToQuery.isNotEmpty) {
      final result = await pool.execute(
        Sql.named('SELECT id, name, type_line FROM cards WHERE lower(name) LIKE ANY(@patterns)'),
        parameters: {'patterns': TypedValue(Type.textArray, splitPatternsToQuery)},
      );
      
      for (final row in result) {
        final id = row[0] as String;
        final dbName = row[1] as String;
        final typeLine = row[2] as String;
        final dbNameLower = dbName.toLowerCase();
        
        final parts = dbNameLower.split(RegExp(r'\s*//\s*'));
        if (parts.isNotEmpty) {
            final prefix = parts[0].trim();
            if (!foundCardsMap.containsKey(prefix)) {
                 foundCardsMap[prefix] = {'id': id, 'name': dbName, 'type_line': typeLine};
            }
        }
      }
  }

  // 5. Montagem da lista final
  for (final item in parsedItems) {
    if (notFoundCards.contains(item['line'])) continue;

    final nameKey = item['cleanName'] != null 
        ? (item['cleanName'] as String).toLowerCase() 
        : (item['name'] as String).toLowerCase();

    if (foundCardsMap.containsKey(nameKey)) {
      final cardData = foundCardsMap[nameKey]!;
      
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
     return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'error': 'No valid cards found in the list.', 'not_found_lines': notFoundCards},
    );
  }

  // 6. Validação de regras
  final limit = (format == 'commander' || format == 'brawl') ? 1 : 4;

  for (final card in cardsToInsert) {
    final name = card['name'] as String;
    final typeLine = card['type_line'] as String;
    final quantity = card['quantity'] as int;
    final isBasicLand = typeLine.toLowerCase().contains('basic land');

    if (!isBasicLand && quantity > limit) {
      warnings.add('$name: $quantity cópias (limite $limit)');
    }
  }

  try {
    await pool.runTx((session) async {
      // Se replaceAll, remove as cartas existentes
      if (replaceAll) {
        await session.execute(
          Sql.named('DELETE FROM deck_cards WHERE deck_id = @deckId'),
          parameters: {'deckId': deckId},
        );
      }

      // Agrupa cartas por card_id para evitar duplicatas
      final cardMap = <String, Map<String, dynamic>>{};
      
      for (final card in cardsToInsert) {
        final cardId = card['card_id'] as String;
        if (cardMap.containsKey(cardId)) {
          // Soma quantidade se já existe
          cardMap[cardId]!['quantity'] = 
              (cardMap[cardId]!['quantity'] as int) + (card['quantity'] as int);
          // Mantém is_commander se qualquer um for true
          if (card['is_commander'] == true) {
            cardMap[cardId]!['is_commander'] = true;
          }
        } else {
          cardMap[cardId] = Map<String, dynamic>.from(card);
        }
      }

      // Se não for replaceAll, verifica cartas existentes para atualizar quantidade
      if (!replaceAll) {
        final existingCards = await session.execute(
          Sql.named('SELECT card_id, quantity FROM deck_cards WHERE deck_id = @deckId'),
          parameters: {'deckId': deckId},
        );
        
        final existingMap = <String, int>{};
        for (final row in existingCards) {
          existingMap[row[0] as String] = row[1] as int;
        }

        // Atualiza ou insere
        for (final entry in cardMap.entries) {
          final cardId = entry.key;
          final card = entry.value;
          
          if (existingMap.containsKey(cardId)) {
            // Atualiza quantidade
            final newQty = existingMap[cardId]! + (card['quantity'] as int);
            await session.execute(
              Sql.named('UPDATE deck_cards SET quantity = @qty WHERE deck_id = @deckId AND card_id = @cardId'),
              parameters: {'qty': newQty, 'deckId': deckId, 'cardId': cardId},
            );
          } else {
            // Insere novo
            await session.execute(
              Sql.named(
                'INSERT INTO deck_cards (deck_id, card_id, quantity, is_commander) VALUES (@deckId, @cardId, @qty, @isCmd)'
              ),
              parameters: {
                'deckId': deckId,
                'cardId': cardId,
                'qty': card['quantity'],
                'isCmd': card['is_commander'] ?? false,
              },
            );
          }
        }
      } else {
        // Insere todas as cartas
        for (final entry in cardMap.entries) {
          final cardId = entry.key;
          final card = entry.value;
          
          await session.execute(
            Sql.named(
              'INSERT INTO deck_cards (deck_id, card_id, quantity, is_commander) VALUES (@deckId, @cardId, @qty, @isCmd)'
            ),
            parameters: {
              'deckId': deckId,
              'cardId': cardId,
              'qty': card['quantity'],
              'isCmd': card['is_commander'] ?? false,
            },
          );
        }
      }
    });

    return Response.json(body: {
      'success': true,
      'cards_imported': cardsToInsert.length,
      'not_found_lines': notFoundCards,
      'warnings': warnings,
    });

  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Failed to import cards: $e'},
    );
  }
}
