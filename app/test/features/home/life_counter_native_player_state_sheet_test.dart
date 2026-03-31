import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/features/home/life_counter/life_counter_native_commander_damage_sheet.dart';
import 'package:manaloom/features/home/life_counter/life_counter_native_player_state_sheet.dart';
import 'package:manaloom/features/home/life_counter/life_counter_session.dart';

class _Host extends StatelessWidget {
  const _Host({required this.initialSession, required this.onResult});

  final LifeCounterSession initialSession;
  final ValueChanged<LifeCounterSession?> onResult;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) {
            return Center(
              child: ElevatedButton(
                onPressed: () async {
                  final result = await showLifeCounterNativePlayerStateSheet(
                    context,
                    initialSession: initialSession,
                    initialTargetPlayerIndex: 0,
                  );
                  onResult(result);
                },
                child: const Text('Open'),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CommanderDamageHost extends StatelessWidget {
  const _CommanderDamageHost({
    required this.initialSession,
    required this.onResult,
  });

  final LifeCounterSession initialSession;
  final ValueChanged<LifeCounterSession?> onResult;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) {
            return Center(
              child: ElevatedButton(
                onPressed: () async {
                  final result = await showLifeCounterNativeCommanderDamageSheet(
                    context,
                    initialSession: initialSession,
                    initialTargetPlayerIndex: 0,
                  );
                  onResult(result);
                },
                child: const Text('Open'),
              ),
            );
          },
        ),
      ),
    );
  }
}

void main() {
  group('LifeCounterNativePlayerStateSheet', () {
    testWidgets('opens the nested set life hub and applies the new total', (
      tester,
    ) async {
      LifeCounterSession? result;

      await tester.pumpWidget(
        _Host(
          initialSession: LifeCounterSession.initial(playerCount: 4),
          onResult: (value) => result = value,
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Player State'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.byKey(const Key('life-counter-native-player-state-set-life')),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(
        find.byKey(const Key('life-counter-native-player-state-set-life')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('life-counter-native-set-life-apply')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const Key('life-counter-native-set-life-clear')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('life-counter-native-set-life-digit-3')),
      );
      await tester.tap(
        find.byKey(const Key('life-counter-native-set-life-digit-7')),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('life-counter-native-set-life-apply')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Player State'), findsOneWidget);

      await tester.tap(
        find.byKey(const Key('life-counter-native-player-state-apply')),
      );
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.lives[0], 37);
      expect(result!.lastTableEvent, isNull);
    });

    testWidgets('opens the nested player counter hub and returns to state', (
      tester,
    ) async {
      LifeCounterSession? result;

      await tester.pumpWidget(
        _Host(
          initialSession: LifeCounterSession.initial(playerCount: 4),
          onResult: (value) => result = value,
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Player State'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.byKey(
          const Key('life-counter-native-player-state-manage-counters'),
        ),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(
        find.byKey(
          const Key('life-counter-native-player-state-manage-counters'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Player Counter'), findsOneWidget);

      await tester.tap(find.text('Cancel').last);
      await tester.pumpAndSettle();

      expect(find.text('Player State'), findsOneWidget);

      await tester.tap(
        find.byKey(const Key('life-counter-native-player-state-apply')),
      );
      await tester.pumpAndSettle();

      expect(result, isNotNull);
    });

    testWidgets(
      'opens the nested commander damage hub and returns to state',
      (tester) async {
        LifeCounterSession? result;

        await tester.pumpWidget(
          _Host(
            initialSession: LifeCounterSession.initial(
              playerCount: 4,
            ).copyWith(
              partnerCommanders: const [false, true, false, false],
            ),
            onResult: (value) => result = value,
          ),
        );

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        expect(find.text('Player State'), findsOneWidget);

        await tester.scrollUntilVisible(
          find.byKey(
            const Key(
              'life-counter-native-player-state-manage-commander-damage',
            ),
          ),
          250,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(
          find.byKey(
            const Key(
              'life-counter-native-player-state-manage-commander-damage',
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(
            const Key('life-counter-native-commander-damage-apply'),
          ),
          findsOneWidget,
        );

        await tester.tap(find.text('Cancel').last);
        await tester.pumpAndSettle();

        expect(find.text('Player State'), findsOneWidget);

        await tester.tap(
          find.byKey(const Key('life-counter-native-player-state-apply')),
        );
        await tester.pumpAndSettle();

        expect(result, isNotNull);
      },
    );

    testWidgets('applies split commander damage through the native shell', (
      tester,
    ) async {
      LifeCounterSession? result;
      await tester.binding.setSurfaceSize(const Size(900, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _CommanderDamageHost(
          initialSession: LifeCounterSession.initial(
            playerCount: 4,
          ).copyWith(partnerCommanders: const [false, true, false, false]),
          onResult: (value) => result = value,
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(
        find.byKey(
          const Key('life-counter-native-commander-damage-plus-1-c1'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(
          const Key('life-counter-native-commander-damage-plus-1-c1'),
        ),
      );
      await tester.tap(
        find.byKey(
          const Key('life-counter-native-commander-damage-plus-1-c1'),
        ),
      );
      await tester.tap(
        find.byKey(
          const Key('life-counter-native-commander-damage-plus-1-c2'),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('life-counter-native-commander-damage-apply')),
      );
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.commanderDamage[0][1], 3);
      expect(
        result!.resolvedCommanderDamageDetails[0][1],
        const LifeCounterCommanderDamageDetail(
          commanderOneDamage: 2,
          commanderTwoDamage: 1,
        ),
      );
    });

    testWidgets('opens the nested player appearance hub and returns to state', (
      tester,
    ) async {
      LifeCounterSession? result;

      await tester.pumpWidget(
        _Host(
          initialSession: LifeCounterSession.initial(playerCount: 4),
          onResult: (value) => result = value,
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Player State'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.byKey(
          const Key('life-counter-native-player-state-manage-appearance'),
        ),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(
        find.byKey(
          const Key('life-counter-native-player-state-manage-appearance'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(
          const Key('life-counter-native-player-state-manage-appearance'),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(
          const Key('life-counter-native-player-appearance-apply'),
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Cancel').last);
      await tester.pumpAndSettle();

      expect(find.text('Player State'), findsOneWidget);

      await tester.tap(
        find.byKey(const Key('life-counter-native-player-state-apply')),
      );
      await tester.pumpAndSettle();

      expect(result, isNotNull);
    });

    testWidgets('rolls player d20 from the player state hub', (tester) async {
      LifeCounterSession? result;

      await tester.pumpWidget(
        _Host(
          initialSession: LifeCounterSession.initial(playerCount: 4),
          onResult: (value) => result = value,
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Player State'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.byKey(const Key('life-counter-native-player-state-roll-d20')),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(
        find.byKey(const Key('life-counter-native-player-state-roll-d20')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('life-counter-native-player-state-roll-d20')),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(
        find.byKey(const Key('life-counter-native-player-state-apply')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('life-counter-native-player-state-apply')),
      );
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.lastPlayerRolls[0], isNotNull);
      expect(result!.lastTableEvent, startsWith('Player 1 rolou D20: '));
    });
  });
}
