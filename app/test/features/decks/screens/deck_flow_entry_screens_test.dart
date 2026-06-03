import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/api/api_client.dart';
import 'package:manaloom/features/decks/providers/deck_provider.dart';
import 'package:manaloom/features/decks/screens/deck_generate_screen.dart';
import 'package:manaloom/features/decks/screens/deck_import_screen.dart';
import 'package:provider/provider.dart';

class _FakeApiClient extends ApiClient {
  final getCalls = <String>[];

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
          'source_system': 'hermes',
          'source_ref': 'learned_deck:82',
          'score': 136.5,
          'legal_status': 'commander_legal',
        },
        'recommended_deck': const {
          'source_system': 'hermes',
          'source_ref': 'learned_deck:82',
          'deck_name': 'Lorehold Learned',
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
}

void main() {
  Widget wrap(Widget child, {DeckProvider? deckProvider}) {
    final app = MaterialApp(home: child);
    if (deckProvider == null) return app;
    return ChangeNotifierProvider<DeckProvider>.value(
      value: deckProvider,
      child: app,
    );
  }

  testWidgets('DeckGenerateScreen aplica o formato inicial vindo do fluxo', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(const DeckGenerateScreen(initialFormat: 'modern')),
    );

    expect(find.text('Modern'), findsOneWidget);
    expect(find.text('Commander'), findsNothing);
  });

  testWidgets(
    'DeckGenerateScreen mostra atalho de deck aprendido em Commander',
    (tester) async {
      final apiClient = _FakeApiClient();
      await tester.pumpWidget(
        wrap(
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
      expect(find.textContaining('learned_deck:82'), findsOneWidget);

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
        find.textContaining('Origem: HERMES learned_deck:82'),
        findsOneWidget,
      );
      expect(find.text('Score: 136.5'), findsOneWidget);
      expect(find.text('Legalidade: commander_legal'), findsOneWidget);
      expect(find.text('Confiança: high'), findsOneWidget);
    },
  );

  testWidgets('DeckImportScreen aplica o formato inicial vindo do fluxo', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(const DeckImportScreen(initialFormat: 'pauper')),
    );

    expect(find.text('Pauper'), findsOneWidget);
    expect(find.text('Commander'), findsNothing);
  });
}
