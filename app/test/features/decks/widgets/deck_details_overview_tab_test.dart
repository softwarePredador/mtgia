import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:manaloom/core/theme/app_theme.dart';
import 'package:manaloom/features/decks/models/deck_card_item.dart';
import 'package:manaloom/features/decks/models/deck_details.dart';
import 'package:manaloom/features/decks/widgets/deck_details_aux_widgets.dart';
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
    required VoidCallback onForcePricingRefresh,
    required VoidCallback onShowPricingDetails,
    required VoidCallback onTogglePublic,
    VoidCallback? onPlay,
    required VoidCallback onShowOptimizationOptions,
    required VoidCallback onSelectCommander,
    required VoidCallback onImportList,
    required ValueChanged<String?> onEditDescription,
    int totalCards = 99,
    Map<String, dynamic>? validationResult = const {
      'ok': false,
      'error': 'Commander ausente',
    },
    double width = 320,
  }) {
    return MaterialApp(
      theme: AppTheme.darkTheme,
      home: Scaffold(
        body: SizedBox(
          width: width,
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
            onValidateNow: onValidationTap,
            onValidationTap: onValidationTap,
            onOpenCards: onOpenCards,
            onForcePricingRefresh: onForcePricingRefresh,
            onShowPricingDetails: onShowPricingDetails,
            onTogglePublic: onTogglePublic,
            onPlay: onPlay ?? () {},
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
    var playTapped = 0;
    var commanderTapped = 0;
    var importTapped = 0;
    var cardsOpened = 0;
    String? editedDescription;

    await tester.pumpWidget(
      createSubject(
        deck: makeDeck(),
        onValidationTap: () => validationTapped++,
        onOpenCards: () => cardsOpened++,
        onForcePricingRefresh: () {},
        onShowPricingDetails: () {},
        onTogglePublic: () {},
        onPlay: () => playTapped++,
        onShowOptimizationOptions: () => optimizationTapped++,
        onSelectCommander: () => commanderTapped++,
        onImportList: () => importTapped++,
        onEditDescription: (value) => editedDescription = value,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Boros Tokens'), findsOneWidget);
    expect(find.text('99 cartas'), findsOneWidget);
    expect(find.text('Abrir cartas'), findsOneWidget);
    expect(find.text('Abrir análise'), findsNothing);
    expect(find.text('Jogar agora'), findsOneWidget);
    expect(find.text('Otimizar'), findsOneWidget);
    expect(find.text('Atenção na legalidade'), findsOneWidget);
    expect(find.text('Comandante ausente'), findsOneWidget);
    expect(find.text('Deck abaixo de 100 cartas'), findsOneWidget);
    expect(find.text('Descrição'), findsOneWidget);
    expect(find.text('Estratégia'), findsOneWidget);
    expect(find.text('Selecionar'), findsOneWidget);

    await tester.tap(find.text('Jogar agora'));
    await tester.pump();
    expect(playTapped, 1);

    final commanderPromptTop = tester.getTopLeft(
      find.text(
        'Selecione um comandante para aplicar regras e filtros de identidade de cor.',
      ),
    );
    final strategyTop = tester.getTopLeft(find.text('Estratégia'));
    final descriptionTop = tester.getTopLeft(find.text('Descrição'));

    expect(commanderPromptTop.dy, lessThan(strategyTop.dy));
    expect(strategyTop.dy, lessThan(descriptionTop.dy));

    await tester.ensureVisible(find.text('Inválido'));
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

    await tester.ensureVisible(find.text('Otimizar'));
    await tester.tap(find.text('Otimizar'));
    await tester.pumpAndSettle();
    expect(optimizationTapped, 1);

    expect(cardsOpened, 0);
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

    expect(find.text('Escolha o comandante primeiro'), findsOneWidget);
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

  testWidgets('hides internal import source from description display', (
    tester,
  ) async {
    const internalDescription =
        'Imported from Hermes deck 607 current champion snapshot 2026-06-30. '
        'Source: docs/hermes-analysis/master_optimizer_reports/report.txt';
    String? editedDescription;

    await tester.pumpWidget(
      createSubject(
        deck: makeDeck().copyWith(description: internalDescription),
        totalCards: 100,
        validationResult: const {'ok': true},
        onValidationTap: () {},
        onOpenCards: () {},
        onForcePricingRefresh: () {},
        onShowPricingDetails: () {},
        onTogglePublic: () {},
        onShowOptimizationOptions: () {},
        onSelectCommander: () {},
        onImportList: () {},
        onEditDescription: (value) => editedDescription = value,
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Deck importado de uma análise validada'),
      findsOneWidget,
    );
    expect(find.textContaining('docs/hermes-analysis'), findsNothing);

    await tester.ensureVisible(find.text('Editar'));
    await tester.tap(find.text('Editar'));
    await tester.pumpAndSettle();
    expect(editedDescription, internalDescription);
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
    expect(find.text('100 cartas • Bracket 2 • tempo'), findsOneWidget);
    expect(find.text('Commander'), findsOneWidget);
    expect(find.text('Definido'), findsOneWidget);
    expect(find.text('Identidade'), findsOneWidget);
    expect(find.text('Público'), findsOneWidget);
    expect(find.text('Válido'), findsOneWidget);

    final strategyTop = tester.getTopLeft(find.text('Estratégia'));
    final commanderSectionTop = tester.getTopLeft(find.text('Comandante'));
    final descriptionTop = tester.getTopLeft(find.text('Descrição'));

    expect(strategyTop.dy, lessThan(commanderSectionTop.dy));
    expect(commanderSectionTop.dy, lessThan(descriptionTop.dy));
  });

  testWidgets('color identity pips normalize symbols and use mana svg assets', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: ColorIdentityPips(colors: ['r', 'W', 'w'])),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SvgPicture), findsNWidgets(2));
    expect(find.text('r'), findsNothing);
    expect(find.text('R'), findsNothing);
    expect(find.text('W'), findsNothing);
  });

  testWidgets('wide overview uses bounded primary and inspector panes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      createSubject(
        deck: makeCommanderDeck(),
        totalCards: 100,
        validationResult: const {'ok': true},
        onValidationTap: () {},
        onOpenCards: () {},
        onForcePricingRefresh: () {},
        onShowPricingDetails: () {},
        onTogglePublic: () {},
        onShowOptimizationOptions: () {},
        onSelectCommander: () {},
        onImportList: () {},
        onEditDescription: (_) {},
        width: 1280,
      ),
    );
    await tester.pump();

    expect(
      find.byKey(const Key('deck-overview-desktop-panes')),
      findsOneWidget,
    );
    expect(
      tester
          .getSize(find.byKey(const Key('deck-overview-inspector-pane')))
          .width,
      AppTheme.inspectorWidth,
    );
    expect(
      tester.getSize(find.byKey(const Key('deck-overview-hero'))).width,
      lessThanOrEqualTo(AppTheme.contentMaxWidth),
    );

    final primaryLeft =
        tester
            .getTopLeft(find.byKey(const Key('deck-overview-primary-pane')))
            .dx;
    final inspectorLeft =
        tester
            .getTopLeft(find.byKey(const Key('deck-overview-inspector-pane')))
            .dx;
    expect(primaryLeft, lessThan(inspectorLeft));
  });

  testWidgets('mobile summary keeps mana identity inside readable tiles', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      createSubject(
        deck: makeCommanderDeck().copyWith(
          colorIdentity: const ['W', 'U', 'B', 'R', 'G'],
        ),
        totalCards: 100,
        validationResult: const {'ok': true},
        onValidationTap: () {},
        onOpenCards: () {},
        onForcePricingRefresh: () {},
        onShowPricingDetails: () {},
        onTogglePublic: () {},
        onShowOptimizationOptions: () {},
        onSelectCommander: () {},
        onImportList: () {},
        onEditDescription: (_) {},
        width: 390,
      ),
    );
    await tester.pump();

    expect(find.byType(SvgPicture), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
