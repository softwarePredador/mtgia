import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/api/api_client.dart';
import 'package:manaloom/features/decks/models/deck.dart';
import 'package:manaloom/features/decks/models/deck_details.dart';
import 'package:manaloom/features/decks/models/deck_card_item.dart';
import 'package:manaloom/features/decks/providers/deck_provider_support.dart';

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

  @override
  Future<ApiResponse> post(
    String endpoint,
    Map<String, dynamic> body, {
    Duration? timeout,
  }) async {
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

void main() {
  test('readFreshDeckDetailsFromCache returns only fresh entries', () {
    final cachedDeck = DeckDetails(
      id: 'deck-1',
      name: 'Cached',
      format: 'commander',
      isPublic: false,
      createdAt: DateTime.parse('2026-03-24T00:00:00.000Z'),
      stats: const {},
      commander: const <DeckCardItem>[],
      mainBoard: const <String, List<DeckCardItem>>{},
    );
    final cache = {'deck-1': cachedDeck};
    final now = DateTime.now();

    expect(
      readFreshDeckDetailsFromCache(
        cache: cache,
        cacheTimes: {'deck-1': now},
        deckId: 'deck-1',
        cacheDuration: const Duration(minutes: 5),
      ),
      isNotNull,
    );
    expect(
      readFreshDeckDetailsFromCache(
        cache: cache,
        cacheTimes: {'deck-1': now.subtract(const Duration(minutes: 6))},
        deckId: 'deck-1',
        cacheDuration: const Duration(minutes: 5),
      ),
      isNull,
    );
  });

  test('extractCardSearchResults supports paginated and direct payloads', () {
    final paginated = extractCardSearchResults({
      'data': [
        {'id': 'card-1', 'name': 'Arcane Signet'},
      ],
    });
    final direct = extractCardSearchResults([
      {'id': 'card-2', 'name': 'Mind Stone'},
    ]);

    expect(paginated.single['id'], 'card-1');
    expect(direct.single['id'], 'card-2');
  });

  test('applyRemovalCountsToCurrentCards decrements and removes entries', () {
    final currentCards = <String, Map<String, dynamic>>{
      'card-1': {'card_id': 'card-1', 'quantity': 2, 'is_commander': false},
      'card-2': {'card_id': 'card-2', 'quantity': 1, 'is_commander': false},
    };

    applyRemovalCountsToCurrentCards(
      currentCards: currentCards,
      removalCounts: buildRemovalCounts(['card-1', 'card-2']),
    );

    expect(currentCards['card-1']?['quantity'], 1);
    expect(currentCards.containsKey('card-2'), isFalse);
  });

  test(
    'applyAdditionsToCurrentCards enforces commander identity and limits',
    () {
      final currentCards = <String, Map<String, dynamic>>{
        'arcane-signet': {
          'card_id': 'arcane-signet',
          'quantity': 1,
          'is_commander': false,
        },
      };

      final applied = applyAdditionsToCurrentCards(
        currentCards: currentCards,
        cardsToAdd: const [
          {
            'card_id': 'arcane-signet',
            'quantity': 1,
            'is_commander': false,
            'type_line': 'Artifact',
            'color_identity': <String>[],
          },
          {
            'card_id': 'counterspell',
            'quantity': 1,
            'is_commander': false,
            'type_line': 'Instant',
            'color_identity': <String>['U'],
          },
          {
            'card_id': 'terminate',
            'quantity': 1,
            'is_commander': false,
            'type_line': 'Instant',
            'color_identity': <String>['B', 'R'],
          },
        ],
        format: 'commander',
        commanderIdentity: {'U'},
      );

      expect(applied, 1);
      expect(currentCards['arcane-signet']?['quantity'], 1);
      expect(currentCards.containsKey('counterspell'), isTrue);
      expect(currentCards.containsKey('terminate'), isFalse);
    },
  );

  test('buildCurrentCardSnapshot reflects structural card changes', () {
    final before = buildCurrentCardSnapshot({
      'card-1': {'card_id': 'card-1', 'quantity': 1, 'is_commander': false},
    });
    final after = buildCurrentCardSnapshot({
      'card-1': {'card_id': 'card-1', 'quantity': 2, 'is_commander': false},
    });

    expect(before, isNot(after));
  });

  test(
    'buildNamedOptimizationApplyResult applies removals/additions and tracks identity skips',
    () {
    final deck = DeckDetails(
        id: 'deck-1',
        name: 'Deck',
        format: 'commander',
        isPublic: false,
        createdAt: DateTime.parse('2026-03-24T00:00:00.000Z'),
        colorIdentity: const ['U'],
        stats: const {'total_cards': 3},
      commander: [
        DeckCardItem(
            id: 'cmd-1',
            name: 'Talrand',
            manaCost: '{2}{U}{U}',
            typeLine: 'Legendary Creature',
            oracleText: '',
            colors: ['U'],
            colorIdentity: ['U'],
            setCode: 'tst',
            rarity: 'rare',
            quantity: 1,
            isCommander: true,
          ),
        ],
      mainBoard: {
        'Artifacts': [
          DeckCardItem(
              id: 'remove-1',
              name: 'Mind Stone',
              manaCost: '{2}',
              typeLine: 'Artifact',
              oracleText: '',
              colors: [],
              colorIdentity: [],
              setCode: 'tst',
              rarity: 'uncommon',
              quantity: 1,
              isCommander: false,
            ),
          ],
        },
      );

      final result = buildNamedOptimizationApplyResult(
        deck: deck,
        cardsToRemoveIds: const ['remove-1'],
        cardsToAddIds: const [
          {
            'card_id': 'add-1',
            'quantity': 1,
            'is_commander': false,
            'type_line': 'Artifact',
            'color_identity': <String>[],
          },
          {
            'card_id': 'off-color',
            'quantity': 1,
            'is_commander': false,
            'type_line': 'Instant',
            'color_identity': <String>['B'],
          },
        ],
      );

      expect(result.currentCards.containsKey('remove-1'), isFalse);
      expect(result.currentCards.containsKey('add-1'), isTrue);
      expect(result.skippedForIdentity, ['off-color']);
      expect(result.hasStructuralChange, isTrue);
    },
  );

  test(
    'buildNamedOptimizationPayload resolves names and returns persisted payload',
    () async {
      final apiClient = _FakeApiClient(
        getHandlers: {
          '/cards?name=Mind+Stone&limit=1': () => ApiResponse(200, {
            'data': [
              {'id': 'remove-1', 'name': 'Mind Stone', 'type_line': 'Artifact'},
            ],
          }),
          '/cards?name=Arcane+Signet&limit=1': () => ApiResponse(200, {
            'data': [
              {
                'id': 'add-1',
                'name': 'Arcane Signet',
                'type_line': 'Artifact',
                'color_identity': const <String>[],
              },
            ],
          }),
        },
      );

      final deck = DeckDetails(
        id: 'deck-1',
        name: 'Deck',
        format: 'commander',
        isPublic: false,
        createdAt: DateTime.parse('2026-03-24T00:00:00.000Z'),
        colorIdentity: const ['U'],
        stats: const {'total_cards': 3},
        commander: [
          DeckCardItem(
            id: 'cmd-1',
            name: 'Talrand',
            manaCost: '{2}{U}{U}',
            typeLine: 'Legendary Creature',
            oracleText: '',
            colors: ['U'],
            colorIdentity: ['U'],
            setCode: 'tst',
            rarity: 'rare',
            quantity: 1,
            isCommander: true,
          ),
        ],
        mainBoard: {
          'Artifacts': [
            DeckCardItem(
              id: 'remove-1',
              name: 'Mind Stone',
              manaCost: '{2}',
              typeLine: 'Artifact',
              oracleText: '',
              colors: const [],
              colorIdentity: const [],
              setCode: 'tst',
              rarity: 'uncommon',
              quantity: 1,
              isCommander: false,
            ),
          ],
        },
      );

      final result = await buildNamedOptimizationPayload(
        apiClient,
        deck: deck,
        cardsToRemove: const ['Mind Stone'],
        cardsToAdd: const ['Arcane Signet'],
      );

      expect(
        result.cardsPayload.any((entry) => entry['card_id'] == 'remove-1'),
        isFalse,
      );
      expect(
        result.cardsPayload.any((entry) => entry['card_id'] == 'add-1'),
        isTrue,
      );
      expect(result.skippedForIdentity, isEmpty);
    },
  );

  test('parseImportDeckResponse maps success payload', () {
    final result = parseImportDeckResponse(
      ApiResponse(200, {
        'deck': {'id': 'deck-1'},
        'cards_imported': 99,
        'not_found_lines': ['1 Missing Card'],
        'warnings': ['warning'],
      }),
    );

    expect(result['success'], isTrue);
    expect(result['cards_imported'], 99);
    expect(result['not_found_lines'], ['1 Missing Card']);
    expect(result['warnings'], ['warning']);
  });

  test('parseImportToDeckResponse maps failure payload', () {
    final result = parseImportToDeckResponse(
      ApiResponse(422, {
        'error': 'lista invalida',
        'not_found_lines': ['1 Unknown'],
      }),
    );

    expect(result['success'], isFalse);
    expect(result['error'], 'lista invalida');
    expect(result['not_found_lines'], ['1 Unknown']);
  });

  test('applyDeckVisibility helpers update selected deck and list', () {
    final selected = DeckDetails(
      id: 'deck-1',
      name: 'Deck',
      format: 'commander',
      isPublic: false,
      createdAt: DateTime.parse('2026-03-24T00:00:00.000Z'),
      stats: const {},
      commander: const <DeckCardItem>[],
      mainBoard: const <String, List<DeckCardItem>>{},
    );
    final list = <Deck>[
      Deck(
        id: 'deck-1',
        name: 'Deck',
        format: 'commander',
        isPublic: false,
        createdAt: DateTime.parse('2026-03-24T00:00:00.000Z'),
      ),
      Deck(
        id: 'deck-2',
        name: 'Other',
        format: 'commander',
        isPublic: false,
        createdAt: DateTime.parse('2026-03-24T00:00:00.000Z'),
      ),
    ];

    final updatedSelected = applyDeckVisibilityToSelectedDeck(
      selected,
      'deck-1',
      isPublic: true,
    );
    final updatedList = applyDeckVisibilityToDeckList(
      list,
      'deck-1',
      isPublic: true,
    );

    expect(updatedSelected?.isPublic, isTrue);
    expect(updatedList.first.isPublic, isTrue);
    expect(updatedList.last.isPublic, isFalse);
  });

  test('applyDeckDeletionToState removes deck from list and clears selection', () {
    final selected = DeckDetails(
      id: 'deck-1',
      name: 'Deck',
      format: 'commander',
      isPublic: false,
      createdAt: DateTime.parse('2026-03-24T00:00:00.000Z'),
      stats: const {},
      commander: const <DeckCardItem>[],
      mainBoard: const <String, List<DeckCardItem>>{},
    );
    final decks = <Deck>[
      Deck(
        id: 'deck-1',
        name: 'Deck',
        format: 'commander',
        isPublic: false,
        createdAt: DateTime.parse('2026-03-24T00:00:00.000Z'),
      ),
      Deck(
        id: 'deck-2',
        name: 'Other',
        format: 'commander',
        isPublic: false,
        createdAt: DateTime.parse('2026-03-24T00:00:00.000Z'),
      ),
    ];

    final nextState = applyDeckDeletionToState(decks, selected, 'deck-1');

    expect(nextState.decks.map((deck) => deck.id), ['deck-2']);
    expect(nextState.selectedDeck, isNull);
  });

  test('color identity list helpers enrich only missing decks', () {
    final decks = <Deck>[
      Deck(
        id: 'deck-1',
        name: 'No Color',
        format: 'commander',
        isPublic: false,
        createdAt: DateTime.parse('2026-03-24T00:00:00.000Z'),
        cardCount: 99,
      ),
      Deck(
        id: 'deck-2',
        name: 'Has Color',
        format: 'commander',
        isPublic: false,
        createdAt: DateTime.parse('2026-03-24T00:00:00.000Z'),
        colorIdentity: const ['G'],
        cardCount: 99,
      ),
    ];
    final cachedDeck = DeckDetails(
      id: 'deck-1',
      name: 'No Color',
      format: 'commander',
      isPublic: false,
      createdAt: DateTime.parse('2026-03-24T00:00:00.000Z'),
      colorIdentity: const ['U'],
      stats: const {},
      commander: const <DeckCardItem>[],
      mainBoard: const <String, List<DeckCardItem>>{},
    );

    final synced = syncDeckColorIdentityToList(decks, 'deck-1', const ['U']);
    final cachedApplied = applyCachedColorIdentitiesToDeckList(synced, {
      'deck-1': cachedDeck,
    });
    final missing = decksMissingColorIdentity(cachedApplied);

    expect(cachedApplied.first.colorIdentity, const ['U']);
    expect(cachedApplied.last.colorIdentity, const ['G']);
    expect(missing, isEmpty);
  });

  test('buildDeckListHydrationResult hydrates cache and exposes missing decks', () {
    final fetchedDecks = <Deck>[
      Deck(
        id: 'deck-1',
        name: 'No Color',
        format: 'commander',
        isPublic: false,
        createdAt: DateTime.parse('2026-03-24T00:00:00.000Z'),
        cardCount: 99,
      ),
      Deck(
        id: 'deck-2',
        name: 'Has Color',
        format: 'commander',
        isPublic: false,
        createdAt: DateTime.parse('2026-03-24T00:00:00.000Z'),
        colorIdentity: const ['G'],
        cardCount: 99,
      ),
    ];
    final cache = {
      'deck-1': DeckDetails(
        id: 'deck-1',
        name: 'No Color',
        format: 'commander',
        isPublic: false,
        createdAt: DateTime.parse('2026-03-24T00:00:00.000Z'),
        colorIdentity: const ['U'],
        stats: const {},
        commander: const <DeckCardItem>[],
        mainBoard: const <String, List<DeckCardItem>>{},
      ),
    };

    final result = buildDeckListHydrationResult(fetchedDecks, cache);

    expect(result.decks.first.colorIdentity, const ['U']);
    expect(result.missingColorIdentityDecks, isEmpty);
  });

  test('applyDeckColorIdentityEnrichment returns updated decks and cache details', () {
    final decks = <Deck>[
      Deck(
        id: 'deck-1',
        name: 'No Color',
        format: 'commander',
        isPublic: false,
        createdAt: DateTime.parse('2026-03-24T00:00:00.000Z'),
        cardCount: 99,
      ),
    ];
    final result = DeckColorIdentityEnrichmentResult(
      detailsByDeckId: {
        'deck-1': DeckDetails(
          id: 'deck-1',
          name: 'No Color',
          format: 'commander',
          isPublic: false,
          createdAt: DateTime.parse('2026-03-24T00:00:00.000Z'),
          colorIdentity: const ['U'],
          stats: const {},
          commander: const <DeckCardItem>[],
          mainBoard: const <String, List<DeckCardItem>>{},
        ),
      },
      failedDeckIds: const [],
    );

    final applyResult = applyDeckColorIdentityEnrichment(decks, result);

    expect(applyResult.decks.single.colorIdentity, const ['U']);
    expect(applyResult.cachedDetails.single.id, 'deck-1');
    expect(applyResult.enrichedCount, 1);
  });

  test('fetchMissingDeckColorIdentities returns only enriched details', () async {
    final apiClient = _FakeApiClient(
      getHandlers: {
        '/decks/deck-1': () => ApiResponse(200, {
          'id': 'deck-1',
          'name': 'Blue Deck',
          'format': 'commander',
          'is_public': false,
          'created_at': '2026-03-24T00:00:00.000Z',
          'color_identity': const ['U'],
          'stats': const <String, dynamic>{},
          'commander': const <dynamic>[],
          'main_board': const <String, List<dynamic>>{},
        }),
        '/decks/deck-2': () => ApiResponse(500, {'error': 'boom'}),
      },
    );

    final result = await fetchMissingDeckColorIdentities(apiClient, [
      Deck(
        id: 'deck-1',
        name: 'Blue Deck',
        format: 'commander',
        isPublic: false,
        createdAt: DateTime.parse('2026-03-24T00:00:00.000Z'),
        cardCount: 99,
      ),
      Deck(
        id: 'deck-2',
        name: 'Broken Deck',
        format: 'commander',
        isPublic: false,
        createdAt: DateTime.parse('2026-03-24T00:00:00.000Z'),
        cardCount: 99,
      ),
    ]);

    expect(result.detailsByDeckId.keys, ['deck-1']);
    expect(result.detailsByDeckId['deck-1']?.colorIdentity, ['U']);
    expect(result.failedDeckIds, isEmpty);
  });

  test('parse deck response helpers map success and unauthorized states', () {
    final detailsState = parseDeckDetailsResponse(
      ApiResponse(401, {'message': 'token expirado'}),
    );
    final listState = parseDeckListResponse(ApiResponse(401, const {}));

    expect(detailsState.statusCode, 401);
    expect(detailsState.errorMessage, 'token expirado');
    expect(listState.errorMessage, contains('Sessão expirada'));
  });

  test('parseAddCardResponse maps success and error', () {
    expect(parseAddCardResponse(ApiResponse(200, const {})).isSuccess, isTrue);

    final failure = parseAddCardResponse(
      ApiResponse(422, {'error': 'carta invalida'}),
    );
    expect(failure.isSuccess, isFalse);
    expect(failure.errorMessage, 'carta invalida');
  });

  test('incrementDeckCardCount updates only target deck', () {
    final decks = <Deck>[
      Deck(
        id: 'deck-1',
        name: 'One',
        format: 'commander',
        isPublic: false,
        createdAt: DateTime.parse('2026-03-24T00:00:00.000Z'),
        cardCount: 99,
      ),
      Deck(
        id: 'deck-2',
        name: 'Two',
        format: 'commander',
        isPublic: false,
        createdAt: DateTime.parse('2026-03-24T00:00:00.000Z'),
        cardCount: 100,
      ),
    ];

    final updated = incrementDeckCardCount(decks, 'deck-1', delta: 2);

    expect(updated.first.cardCount, 101);
    expect(updated.last.cardCount, 100);
  });

  test('ai analysis helpers update selected deck and list', () {
    final selected = DeckDetails(
      id: 'deck-1',
      name: 'Deck',
      format: 'commander',
      isPublic: false,
      createdAt: DateTime.parse('2026-03-24T00:00:00.000Z'),
      stats: const {},
      commander: const <DeckCardItem>[],
      mainBoard: const <String, List<DeckCardItem>>{},
    );
    final decks = <Deck>[
      Deck(
        id: 'deck-1',
        name: 'Deck',
        format: 'commander',
        isPublic: false,
        createdAt: DateTime.parse('2026-03-24T00:00:00.000Z'),
      ),
    ];

    final updatedSelected = applyAiAnalysisToSelectedDeck(
      selected,
      'deck-1',
      synergyScore: 88,
      strengths: 'draw',
      weaknesses: 'ramp',
    );
    final updatedDecks = applyAiAnalysisToDeckList(
      decks,
      'deck-1',
      synergyScore: 88,
      strengths: 'draw',
      weaknesses: 'ramp',
    );

    expect(updatedSelected?.synergyScore, 88);
    expect(updatedDecks.single.synergyScore, 88);
    expect(updatedDecks.single.weaknesses, 'ramp');
  });

  test('parseDeckAiAnalysisResponse maps payload and throws on failure', () {
    final payload = parseDeckAiAnalysisResponse(
      ApiResponse(200, {
        'synergy_score': 91,
        'strengths': 'tempo',
        'weaknesses': 'mana',
      }),
    );

    expect(payload.synergyScore, 91);
    expect(payload.strengths, 'tempo');

    expect(
      () => parseDeckAiAnalysisResponse(ApiResponse(500, {'error': 'falhou'})),
      throwsA(isA<Exception>()),
    );
  });

  test('response helpers cover options validation pricing and mutations', () {
    final options = parseOptimizationOptionsResponse(
      ApiResponse(200, {
        'options': [
          {'id': 'control', 'label': 'Control'},
        ],
      }),
    );
    final validation = parseDeckValidationResponse(
      ApiResponse(422, {
        'ok': false,
        'errors': ['invalid'],
      }),
    );
    final pricing = parseDeckPricingResponse(
      ApiResponse(200, {'currency': 'USD', 'total': 123.4}),
    );

    expect(options.single['id'], 'control');
    expect(validation['ok'], isFalse);
    expect(pricing['currency'], 'USD');
    expect(
      () => ensureSuccessfulDeckMutationResponse(
        ApiResponse(500, {'error': 'falhou mutacao'}),
        fallbackMessage: 'fallback',
      ),
      throwsA(isA<Exception>()),
    );
  });

  test(
    'requestOptimizeDeck maps immediate success, async jobs and quality errors',
    () async {
      final successClient = _FakeApiClient(
        postHandlers: {
          '/ai/optimize': (body) {
            expect(body['deck_id'], 'deck-1');
            expect(body['archetype'], 'control');
            expect(body['bracket'], 2);
            expect(body['keep_theme'], isTrue);
            return ApiResponse(200, {'mode': 'optimize'});
          },
        },
      );
      final successResult = await requestOptimizeDeck(
        successClient,
        deckId: 'deck-1',
        archetype: 'control',
        bracket: 2,
        keepTheme: true,
      );
      expect(successResult.isAsync, isFalse);
      expect(successResult.result?['mode'], 'optimize');

      final asyncClient = _FakeApiClient(
        postHandlers: {
          '/ai/optimize': (_) => ApiResponse(202, {
            'job_id': 'job-1',
            'poll_interval_ms': 2500,
            'total_stages': 7,
          }),
        },
      );
      final asyncResult = await requestOptimizeDeck(
        asyncClient,
        deckId: 'deck-1',
        archetype: 'control',
        keepTheme: false,
      );
      expect(asyncResult.isAsync, isTrue);
      expect(asyncResult.jobId, 'job-1');
      expect(asyncResult.pollIntervalMs, 2500);
      expect(asyncResult.totalStages, 7);

      final failureClient = _FakeApiClient(
        postHandlers: {
          '/ai/optimize': (_) => ApiResponse(422, {
            'error': 'Precisa de reparo',
            'quality_error': {'code': 'OPTIMIZE_NEEDS_REPAIR'},
            'outcome_code': 'needs_repair',
          }),
        },
      );
      await expectLater(
        () => requestOptimizeDeck(
          failureClient,
          deckId: 'deck-1',
          archetype: 'control',
          keepTheme: true,
        ),
        throwsA(isA<DeckAiFlowException>()),
      );
    },
  );

  test(
    'requestRebuildDeck and persistDeckCardsPayloadWithValidation cover success and quality failure',
    () async {
      final successClient = _FakeApiClient(
        postHandlers: {
          '/ai/rebuild': (body) {
            expect(body['deck_id'], 'deck-1');
            expect(body['save_mode'], 'draft_clone');
            expect(body['rebuild_scope'], 'auto');
            return ApiResponse(200, {
              'draft_deck_id': 'draft-1',
              'rebuild_scope_selected': 'full_non_commander_rebuild',
            });
          },
          '/decks/deck-1/validate': (_) => ApiResponse(200, {
            'valid': true,
            'errors': const <String>[],
          }),
        },
        putHandlers: {
          '/decks/deck-1': (body) {
            expect(body['cards'], isNotEmpty);
            return ApiResponse(200, const {});
          },
        },
      );

      final rebuildResult = await requestRebuildDeck(
        successClient,
        deckId: 'deck-1',
        rebuildScope: 'auto',
        saveMode: 'draft_clone',
        mustKeep: const [],
        mustAvoid: const [],
      );
      expect(rebuildResult.draftDeckId, 'draft-1');

      final persistResult = await persistDeckCardsPayloadWithValidation(
        successClient,
        deckId: 'deck-1',
        cardsPayload: const [
          {'card_id': 'card-1', 'quantity': 1, 'is_commander': false},
        ],
      );
      expect(persistResult.validation['valid'], isTrue);
      expect(persistResult.elapsedMilliseconds, greaterThanOrEqualTo(0));

      final failureClient = _FakeApiClient(
        postHandlers: {
          '/ai/rebuild': (_) => ApiResponse(422, {
            'error': 'Rebuild falhou',
            'quality_error': {'code': 'REBUILD_FAILED'},
          }),
        },
      );
      await expectLater(
        () => requestRebuildDeck(
          failureClient,
          deckId: 'deck-1',
          rebuildScope: 'auto',
          saveMode: 'draft_clone',
          mustKeep: const [],
          mustAvoid: const [],
        ),
        throwsA(isA<DeckAiFlowException>()),
      );
    },
  );

  test(
    'pollOptimizeJobRequest maps pending, completed and failed outcomes',
    () async {
      final pendingClient = _FakeApiClient(
        getHandlers: {
          '/ai/optimize/jobs/job-1': () => ApiResponse(200, {
            'status': 'processing',
            'stage': 'Analisando',
            'stage_number': 2,
            'total_stages': 6,
          }),
        },
      );
      final pending = await pollOptimizeJobRequest(pendingClient, 'job-1');
      expect(pending.isCompleted, isFalse);
      expect(pending.stage, 'Analisando');
      expect(pending.stageNumber, 2);

      final completedClient = _FakeApiClient(
        getHandlers: {
          '/ai/optimize/jobs/job-2': () => ApiResponse(200, {
            'status': 'completed',
            'result': {'mode': 'optimize'},
          }),
        },
      );
      final completed = await pollOptimizeJobRequest(completedClient, 'job-2');
      expect(completed.isCompleted, isTrue);
      expect(completed.result?['mode'], 'optimize');

      final failedClient = _FakeApiClient(
        getHandlers: {
          '/ai/optimize/jobs/job-3': () => ApiResponse(200, {
            'status': 'failed',
            'error': 'Falhou',
            'quality_error': {'code': 'OPTIMIZE_JOB_FAILED'},
          }),
        },
      );
      await expectLater(
        () => pollOptimizeJobRequest(failedClient, 'job-3'),
        throwsA(isA<DeckAiFlowException>()),
      );
    },
  );

  test('parseCopyPublicDeckResponse maps success and failure', () {
    final success = parseCopyPublicDeckResponse(
      ApiResponse(201, {
        'deck': {'id': 'deck-copy'},
      }),
    );
    final failure = parseCopyPublicDeckResponse(
      ApiResponse(500, {'error': 'falhou'}),
    );

    expect(success['success'], isTrue);
    expect((success['deck'] as Map<String, dynamic>)['id'], 'deck-copy');
    expect(failure['success'], isFalse);
    expect(failure['error'], 'falhou');
  });

  test('extractApiError prefers error and falls back safely', () {
    expect(
      extractApiError({'error': 'deck invalido'}, fallback: 'fallback'),
      'deck invalido',
    );
    expect(extractApiError({}, fallback: 'fallback'), 'fallback');
  });

  test('connection failure helpers preserve expected shapes', () async {
    final generic = await runConnectionSafeMapRequest(() async {
      throw Exception('offline');
    });
    final export = buildExportConnectionFailureResult(Exception('offline'));

    expect(generic['success'], isFalse);
    expect(generic['error'], contains('offline'));
    expect(export.containsKey('success'), isFalse);
    expect(export['error'], contains('offline'));
  });

  test(
    'normalizeCreateDeckCards resolves names and preserves direct ids',
    () async {
      final apiClient = _FakeApiClient(
        postHandlers: {
          '/cards/resolve/batch': (body) {
            expect(body['names'], equals(['Sol Ring']));
            return ApiResponse(200, {
              'data': const [
                {'input_name': 'Sol Ring', 'card_id': 'sol-ring-id'},
              ],
              'unresolved': const [],
              'ambiguous': const [],
            });
          },
        },
      );

      final result = await normalizeCreateDeckCards(apiClient, const [
        {'card_id': 'cmd-1', 'quantity': 1, 'is_commander': true},
        {'name': 'Sol Ring', 'quantity': 2, 'is_commander': false},
      ]);

      expect(result, [
        {'card_id': 'cmd-1', 'quantity': 1, 'is_commander': true},
        {'card_id': 'sol-ring-id', 'quantity': 2, 'is_commander': false},
      ]);
    },
  );

  test('generateDeckFromPrompt surfaces backend error message', () async {
    final apiClient = _FakeApiClient(
      postHandlers: {
        '/ai/generate': (_) => ApiResponse(500, {'error': 'falhou geral'}),
      },
    );

    expect(
      () => generateDeckFromPrompt(
        apiClient,
        prompt: 'mono blue artifacts',
        format: 'commander',
      ),
      throwsA(isA<Exception>()),
    );
  });

  test(
    'resolveOptimizationAdditions and removals search cards by name',
    () async {
      final apiClient = _FakeApiClient(
        getHandlers: {
          '/cards?name=Arcane+Signet&limit=1':
              () => ApiResponse(200, {
                'data': [
                  {
                    'id': 'add-1',
                    'type_line': 'Artifact',
                    'color_identity': const <String>[],
                  },
                ],
              }),
          '/cards?name=Mind+Stone&limit=1':
              () => ApiResponse(200, {
                'data': [
                  {
                    'id': 'remove-1',
                    'type_line': 'Artifact',
                    'color_identity': const <String>[],
                  },
                ],
              }),
        },
      );

      final additions = await resolveOptimizationAdditions(apiClient, const [
        'Arcane Signet',
      ]);
      final removals = await resolveOptimizationRemovals(apiClient, const [
        'Mind Stone',
      ]);

      expect(additions.single['card_id'], 'add-1');
      expect(removals.single, 'remove-1');
    },
  );

  test('request helpers dispatch expected endpoints and parse responses', () async {
    final apiClient = _FakeApiClient(
      postHandlers: {
        '/decks': (body) {
          expect(body['name'], 'Deck');
          expect(body['format'], 'commander');
          return ApiResponse(201, {'id': 'deck-1'});
        },
        '/decks/deck-1/cards': (body) {
          expect(body['card_id'], 'card-1');
          return ApiResponse(200, const {});
        },
        '/decks/deck-1/cards/bulk': (body) {
          expect(body['cards'], isA<List>());
          return ApiResponse(200, const {});
        },
        '/decks/deck-1/cards/set': (body) {
          expect(body['card_id'], 'card-1');
          expect(body['replace_same_name'], isFalse);
          return ApiResponse(200, const {});
        },
        '/ai/archetypes': (body) {
          expect(body['deck_id'], 'deck-1');
          return ApiResponse(200, {
            'options': [
              {'id': 'control'},
            ],
          });
        },
        '/decks/deck-1/validate': (_) => ApiResponse(200, {'valid': true}),
        '/decks/deck-1/pricing': (body) {
          expect(body['force'], isTrue);
          return ApiResponse(200, {'total': 42});
        },
        '/decks/deck-1/ai-analysis': (body) {
          expect(body['force'], isFalse);
          return ApiResponse(200, {'synergy_score': 77});
        },
        '/decks/deck-1/cards/replace': (body) {
          expect(body['old_card_id'], 'old');
          expect(body['new_card_id'], 'new');
          return ApiResponse(200, const {});
        },
        '/import': (body) {
          expect(body['name'], 'Deck');
          return ApiResponse(200, {'deck': {'id': 'deck-1'}});
        },
        '/import/validate': (body) {
          expect(body['format'], 'commander');
          return ApiResponse(200, {'found_cards': []});
        },
        '/import/to-deck': (body) {
          expect(body['replace_all'], isTrue);
          return ApiResponse(200, {'cards_imported': 99});
        },
        '/community/decks/deck-1': (_) => ApiResponse(201, {
          'deck': {'id': 'copied'},
        }),
      },
      getHandlers: {
        '/decks/deck-1': () => ApiResponse(200, {
          'id': 'deck-1',
          'name': 'Deck',
          'format': 'commander',
          'is_public': false,
          'created_at': '2026-03-24T00:00:00.000Z',
          'stats': const <String, dynamic>{},
          'commander': const <dynamic>[],
          'main_board': const <String, List<dynamic>>{},
        }),
        '/decks': () => ApiResponse(200, [
          {
            'id': 'deck-1',
            'name': 'Deck',
            'format': 'commander',
            'is_public': false,
            'created_at': '2026-03-24T00:00:00.000Z',
          },
        ]),
        '/decks/deck-1/export': () => ApiResponse(200, {'text': '1 Sol Ring'}),
      },
      putHandlers: {
        '/decks/deck-1': (body) {
          if (body.containsKey('is_public')) {
            return ApiResponse(200, const {});
          }
          if (body.containsKey('cards')) {
            return ApiResponse(200, const {});
          }
          if (body.containsKey('description')) {
            return ApiResponse(200, const {});
          }
          if (body.containsKey('archetype')) {
            return ApiResponse(200, const {});
          }
          throw StateError('unexpected PUT body: $body');
        },
      },
      deleteHandlers: {
        '/decks/deck-1': () => ApiResponse(204, const {}),
      },
    );

    final detailsState = await fetchDeckDetailsRequest(apiClient, 'deck-1');
    final listState = await fetchDeckListRequest(apiClient);
    final createResult = await createDeckRequest(
      apiClient,
      name: 'Deck',
      format: 'commander',
      isPublic: false,
      cards: const [],
    );
    final addResult = await addCardToDeckRequest(
      apiClient,
      deckId: 'deck-1',
      cardId: 'card-1',
      quantity: 1,
      isCommander: false,
      condition: 'NM',
    );
    final bulkResult = await addCardsBulkRequest(
      apiClient,
      deckId: 'deck-1',
      cards: const [
        {'card_id': 'card-1', 'quantity': 1, 'is_commander': false},
      ],
    );
    final options = await fetchOptimizationOptionsRequest(apiClient, 'deck-1');
    final validation = await validateDeckRequest(apiClient, 'deck-1');
    final pricing = await fetchDeckPricingRequest(
      apiClient,
      'deck-1',
      force: true,
    );
    final deleteResult = await deleteDeckRequest(apiClient, 'deck-1');
    final removeResult = await removeCardFromDeckRequest(
      apiClient,
      deckId: 'deck-1',
      cardsPayload: const [
        {'card_id': 'card-2', 'quantity': 1, 'is_commander': false},
      ],
    );
    final analysis = await refreshAiAnalysisRequest(
      apiClient,
      'deck-1',
      force: false,
    );
    await updateDeckDescriptionRequest(
      apiClient,
      deckId: 'deck-1',
      description: 'nova',
    );
    await updateDeckStrategyRequest(
      apiClient,
      deckId: 'deck-1',
      archetype: 'control',
      bracket: 3,
    );
    await replaceCardEditionRequest(
      apiClient,
      deckId: 'deck-1',
      oldCardId: 'old',
      newCardId: 'new',
    );
    final setQuantityResult = await setDeckCardQuantityRequest(
      apiClient,
      deckId: 'deck-1',
      cardId: 'card-1',
      quantity: 2,
      replaceSameName: false,
      condition: 'NM',
    );
    final importResult = await importDeckFromListRequest(
      apiClient,
      name: 'Deck',
      format: 'commander',
      list: '1 Sol Ring',
    );
    final validateImportResult = await validateImportListRequest(
      apiClient,
      format: 'commander',
      list: '1 Sol Ring',
    );
    final importToDeckResult = await importListToDeckRequest(
      apiClient,
      deckId: 'deck-1',
      list: '1 Sol Ring',
      replaceAll: true,
    );
    final toggled = await togglePublicRequest(
      apiClient,
      deckId: 'deck-1',
      isPublic: true,
    );
    final export = await exportDeckAsTextRequest(apiClient, 'deck-1');
    final copied = await copyPublicDeckRequest(apiClient, 'deck-1');
    await persistDeckCardsPayloadRequest(
      apiClient,
      deckId: 'deck-1',
      cardsPayload: const [
        {'card_id': 'card-1', 'quantity': 1, 'is_commander': false},
      ],
    );

    expect(detailsState.statusCode, 200);
    expect(listState.decks, isNotNull);
    expect(createResult.isSuccess, isTrue);
    expect(addResult.isSuccess, isTrue);
    expect(bulkResult.isSuccess, isTrue);
    expect(options.single['id'], 'control');
    expect(validation['valid'], isTrue);
    expect(pricing['total'], 42);
    expect(deleteResult.isSuccess, isTrue);
    expect(removeResult.isSuccess, isTrue);
    expect(analysis.synergyScore, 77);
    expect(setQuantityResult.isSuccess, isTrue);
    expect(importResult['success'], isTrue);
    expect(validateImportResult['success'], isTrue);
    expect(importToDeckResult['success'], isTrue);
    expect(toggled, isTrue);
    expect(export['text'], '1 Sol Ring');
    expect(copied['success'], isTrue);
  });
}
