import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/theme/app_theme.dart';
import 'package:manaloom/features/decks/models/deck_details.dart';
import 'package:manaloom/features/decks/widgets/deck_details_overview_tab.dart';

void main() {
  DeckDetails makeDeck() {
    return DeckDetails(
      id: 'deck-1',
      name: 'Boros Tokens',
      format: 'commander',
      description: null,
      archetype: null,
      bracket: null,
      colorIdentity: const ['R', 'W'],
      isPublic: false,
      createdAt: DateTime(2026, 3, 24),
      cardCount: 99,
      stats: const {},
      commander: const [],
      mainBoard: const {},
    );
  }

  Widget createSubject({
    required DeckDetails deck,
    required VoidCallback onValidationTap,
    required VoidCallback onOpenCards,
    required VoidCallback onOpenAnalysis,
    required VoidCallback onForcePricingRefresh,
    required VoidCallback onShowPricingDetails,
    required VoidCallback onTogglePublic,
    required VoidCallback onShowOptimizationOptions,
    required VoidCallback onSelectCommander,
    required ValueChanged<String?> onEditDescription,
  }) {
    return MaterialApp(
      theme: AppTheme.darkTheme,
      home: Scaffold(
        body: SizedBox(
          width: 320,
          child: DeckDetailsOverviewTab(
            deckId: deck.id,
            deck: deck,
            totalCards: 99,
            maxCards: 100,
            isCommanderFormat: true,
            isValidating: false,
            isPricingLoading: false,
            validationResult: const {'ok': false, 'error': 'Commander ausente'},
            pricing: const {'estimated_total_usd': 123.45, 'currency': 'USD'},
            isCardInvalid: (_) => false,
            bracketLabel: (_) => 'Casual',
            onValidationTap: onValidationTap,
            onOpenCards: onOpenCards,
            onOpenAnalysis: onOpenAnalysis,
            onForcePricingRefresh: onForcePricingRefresh,
            onShowPricingDetails: onShowPricingDetails,
            onTogglePublic: onTogglePublic,
            onShowOptimizationOptions: onShowOptimizationOptions,
            onSelectCommander: onSelectCommander,
            onEditDescription: onEditDescription,
            onShowCardDetails: (_) {},
          ),
        ),
      ),
    );
  }

  testWidgets('renders summary actions and dispatches primary callbacks', (
    tester,
  ) async {
    var validationTapped = 0;
    var optimizationTapped = 0;
    var commanderTapped = 0;
    String? editedDescription;

    await tester.pumpWidget(
      createSubject(
        deck: makeDeck(),
        onValidationTap: () => validationTapped++,
        onOpenCards: () {},
        onOpenAnalysis: () {},
        onForcePricingRefresh: () {},
        onShowPricingDetails: () {},
        onTogglePublic: () {},
        onShowOptimizationOptions: () => optimizationTapped++,
        onSelectCommander: () => commanderTapped++,
        onEditDescription: (value) => editedDescription = value,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Boros Tokens'), findsOneWidget);
    expect(find.text('Descrição'), findsOneWidget);
    expect(find.text('Estratégia'), findsOneWidget);
    expect(find.text('Selecionar'), findsOneWidget);

    await tester.tap(find.text('Inválido'));
    await tester.pumpAndSettle();
    expect(validationTapped, 1);

    await tester.ensureVisible(find.text('Adicionar'));
    await tester.tap(find.text('Adicionar'));
    await tester.pumpAndSettle();
    expect(editedDescription, isNull);

    await tester.ensureVisible(find.text('Selecionar'));
    await tester.tap(find.text('Selecionar'));
    await tester.pumpAndSettle();
    expect(commanderTapped, 1);

    await tester.ensureVisible(find.text('Definir'));
    await tester.tap(find.text('Definir'));
    await tester.pumpAndSettle();
    expect(optimizationTapped, 1);
  });
}
