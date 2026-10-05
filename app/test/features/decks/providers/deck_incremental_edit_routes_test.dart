import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/api/api_client.dart';
import 'package:manaloom/features/decks/providers/deck_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// DCK-P0-00 (D-27): small edits use the incremental routes that stay open
/// under `decks_private`. `PUT /decks/:id` rewrites the whole list and
/// belongs to `deck_replace_all`, which is closed in the beta.
class _RecordingApiClient extends ApiClient {
  _RecordingApiClient({this.patchResponse});

  final ApiResponse? patchResponse;
  final calls = <String>[];
  final bodies = <String, Map<String, dynamic>>{};

  @override
  Future<ApiResponse> get(String endpoint) async {
    calls.add('GET $endpoint');
    return ApiResponse(200, {
      'id': 'deck-1',
      'name': 'Deck',
      'format': 'commander',
      'is_public': false,
      'created_at': '2026-10-01T00:00:00.000Z',
      'color_identity': const ['U'],
      'stats': const {'total_cards': 1},
      'commander': const <Object?>[],
      'main_board': const <String, Object?>{},
    });
  }

  @override
  Future<ApiResponse> post(
    String endpoint,
    Map<String, dynamic> body, {
    Duration? timeout,
  }) async {
    calls.add('POST $endpoint');
    bodies['POST $endpoint'] = body;
    return ApiResponse(200, const {'ok': true});
  }

  @override
  Future<ApiResponse> patch(String endpoint, Map<String, dynamic> body) async {
    calls.add('PATCH $endpoint');
    bodies['PATCH $endpoint'] = body;
    return patchResponse ?? ApiResponse(200, const {'ok': true});
  }

  @override
  Future<ApiResponse> put(String endpoint, Map<String, dynamic> body) async {
    calls.add('PUT $endpoint');
    return ApiResponse(403, const {'error': 'capability_unavailable'});
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(ApiClient.resetForTesting);

  test('removing a card sends only that card to cards/remove', () async {
    final client = _RecordingApiClient();
    final provider = DeckProvider(apiClient: client);
    addTearDown(provider.dispose);

    await provider.removeCardFromDeck(deckId: 'deck-1', cardId: 'card-9');

    expect(client.calls, contains('POST /decks/deck-1/cards/remove'));
    expect(client.bodies['POST /decks/deck-1/cards/remove'], {
      'card_id': 'card-9',
    });
    expect(client.calls.where((call) => call.startsWith('PUT ')), isEmpty);
  });

  test('description, strategy and visibility go through PATCH', () async {
    final client = _RecordingApiClient();
    final provider = DeckProvider(apiClient: client);
    addTearDown(provider.dispose);

    await provider.updateDeckDescription(deckId: 'deck-1', description: 'x');
    await provider.updateDeckStrategy(
      deckId: 'deck-1',
      archetype: 'control',
      bracket: 3,
    );
    final visibility = await provider.togglePublic('deck-1', isPublic: false);

    expect(visibility.isSuccess, isTrue);
    expect(
      client.calls.where((call) => call == 'PATCH /decks/deck-1'),
      hasLength(3),
    );
    expect(client.calls.where((call) => call.startsWith('PUT ')), isEmpty);
  });

  test('a refused publication returns the server phrase, not the code', () async {
    final client = _RecordingApiClient(
      patchResponse: ApiResponse(422, const {
        'error':
            'Um deck vazio não pode ser público. Adicione cartas antes de publicar.',
        'error_code': 'deck_public_requires_cards',
      }),
    );
    final provider = DeckProvider(apiClient: client);
    addTearDown(provider.dispose);

    final result = await provider.togglePublic('deck-1', isPublic: true);

    expect(result.isSuccess, isFalse);
    expect(
      result.errorMessage,
      startsWith('Um deck vazio não pode ser público'),
    );
    expect(result.errorMessage, isNot(contains('deck_public_requires_cards')));
  });
}
