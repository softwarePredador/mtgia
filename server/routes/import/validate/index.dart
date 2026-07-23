import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';
import '../../../lib/basic_land_utils.dart' as basic_lands;
import '../../../lib/deck_format_support.dart';
import '../../../lib/deck_request_support.dart';
import '../../../lib/deck_rules_service.dart';
import '../../../lib/import_list_service.dart';
import '../../../lib/import_card_lookup_service.dart';

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

  late final String normalizedFormat;
  late final Object rawList;
  try {
    final body = requireJsonObject(await context.request.json());
    final rawFormat = requireNonEmptyString(body, 'format');
    final supportedFormat = normalizeSupportedDeckFormat(rawFormat);
    if (supportedFormat == null) {
      throw DeckRequestException(unsupportedDeckFormatMessage(rawFormat));
    }
    normalizedFormat = supportedFormat;
    final listValue = body['list'];
    if (listValue == null) {
      throw const DeckRequestException('Field list is required.');
    }
    rawList = listValue;
  } on FormatException catch (e) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'error': 'Invalid JSON body: ${e.message}'},
    );
  } on DeckRequestException catch (e) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'error': e.message},
    );
  }

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
  final localizedMatches = <Map<String, dynamic>>[];
  final localizedMatchKeys = <String>{};

  final parseResult = parseImportLines(lines);
  final parsedItems = parseResult.parsedItems;
  notFoundLines.addAll(parseResult.invalidLines);

  // 2) Resolve nomes em lote (exato + clean + split fallback)
  final foundCardsMap = await resolveImportCardNames(
    pool,
    parsedItems,
    preferredFormat: normalizedFormat,
  );

  // 5. Montagem da lista de resultados
  for (final item in parsedItems) {
    if (notFoundLines.contains(item['line'])) continue;

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

      foundCards.add({
        'card_id': cardData['id'],
        'oracle_id': cardData['oracle_id'],
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

  final copiesByPhysicalKey = <String, Map<String, dynamic>>{};

  for (final card in consolidated) {
    final name = (card['name'] as String).trim();
    final oracleId = card['oracle_id']?.toString().trim();
    final typeLine = card['type_line'] as String;
    final quantity = card['quantity'] as int;
    final isCommander = card['is_commander'] == true;

    final isBasicLand = basic_lands.isBasicLandCard(
      name: name,
      typeLine: typeLine,
    );

    if (isCommander && quantity != 1) {
      warnings.add(
        'Comandante "$name" deve ter quantidade 1 (atual: $quantity).',
      );
    }

    if (isCommander || isBasicLand) continue;

    final key =
        oracleId != null && oracleId.isNotEmpty
            ? 'oracle:$oracleId'
            : 'name:${normalizePhysicalCardCopyName(name)}';
    final existing = copiesByPhysicalKey[key];
    if (existing == null) {
      copiesByPhysicalKey[key] = {
        'name': name,
        'qty': quantity,
        'source_names': <String>{name},
      };
    } else {
      final sourceNames = existing['source_names'] as Set<String>;
      sourceNames.add(name);
      copiesByPhysicalKey[key] = {
        'name': existing['name'] as String,
        'qty': (existing['qty'] as int) + quantity,
        'source_names': sourceNames,
      };
    }
  }

  for (final entry in copiesByPhysicalKey.values) {
    final name = entry['name'] as String;
    final qty = entry['qty'] as int;
    if (qty > limit) {
      final sourceNames = entry['source_names'] as Set<String>;
      if (sourceNames.length > 1) {
        final names = sourceNames.join('" / "');
        warnings.add(
          '"$names" contam como a mesma carta física e têm $qty cópias (limite: $limit)',
        );
      } else {
        warnings.add('$name tem $qty cópias (limite: $limit)');
      }
    }
  }

  if (consolidated.isNotEmpty) {
    try {
      await DeckRulesService(pool).validateAndThrow(
        format: normalizedFormat,
        cards: [
          for (final card in consolidated)
            {
              'card_id': card['card_id'],
              'quantity': card['quantity'],
              'is_commander': card['is_commander'] ?? false,
            },
        ],
      );
    } on DeckRulesException catch (e) {
      final message = e.message;
      final cardName = e.cardName;
      final alreadyCovered =
          cardName != null &&
          warnings.any(
            (warning) => warning.toLowerCase().contains(cardName.toLowerCase()),
          );
      if (!alreadyCovered && !warnings.contains(message)) {
        warnings.add(message);
      }
    }
  }

  // 7. Verifica legalidades (banned / restricted / not_legal)
  final cardIdsToCheck =
      consolidated
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
        'Deck de Commander não pode exceder 100 cartas (encontradas: $totalCards)',
      );
    } else if (totalCards != 100) {
      warnings.add(
        'Para validação estrita, Commander deve ter exatamente 100 cartas (encontradas: $totalCards)',
      );
    }
    final hasCommander = consolidated.any((c) => c['is_commander'] == true);
    if (!hasCommander) {
      warnings.add('Nenhum comandante foi marcado na lista.');
    }
  }

  if (normalizedFormat == 'brawl') {
    if (totalCards > 60) {
      warnings.add(
        'Deck de Brawl não pode exceder 60 cartas (encontradas: $totalCards)',
      );
    } else if (totalCards != 60) {
      warnings.add(
        'Para validação estrita, Brawl deve ter exatamente 60 cartas (encontradas: $totalCards)',
      );
    }
    final hasCommander = consolidated.any((c) => c['is_commander'] == true);
    if (!hasCommander) {
      warnings.add('Nenhum comandante foi marcado na lista.');
    }
  }

  return Response.json(
    body: {
      'found_cards': foundCards,
      'not_found_lines': notFoundLines,
      'localized_matches': localizedMatches,
      'localized_matches_count': localizedMatches.length,
      'warnings': warnings,
      'total_cards': totalCards,
      'total_unique': consolidated.length,
    },
  );
}
