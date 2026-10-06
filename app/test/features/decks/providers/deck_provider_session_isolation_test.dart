import 'dart:async';
import 'dart:collection';

import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/api/api_client.dart';
import 'package:manaloom/features/decks/providers/deck_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Every GET waits on a completer the test releases, in any order.
class _ControlledGetApiClient extends ApiClient {
  final Map<String, Queue<Completer<ApiResponse>>> _pending = {};

  @override
  Future<ApiResponse> get(String endpoint) {
    final completer = Completer<ApiResponse>();
    _pending.putIfAbsent(endpoint, Queue.new).add(completer);
    return completer.future;
  }

  void respond(String endpoint, ApiResponse response) {
    final queue = _pending[endpoint];
    if (queue == null || queue.isEmpty) {
      throw StateError('No pending GET for $endpoint');
    }
    queue.removeFirst().complete(response);
  }

  void respondNewest(String endpoint, ApiResponse response) {
    final queue = _pending[endpoint];
    if (queue == null || queue.isEmpty) {
      throw StateError('No pending GET for $endpoint');
    }
    queue.removeLast().complete(response);
  }
}

Map<String, dynamic> _deckSummary(String id, String name) => {
  'id': id,
  'name': name,
  'format': 'commander',
  'is_public': false,
  'created_at': '2026-10-01T00:00:00.000Z',
  'card_count': 100,
  'color_identity': const ['U'],
};

Map<String, dynamic> _deckDetails(String id, String name) => {
  'id': id,
  'name': name,
  'format': 'commander',
  'is_public': false,
  'created_at': '2026-10-01T00:00:00.000Z',
  'color_identity': const ['U'],
  'stats': {'total_cards': 0},
  'commander': const <Object?>[],
  'main_board': const <String, Object?>{},
};

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(ApiClient.resetForTesting);

  group('DeckProvider session isolation (DCK-P0-07)', () {
    test(
      'a late deck A response never replaces the deck B opened after it',
      () async {
        final client = _ControlledGetApiClient();
        final provider = DeckProvider(apiClient: client);
        addTearDown(provider.dispose);

        final openA = provider.fetchDeckDetails('deck-a');
        final openB = provider.fetchDeckDetails('deck-b');
        await _settle();

        client.respond(
          '/decks/deck-b',
          ApiResponse(200, _deckDetails('deck-b', 'B')),
        );
        await openB;
        expect(provider.selectedDeck?.id, 'deck-b');

        client.respond(
          '/decks/deck-a',
          ApiResponse(200, _deckDetails('deck-a', 'A')),
        );
        await openA;
        expect(provider.selectedDeck?.id, 'deck-b');
        expect(provider.detailsErrorMessage, isNull);
      },
    );

    test(
      'a late deck A error never lands on the deck B opened after it',
      () async {
        final client = _ControlledGetApiClient();
        final provider = DeckProvider(apiClient: client);
        addTearDown(provider.dispose);

        final openA = provider.fetchDeckDetails('deck-a');
        final openB = provider.fetchDeckDetails('deck-b');
        await _settle();

        client.respond(
          '/decks/deck-b',
          ApiResponse(200, _deckDetails('deck-b', 'B')),
        );
        await openB;
        client.respond(
          '/decks/deck-a',
          ApiResponse(404, const {'error': 'deck_not_found'}),
        );
        await openA;

        expect(provider.selectedDeck?.id, 'deck-b');
        expect(provider.detailsErrorMessage, isNull);
        expect(provider.detailsStatusCode, 200);
      },
    );

    test('an older deck list response cannot replace a newer one', () async {
      final client = _ControlledGetApiClient();
      final provider = DeckProvider(apiClient: client);
      addTearDown(provider.dispose);

      final first = provider.fetchDecks();
      final second = provider.fetchDecks();
      await _settle();

      client.respondNewest(
        '/decks',
        ApiResponse(200, [_deckSummary('deck-new', 'Novo')]),
      );
      await second;
      client.respond(
        '/decks',
        ApiResponse(200, [_deckSummary('deck-old', 'Velho')]),
      );
      await first;

      expect(provider.decks.map((deck) => deck.id), ['deck-new']);
      expect(provider.isLoading, isFalse);
    });

    test(
      'login A, logout, login B: account A responses never reach B',
      () async {
        final client = _ControlledGetApiClient();
        final provider = DeckProvider(apiClient: client);
        addTearDown(provider.dispose);

        // Account A starts loading its list and one deck.
        final listA = provider.fetchDecks();
        final deckA = provider.fetchDeckDetails('deck-a');
        await _settle();
        final epochA = provider.sessionEpochForTesting;

        // Logout clears the provider and switches the epoch.
        provider.clearAllState();
        expect(provider.sessionEpochForTesting, isNot(epochA));
        expect(provider.decks, isEmpty);
        expect(provider.selectedDeck, isNull);

        // Account B logs in and loads its own list.
        final listB = provider.fetchDecks();
        await _settle();
        client.respond(
          '/decks',
          ApiResponse(200, [_deckSummary('deck-a', 'A')]),
        );
        client.respond(
          '/decks',
          ApiResponse(200, [_deckSummary('deck-b', 'B')]),
        );
        await Future.wait([listA, listB]);

        client.respond(
          '/decks/deck-a',
          ApiResponse(200, _deckDetails('deck-a', 'A')),
        );
        await deckA;

        expect(provider.decks.map((deck) => deck.id), ['deck-b']);
        expect(provider.selectedDeck, isNull);
        expect(provider.isLoading, isFalse);
      },
    );

    test('logout drops the active optimize job and the analysis caches', () {
      final provider = DeckProvider(apiClient: _ControlledGetApiClient());
      addTearDown(provider.dispose);

      provider.clearAllState();

      expect(provider.hasActiveOptimizeJob, isFalse);
      expect(provider.activeOptimizeDeckId, isNull);
      expect(provider.lastAppliedOptimizationEventId, isNull);
      expect(provider.optimizationHistoryFor('deck-a'), isEmpty);
      expect(provider.deckAnalysisFor('deck-a'), isNull);
    });
  });
}
