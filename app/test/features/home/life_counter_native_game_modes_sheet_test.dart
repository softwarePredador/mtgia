import 'package:flutter/material.dart';
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

    expect(find.text('Game Modes'), findsOneWidget);
    expect(find.text('Planechase'), findsOneWidget);
    expect(find.text('Archenemy'), findsOneWidget);
    expect(find.text('Bounty'), findsOneWidget);
    expect(find.text('Available'), findsNWidgets(2));
    expect(find.text('Unavailable'), findsOneWidget);
    expect(find.text('Active Now'), findsOneWidget);
    expect(find.text('Card Pool Open'), findsOneWidget);
    expect(find.text('Selected Surface'), findsOneWidget);
    expect(
      find.text('An embedded overlay for this mode is already open in the current game.'),
      findsOneWidget,
    );
    expect(
      find.text(
        'The embedded card pool editor for this mode is already open in the current game.',
      ),
      findsOneWidget,
    );
    expect(find.text('Return To Embedded Card Pool'), findsOneWidget);
    expect(find.text('Edit Card Pool'), findsNWidgets(2));
    expect(find.text('Close Embedded Overlay'), findsOneWidget);
    expect(find.text('Close Embedded Card Pool'), findsOneWidget);

    await tester.ensureVisible(
      find.byKey(const Key('life-counter-native-game-modes-planechase-info')),
    );
    await tester.tap(
      find.byKey(const Key('life-counter-native-game-modes-planechase-info')),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    expect(find.text('Quick Rules'), findsOneWidget);
    expect(
      find.text(
        'Tip: long-press the Planechase button to roll the planar die instantly.',
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

    expect(find.text('Continue To Embedded Card Pool'), findsOneWidget);
    expect(
      find.textContaining('embedded Planechase card pool editor'),
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
      MaterialApp(
        home: _GameModesHost(
          onResult: (value) => result = value,
        ),
      ),
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

  testWidgets('offers explicit close action for active overlays', (tester) async {
    LifeCounterGameModesAction? result;

    await tester.pumpWidget(
      MaterialApp(
        home: _GameModesHost(
          onResult: (value) => result = value,
        ),
      ),
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

    expect(find.text('Selected Surface'), findsOneWidget);
    expect(find.text('Not Available Right Now'), findsOneWidget);
    expect(find.text('Open Settings'), findsOneWidget);

    await tester.ensureVisible(
      find.byKey(const Key('life-counter-native-game-modes-archenemy-settings')),
    );
    await tester.tap(
      find.byKey(const Key('life-counter-native-game-modes-archenemy-settings')),
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
    expect(find.text('Close One Active Mode First'), findsOneWidget);
    expect(
      find.byKey(const Key('life-counter-native-game-modes-bounty-edit-cards')),
      findsNothing,
    );
    expect(
      find.textContaining('Lotus only allows 2 active game modes at once'),
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
