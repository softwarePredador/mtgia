import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:manaloom/features/home/life_counter/life_counter_day_night_state_store.dart';
import 'package:manaloom/features/home/life_counter/life_counter_game_timer_state_store.dart';
import 'package:manaloom/features/home/life_counter/life_counter_player_appearance_profile_store.dart';
import 'package:manaloom/features/home/life_counter/life_counter_session_store.dart';
import 'package:manaloom/features/home/life_counter/life_counter_settings_store.dart';
import 'package:manaloom/features/home/lotus/lotus_storage_snapshot_store.dart';
import 'package:manaloom/features/home/lotus_life_counter_screen.dart';

Future<void> _bootLiveLotus(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(900, 1200));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await LotusStorageSnapshotStore().clear();
  await LifeCounterSettingsStore().clear();
  await LifeCounterSessionStore().clear();
  await LifeCounterGameTimerStateStore().clear();
  await LifeCounterDayNightStateStore().clear();
  await LifeCounterPlayerAppearanceProfileStore().clear();

  await tester.pumpWidget(const MaterialApp(home: LotusLifeCounterScreen()));
  await tester.pump();
  await tester.pump(const Duration(seconds: 8));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'opens the ManaLoom-owned game modes shell on the live WebView path',
    (tester) async {
      await _bootLiveLotus(tester);

      final dynamic state = tester.state(find.byType(LotusLifeCounterScreen));
      await state.debugRunJavaScript('''
        (() => {
          const ensureNode = (selector, className) => {
            if (document.querySelector(selector)) {
              return;
            }
            const node = document.createElement('button');
            node.className = className;
            document.body.appendChild(node);
          };
          ensureNode('.planechase-btn', 'planechase-btn');
          ensureNode('.archenemy-btn', 'archenemy-btn');
          ensureNode('.bounty-btn', 'bounty-btn');
        })();
      ''');
      await tester.pump(const Duration(milliseconds: 300));
      await state.debugHandleShellMessage(
        '{"type":"open-native-game-modes","source":"quick_actions_game_modes"}',
      );
      await tester.pumpAndSettle();

      expect(find.text('Game Modes'), findsOneWidget);
      expect(find.text('Planechase'), findsOneWidget);
      expect(find.text('Archenemy'), findsOneWidget);
      expect(find.text('Bounty'), findsOneWidget);
      expect(find.text('Available'), findsNWidgets(3));
    },
  );
}
