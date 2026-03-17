import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/api/api_client.dart';
import 'package:manaloom/features/decks/providers/deck_provider.dart';

class _FakeApiClient extends ApiClient {
  _FakeApiClient({
    Map<String, ApiResponse Function(Map<String, dynamic>)>? postHandlers,
    Map<String, ApiResponse Function()>? getHandlers,
  }) : _postHandlers = postHandlers ?? const {},
       _getHandlers = getHandlers ?? const {};

  final Map<String, ApiResponse Function(Map<String, dynamic>)> _postHandlers;
  final Map<String, ApiResponse Function()> _getHandlers;
  final List<String> postCalls = [];
  final List<Map<String, dynamic>> postBodies = [];

  @override
  Future<ApiResponse> post(
    String endpoint,
    Map<String, dynamic> body, {
    Duration? timeout,
  }) async {
    postCalls.add(endpoint);
    postBodies.add(body);
    final handler = _postHandlers[endpoint];
    if (handler == null) {
      throw UnimplementedError('No POST handler for $endpoint');
    }
    return handler(body);
  }

  @override
  Future<ApiResponse> get(String endpoint) async {
    final handler = _getHandlers[endpoint];
    if (handler == null) {
      throw UnimplementedError('No GET handler for $endpoint');
    }
    return handler();
  }
}

