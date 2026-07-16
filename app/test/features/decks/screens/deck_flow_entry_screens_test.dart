import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:manaloom/core/api/api_client.dart';
import 'package:manaloom/features/decks/providers/deck_provider.dart';
import 'package:manaloom/features/decks/screens/deck_generate_screen.dart';
import 'package:manaloom/features/decks/screens/deck_import_screen.dart';
import 'package:provider/provider.dart';

class _FakeApiClient extends ApiClient {
  final getCalls = <String>[];
  final postCalls = <String>[];
  final List<Map<String, dynamic>> postBodies = [];

  @override
  Future<ApiResponse> get(String endpoint) async {
    getCalls.add(endpoint);
    if (endpoint == '/ai/commander-learning') {
      return ApiResponse(200, {
        'available': true,
        'count': 1,
        'commanders': const [
          {
            'commander': 'Lorehold, the Historian',
            'source_ref': 'learned_deck:82',
            'score': 136.5,
            'legal_status': 'commander_legal',
          },
        ],
      });
    }
    if (endpoint.startsWith('/ai/commander-learning?commander=')) {
      return ApiResponse(200, {
        'available': true,
        'source': 'pg_commander_learned_decks',
        'promoted_deck': const {
          'commander': 'Lorehold, the Historian',
          'source_system': 'pg_commander_learned_decks',
          'source_ref': 'learned_deck:82',
          'score': 136.5,
          'legal_status': 'commander_legal',
        },
        'recommended_deck': const {
          'source_system': 'pg_commander_learned_decks',
          'source_ref': 'learned_deck:82',
          'deck_name': 'Lorehold Learned',
          'archetype': 'spellslinger',
          'bracket': 3,
          'score': 136.5,
          'source_confidence': 'high',
          'commander': {'name': 'Lorehold, the Historian'},
          'cards': [
            {'name': 'Arcane Signet', 'quantity': 1},
          ],
          'validation': {'is_valid': true, 'errors': <String>[]},
          'legality': {
            'is_valid': true,
            'banned_cards': <String>[],
            'unknown_legality_cards': <String>[],
          },
        },
      });
    }
    throw UnimplementedError('No GET handler for $endpoint');
  }

  @override
  Future<ApiResponse> post(
    String endpoint,
    Map<String, dynamic> body, {
    Duration? timeout,
  }) async {
    postCalls.add(endpoint);
    postBodies.add(body);
    if (endpoint == '/cards/resolve/batch') {
      final names = (body['names'] as List?)?.cast<String>() ?? [];
      final data =
          names
              .map(
                (name) => {
                  'input_name': name,
                  'card_id': 'resolved-${name.hashCode}',
                },
              )
              .toList();
      return ApiResponse(200, {
        'data': data,
        'unresolved': <String>[],
        'ambiguous': <String>[],
      });
    }
    if (endpoint == '/decks') {
      return ApiResponse(201, {
        'id': 'deck-saved-1',
        'name': body['name'],
        'format': body['format'],
      });
    }
    throw UnimplementedError('No POST handler for $endpoint');
  }
}

