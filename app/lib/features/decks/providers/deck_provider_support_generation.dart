import '../../../core/api/api_client.dart';
import '../../../core/utils/logger.dart';
import 'deck_provider_support_common.dart';

Future<List<Map<String, dynamic>>> normalizeCreateDeckCards(
  ApiClient apiClient,
  List<Map<String, dynamic>> cards,
) async {
  if (cards.isEmpty) return const [];

  final aggregatedByCardId = <String, Map<String, dynamic>>{};
  final aggregatedByName = <String, Map<String, dynamic>>{};

  for (final card in cards) {
    final quantity = (card['quantity'] as int?) ?? 1;
    final isCommander = (card['is_commander'] as bool?) ?? false;
    final cardId = (card['card_id'] as String?)?.trim();
    final name = (card['name'] as String?)?.trim();

    if (cardId != null && cardId.isNotEmpty) {
      final key = '$cardId::$isCommander';
      final existing = aggregatedByCardId[key];
      if (existing == null) {
        aggregatedByCardId[key] = {
          'card_id': cardId,
          'quantity': quantity,
          'is_commander': isCommander,
        };
      } else {
        aggregatedByCardId[key] = {
          ...existing,
          'quantity': (existing['quantity'] as int) + quantity,
        };
      }
      continue;
    }

    if (name == null || name.isEmpty) {
      throw Exception('Cada carta precisa de card_id ou name.');
    }

    final key = '${name.toLowerCase()}::$isCommander';
    final existing = aggregatedByName[key];
    if (existing == null) {
      aggregatedByName[key] = {
        'name': name,
        'quantity': quantity,
        'is_commander': isCommander,
      };
    } else {
      aggregatedByName[key] = {
        ...existing,
        'quantity': (existing['quantity'] as int) + quantity,
      };
    }
  }

  final normalized =
      aggregatedByCardId.values
          .map((card) => Map<String, dynamic>.from(card))
          .toList();

  if (aggregatedByName.isEmpty) {
    return normalized;
  }

  final names =
      aggregatedByName.values
          .map((card) => (card['name'] as String).trim())
          .where((name) => name.isNotEmpty)
          .toSet()
          .toList();

  if (names.isEmpty) return normalized;

  final response = await apiClient.post('/cards/resolve/batch', {
    'names': names,
  });

  if (response.statusCode != 200 || response.data is! Map) {
    throw Exception(
      extractApiError(
        response.data,
        fallback: 'Falha ao resolver cartas antes de criar o deck.',
      ),
    );
  }

  final payload = response.data as Map<String, dynamic>;
  final resolvedList = (payload['data'] as List?) ?? const [];
  final unresolvedList = (payload['unresolved'] as List?) ?? const [];
  final ambiguousList = (payload['ambiguous'] as List?) ?? const [];

  final cardIdByInputName = <String, String>{};
  for (final item in resolvedList) {
    if (item is! Map) continue;
    final inputName = item['input_name']?.toString().trim();
    final cardId = item['card_id']?.toString().trim();
    if (inputName == null || inputName.isEmpty) continue;
    if (cardId == null || cardId.isEmpty) continue;
    cardIdByInputName[inputName.toLowerCase()] = cardId;
  }

  final unresolvedNames =
      unresolvedList
          .map((item) => item.toString().trim())
          .where((name) => name.isNotEmpty)
          .toSet();
  final ambiguousNames = <String>{};

  for (final item in ambiguousList) {
    if (item is! Map) continue;
    final inputName = item['input_name']?.toString().trim();
    if (inputName == null || inputName.isEmpty) continue;
    final candidates =
        (item['candidates'] as List?)
            ?.map((candidate) => candidate.toString().trim())
            .where((candidate) => candidate.isNotEmpty)
            .toList() ??
        const <String>[];
    if (candidates.isEmpty) {
      ambiguousNames.add(inputName);
    } else {
      ambiguousNames.add('$inputName (${candidates.join(', ')})');
    }
  }

  for (final card in aggregatedByName.values) {
    final name = (card['name'] as String?)?.trim();
    if (name == null || name.isEmpty) continue;

    final cardId = cardIdByInputName[name.toLowerCase()];
    if (cardId == null || cardId.isEmpty) {
      unresolvedNames.add(name);
      continue;
    }

    normalized.add({
      'card_id': cardId,
      'quantity': card['quantity'] ?? 1,
      'is_commander': card['is_commander'] ?? false,
    });
  }

  if (unresolvedNames.isNotEmpty || ambiguousNames.isNotEmpty) {
    final sortedNames =
        {...unresolvedNames, ...ambiguousNames}.toList()..sort();
    throw Exception(
      'Nao foi possivel resolver todas as cartas antes de criar o deck: '
      '${sortedNames.join(', ')}.',
    );
  }

  return normalized;
}