void main() {
  group('DeckProvider.createDeck', () {
    test('fails when batch resolve endpoint fails', () async {
      final apiClient = _FakeApiClient(
        postHandlers: {
          '/cards/resolve/batch':
              (_) => ApiResponse(500, {'error': 'resolve failed'}),
        },
      );
      final provider = DeckProvider(apiClient: apiClient);

      final created = await provider.createDeck(
        name: 'Test Deck',
        format: 'commander',
        cards: const [
          {'name': 'Sol Ring', 'quantity': 1, 'is_commander': false},
        ],
      );

      expect(created, isFalse);
      expect(provider.errorMessage, contains('resolve failed'));
      expect(apiClient.postCalls, equals(['/cards/resolve/batch']));
    });

    test('fails when batch resolve returns unresolved names', () async {
      final apiClient = _FakeApiClient(
        postHandlers: {
          '/cards/resolve/batch':
              (_) => ApiResponse(200, {
                'data': const [],
                'unresolved': const ['Unknown Card'],
                'total_input': 1,
                'total_resolved': 0,
              }),
        },
      );
      final provider = DeckProvider(apiClient: apiClient);

      final created = await provider.createDeck(
        name: 'Test Deck',
        format: 'commander',
        cards: const [
          {'name': 'Unknown Card', 'quantity': 1, 'is_commander': false},
        ],
      );

      expect(created, isFalse);
      expect(provider.errorMessage, contains('Unknown Card'));
      expect(apiClient.postCalls, equals(['/cards/resolve/batch']));
    });

    test('fails when batch resolve returns ambiguous names', () async {
      final apiClient = _FakeApiClient(
        postHandlers: {
          '/cards/resolve/batch':
              (_) => ApiResponse(200, {
                'data': const [],
                'unresolved': const [],
                'ambiguous': const [
                  {
                    'input_name': 'Lightning',
                    'candidates': ['Lightning Bolt', 'Lightning Helix'],
                  },
                ],
                'total_input': 1,
                'total_resolved': 0,
                'total_ambiguous': 1,
              }),
        },
      );
      final provider = DeckProvider(apiClient: apiClient);

      final created = await provider.createDeck(
        name: 'Test Deck',
        format: 'commander',
        cards: const [
          {'name': 'Lightning', 'quantity': 1, 'is_commander': false},
        ],
      );

      expect(created, isFalse);
      expect(provider.errorMessage, contains('Lightning'));
      expect(provider.errorMessage, contains('Lightning Bolt'));
      expect(provider.errorMessage, contains('Lightning Helix'));
      expect(apiClient.postCalls, equals(['/cards/resolve/batch']));
    });

    test(
      'keeps direct card ids and resolved names when creating deck',
      () async {
        final apiClient = _FakeApiClient(
          postHandlers: {
            '/cards/resolve/batch': (body) {
              expect(body['names'], equals(['Sol Ring']));
              return ApiResponse(200, {
                'data': const [
                  {
                    'input_name': 'Sol Ring',
                    'card_id': 'sol-ring-id',
                    'matched_name': 'Sol Ring',
                  },
                ],
                'unresolved': const [],
                'total_input': 1,
                'total_resolved': 1,
              });
            },
            '/decks': (body) {
              expect(body['is_public'], isTrue);
              expect(
                body['cards'],
                equals([
                  {
                    'card_id': 'commander-id',
                    'quantity': 1,
                    'is_commander': true,
                  },
                  {
                    'card_id': 'sol-ring-id',
                    'quantity': 2,
                    'is_commander': false,
                  },
                ]),
              );
              return ApiResponse(201, {'id': 'deck-1'});
            },
          },
          getHandlers: {'/decks': () => ApiResponse(200, const [])},
        );
        final provider = DeckProvider(
          apiClient: apiClient,
          trackActivationEvent:
              (
                String eventName, {
                String? format,
                String? deckId,
                String source = 'app',
                Map<String, dynamic>? metadata,
              }) async {},
        );

        final created = await provider.createDeck(
          name: 'Test Deck',
          format: 'commander',
          isPublic: true,
          cards: const [
            {'card_id': 'commander-id', 'quantity': 1, 'is_commander': true},
            {'name': 'Sol Ring', 'quantity': 2, 'is_commander': false},
          ],
        );

        expect(created, isTrue);
      expect(apiClient.postCalls, equals(['/cards/resolve/batch', '/decks']));
    },
    );
  });

  group('DeckProvider AI deck flows', () {
    test('optimizeDeck surfaces structured needs_repair payload on 422', () async {
      final apiClient = _FakeApiClient(
        postHandlers: {
          '/ai/optimize': (_) => ApiResponse(422, {
                'error': 'O deck precisa de reparo estrutural.',
                'outcome_code': 'needs_repair',
                'quality_error': {
                  'code': 'OPTIMIZE_NEEDS_REPAIR',
                  'message': 'O deck atual está fora da faixa de optimize.',
                  'reasons': ['Poucas mágicas relevantes para o comandante.'],
                  'repair_plan': {'target_land_count': 36},
                },
                'next_action': {
                  'type': 'rebuild_guided',
                  'endpoint': '/ai/rebuild',
                  'payload': {
                    'deck_id': 'deck-1',
                    'rebuild_scope': 'auto',
                    'save_mode': 'draft_clone',
                  },
                },
              }),
        },
      );
      final provider = DeckProvider(apiClient: apiClient);

      expect(
        () => provider.optimizeDeck('deck-1', 'control'),
        throwsA(
          isA<DeckAiFlowException>()
              .having((e) => e.code, 'code', 'OPTIMIZE_NEEDS_REPAIR')
              .having((e) => e.outcomeCode, 'outcomeCode', 'needs_repair')
              .having(
                (e) => e.nextAction['type'],
                'nextAction.type',
                'rebuild_guided',
              ),
        ),
      );
    });

    test('rebuildDeck returns saved draft payload on success', () async {
      final apiClient = _FakeApiClient(
        postHandlers: {
          '/ai/rebuild': (body) {
            expect(body['deck_id'], 'deck-1');
            expect(body['save_mode'], 'draft_clone');
            expect(body['rebuild_scope'], 'auto');
            return ApiResponse(200, {
              'mode': 'rebuild_guided',
              'outcome_code': 'rebuild_created',
              'draft_deck_id': 'draft-1',
              'rebuild_scope_selected': 'full_non_commander_rebuild',
            });
          },
        },
      );
      final trackedEvents = <String>[];
      final provider = DeckProvider(
        apiClient: apiClient,
        trackActivationEvent:
            (
              String eventName, {
              String? format,
              String? deckId,
              String source = 'app',
              Map<String, dynamic>? metadata,
            }) async {
              trackedEvents.add(eventName);
            },
      );

      final result = await provider.rebuildDeck('deck-1');

      expect(result['draft_deck_id'], 'draft-1');
      expect(trackedEvents, contains('deck_rebuild_created'));
    });
  });
}
