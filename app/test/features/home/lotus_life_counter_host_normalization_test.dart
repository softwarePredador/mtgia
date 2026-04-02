import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/features/home/life_counter/life_counter_session.dart';
import 'package:manaloom/features/home/life_counter/life_counter_session_store.dart';
import 'package:manaloom/features/home/life_counter/life_counter_settings.dart';
import 'package:manaloom/features/home/life_counter/life_counter_settings_store.dart';
import 'package:manaloom/features/home/lotus/lotus_host.dart';
import 'package:manaloom/features/home/lotus/lotus_js_bridges.dart';
import 'package:manaloom/features/home/lotus/lotus_life_counter_session_adapter.dart';
import 'package:manaloom/features/home/lotus/lotus_storage_snapshot_store.dart';
import 'package:manaloom/features/home/lotus_life_counter_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeLotusHost implements LotusHost {
  _FakeLotusHost({required this.onShellMessageRequested});

  final LotusShellMessageCallback onShellMessageRequested;

  @override
  final ValueNotifier<bool> isLoading = ValueNotifier<bool>(true);

  @override
  final ValueNotifier<String?> errorMessage = ValueNotifier<String?>(null);

  int loadBundleCallCount = 0;
  final List<String> executedScripts = <String>[];

  @override
  Widget buildView(BuildContext context) {
    return const ColoredBox(
      key: Key('fake-lotus-host-view'),
      color: Colors.black,
    );
  }

  @override
  void suppressStaleBeforeUnloadSnapshot() {}

  @override
  Future<void> loadBundle() async {
    loadBundleCallCount += 1;
  }

  @override
  Future<void> runJavaScript(String script) async {
    executedScripts.add(script);
  }

  @override
  Future<Object?> runJavaScriptReturningResult(String script) async {
    return jsonEncode(<String, Object>{
      'planechaseAvailable': true,
      'planechaseActive': false,
      'planechaseCardPoolActive': false,
      'archenemyAvailable': true,
      'archenemyActive': false,
      'archenemyCardPoolActive': false,
      'bountyAvailable': true,
      'bountyActive': false,
      'bountyCardPoolActive': false,
      'maxActiveModes': 2,
    });
  }

  void completeSuccessfulLoad() {
    errorMessage.value = null;
    isLoading.value = false;
  }

  void emitShellMessage(String message) {
    onShellMessageRequested(message);
  }

  @override
  void dispose() {
    isLoading.dispose();
    errorMessage.dispose();
  }
}

