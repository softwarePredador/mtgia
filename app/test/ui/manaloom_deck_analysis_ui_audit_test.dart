import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/api/api_client.dart';
import 'package:manaloom/core/theme/app_theme.dart';
import 'package:manaloom/features/decks/models/deck_card_item.dart';
import 'package:manaloom/features/decks/models/deck_details.dart';
import 'package:manaloom/features/decks/providers/deck_provider.dart';
import 'package:manaloom/features/decks/widgets/deck_analysis_tab.dart';
import 'package:provider/provider.dart';

import 'support/manaloom_ui_audit_harness.dart';

void main() {
  runManaLoomUiGoldenConfig(
    run: () {
      goldenTest(
        'deck analysis summary keeps readable player-facing metrics',
        fileName: 'manaloom_deck_analysis_summary',
        constraints: manaloomFullScreenGoldenConstraints,
        builder: () => _deckAnalysisShell(_pricedDeck()),
      );
    },
  );

  testWidgets('deck analysis summary keeps key values visible', (tester) async {
    setManaLoomMobileViewport(tester);

    await tester.pumpWidget(_deckAnalysisShell(_pricedDeck()));
    await tester.pumpAndSettle();

    expect(find.text('Análise do deck'), findsOneWidget);
    expect(find.text('Legalidade'), findsOneWidget);
    expect(find.text('100/100'), findsOneWidget);
    expect(find.text('Preço total'), findsOneWidget);
    expect(find.text('R\$ 1.234,56'), findsOneWidget);
    expect(find.text('2 sem preço'), findsOneWidget);
    expect(find.text('R\$ ...'), findsNothing);
    expect(find.text('Leitura pronta'), findsOneWidget);
    expect(find.text('Atualizar análise'), findsOneWidget);
  });
}

Widget _deckAnalysisShell(DeckDetails deck) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.darkTheme,
    home: ChangeNotifierProvider(
      create: (_) => DeckProvider(apiClient: _DeckAnalysisApiFixture(deck.id)),
      child: Scaffold(
        body: manaloomDecoratedAuditSurface(
          child: SingleChildScrollView(child: DeckAnalysisTab(deck: deck)),
        ),
      ),
    ),
  );
}

DeckDetails _pricedDeck() {
  return DeckDetails(
    id: 'deck-visual-proof',
    name: 'Talrand Visual Proof',
    format: 'commander',
    description: 'Deck de teste visual',
    archetype: 'tempo',
    bracket: 2,
    colorIdentity: const ['U'],
    isPublic: false,
    createdAt: DateTime(2026, 7, 7),
    cardCount: 100,
    synergyScore: 85,
    strengths:
        'O deck tem aceleração e compra suficientes para executar o plano.',
    weaknesses:
        'Ainda vale revisar remoções pontuais contra mesas mais rápidas.',
    pricingTotal: 1234.56,
    pricingCurrency: 'BRL',
    pricingMissingCards: 2,
    stats: const {
      'average_cmc': 3.9,
      'land_count': 34,
      'composition': {
        'ramp': 12,
        'draw': 10,
        'removal': 11,
        'board_wipes': 3,
        'protection': 4,
      },
    },
    commander: [
      DeckCardItem(
        id: 'cmd-visual',
        name: 'Talrand, Sky Summoner',
        manaCost: '{2}{U}{U}',
        typeLine: 'Legendary Creature - Merfolk Wizard',
        oracleText:
            'Whenever you cast an instant or sorcery spell, create a 2/2 blue Drake creature token with flying.',
        colors: ['U'],
        colorIdentity: ['U'],
        imageUrl: null,
        setCode: 'm13',
        setName: 'Magic 2013',
        rarity: 'rare',
        quantity: 1,
        isCommander: true,
      ),
    ],
    mainBoard: {
      'Instants': [
        DeckCardItem(
          id: 'spell-visual',
          name: 'Counterspell',
          manaCost: '{U}{U}',
          typeLine: 'Instant',
          oracleText: 'Counter target spell.',
          colors: ['U'],
          colorIdentity: ['U'],
          imageUrl: null,
          setCode: '2xm',
          setName: 'Double Masters',
          rarity: 'uncommon',
          quantity: 1,
          isCommander: false,
        ),
      ],
      'Lands': [
        DeckCardItem(
          id: 'land-visual',
          name: 'Island',
          manaCost: '',
          typeLine: 'Basic Land - Island',
          oracleText: '',
          colors: [],
          colorIdentity: ['U'],
          imageUrl: null,
          setCode: 'und',
          setName: 'Unsanctioned',
          rarity: 'common',
          quantity: 34,
          isCommander: false,
        ),
      ],
    },
  );
}

class _DeckAnalysisApiFixture extends ApiClient {
  _DeckAnalysisApiFixture(this.deckId);

  final String deckId;

  @override
  Future<ApiResponse> get(String endpoint) async {
    if (endpoint.endsWith('/analysis')) {
      return ApiResponse(200, {
        'deck_id': deckId,
        'stats': const {
          'composition': {
            'ramp': 12,
            'draw': 10,
            'removal': 11,
            'board_wipes': 3,
            'protection': 4,
          },
        },
      });
    }
    throw UnimplementedError('No GET handler for $endpoint');
  }
}
