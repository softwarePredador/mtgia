import '../../../core/api/api_client.dart';
import '../models/deck.dart';
import '../models/deck_details.dart';
import 'deck_provider_support_common.dart';

Map<String, dynamic> buildImportDeckRequestBody({
  required String name,
  required String format,
  required String list,
  String? description,
  String? commander,
}) {
  return {
    'name': name,
    'format': format,
    'list': list,
    if (description != null && description.isNotEmpty)
      'description': description,
    if (commander != null && commander.isNotEmpty) 'commander': commander,
  };
}

Map<String, dynamic> parseImportDeckResponse(ApiResponse response) {
  if (response.statusCode == 200) {
    final data = asDynamicMap(response.data);
    return {
      'success': true,
      'deck': data['deck'],
      'cards_imported': data['cards_imported'] ?? 0,
      'not_found_lines': data['not_found_lines'] ?? const <String>[],
      'warnings': data['warnings'] ?? const <String>[],
    };
  }

  final data = asDynamicMap(response.data);
  return {
    'success': false,
    'error':
        data['error']?.toString() ??
        'Erro ao importar deck: ${response.statusCode}',
    'not_found_lines':
        (data['not_found'] is List)
            ? List<String>.from(data['not_found'])
            : const <String>[],
  };
}

Future<Map<String, dynamic>> importDeckFromListRequest(
  ApiClient apiClient, {
  required String name,
  required String format,
  required String list,
  String? description,
  String? commander,
}) async {
  final response = await apiClient.post(
    '/import',
    buildImportDeckRequestBody(
      name: name,
      format: format,
      list: list,
      description: description,
      commander: commander,
    ),
  );
  return parseImportDeckResponse(response);
}

Map<String, dynamic> parseValidateImportListResponse(ApiResponse response) {
  if (response.statusCode == 200) {
    final data = asDynamicMap(response.data);
    return {
      'success': true,
      'found_cards': data['found_cards'] ?? const <dynamic>[],
      'not_found_lines': data['not_found_lines'] ?? const <String>[],
      'warnings': data['warnings'] ?? const <String>[],
    };
  }

  final data = asDynamicMap(response.data);
  return {
    'success': false,
    'error': data['error']?.toString() ?? 'Erro ao validar lista',
  };
}

Future<Map<String, dynamic>> validateImportListRequest(
  ApiClient apiClient, {
  required String format,
  required String list,
}) async {
  final response = await apiClient.post('/import/validate', {
    'format': format,
    'list': list,
  });
  return parseValidateImportListResponse(response);
}

Map<String, dynamic> buildImportToDeckRequestBody({
  required String deckId,
  required String list,
  required bool replaceAll,
}) {
  return {'deck_id': deckId, 'list': list, 'replace_all': replaceAll};
}

Map<String, dynamic> parseImportToDeckResponse(ApiResponse response) {
  if (response.statusCode == 200) {
    final data = asDynamicMap(response.data);
    return {
      'success': true,
      'cards_imported': data['cards_imported'] ?? 0,
      'not_found_lines': data['not_found_lines'] ?? const <String>[],
      'warnings': data['warnings'] ?? const <String>[],
    };
  }

  final data = asDynamicMap(response.data);
  return {
    'success': false,
    'error':
        data['error']?.toString() ?? 'Erro ao importar: ${response.statusCode}',
    'not_found_lines':
        (data['not_found_lines'] is List)
            ? List<String>.from(data['not_found_lines'])
            : const <String>[],
  };
}

Future<Map<String, dynamic>> importListToDeckRequest(
  ApiClient apiClient, {
  required String deckId,
  required String list,
  required bool replaceAll,
}) async {
  final response = await apiClient.post(
    '/import/to-deck',
    buildImportToDeckRequestBody(
      deckId: deckId,
      list: list,
      replaceAll: replaceAll,
    ),
  );
  return parseImportToDeckResponse(response);
}

DeckDetails? applyDeckVisibilityToSelectedDeck(
  DeckDetails? selectedDeck,
  String deckId, {
  required bool isPublic,
}) {
  if (selectedDeck == null || selectedDeck.id != deckId) {
    return selectedDeck;
  }
  return selectedDeck.copyWith(isPublic: isPublic);
}

List<Deck> applyDeckVisibilityToDeckList(
  List<Deck> decks,
  String deckId, {
  required bool isPublic,
}) {
  return decks
      .map(
        (deck) => deck.id == deckId ? deck.copyWith(isPublic: isPublic) : deck,
      )
      .toList();
}

Map<String, dynamic> parseDeckExportResponse(ApiResponse response) {
  if (response.statusCode == 200 && response.data is Map) {
    return Map<String, dynamic>.from(response.data as Map);
  }
  return {'error': 'Falha ao exportar deck: ${response.statusCode}'};
}

Future<bool> togglePublicRequest(
  ApiClient apiClient, {
  required String deckId,
  required bool isPublic,
}) async {
  final response = await apiClient.put('/decks/$deckId', {
    'is_public': isPublic,
  });
  return response.statusCode == 200;
}

Future<Map<String, dynamic>> exportDeckAsTextRequest(
  ApiClient apiClient,
  String deckId,
) async {
  final response = await apiClient.get('/decks/$deckId/export');
  return parseDeckExportResponse(response);
}

Map<String, dynamic> parseCopyPublicDeckResponse(ApiResponse response) {
  if (response.statusCode == 201) {
    final data = asDynamicMap(response.data);
    return {'success': true, 'deck': data['deck']};
  }

  final data = asDynamicMap(response.data);
  return {
    'success': false,
    'error':
        data['error']?.toString() ??
        'Falha ao copiar deck: ${response.statusCode}',
  };
}

Future<Map<String, dynamic>> copyPublicDeckRequest(
  ApiClient apiClient,
  String deckId,
) async {
  final response = await apiClient.post('/community/decks/$deckId', {});
  return parseCopyPublicDeckResponse(response);
}
