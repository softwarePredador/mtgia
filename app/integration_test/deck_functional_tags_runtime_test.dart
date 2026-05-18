import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:manaloom/core/api/api_client.dart';
import 'package:manaloom/core/theme/app_theme.dart';
import 'package:manaloom/features/decks/models/deck_details.dart';
import 'package:manaloom/features/decks/providers/deck_provider.dart';
import 'package:manaloom/features/decks/widgets/deck_analysis_tab.dart';
import 'package:provider/provider.dart';

import 'runtime_test_helpers.dart';

Future<String> _resolveFirstCardId(ApiClient api, String name) async {
  final query = Uri(queryParameters: {'name': name, 'limit': '1'}).query;
  final response = await api.get('/cards?$query');
  expect(response.statusCode, 200, reason: 'resolve $name');
  final data = response.data as Map<String, dynamic>;
  final rows = (data['data'] as List?) ?? const [];
  expect(rows, isNotEmpty, reason: 'card exists locally: $name');
  final card = rows.first as Map<String, dynamic>;
  final id = card['id']?.toString();
  expect(id, isNotNull, reason: 'card id for $name');
  return id!;
}

Future<String> _createSmallFunctionalDeck(ApiClient api) async {
  const cardNames = [
    'Talrand, Sky Summoner',
    'Sol Ring',
    'Arcane Signet',
    'Brainstorm',
    'Pongify',
    'Counterspell',
    'Whelming Wave',
  ];
  final cardIds = <String, String>{};
  for (final name in cardNames) {
    cardIds[name] = await _resolveFirstCardId(api, name);
  }

  final response = await api.post('/decks', {
    'name': 'Runtime Functional Tags',
    'format': 'commander',
    'description': 'Runtime sanitized functional tags proof',
    'cards': [
      {
        'card_id': cardIds['Talrand, Sky Summoner'],
        'quantity': 1,
        'is_commander': true,
      },
      for (final name in cardNames.skip(1))
        {'card_id': cardIds[name], 'quantity': 1, 'is_commander': false},
    ],
  });
  expect(response.statusCode, anyOf(200, 201));
  final data = response.data as Map<String, dynamic>;
  final deck = (data['deck'] as Map?)?.cast<String, dynamic>();
  final deckId = data['id']?.toString() ?? deck?['id']?.toString();
  expect(deckId, isNotNull);
  return deckId!;
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await clearRuntimeAuth();
  });

  testWidgets('Deck Analysis shows backend functional tag samples', (
    tester,
  ) async {
    final api = ApiClient();
    final health = await api.get('/health');
    expect(health.statusCode, 200);

    await seedAuthenticatedSession(
      api,
      usernamePrefix: 'functional_tags_runtime',
    );
    final deckId = await _createSmallFunctionalDeck(api);

    final provider = DeckProvider(apiClient: api);
    await provider.fetchDeckDetails(deckId);
    final deck = provider.selectedDeck;
    expect(deck, isA<DeckDetails>());

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: ChangeNotifierProvider.value(
          value: provider,
          child: Scaffold(
            body: SingleChildScrollView(child: DeckAnalysisTab(deck: deck!)),
          ),
        ),
      ),
    );

    await pumpUntilFound(
      tester,
      find.byKey(Key('deck-analysis-functional-section-$deckId')),
      attempts: 60,
      step: const Duration(milliseconds: 500),
    );
    await pumpUntilFound(
      tester,
      find.byKey(Key('deck-analysis-functional-origin-$deckId')),
      attempts: 60,
      step: const Duration(milliseconds: 500),
    );

    final rampBucket = find.byKey(
      Key('deck-analysis-functional-bucket-$deckId-ramp'),
    );
    await tester.ensureVisible(rampBucket);
    await tester.tap(rampBucket);
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Origem da contagem: functional_tags'),
      findsOneWidget,
    );
    expect(find.textContaining('Sol Ring'), findsWidgets);
    expectNoRawTechnicalErrorText(tester);

    // Keep binding referenced so visual capture setup stays available if enabled.
    expect(binding, isA<IntegrationTestWidgetsFlutterBinding>());
  });
}
