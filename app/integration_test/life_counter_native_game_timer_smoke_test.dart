import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:manaloom/features/home/life_counter/life_counter_game_timer_state.dart';
import 'package:manaloom/features/home/life_counter/life_counter_game_timer_state_store.dart';
import 'package:manaloom/features/home/lotus/lotus_storage_snapshot.dart';
import 'package:manaloom/features/home/lotus/lotus_storage_snapshot_store.dart';
import 'package:manaloom/features/home/lotus_life_counter_screen.dart';

Future<LifeCounterGameTimerState?> _pumpUntilPausedStateAvailable(
  WidgetTester tester,
  LifeCounterGameTimerStateStore store,
) async {
  LifeCounterGameTimerState? state = await store.load();
  for (
    var attempt = 0;
    attempt < 20 && (state == null || !state.isPaused);
    attempt += 1
  ) {
    await tester.pump(const Duration(seconds: 1));
    state = await store.load();
  }
  return state;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'opens the ManaLoom-owned native game timer on the live WebView path',
    (tester) async {
      await LifeCounterGameTimerStateStore().save(
        const LifeCounterGameTimerState(
          startTimeEpochMs: 1_000,
          isPaused: false,
          pausedTimeEpochMs: null,
        ),
      );
      await LotusStorageSnapshotStore().save(
        const LotusStorageSnapshot(
          values: {
            'gameTimerState':
                '{"startTime":1000,"isPaused":false,"pausedTime":0}',
          },
        ),
      );

      await tester.pumpWidget(
        const MaterialApp(home: LotusLifeCounterScreen()),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 8));

      final dynamic state = tester.state(find.byType(LotusLifeCounterScreen));
      await state.debugHandleShellMessage(
        '{"type":"open-native-game-timer","source":"game_timer_surface_pressed"}',
      );
      await tester.pumpAndSettle();

      expect(find.text('Game Timer'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.byKey(const Key('life-counter-native-game-timer-pause')),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(
        find.byKey(const Key('life-counter-native-game-timer-pause')),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('life-counter-native-game-timer-apply')),
      );
      await tester.pumpAndSettle();

      final updatedState = await _pumpUntilPausedStateAvailable(
        tester,
        LifeCounterGameTimerStateStore(),
      );
      expect(updatedState, isNotNull);
      expect(updatedState!.isActive, isTrue);
      expect(updatedState.isPaused, isTrue);
      expect(updatedState.pausedTimeEpochMs, isNotNull);
    },
  );
}
