import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';
import '../../../lib/import_card_lookup_service.dart';
import '../../../lib/import_list_service.dart';

String _cleanLookupKey(String value) =>
    value.replaceAll(RegExp(r'\s+\d+$'), '');

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method == HttpMethod.post) {
    return _validateList(context);
  }
  return Response(statusCode: HttpStatus.methodNotAllowed);
}

/// Valida uma lista de cartas sem criar o deck
/// Retorna quais cartas foram encontradas e quais não
Future<Response> _validateList(RequestContext context) async {
  final pool = context.read<Pool>();

  final body = await context.request.json();
  final format = body['format'] as String?;
  final rawList = body['list'];

  if (format == null || rawList == null) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'error': 'Fields format and list are required.'},
    );
  }

  final normalizedFormat = format.trim().toLowerCase();

  late final List<String> lines;
  try {
    lines = normalizeImportLines(rawList);
  } on FormatException catch (e) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'error': e.message},
    );
  }

  final foundCards = <Map<String, dynamic>>[];
  final notFoundLines = <String>[];
  final warnings = <String>[];

  final parseResult = parseImportLines(lines);
  final parsedItems = parseResult.parsedItems;
  notFoundLines.addAll(parseResult.invalidLines);

  // 2) Resolve nomes em lote (exato + clean + split fallback)
  final foundCardsMap = await resolveImportCardNames(pool, parsedItems);

  // 5. Montagem da lista de resultados
  for (final item in parsedItems) {
    if (notFoundLines.contains(item['line'])) continue;

    final originalKey = (item['name'] as String).toLowerCase();
    final cleanedKey = _cleanLookupKey(originalKey);
    final nameKey =
        foundCardsMap.containsKey(originalKey) ? originalKey : cleanedKey;

    if (foundCardsMap.containsKey(nameKey)) {
      final cardData = foundCardsMap[nameKey]!;

      foundCards.add({
        'card_id': cardData['id'],
        'name': cardData['name'],
        'type_line': cardData['type_line'],
        'image_url': cardData['image_url'],
        'quantity': item['quantity'],
        'is_commander': item['isCommanderTag'],
        'original_line': item['line'],
      });
    } else {
      if (!notFoundLines.contains(item['line'])) {
        notFoundLines.add(item['line']);
      }
    }
  }

  // 6. Validações de regras (consolidado por card_id)
  final limit =
      (normalizedFormat == 'commander' || normalizedFormat == 'brawl') ? 1 : 4;

  final byId = <String, Map<String, dynamic>>{};
  for (final card in foundCards) {
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
  final consolidated = byId.values.toList();

  for (final card in consolidated) {
    final name = card['name'] as String;
    final typeLine = card['type_line'] as String;
    final quantity = card['quantity'] as int;
    final isCommander = card['is_commander'] == true;
    final isBasicLand = typeLine.toLowerCase().contains('basic land');

    if (isCommander && quantity != 1) {
      warnings
          .add('Comandante "$name" deve ter quantidade 1 (atual: $quantity).');
    }

    if (!isBasicLand && !isCommander && quantity > limit) {
      warnings.add('$name tem $quantity cópias (limite: $limit)');
    }
  }

  // 7. Verifica legalidades (banned / restricted / not_legal)
  final cardIdsToCheck = consolidated
      .map((c) => c['card_id'] as String)
      .where((id) => id.isNotEmpty)
      .toList();

  if (cardIdsToCheck.isNotEmpty) {
    final legalityResult = await pool.execute(
      Sql.named(
        'SELECT c.name, cl.status FROM card_legalities cl JOIN cards c ON c.id = cl.card_id WHERE cl.card_id = ANY(@ids) AND cl.format = @format',
      ),
      parameters: {
        'ids': TypedValue(Type.uuidArray, cardIdsToCheck),
        'format': normalizedFormat,
      },
    );

    for (final row in legalityResult) {
      final cardName = row[0] as String;
      final status = (row[1] as String?)?.toLowerCase() ?? 'unknown';
      if (status == 'banned') {
        warnings.add('$cardName é BANIDA em $normalizedFormat');
      } else if (status == 'restricted') {
        warnings.add('$cardName é RESTRITA em $normalizedFormat (máx 1)');
      } else if (status == 'not_legal') {
        warnings.add('$cardName não é válida em $normalizedFormat');
      }
    }
  }

  // Total de cartas
  final totalCards = consolidated.fold<int>(
    0,
    (sum, c) => sum + (c['quantity'] as int),
  );

  // Warnings de tamanho do deck
  if (normalizedFormat == 'commander') {
    if (totalCards > 100) {
      warnings.add(
          'Deck de Commander não pode exceder 100 cartas (encontradas: $totalCards)');
    } else if (totalCards != 100) {
      warnings.add(
          'Para validação estrita, Commander deve ter exatamente 100 cartas (encontradas: $totalCards)');
    }
    final hasCommander = consolidated.any((c) => c['is_commander'] == true);
    if (!hasCommander) {
      warnings.add('Nenhum comandante foi marcado na lista.');
    }
  }

  if (normalizedFormat == 'brawl') {
    if (totalCards > 60) {
      warnings.add(
          'Deck de Brawl não pode exceder 60 cartas (encontradas: $totalCards)');
    } else if (totalCards != 60) {
      warnings.add(
          'Para validação estrita, Brawl deve ter exatamente 60 cartas (encontradas: $totalCards)');
    }
    final hasCommander = consolidated.any((c) => c['is_commander'] == true);
    if (!hasCommander) {
      warnings.add('Nenhum comandante foi marcado na lista.');
    }
  }

  return Response.json(body: {
    'found_cards': foundCards,
    'not_found_lines': notFoundLines,
    'warnings': warnings,
    'total_cards': totalCards,
    'total_unique': consolidated.length,
  });
}
