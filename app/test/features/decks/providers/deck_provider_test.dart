import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/api/api_client.dart';
import 'package:manaloom/features/decks/providers/deck_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeApiClient extends ApiClient {
  _FakeApiClient({
    Map<String, ApiResponse Function(Map<String, dynamic>)>? postHandlers,
    Map<String, ApiResponse Function()>? getHandlers,
    Map<String, ApiResponse Function(Map<String, dynamic>)>? putHandlers,
    Map<String, ApiResponse Function()>? deleteHandlers,
  }) : _postHandlers = postHandlers ?? const {},
       _getHandlers = getHandlers ?? const {},
       _putHandlers = putHandlers ?? const {},
       _deleteHandlers = deleteHandlers ?? const {};

  final Map<String, ApiResponse Function(Map<String, dynamic>)> _postHandlers;
  final Map<String, ApiResponse Function()> _getHandlers;
  final Map<String, ApiResponse Function(Map<String, dynamic>)> _putHandlers;
  final Map<String, ApiResponse Function()> _deleteHandlers;
  final List<String> postCalls = [];
  final List<Map<String, dynamic>> postBodies = [];
  final List<String> putCalls = [];
  final List<Map<String, dynamic>> putBodies = [];

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

  @override
  Future<ApiResponse> put(String endpoint, Map<String, dynamic> body) async {
    putCalls.add(endpoint);
    putBodies.add(body);
    final handler = _putHandlers[endpoint];
    if (handler == null) {
      throw UnimplementedError('No PUT handler for $endpoint');
    }
    return handler(body);
  }

  @override
  Future<ApiResponse> delete(String endpoint) async {
    final handler = _deleteHandlers[endpoint];
    if (handler == null) {
      throw UnimplementedError('No DELETE handler for $endpoint');
    }
    return handler();
  }
}

