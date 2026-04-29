import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/api/api_client.dart';
import 'package:manaloom/features/scanner/services/scanner_card_search_service.dart';

class _FakeApiClient extends ApiClient {
  _FakeApiClient({
    Map<String, ApiResponse> getResponses = const {},
    Map<String, ApiResponse> postResponses = const {},
  }) : _getResponses = getResponses,
       _postResponses = postResponses;

  final Map<String, ApiResponse> _getResponses;
  final Map<String, ApiResponse> _postResponses;
  final List<String> getCalls = [];
  final List<String> postCalls = [];

  @override
  Future<ApiResponse> get(String endpoint) async {
    getCalls.add(endpoint);
    final response = _getResponses[endpoint];
    if (response == null) {
      throw UnimplementedError('No GET response for $endpoint');
    }
    return response;
  }

  @override
  Future<ApiResponse> post(
    String endpoint,
    Map<String, dynamic> body, {
    Duration? timeout,
  }) async {
    postCalls.add(endpoint);
    final response = _postResponses[endpoint];
    if (response == null) {
      throw UnimplementedError('No POST response for $endpoint');
    }
    return response;
  }
}

void main() {
  group('ScannerCardSearchService', () {
    test('maps printings collector number and foil fields', () async {
      final apiClient = _FakeApiClient(
        getResponses: {
          '/cards/printings?name=Lightning+Bolt&limit=50': ApiResponse(200, {
            'data': const [
              {
                'id': 'card-1',
                'name': 'Lightning Bolt',
                'mana_cost': '{R}',
                'type_line': 'Instant',
                'oracle_text': 'Deal 3 damage to any target.',
                'colors': ['R'],
                'color_identity': ['R'],
                'set_code': 'blb',
                'set_name': 'Bloomburrow',
                'set_release_date': '2024-08-02',
                'rarity': 'rare',
                'collector_number': '157',
                'foil': true,
              },
            ],
          }),
        },
      );
      final service = ScannerCardSearchService(apiClient: apiClient);

      final printings = await service.fetchPrintingsByExactName(
        'Lightning Bolt',
      );

      expect(printings, hasLength(1));
      expect(printings.single.collectorNumber, '157');
      expect(printings.single.foil, isTrue);
      expect(apiClient.getCalls, [
        '/cards/printings?name=Lightning+Bolt&limit=50',
      ]);
    });

    test(
      'maps resolve fallback response from Scryfall auto-import path',
      () async {
        final apiClient = _FakeApiClient(
          postResponses: {
            '/cards/resolve': ApiResponse(200, {
              'source': 'scryfall',
              'data': const [
                {
                  'id': 'card-2',
                  'name': 'New Card',
                  'type_line': 'Creature',
                  'colors': [],
                  'color_identity': [],
                  'set_code': 'fic',
                  'rarity': 'mythic',
                  'collector_number': '397',
                  'foil': false,
                },
              ],
            }),
          },
        );
        final service = ScannerCardSearchService(apiClient: apiClient);

        final resolved = await service.resolveCard('New Card');

        expect(resolved, hasLength(1));
        expect(resolved.single.name, 'New Card');
        expect(resolved.single.collectorNumber, '397');
        expect(resolved.single.foil, isFalse);
        expect(apiClient.postCalls, ['/cards/resolve']);
      },
    );
  });
}