void main() {
  group('LotusLifeCounterScreen host normalization', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets(
      'sanitizes stale table state ownership and tracker pointers when table state is applied',
      (tester) async {
        late _FakeLotusHost host;
        await tester.binding.setSurfaceSize(const Size(900, 1200));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await LifeCounterSettingsStore().save(
          LifeCounterSettings.defaults.copyWith(autoKill: true),
        );
        await LifeCounterSessionStore().save(
          const LifeCounterSession(
            playerCount: 4,
            startingLifeTwoPlayer: 20,
            startingLifeMultiPlayer: 40,
            lives: [40, 0, 40, 40],
            poison: [0, 0, 0, 0],
            energy: [0, 0, 0, 0],
            experience: [0, 0, 0, 0],
            commanderCasts: [0, 0, 0, 0],
            partnerCommanders: [false, false, false, false],
            playerSpecialStates: [
              LifeCounterPlayerSpecialState.none,
              LifeCounterPlayerSpecialState.none,
              LifeCounterPlayerSpecialState.none,
              LifeCounterPlayerSpecialState.none,
            ],
            lastPlayerRolls: [null, null, null, null],
            lastHighRolls: [null, null, null, null],
            commanderDamage: [
              [0, 0, 0, 0],
              [0, 0, 0, 0],
              [0, 0, 0, 0],
              [0, 0, 0, 0],
            ],
            stormCount: 0,
            monarchPlayer: 1,
            initiativePlayer: 2,
            firstPlayerIndex: 1,
            turnTrackerActive: true,
            turnTrackerOngoingGame: true,
            turnTrackerAutoHighRoll: false,
            currentTurnPlayerIndex: 1,
            currentTurnNumber: 4,
            turnTimerActive: false,
            turnTimerSeconds: 0,
            lastTableEvent: null,
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: LotusLifeCounterScreen(
              hostFactory: ({
                required onAppReviewRequested,
                required onShellMessageRequested,
              }) {
                host = _FakeLotusHost(
                  onShellMessageRequested: onShellMessageRequested,
                )..completeSuccessfulLoad();
                return host;
              },
            ),
          ),
        );

        await tester.pump();
        await tester.pump();

        host.emitShellMessage(
          '{"type":"open-native-table-state","source":"monarch_surface_pressed"}',
        );
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(
          find.byKey(const Key('life-counter-native-table-state-storm-plus')),
          250,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.ensureVisible(
          find.byKey(const Key('life-counter-native-table-state-storm-plus')),
        );
        await tester.tap(
          find.byKey(const Key('life-counter-native-table-state-storm-plus')),
        );
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(const Key('life-counter-native-table-state-apply')),
        );
        await tester.pumpAndSettle();

        final session = await LifeCounterSessionStore().load();
        expect(session, isNotNull);
        expect(session!.stormCount, 1);
        expect(session.monarchPlayer, isNull);
        expect(session.initiativePlayer, 2);
        expect(session.firstPlayerIndex, 2);
        expect(session.currentTurnPlayerIndex, 2);
        expect(host.loadBundleCallCount, 2);
      },
    );

    testWidgets(
      'clears monarch ownership when auto-kill removes that player from the table',
      (tester) async {
        late _FakeLotusHost host;
        await tester.binding.setSurfaceSize(const Size(900, 1200));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await LifeCounterSettingsStore().save(
          LifeCounterSettings.defaults.copyWith(autoKill: true),
        );
        await LifeCounterSessionStore().save(
          const LifeCounterSession(
            playerCount: 4,
            startingLifeTwoPlayer: 20,
            startingLifeMultiPlayer: 40,
            lives: [40, 5, 25, 11],
            poison: [0, 0, 0, 0],
            energy: [0, 0, 0, 0],
            experience: [0, 0, 0, 0],
            commanderCasts: [0, 0, 0, 0],
            partnerCommanders: [false, false, false, false],
            playerSpecialStates: [
              LifeCounterPlayerSpecialState.none,
              LifeCounterPlayerSpecialState.none,
              LifeCounterPlayerSpecialState.none,
              LifeCounterPlayerSpecialState.none,
            ],
            lastPlayerRolls: [null, null, null, null],
            lastHighRolls: [null, null, null, null],
            commanderDamage: [
              [0, 0, 0, 0],
              [0, 0, 0, 0],
              [0, 0, 0, 0],
              [0, 0, 0, 0],
            ],
            stormCount: 0,
            monarchPlayer: 1,
            initiativePlayer: null,
            firstPlayerIndex: null,
            turnTrackerActive: false,
            turnTrackerOngoingGame: false,
            turnTrackerAutoHighRoll: false,
            currentTurnPlayerIndex: null,
            currentTurnNumber: 1,
            turnTimerActive: false,
            turnTimerSeconds: 0,
            lastTableEvent: null,
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: LotusLifeCounterScreen(
              hostFactory: ({
                required onAppReviewRequested,
                required onShellMessageRequested,
              }) {
                host = _FakeLotusHost(
                  onShellMessageRequested: onShellMessageRequested,
                )..completeSuccessfulLoad();
                return host;
              },
            ),
          ),
        );

        await tester.pump();
        await tester.pump();

        host.emitShellMessage(
          '{"type":"open-native-set-life","source":"player_life_total_surface_pressed","targetPlayerIndex":1}',
        );
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(const Key('life-counter-native-set-life-adjust-minus-10')),
        );
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(const Key('life-counter-native-set-life-apply')),
        );
        await tester.pumpAndSettle();

        final session = await LifeCounterSessionStore().load();
        expect(session, isNotNull);
        expect(session!.lives[1], 0);
        expect(session.monarchPlayer, isNull);
        expect(host.loadBundleCallCount, 2);
      },
    );

    testWidgets(
      'reassigns turn tracker pointers when auto-kill removes the current tracked player',
      (tester) async {
        late _FakeLotusHost host;
        await tester.binding.setSurfaceSize(const Size(900, 1200));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await LifeCounterSettingsStore().save(
          LifeCounterSettings.defaults.copyWith(autoKill: true),
        );
        await LifeCounterSessionStore().save(
          const LifeCounterSession(
            playerCount: 4,
            startingLifeTwoPlayer: 20,
            startingLifeMultiPlayer: 40,
            lives: [40, 40, 5, 11],
            poison: [0, 0, 0, 0],
            energy: [0, 0, 0, 0],
            experience: [0, 0, 0, 0],
            commanderCasts: [0, 0, 0, 0],
            partnerCommanders: [false, false, false, false],
            playerSpecialStates: [
              LifeCounterPlayerSpecialState.none,
              LifeCounterPlayerSpecialState.none,
              LifeCounterPlayerSpecialState.none,
              LifeCounterPlayerSpecialState.none,
            ],
            lastPlayerRolls: [null, null, null, null],
            lastHighRolls: [null, null, null, null],
            commanderDamage: [
              [0, 0, 0, 0],
              [0, 0, 0, 0],
              [0, 0, 0, 0],
              [0, 0, 0, 0],
            ],
            stormCount: 0,
            monarchPlayer: null,
            initiativePlayer: null,
            firstPlayerIndex: 2,
            turnTrackerActive: true,
            turnTrackerOngoingGame: true,
            turnTrackerAutoHighRoll: false,
            currentTurnPlayerIndex: 2,
            currentTurnNumber: 4,
            turnTimerActive: true,
            turnTimerSeconds: 19,
            lastTableEvent: null,
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: LotusLifeCounterScreen(
              hostFactory: ({
                required onAppReviewRequested,
                required onShellMessageRequested,
              }) {
                host = _FakeLotusHost(
                  onShellMessageRequested: onShellMessageRequested,
                )..completeSuccessfulLoad();
                return host;
              },
            ),
          ),
        );

        await tester.pump();
        await tester.pump();

        host.emitShellMessage(
          '{"type":"open-native-set-life","source":"player_life_total_surface_pressed","targetPlayerIndex":2}',
        );
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(const Key('life-counter-native-set-life-adjust-minus-10')),
        );
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(const Key('life-counter-native-set-life-apply')),
        );
        await tester.pumpAndSettle();

        final session = await LifeCounterSessionStore().load();
        expect(session, isNotNull);
        expect(session!.lives[2], 0);
        expect(session.currentTurnPlayerIndex, 3);
        expect(session.firstPlayerIndex, 3);
        expect(session.currentTurnNumber, 4);
        expect(session.turnTimerSeconds, 19);
        final snapshot = await LotusStorageSnapshotStore().load();
        expect(snapshot, isNotNull);
        final snapshotSession = LotusLifeCounterSessionAdapter.tryBuildSession(
          snapshot!,
        );
        expect(snapshotSession, isNotNull);
        expect(snapshotSession!.currentTurnPlayerIndex, 3);
        expect(snapshotSession.firstPlayerIndex, 3);
        expect(host.loadBundleCallCount, 2);
      },
    );
  });
}
