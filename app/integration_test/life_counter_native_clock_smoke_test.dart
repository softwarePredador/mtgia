import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:manaloom/features/home/life_counter/life_counter_game_timer_state_store.dart';
import 'package:manaloom/features/home/life_counter/life_counter_session.dart';
import 'package:manaloom/features/home/life_counter/life_counter_session_store.dart';
import 'package:manaloom/features/home/life_counter/life_counter_settings.dart';
import 'package:manaloom/features/home/life_counter/life_counter_settings_store.dart';
import 'package:manaloom/features/home/lotus/lotus_storage_snapshot_store.dart';
import 'package:manaloom/features/home/lotus/lotus_ui_snapshot_store.dart';
import 'package:manaloom/features/home/lotus_life_counter_screen.dart';

Future<void> _pumpUntilUiSnapshotAvailable(
  WidgetTester tester,
  LotusUiSnapshotStore uiSnapshotStore,
) async {
  var snapshot = await uiSnapshotStore.load();
  for (var attempt = 0; attempt < 20 && snapshot == null; attempt += 1) {
    await tester.pump(const Duration(seconds: 1));
    snapshot = await uiSnapshotStore.load();
  }
  expect(snapshot, isNotNull);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'opens the ManaLoom-owned timer sheet from a clock-only tabletop state',
    (tester) async {
      final snapshotStore = LotusStorageSnapshotStore();
      final uiSnapshotStore = LotusUiSnapshotStore();
      await snapshotStore.clear();
      await uiSnapshotStore.clear();
      await LifeCounterGameTimerStateStore().clear();
      await LifeCounterSessionStore().save(
        LifeCounterSession.initial(playerCount: 4),
      );
      await LifeCounterSettingsStore().save(
        const LifeCounterSettings(
          autoKill: true,
          lifeLossOnCommanderDamage: true,
          showCountersOnPlayerCard: true,
          showRegularCounters: true,
          showCommanderDamageCounters: false,
          clickableCommanderDamageCounters: false,
          keepZeroCountersOnPlayerCard: false,
          saltyDefeatMessages: true,
          cycleSaltyDefeatMessages: true,
          gameTimer: false,
          gameTimerMainScreen: false,
          showClockOnMainScreen: true,
          randomPlayerColors: false,
          preserveBackgroundImagesOnShuffle: true,
          setLifeByTappingNumber: true,
          verticalTapAreas: false,
          cleanLook: false,
          criticalDamageWarning: true,
          customLongTapEnabled: false,
          customLongTapValue: 10,
          whitelabelIcon: null,
        ),
      );

      await tester.pumpWidget(
        const MaterialApp(home: LotusLifeCounterScreen()),
      );
      await tester.pump();

      await _pumpUntilUiSnapshotAvailable(tester, uiSnapshotStore);
      final snapshot = await uiSnapshotStore.load();
      expect(snapshot, isNotNull);
      expect(snapshot!.clockCount, 1);
      expect(snapshot.clockWithGameTimerCount, 0);
      expect(snapshot.gameTimerCount, 0);

      final dynamic state = tester.state(find.byType(LotusLifeCounterScreen));
      await state.debugHandleShellMessage(
        '{"type":"open-native-game-timer","source":"clock_surface_pressed"}',
      );
      await tester.pumpAndSettle();

      expect(find.text('Game Timer'), findsOneWidget);
    },
  );
}
