import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/features/home/life_counter/life_counter_native_game_modes_sheet.dart';

class _GameModesHost extends StatelessWidget {
  const _GameModesHost({
    required this.onResult,
    this.preferredAction = LifeCounterGameModesAction.openPlanechase,
    this.preferredIntent = LifeCounterGameModesEntryIntent.openMode,
    this.planechaseCardPoolActive = false,
    this.planechaseAvailable = true,
    this.planechaseActive = true,
    this.archenemyAvailable = false,
    this.archenemyActive = false,
    this.bountyAvailable = true,
    this.bountyActive = false,
  });

  final ValueChanged<LifeCounterGameModesAction?> onResult;
  final LifeCounterGameModesAction preferredAction;
  final LifeCounterGameModesEntryIntent preferredIntent;
  final bool planechaseCardPoolActive;
  final bool planechaseAvailable;
  final bool planechaseActive;
  final bool archenemyAvailable;
  final bool archenemyActive;
  final bool bountyAvailable;
  final bool bountyActive;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            final result = await showLifeCounterNativeGameModesSheet(
              context,
              availability: LifeCounterGameModesAvailability(
                planechaseAvailable: planechaseAvailable,
                planechaseActive: planechaseActive,
                archenemyAvailable: archenemyAvailable,
                archenemyActive: archenemyActive,
                bountyAvailable: bountyAvailable,
                bountyActive: bountyActive,
                planechaseCardPoolActive: planechaseCardPoolActive,
                activeModeCount:
                    (planechaseActive ? 1 : 0) +
                    (archenemyActive ? 1 : 0) +
                    (bountyActive ? 1 : 0),
              ),
              preferredAction: preferredAction,
              preferredIntent: preferredIntent,
            );
            onResult(result);
          },
          child: const Text('Open'),
        ),
      ),
    );
  }
}