Future<Map<String, dynamic>> generateDeckFromPrompt(
  ApiClient apiClient, {
  required String prompt,
  required String format,
}) async {
  final response = await apiClient.post('/ai/generate', {
    'prompt': prompt,
    'format': format,
  });

  if (response.statusCode == 200) {
    return response.data as Map<String, dynamic>;
  }

  final data = response.data;
  final message =
      data is Map<String, dynamic>
          ? (data['error'] as String? ??
              data['message'] as String? ??
              'Falha ao gerar deck')
          : 'Falha ao gerar deck';
  throw Exception('$message (${response.statusCode})');
}

Future<Map<String, dynamic>?> searchFirstCardByName(
  ApiClient apiClient,
  String cardName,
) async {
  final encoded = Uri.encodeQueryComponent(cardName);
  final searchResponse = await apiClient.get('/cards?name=$encoded&limit=1');

  if (searchResponse.statusCode != 200) {
    return null;
  }

  final results = extractCardSearchResults(searchResponse.data);
  if (results.isEmpty) {
    return null;
  }

  return results.first;
}

Future<List<Map<String, dynamic>>> resolveOptimizationAdditions(
  ApiClient apiClient,
  List<String> cardsToAdd,
) async {
  AppLogger.debug('🔍 [DeckProvider] Buscando IDs das cartas a adicionar...');
  return resolveCardNamesInParallel<Map<String, dynamic>>(
    cardNames: cardsToAdd,
    resolver: (cardName) async {
      try {
        AppLogger.debug('  🔎 Buscando: $cardName');
        final card = await searchFirstCardByName(apiClient, cardName);

        if (card != null) {
          AppLogger.debug('  ✅ Encontrado: $cardName -> ${card['id']}');
          return {
            'card_id': card['id'],
            'quantity': 1,
            'is_commander': false,
            'type_line': card['type_line'] ?? '',
            'color_identity':
                (card['color_identity'] as List?)
                    ?.map((e) => e.toString())
                    .toList() ??
                const <String>[],
          };
        }
        AppLogger.debug('  ❌ Não encontrado: $cardName');
      } catch (e) {
        AppLogger.warning('Erro ao buscar $cardName: $e');
      }
      return null;
    },
  );
}

Future<List<String>> resolveOptimizationRemovals(
  ApiClient apiClient,
  List<String> cardsToRemove,
) async {
  AppLogger.debug('🔍 [DeckProvider] Buscando IDs das cartas a remover...');
  return resolveCardNamesInParallel<String>(
    cardNames: cardsToRemove,
    resolver: (cardName) async {
      try {
        AppLogger.debug('  🔎 Buscando para remover: $cardName');
        final card = await searchFirstCardByName(apiClient, cardName);

        if (card != null) {
          AppLogger.debug(
            '  ✅ Encontrado para remoção: $cardName -> ${card['id']}',
          );
          return card['id'] as String;
        }
      } catch (e) {
        AppLogger.warning('Erro ao buscar $cardName: $e');
      }
      return null;
    },
  );
}
