import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/features/home/life_counter/life_counter_settings.dart';
import 'package:manaloom/features/home/life_counter/life_counter_settings_store.dart';
import 'package:manaloom/features/home/life_counter/life_counter_session.dart';
import 'package:manaloom/features/home/life_counter/life_counter_session_store.dart';
import 'package:manaloom/features/home/lotus/lotus_host.dart';
import 'package:manaloom/features/home/lotus/lotus_js_bridges.dart';
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
  Future<void> runJavaScript(String script) async {}

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

Future<void> _captureDebugLogs(
  Future<void> Function(List<String> logs) action,
) async {
  final logs = <String>[];
  final originalDebugPrint = debugPrint;
  debugPrint = (String? message, {int? wrapWidth}) {
    if (message != null) {
      logs.add(message);
    }
  };
  try {
    await action(logs);
  } finally {
    debugPrint = originalDebugPrint;
  }
}

void main() {
  group('LotusLifeCounterScreen internal player values fallback', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('opens native commander damage from shell shortcut', (
      tester,
    ) async {
      late _FakeLotusHost host;
      await _captureDebugLogs((logs) async {
        await tester.binding.setSurfaceSize(const Size(900, 1200));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await LifeCounterSessionStore().save(
          const LifeCounterSession(
            playerCount: 4,
            startingLifeTwoPlayer: 20,
            startingLifeMultiPlayer: 40,
            lives: [40, 32, 25, 11],
            poison: [0, 0, 0, 0],
            energy: [0, 0, 0, 0],
            experience: [0, 0, 0, 0],
            commanderCasts: [0, 0, 0, 0],
            partnerCommanders: [false, true, false, false],
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
          '{"type":"open-native-commander-damage","source":"commander_damage_surface_pressed","targetPlayerIndex":0}',
        );
        await tester.pumpAndSettle();

        expect(find.text('Commander Damage'), findsOneWidget);

        await tester.scrollUntilVisible(
          find.byKey(
            const Key('life-counter-native-commander-damage-plus-1-c1'),
          ),
          250,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(
          find.byKey(
            const Key('life-counter-native-commander-damage-plus-1-c1'),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(const Key('life-counter-native-commander-damage-apply')),
        );
        await tester.pumpAndSettle();

        final session = await LifeCounterSessionStore().load();
        expect(session, isNotNull);
        expect(session!.commanderDamage[0][1], 1);
        expect(
          session.resolvedCommanderDamageDetails[0][1],
          const LifeCounterCommanderDamageDetail(
            commanderOneDamage: 1,
            commanderTwoDamage: 0,
          ),
        );
        expect(host.loadBundleCallCount, 2);
        expect(
          logs.any(
            (message) =>
                message.contains('message=native_commander_damage_opened') &&
                message.contains('surface_strategy: native_fallback'),
          ),
          isTrue,
        );
        expect(
          logs.any(
            (message) =>
                message.contains('message=native_commander_damage_applied') &&
                message.contains('apply_strategy: reload_fallback') &&
                message.contains('live_patch_eligible: false'),
          ),
          isTrue,
        );
      });
    });

    testWidgets(
      'keeps commander damage canonical sync without reload when hidden by settings',
      (tester) async {
        late _FakeLotusHost host;
        await _captureDebugLogs((logs) async {
          await tester.binding.setSurfaceSize(const Size(900, 1200));
          addTearDown(() => tester.binding.setSurfaceSize(null));

          await LifeCounterSettingsStore().save(
            LifeCounterSettings.defaults.copyWith(
              autoKill: false,
              lifeLossOnCommanderDamage: false,
              showCountersOnPlayerCard: false,
              showCommanderDamageCounters: false,
            ),
          );
          await LifeCounterSessionStore().save(
            const LifeCounterSession(
              playerCount: 4,
              startingLifeTwoPlayer: 20,
              startingLifeMultiPlayer: 40,
              lives: [40, 32, 25, 11],
              poison: [0, 0, 0, 0],
              energy: [0, 0, 0, 0],
              experience: [0, 0, 0, 0],
              commanderCasts: [0, 0, 0, 0],
              partnerCommanders: [false, true, false, false],
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
            '{"type":"open-native-commander-damage","source":"commander_damage_surface_pressed","targetPlayerIndex":0}',
          );
          await tester.pumpAndSettle();

          await tester.scrollUntilVisible(
            find.byKey(
              const Key('life-counter-native-commander-damage-plus-1-c1'),
            ),
            250,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.tap(
            find.byKey(
              const Key('life-counter-native-commander-damage-plus-1-c1'),
            ),
          );
          await tester.pumpAndSettle();

          await tester.tap(
            find.byKey(const Key('life-counter-native-commander-damage-apply')),
          );
          await tester.pumpAndSettle();

          final session = await LifeCounterSessionStore().load();
          expect(session, isNotNull);
          expect(session!.commanderDamage[0][1], 1);
          expect(host.loadBundleCallCount, 1);
          expect(
            logs.any(
              (message) =>
                  message.contains('message=native_commander_damage_applied') &&
                  message.contains('apply_strategy: canonical_store_sync') &&
                  message.contains('reload_required: false'),
            ),
            isTrue,
          );
        });
      },
    );

    testWidgets(
      'keeps commander damage on reload fallback when life loss on commander damage stays enabled',
      (tester) async {
        late _FakeLotusHost host;
        await _captureDebugLogs((logs) async {
          await tester.binding.setSurfaceSize(const Size(900, 1200));
          addTearDown(() => tester.binding.setSurfaceSize(null));

          await LifeCounterSettingsStore().save(
            LifeCounterSettings.defaults.copyWith(
              autoKill: false,
              lifeLossOnCommanderDamage: true,
              showCountersOnPlayerCard: false,
              showCommanderDamageCounters: false,
            ),
          );
          await LifeCounterSessionStore().save(
            const LifeCounterSession(
              playerCount: 4,
              startingLifeTwoPlayer: 20,
              startingLifeMultiPlayer: 40,
              lives: [40, 32, 25, 11],
              poison: [0, 0, 0, 0],
              energy: [0, 0, 0, 0],
              experience: [0, 0, 0, 0],
              commanderCasts: [0, 0, 0, 0],
              partnerCommanders: [false, true, false, false],
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
            '{"type":"open-native-commander-damage","source":"commander_damage_surface_pressed","targetPlayerIndex":0}',
          );
          await tester.pumpAndSettle();

          await tester.scrollUntilVisible(
            find.byKey(
              const Key('life-counter-native-commander-damage-plus-1-c1'),
            ),
            250,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.tap(
            find.byKey(
              const Key('life-counter-native-commander-damage-plus-1-c1'),
            ),
          );
          await tester.pumpAndSettle();

          await tester.tap(
            find.byKey(const Key('life-counter-native-commander-damage-apply')),
          );
          await tester.pumpAndSettle();

          final session = await LifeCounterSessionStore().load();
          expect(session, isNotNull);
          expect(session!.commanderDamage[0][1], 1);
          expect(host.loadBundleCallCount, 2);
          expect(
            logs.any(
              (message) =>
                  message.contains('message=native_commander_damage_applied') &&
                  message.contains('apply_strategy: reload_fallback'),
            ),
            isTrue,
          );
        });
      },
    );

    testWidgets('opens native player counter from shell shortcut', (
      tester,
    ) async {
      late _FakeLotusHost host;
      await _captureDebugLogs((logs) async {
        await LifeCounterSessionStore().save(
          const LifeCounterSession(
            playerCount: 4,
            startingLifeTwoPlayer: 20,
            startingLifeMultiPlayer: 40,
            lives: [40, 32, 25, 11],
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
          '{"type":"open-native-player-counter","source":"player_counter_surface_pressed","targetPlayerIndex":0,"counterKey":"poison"}',
        );
        await tester.pumpAndSettle();

        expect(find.text('Player Counter'), findsOneWidget);
        expect(find.text('Player 1 · Poison'), findsOneWidget);

        await tester.scrollUntilVisible(
          find.byKey(const Key('life-counter-native-player-counter-plus')),
          250,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.ensureVisible(
          find.byKey(const Key('life-counter-native-player-counter-plus')),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const Key('life-counter-native-player-counter-plus')),
        );
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(const Key('life-counter-native-player-counter-apply')),
        );
        await tester.pumpAndSettle();

        final session = await LifeCounterSessionStore().load();
        expect(session, isNotNull);
        expect(session!.poison[0], 1);
        expect(host.loadBundleCallCount, 2);
        expect(
          logs.any(
            (message) =>
                message.contains('message=native_player_counter_opened') &&
                message.contains('surface_strategy: native_fallback'),
          ),
          isTrue,
        );
        expect(
          logs.any(
            (message) =>
                message.contains('message=native_player_counter_applied') &&
                message.contains('apply_strategy: reload_fallback') &&
                message.contains('live_patch_eligible: false'),
          ),
          isTrue,
        );
      });
    });

    testWidgets(
      'keeps player counter canonical sync without reload when counters stay hidden',
      (tester) async {
        late _FakeLotusHost host;
        await _captureDebugLogs((logs) async {
          await LifeCounterSettingsStore().save(
            LifeCounterSettings.defaults.copyWith(
              autoKill: false,
              showCountersOnPlayerCard: false,
            ),
          );
          await LifeCounterSessionStore().save(
            const LifeCounterSession(
              playerCount: 4,
              startingLifeTwoPlayer: 20,
              startingLifeMultiPlayer: 40,
              lives: [40, 32, 25, 11],
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
            '{"type":"open-native-player-counter","source":"player_counter_surface_pressed","targetPlayerIndex":0,"counterKey":"poison"}',
          );
          await tester.pumpAndSettle();

          await tester.scrollUntilVisible(
            find.byKey(const Key('life-counter-native-player-counter-plus')),
            250,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.ensureVisible(
            find.byKey(const Key('life-counter-native-player-counter-plus')),
          );
          await tester.pumpAndSettle();
          await tester.tap(
            find.byKey(const Key('life-counter-native-player-counter-plus')),
          );
          await tester.pumpAndSettle();

          await tester.tap(
            find.byKey(const Key('life-counter-native-player-counter-apply')),
          );
          await tester.pumpAndSettle();

          final session = await LifeCounterSessionStore().load();
          expect(session, isNotNull);
          expect(session!.poison[0], 1);
          expect(host.loadBundleCallCount, 1);
          expect(
            logs.any(
              (message) =>
                  message.contains('message=native_player_counter_applied') &&
                  message.contains('apply_strategy: canonical_store_sync') &&
                  message.contains('reload_required: false'),
            ),
            isTrue,
          );
        });
      },
    );

    testWidgets(
      'keeps player counter on reload fallback when counters stay visible on player card',
      (tester) async {
        late _FakeLotusHost host;
        await _captureDebugLogs((logs) async {
          await LifeCounterSettingsStore().save(
            LifeCounterSettings.defaults.copyWith(
              autoKill: false,
              showCountersOnPlayerCard: true,
            ),
          );
          await LifeCounterSessionStore().save(
            const LifeCounterSession(
              playerCount: 4,
              startingLifeTwoPlayer: 20,
              startingLifeMultiPlayer: 40,
              lives: [40, 32, 25, 11],
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
            '{"type":"open-native-player-counter","source":"player_counter_surface_pressed","targetPlayerIndex":0,"counterKey":"poison"}',
          );
          await tester.pumpAndSettle();

          await tester.scrollUntilVisible(
            find.byKey(const Key('life-counter-native-player-counter-plus')),
            250,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.ensureVisible(
            find.byKey(const Key('life-counter-native-player-counter-plus')),
          );
          await tester.pumpAndSettle();
          await tester.tap(
            find.byKey(const Key('life-counter-native-player-counter-plus')),
          );
          await tester.pumpAndSettle();

          await tester.tap(
            find.byKey(const Key('life-counter-native-player-counter-apply')),
          );
          await tester.pumpAndSettle();

          final session = await LifeCounterSessionStore().load();
          expect(session, isNotNull);
          expect(session!.poison[0], 1);
          expect(host.loadBundleCallCount, 2);
          expect(
            logs.any(
              (message) =>
                  message.contains('message=native_player_counter_applied') &&
                  message.contains('apply_strategy: reload_fallback'),
            ),
            isTrue,
          );
        });
      },
    );
  });
}