void main() {
  testWidgets(
    'renders thematic game mode symbols with accessible Material fallbacks',
    (tester) async {
      final semanticsHandle = tester.ensureSemantics();
      const symbols = <String, ({String assetPath, IconData fallbackIcon})>{
        'planechase': (
          assetPath: 'assets/lotus/images/planechase.svg',
          fallbackIcon: Icons.public_rounded,
        ),
        'archenemy': (
          assetPath: 'assets/lotus/images/archenemy.svg',
          fallbackIcon: Icons.shield_moon_outlined,
        ),
        'bounty': (
          assetPath: 'assets/lotus/images/bounty.svg',
          fallbackIcon: Icons.workspace_premium_outlined,
        ),
      };

      final fallbackWidgets = <Widget>[];
      try {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(splashFactory: InkRipple.splashFactory),
            home: _GameModesHost(onResult: (_) {}),
          ),
        );

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        for (final entry in symbols.entries) {
          final symbolFinder = find.byKey(
            Key('life-counter-native-game-modes-${entry.key}-symbol'),
          );
          expect(symbolFinder, findsOneWidget);

          final picture = tester.widget<SvgPicture>(symbolFinder);
          final loader = picture.bytesLoader as SvgAssetLoader;
          expect(loader.assetName, entry.value.assetPath);
          expect(picture.width, 24);
          expect(picture.height, 24);
          expect(picture.colorFilter, isNotNull);
          expect(picture.excludeFromSemantics, isTrue);
          expect(picture.placeholderBuilder, isNotNull);
          expect(picture.errorBuilder, isNotNull);

          final title = switch (entry.key) {
            'planechase' => 'Planechase',
            'archenemy' => 'Archenemy',
            _ => 'Bounty',
          };
          final semanticLabel = 'Símbolo do modo $title';
          expect(find.byTooltip(semanticLabel), findsOneWidget);
          expect(
            tester
                .getSemantics(
                  find.byKey(
                    Key(
                      'life-counter-native-game-modes-${entry.key}-symbol-semantics',
                    ),
                  ),
                )
                .label,
            semanticLabel,
          );

          fallbackWidgets.add(
            picture.errorBuilder!(
              tester.element(symbolFinder),
              StateError('asset indisponível'),
              StackTrace.empty,
            ),
          );
        }
      } finally {
        semanticsHandle.dispose();
      }

      await tester.pumpWidget(
        MaterialApp(home: Row(children: fallbackWidgets)),
      );

      for (final entry in symbols.entries) {
        final fallbackFinder = find.byKey(
          Key('life-counter-native-game-modes-${entry.key}-symbol-fallback'),
        );
        expect(fallbackFinder, findsOneWidget);
        expect(
          tester.widget<Icon>(fallbackFinder).icon,
          entry.value.fallbackIcon,
        );
      }
    },
  );

  testWidgets('shows the owned game modes sheet', (tester) async {
    LifeCounterGameModesAction? result;

    await tester.pumpWidget(
      MaterialApp(
        home: _GameModesHost(
          onResult: (value) => result = value,
          planechaseCardPoolActive: true,
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Modos de jogo'), findsOneWidget);
    expect(find.text('Planechase'), findsOneWidget);
    expect(find.text('Archenemy'), findsOneWidget);
    expect(find.text('Bounty'), findsOneWidget);
    expect(find.text('Disponível'), findsNWidgets(2));
    expect(find.text('Indisponível'), findsOneWidget);
    expect(find.text('Ativo agora'), findsOneWidget);
    expect(find.text('Conjunto de cartas aberto'), findsOneWidget);
    expect(find.text('Selecionado'), findsOneWidget);
    expect(
      find.text('Este modo já está aberto na partida atual.'),
      findsOneWidget,
    );
    expect(
      find.text('O conjunto de cartas já está aberto para este modo.'),
      findsOneWidget,
    );
    expect(find.text('Voltar ao conjunto de cartas'), findsOneWidget);
    expect(find.text('Editar conjunto de cartas'), findsNWidgets(2));
    expect(find.text('Encerrar modo'), findsOneWidget);
    expect(find.text('Fechar conjunto de cartas'), findsOneWidget);

    await tester.ensureVisible(
      find.byKey(const Key('life-counter-native-game-modes-planechase-info')),
    );
    await tester.tap(
      find.byKey(const Key('life-counter-native-game-modes-planechase-info')),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    expect(find.text('Regras rápidas'), findsOneWidget);
    expect(
      find.text(
        'Dica: mantenha Planechase pressionado para rolar o dado planar imediatamente.',
      ),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(
        const Key('life-counter-native-game-modes-planechase-info-close'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(const Key('life-counter-native-game-modes-planechase-open')),
    );

    await tester.tap(
      find.byKey(const Key('life-counter-native-game-modes-planechase-open')),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    expect(result, LifeCounterGameModesAction.openPlanechase);
  });

  testWidgets('surfaces embedded card pool handoff intent', (tester) async {
    LifeCounterGameModesAction? result;

    await tester.pumpWidget(
      MaterialApp(
        home: _GameModesHost(
          preferredIntent: LifeCounterGameModesEntryIntent.editCards,
          onResult: (value) => result = value,
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Continuar para o conjunto'), findsOneWidget);
    expect(
      find.textContaining('Continue para o conjunto de cartas de Planechase.'),
      findsOneWidget,
    );

    await tester.ensureVisible(
      find.byKey(const Key('life-counter-native-game-modes-planechase-open')),
    );
    await tester.tap(
      find.byKey(const Key('life-counter-native-game-modes-planechase-open')),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    expect(result, LifeCounterGameModesAction.editPlanechaseCards);
  });

  testWidgets('offers explicit edit card pool action for available modes', (
    tester,
  ) async {
    LifeCounterGameModesAction? result;

    await tester.pumpWidget(
      MaterialApp(home: _GameModesHost(onResult: (value) => result = value)),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(
        const Key('life-counter-native-game-modes-planechase-edit-cards'),
      ),
    );
    await tester.tap(
      find.byKey(
        const Key('life-counter-native-game-modes-planechase-edit-cards'),
      ),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    expect(result, LifeCounterGameModesAction.editPlanechaseCards);
  });

  testWidgets('offers explicit close action for active overlays', (
    tester,
  ) async {
    LifeCounterGameModesAction? result;

    await tester.pumpWidget(
      MaterialApp(home: _GameModesHost(onResult: (value) => result = value)),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(
        const Key('life-counter-native-game-modes-planechase-close-overlay'),
      ),
    );
    await tester.tap(
      find.byKey(
        const Key('life-counter-native-game-modes-planechase-close-overlay'),
      ),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    expect(result, LifeCounterGameModesAction.closePlanechase);
  });

  testWidgets('offers explicit close action for active card pool editors', (
    tester,
  ) async {
    LifeCounterGameModesAction? result;

    await tester.pumpWidget(
      MaterialApp(
        home: _GameModesHost(
          onResult: (value) => result = value,
          planechaseCardPoolActive: true,
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(
        const Key('life-counter-native-game-modes-planechase-close-card-pool'),
      ),
    );
    await tester.tap(
      find.byKey(
        const Key('life-counter-native-game-modes-planechase-close-card-pool'),
      ),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    expect(result, LifeCounterGameModesAction.closePlanechaseCardPool);
  });

  testWidgets('offers settings when a preferred mode is unavailable', (
    tester,
  ) async {
    LifeCounterGameModesAction? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () async {
                result = await showLifeCounterNativeGameModesSheet(
                  tester.element(find.byType(ElevatedButton)),
                  availability: const LifeCounterGameModesAvailability(
                    planechaseAvailable: true,
                    archenemyAvailable: false,
                    bountyAvailable: true,
                  ),
                  preferredAction: LifeCounterGameModesAction.openArchenemy,
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Selecionado'), findsOneWidget);
    expect(find.text('Indisponível no momento'), findsOneWidget);
    expect(find.text('Abrir configurações'), findsOneWidget);

    await tester.ensureVisible(
      find.byKey(
        const Key('life-counter-native-game-modes-archenemy-settings'),
      ),
    );
    await tester.tap(
      find.byKey(
        const Key('life-counter-native-game-modes-archenemy-settings'),
      ),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    expect(result, LifeCounterGameModesAction.openSettings);
  });

  testWidgets('blocks opening a third mode when two modes are already active', (
    tester,
  ) async {
    LifeCounterGameModesAction? result;

    await tester.pumpWidget(
      MaterialApp(
        home: _GameModesHost(
          onResult: (value) => result = value,
          preferredAction: LifeCounterGameModesAction.openBounty,
          planechaseAvailable: true,
          planechaseActive: true,
          archenemyAvailable: true,
          archenemyActive: true,
          bountyAvailable: true,
          bountyActive: false,
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('life-counter-native-game-modes-limit-warning')),
      findsOneWidget,
    );
    expect(find.text('Encerre um modo ativo primeiro'), findsOneWidget);
    expect(
      find.byKey(const Key('life-counter-native-game-modes-bounty-edit-cards')),
      findsNothing,
    );
    expect(
      find.textContaining(
        'Apenas 2 modos de jogo podem ficar ativos ao mesmo tempo',
      ),
      findsOneWidget,
    );

    await tester.ensureVisible(
      find.byKey(const Key('life-counter-native-game-modes-bounty-open')),
    );
    await tester.tap(
      find.byKey(const Key('life-counter-native-game-modes-bounty-open')),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    expect(result, isNull);
  });
}
