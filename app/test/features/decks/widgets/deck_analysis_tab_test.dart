import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/api/api_client.dart';
import 'package:manaloom/core/theme/app_theme.dart';
import 'package:manaloom/features/decks/models/deck_card_item.dart';
import 'package:manaloom/features/decks/models/deck_details.dart';
import 'package:manaloom/features/decks/providers/deck_provider.dart';
import 'package:manaloom/features/decks/widgets/deck_analysis_tab.dart';
import 'package:provider/provider.dart';

DeckDetails _makeDeck({
  required String id,
  required String name,
  int? synergyScore,
  String? strengths,
  String? weaknesses,
  int cardCount = 100,
}) {
  return DeckDetails(
    id: id,
    name: name,
    format: 'commander',
    description: 'Deck de teste',
    archetype: 'tempo',
    bracket: 2,
    colorIdentity: const ['U'],
    isPublic: false,
    createdAt: DateTime(2026, 3, 25),
    cardCount: cardCount,
    synergyScore: synergyScore,
    strengths: strengths,
    weaknesses: weaknesses,
    stats: const {},
    commander: [
      DeckCardItem(
        id: 'cmd-1',
        name: 'Talrand, Sky Summoner',
        manaCost: '{2}{U}{U}',
        typeLine: 'Legendary Creature — Merfolk Wizard',
        oracleText: '',
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
          id: 'spell-1',
          name: 'Opt',
          manaCost: '{U}',
          typeLine: 'Instant',
          oracleText: '',
          colors: ['U'],
          colorIdentity: ['U'],
          imageUrl: null,
          setCode: 'dom',
          setName: 'Dominaria',
          rarity: 'common',
          quantity: 4,
          isCommander: false,
        ),
      ],
      'Artifacts': [
        DeckCardItem(
          id: 'artifact-1',
          name: 'Mind Stone',
          manaCost: '{2}',
          typeLine: 'Artifact',
          oracleText: '',
          colors: [],
          colorIdentity: [],
          imageUrl: null,
          setCode: 'war',
          setName: 'War of the Spark',
          rarity: 'uncommon',
          quantity: 2,
          isCommander: false,
        ),
      ],
    },
  );
}

Widget _subject(DeckDetails deck) {
  return MaterialApp(
    theme: AppTheme.darkTheme,
    home: ChangeNotifierProvider(
      create: (_) => DeckProvider(apiClient: ApiClient()),
      child: Scaffold(
        body: SingleChildScrollView(child: DeckAnalysisTab(deck: deck)),
      ),
    ),
  );
}

void main() {
  testWidgets('renders executive AI summary when analysis exists', (
    tester,
  ) async {
    final deck = _makeDeck(
      id: 'deck-ready',
      name: 'Talrand Tempo',
      synergyScore: 82,
      strengths:
          'Boa densidade de mágicas instantâneas e geração consistente de valor.',
      weaknesses:
          'Pode sofrer se faltar ramp cedo ou se a mesa acelerar demais.',
    );

    await tester.pumpWidget(_subject(deck));
    await tester.pumpAndSettle();

    expect(find.text('Análise do deck'), findsOneWidget);
    expect(find.text('Leitura pronta'), findsOneWidget);
    expect(find.text('Atualizar análise'), findsOneWidget);
    expect(find.text('Leitura de sinergia'), findsOneWidget);
    expect(find.text('Pontos fortes'), findsOneWidget);
    expect(find.text('Pontos fracos'), findsOneWidget);
    expect(find.text('Curva de mana'), findsOneWidget);
    expect(find.text('Distribuição de cores'), findsOneWidget);
  });

  testWidgets('renders pending state when AI summary does not exist yet', (
    tester,
  ) async {
    final deck = _makeDeck(
      id: 'deck-pending',
      name: 'Novo Talrand',
      cardCount: 30,
    );

    await tester.pumpWidget(_subject(deck));
    await tester.pumpAndSettle();

    expect(find.text('Leitura pendente'), findsOneWidget);
    expect(find.text('Gerar análise'), findsOneWidget);
    expect(find.text('Sinergia ainda não gerada'), findsOneWidget);
  });
}