Map<String, dynamic> _buildDeckDetailsJson(
  Map<String, int> cardsById, {
  String deckId = 'deck-1',
}) {
  Map<String, dynamic> card(
    String id,
    String name, {
    required int quantity,
    bool isCommander = false,
    List<String> colors = const <String>[],
    List<String> colorIdentity = const <String>[],
    String typeLine = 'Artifact',
    String manaCost = '{2}',
  }) => {
    'id': id,
    'name': name,
    'mana_cost': manaCost,
    'type_line': typeLine,
    'oracle_text': '',
    'colors': colors,
    'color_identity': colorIdentity,
    'image_url': null,
    'set_code': 'tst',
    'set_name': 'Test Set',
    'set_release_date': '2026-01-01',
    'rarity': 'rare',
    'quantity': quantity,
    'is_commander': isCommander,
    'condition': 'NM',
  };

  return {
    'id': deckId,
    'name': 'Smoke Deck',
    'format': 'commander',
    'description': 'Deck para smoke do fluxo core',
    'is_public': false,
    'created_at': '2026-03-23T00:00:00.000Z',
    'color_identity': const ['U'],
    'stats': {
      'total_cards': cardsById.values.fold<int>(0, (sum, qty) => sum + qty),
    },
    'commander': [
      card(
        'cmd-1',
        'Talrand, Sky Summoner',
        quantity: 1,
        isCommander: true,
        colors: const ['U'],
        colorIdentity: const ['U'],
        typeLine: 'Legendary Creature — Merfolk Wizard',
        manaCost: '{2}{U}{U}',
      ),
    ],
    'main_board': {
      'Artifacts': [
        if ((cardsById['remove-1'] ?? 0) > 0)
          card('remove-1', 'Mind Stone', quantity: cardsById['remove-1']!),
        if ((cardsById['add-1'] ?? 0) > 0)
          card('add-1', 'Arcane Signet', quantity: cardsById['add-1']!),
      ],
      'Instants': [
        card(
          'spell-1',
          'Opt',
          quantity: cardsById['spell-1'] ?? 1,
          colors: const ['U'],
          colorIdentity: const ['U'],
          typeLine: 'Instant',
          manaCost: '{U}',
        ),
      ],
      'Lands': List.generate(
        cardsById['land-1'] ?? 36,
        (index) => card(
          'land-$index',
          'Island',
          quantity: 1,
          colors: const <String>[],
          colorIdentity: const <String>[],
          typeLine: 'Basic Land — Island',
          manaCost: '',
        ),
      ),
    },
  };
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

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
    test(
      'optimizeDeck surfaces structured needs_repair payload on 422',
      () async {
        final apiClient = _FakeApiClient(
          postHandlers: {
            '/ai/optimize':
                (_) => ApiResponse(422, {
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
      },
    );

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
        trackActivationEvent: (
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

    test(
      'core smoke: deck details -> optimize -> apply with ids -> validate',
      () async {
        final currentCards = <String, int>{
          'remove-1': 1,
          'spell-1': 1,
          'land-1': 36,
        };

        final apiClient = _FakeApiClient(
          getHandlers: {
            '/decks/deck-1':
                () => ApiResponse(200, _buildDeckDetailsJson(currentCards)),
          },
          postHandlers: {
            '/ai/optimize':
                (_) => ApiResponse(200, {
                  'mode': 'optimize',
                  'removals': const ['Mind Stone'],
                  'additions': const ['Arcane Signet'],
                  'removals_detailed': const [
                    {
                      'card_id': 'remove-1',
                      'name': 'Mind Stone',
                      'type_line': 'Artifact',
                      'color_identity': <String>[],
                    },
                  ],
                  'additions_detailed': const [
                    {
                      'card_id': 'add-1',
                      'name': 'Arcane Signet',
                      'type_line': 'Artifact',
                      'color_identity': <String>[],
                    },
                  ],
                }),
            '/decks/deck-1/validate':
                (_) => ApiResponse(200, {
                  'valid': true,
                  'ok': true,
                  'errors': const <String>[],
                }),
          },
          putHandlers: {
            '/decks/deck-1': (body) {
              final cards =
                  (body['cards'] as List).cast<Map<String, dynamic>>();
              expect(cards.any((entry) => entry['card_id'] == 'add-1'), isTrue);
              expect(
                cards.any((entry) => entry['card_id'] == 'remove-1'),
                isFalse,
              );

              currentCards
                ..remove('remove-1')
                ..['add-1'] = 1;

              return ApiResponse(200, {'ok': true});
            },
          },
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

        await provider.fetchDeckDetails('deck-1');

        final optimizeResult = await provider.optimizeDeck('deck-1', 'control');
        final applied = await provider.applyOptimizationWithIds(
          deckId: 'deck-1',
          removalsDetailed:
              (optimizeResult['removals_detailed'] as List)
                  .cast<Map<String, dynamic>>(),
          additionsDetailed:
              (optimizeResult['additions_detailed'] as List)
                  .cast<Map<String, dynamic>>(),
        );
        final validation = await provider.validateDeck('deck-1');

        expect(applied, isTrue);
        expect(validation['valid'], isTrue);
        expect(apiClient.postCalls, contains('/ai/optimize'));
        expect(apiClient.postCalls, contains('/decks/deck-1/validate'));
        expect(apiClient.putCalls, contains('/decks/deck-1'));
      },
    );
  });

  group('DeckProvider incremental mutations', () {
    test(
      'addCardToDeck increments local count and refreshes details',
      () async {
        final currentCards = <String, int>{'spell-1': 1, 'land-1': 36};

        final apiClient = _FakeApiClient(
          getHandlers: {
            '/decks':
                () => ApiResponse(200, [
                  {
                    'id': 'deck-1',
                    'name': 'Smoke Deck',
                    'format': 'commander',
                    'is_public': false,
                    'created_at': '2026-03-23T00:00:00.000Z',
                    'card_count': 37,
                  },
                ]),
            '/decks/deck-1':
                () => ApiResponse(200, _buildDeckDetailsJson(currentCards)),
          },
          postHandlers: {
            '/decks/deck-1/cards': (_) => ApiResponse(200, {'ok': true}),
          },
        );

        final provider = DeckProvider(apiClient: apiClient);
        await provider.fetchDecks();
        await provider.fetchDeckDetails('deck-1');

        final added = await provider.addCardToDeck(
          'deck-1',
          provider.selectedDeck!.mainBoard['Instants']!.first,
          2,
        );

        expect(added, isTrue);
        expect(provider.decks.single.cardCount, 39);
      },
    );

    test('deleteDeck removes item from list and clears selected deck', () async {
      final apiClient = _FakeApiClient(
        getHandlers: {
          '/decks': () => ApiResponse(200, [
            {
              'id': 'deck-1',
              'name': 'Smoke Deck',
              'format': 'commander',
              'is_public': false,
              'created_at': '2026-03-23T00:00:00.000Z',
              'card_count': 37,
            },
          ]),
          '/decks/deck-1': () => ApiResponse(
            200,
            _buildDeckDetailsJson({'spell-1': 1, 'land-1': 36}),
          ),
        },
        deleteHandlers: {
          '/decks/deck-1': () => ApiResponse(204, const {}),
        },
      );

      final provider = DeckProvider(apiClient: apiClient);
      await provider.fetchDecks();
      await provider.fetchDeckDetails('deck-1');

      final deleted = await provider.deleteDeck('deck-1');

      expect(deleted, isTrue);
      expect(provider.decks, isEmpty);
      expect(provider.selectedDeck, isNull);
    });

    test('refreshAiAnalysis updates selected deck and list', () async {
      final apiClient = _FakeApiClient(
        getHandlers: {
          '/decks':
              () => ApiResponse(200, [
                {
                  'id': 'deck-1',
                  'name': 'Smoke Deck',
                  'format': 'commander',
                  'is_public': false,
                  'created_at': '2026-03-23T00:00:00.000Z',
                  'card_count': 37,
                },
              ]),
          '/decks/deck-1':
              () => ApiResponse(
                200,
                _buildDeckDetailsJson({'spell-1': 1, 'land-1': 36}),
              ),
        },
        postHandlers: {
          '/decks/deck-1/ai-analysis':
              (_) => ApiResponse(200, {
                'synergy_score': 87,
                'strengths': 'draw',
                'weaknesses': 'ramp',
              }),
        },
      );

      final provider = DeckProvider(apiClient: apiClient);
      await provider.fetchDecks();
      await provider.fetchDeckDetails('deck-1');

      final result = await provider.refreshAiAnalysis('deck-1');

      expect(result['synergy_score'], 87);
      expect(provider.selectedDeck?.synergyScore, 87);
      expect(provider.decks.single.synergyScore, 87);
    });

    test('copyPublicDeck refreshes deck list on success', () async {
      var decksFetchCount = 0;
      final apiClient = _FakeApiClient(
        getHandlers: {
          '/decks': () {
            decksFetchCount += 1;
            return ApiResponse(200, [
              {
                'id': 'deck-copy',
                'name': 'Copied Deck',
                'format': 'commander',
                'is_public': false,
                'created_at': '2026-03-23T00:00:00.000Z',
                'card_count': 37,
              },
            ]);
          },
        },
        postHandlers: {
          '/community/decks/public-1': (_) => ApiResponse(201, {
            'deck': {'id': 'deck-copy'},
          }),
        },
      );

      final provider = DeckProvider(apiClient: apiClient);

      final result = await provider.copyPublicDeck('public-1');

      expect(result['success'], isTrue);
      expect(decksFetchCount, 1);
      expect(provider.decks.single.id, 'deck-copy');
    });
  });
}
