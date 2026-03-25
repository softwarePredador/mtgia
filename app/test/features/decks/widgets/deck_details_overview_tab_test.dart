import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/theme/app_theme.dart';
import 'package:manaloom/features/decks/models/deck_card_item.dart';
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

  DeckDetails makeCommanderDeck() {
    return DeckDetails(
      id: 'deck-2',
      name: 'Talrand Tempo',
      format: 'commander',
      description: 'Deck de tempo azul.',
      archetype: 'tempo',
      bracket: 2,
      colorIdentity: const ['U'],
      isPublic: true,
      createdAt: DateTime(2026, 3, 24),
      cardCount: 100,
      stats: const {},
      commander: [
        DeckCardItem(
          id: 'cmd-1',
          name: 'Talrand, Sky Summoner',
          manaCost: '{2}{U}{U}',
          typeLine: 'Legendary Creature — Merfolk Wizard',
          oracleText: 'Sempre que você conjura uma mágica instantânea...',
          colors: const ['U'],
          colorIdentity: const ['U'],
          imageUrl: 'https://cards.scryfall.io/normal/front/test.jpg',
          setCode: 'm13',
          setName: 'Magic 2013',
          rarity: 'rare',
          quantity: 1,
          isCommander: true,
        ),
      ],
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
    required VoidCallback onImportList,
    required ValueChanged<String?> onEditDescription,
    int totalCards = 99,
    Map<String, dynamic>? validationResult = const {
      'ok': false,
      'error': 'Commander ausente',
    },
  }) {
    return MaterialApp(
      theme: AppTheme.darkTheme,
      home: Scaffold(
        body: SizedBox(
          width: 320,
          child: DeckDetailsOverviewTab(
            deckId: deck.id,
            deck: deck,
            totalCards: totalCards,
            maxCards: 100,
            isCommanderFormat: true,
            isValidating: false,
            isPricingLoading: false,
            validationResult: validationResult,
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
            onImportList: onImportList,
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
    var importTapped = 0;
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
        onImportList: () => importTapped++,
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

    expect(importTapped, 0);
  });

  testWidgets('renders calm empty-deck state without validation noise', (
    tester,
  ) async {
    var commanderTapped = 0;
    var cardsTapped = 0;
    var importTapped = 0;

    await tester.pumpWidget(
      createSubject(
        deck: makeDeck(),
        totalCards: 0,
        validationResult: null,
        onValidationTap: () {},
        onOpenCards: () => cardsTapped++,
        onOpenAnalysis: () {},
        onForcePricingRefresh: () {},
        onShowPricingDetails: () {},
        onTogglePublic: () {},
        onShowOptimizationOptions: () {},
        onSelectCommander: () => commanderTapped++,
        onImportList: () => importTapped++,
        onEditDescription: (_) {},
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Deck pronto para começar'), findsOneWidget);
    expect(find.text('Selecionar comandante'), findsOneWidget);
    expect(find.text('Buscar cartas'), findsOneWidget);
    expect(find.text('Colar lista'), findsOneWidget);
    expect(find.text('Inválido'), findsNothing);
    expect(find.text('Estratégia'), findsNothing);
    expect(find.text('Comandante'), findsNothing);

    await tester.tap(find.text('Selecionar comandante'));
    await tester.pumpAndSettle();
    expect(commanderTapped, 1);

    await tester.ensureVisible(find.text('Buscar cartas'));
    await tester.tap(find.text('Buscar cartas'));
    await tester.pumpAndSettle();
    expect(cardsTapped, 1);

    await tester.ensureVisible(find.text('Colar lista'));
    await tester.tap(find.text('Colar lista'));
    await tester.pumpAndSettle();
    expect(importTapped, 1);
  });

  testWidgets('renders commander hero identity when commander exists', (
    tester,
  ) async {
    await tester.pumpWidget(
      createSubject(
        deck: makeCommanderDeck(),
        totalCards: 100,
        validationResult: const {'ok': true},
        onValidationTap: () {},
        onOpenCards: () {},
        onOpenAnalysis: () {},
        onForcePricingRefresh: () {},
        onShowPricingDetails: () {},
        onTogglePublic: () {},
        onShowOptimizationOptions: () {},
        onSelectCommander: () {},
        onImportList: () {},
        onEditDescription: (_) {},
      ),
    );
    await tester.pump();

    expect(find.text('Talrand Tempo'), findsOneWidget);
    expect(find.text('Comandante: Talrand, Sky Summoner'), findsOneWidget);
    expect(find.text('Público'), findsOneWidget);
    expect(find.text('Válido'), findsOneWidget);
  });
}