void main() {
  test('generated deck warnings panel ignores empty warning payloads', () {
    expect(
      hasMeaningfulGeneratedDeckWarnings(
        isMock: false,
        warnings: const {'invalid_cards': <String>[]},
      ),
      isFalse,
    );
    expect(
      hasMeaningfulGeneratedDeckWarnings(
        isMock: false,
        warnings: const {
          'messages': <String>['Carta substituída durante a validação.'],
        },
      ),
      isTrue,
    );
    expect(
      hasMeaningfulGeneratedDeckWarnings(
        isMock: true,
        warnings: const <String, dynamic>{},
      ),
      isTrue,
    );
  });

  Widget wrapSimple(Widget child, {DeckProvider? deckProvider}) {
    final app = MaterialApp(home: child);
    if (deckProvider == null) return app;
    return ChangeNotifierProvider<DeckProvider>.value(
      value: deckProvider,
      child: app,
    );
  }

  Widget wrapWithRouter(DeckProvider deckProvider) {
    return MaterialApp.router(
      routerConfig: GoRouter(
        initialLocation: '/generate',
        routes: [
          GoRoute(
            path: '/generate',
            builder:
                (_, __) => ChangeNotifierProvider<DeckProvider>.value(
                  value: deckProvider,
                  child: const DeckGenerateScreen(),
                ),
          ),
          GoRoute(path: '/decks', builder: (_, __) => const SizedBox.shrink()),
        ],
      ),
    );
  }

  testWidgets('DeckGenerateScreen aplica o formato inicial vindo do fluxo', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrapSimple(const DeckGenerateScreen(initialFormat: 'modern')),
    );

    expect(find.text('Modern'), findsOneWidget);
    expect(find.text('Commander'), findsNothing);
  });

  testWidgets(
    'DeckGenerateScreen mostra atalho de deck aprendido em Commander',
    (tester) async {
      final apiClient = _FakeApiClient();
      await tester.pumpWidget(
        wrapSimple(
          const DeckGenerateScreen(),
          deckProvider: DeckProvider(apiClient: apiClient),
        ),
      );
      await tester.pump();

      expect(
        find.byKey(const Key('deck-generate-learned-deck-button')),
        findsNothing,
      );

      await tester.enterText(
        find.byKey(const Key('deck-generate-commander-field')),
        'Lorehold, the Historian',
      );
      await tester.pump();

      expect(
        find.byKey(const Key('deck-generate-learned-deck-button')),
        findsOneWidget,
      );
      expect(find.text('Usar deck aprendido do comandante'), findsOneWidget);
      expect(find.textContaining('curado pelo Hermes'), findsOneWidget);
      expect(find.textContaining('learned_deck:82'), findsNothing);

      final learnedDeckButton = find.byKey(
        const Key('deck-generate-learned-deck-button'),
      );
      await tester.ensureVisible(learnedDeckButton);
      await tester.tap(learnedDeckButton);
      await tester.pumpAndSettle();

      expect(
        apiClient.getCalls.any(
          (call) => call.startsWith('/ai/commander-learning?commander='),
        ),
        isTrue,
      );
      expect(find.text('Deck aprendido Hermes'), findsOneWidget);
      expect(
        find.textContaining('Origem: Deck aprendido Hermes'),
        findsOneWidget,
      );
      expect(find.textContaining('learned_deck:82'), findsNothing);
      expect(find.text('Score: 136.5'), findsOneWidget);
      expect(find.text('Legalidade: commander_legal'), findsOneWidget);
      expect(find.text('Confiança: high'), findsOneWidget);
    },
  );

  testWidgets('DeckImportScreen aplica o formato inicial vindo do fluxo', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrapSimple(const DeckImportScreen(initialFormat: 'pauper')),
    );

    expect(find.text('Pauper'), findsOneWidget);
    expect(find.text('Commander'), findsNothing);
  });

  testWidgets(
    'DeckGenerateScreen save learned deck POSTs 99 main + 1 commander',
    (tester) async {
      final apiClient = _FakeApiClient();
      await tester.pumpWidget(
        wrapWithRouter(DeckProvider(apiClient: apiClient)),
      );
      await tester.pump();

      await tester.enterText(
        find.byKey(const Key('deck-generate-commander-field')),
        'Lorehold, the Historian',
      );
      await tester.pump();

      final learnedDeckButton = find.byKey(
        const Key('deck-generate-learned-deck-button'),
      );
      await tester.ensureVisible(learnedDeckButton);
      await tester.tap(learnedDeckButton);
      await tester.pumpAndSettle();

      final saveButton = find.byKey(const Key('deck-generate-save-button'));
      await tester.ensureVisible(saveButton);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      final resolveCall = apiClient.postCalls.any(
        (call) => call == '/cards/resolve/batch',
      );
      expect(resolveCall, isTrue);

      final deckCall = apiClient.postCalls.any((call) => call == '/decks');
      expect(deckCall, isTrue);

      for (final body in apiClient.postBodies) {
        if (body.containsKey('cards')) {
          final cards = body['cards'] as List;
          final commanders = cards.where(
            (c) => c is Map && c['is_commander'] == true,
          );
          final main = cards.where(
            (c) => c is Map && c['is_commander'] != true,
          );
          expect(commanders.length, 1);
          expect(commanders.first['card_id'], isNotNull);
          expect(commanders.first['card_id'], isNotEmpty);
          expect(main.length, 1);
          expect(main.first['card_id'], isNotNull);
          expect(main.first['card_id'], isNotEmpty);
          expect(body['format'], 'commander');
          expect(body['archetype'], 'spellslinger');
          expect(body['bracket'], 3);
        }
      }
    },
  );
}
