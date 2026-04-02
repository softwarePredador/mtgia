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
  Future<void> runJavaScript(String script) async {}

  @override
  Future<Object?> runJavaScriptReturningResult(String script) async {
    executedScripts.add(script);

    if (script.contains('.increase-button.life') ||
        script.contains('.decrease-button.life') ||
        script.contains('.player-card')) {
      return jsonEncode(<String, Object>{'ok': true});
    }

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
  group('LotusLifeCounterScreen internal player state fallback', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('opens native player state from shell shortcut', (
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
          '{"type":"open-native-player-state","source":"player_state_surface_pressed","targetPlayerIndex":1}',
        );
        await tester.pumpAndSettle();

        expect(find.text('Player State'), findsOneWidget);

        await tester.tap(find.text('Partner commander'));
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(
          find.byKey(const Key('life-counter-native-player-state-answerLeft')),
          250,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.ensureVisible(
          find.byKey(const Key('life-counter-native-player-state-answerLeft')),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const Key('life-counter-native-player-state-answerLeft')),
        );
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(const Key('life-counter-native-player-state-apply')),
        );
        await tester.pumpAndSettle();

        final session = await LifeCounterSessionStore().load();
        expect(session, isNotNull);
        expect(session!.partnerCommanders[1], isTrue);
        expect(
          session.playerSpecialStates[1],
          LifeCounterPlayerSpecialState.answerLeft,
        );
        expect(host.loadBundleCallCount, 2);
        expect(
          logs.any(
            (message) =>
                message.contains(
                  'message=native_fallback_surface_requested',
                ) &&
                message.contains('message_type: open-native-player-state') &&
                message.contains(
                  'fallback_classification: ownership_bridge',
                ) &&
                message.contains('target_player_index: 1'),
          ),
          isTrue,
        );
        expect(
          logs.any(
            (message) =>
                message.contains('message=native_player_state_opened') &&
                message.contains('surface_strategy: native_fallback') &&
                message.contains(
                  'fallback_classification: ownership_bridge',
                ),
          ),
          isTrue,
        );
        expect(
          logs.any(
            (message) =>
                message.contains('message=native_player_state_applied') &&
                message.contains('apply_strategy: reload_fallback') &&
                message.contains('live_patch_eligible: false') &&
                message.contains('show_counters_on_player_card_enabled') &&
                message.contains(
                  'session_change_outside_hidden_partner_commander',
                ),
          ),
          isTrue,
        );
      });
    });

    testWidgets(
      'keeps partner commander canonical sync through the player state hub when counters stay hidden',
      (tester) async {
        late _FakeLotusHost host;
        await _captureDebugLogs((logs) async {
          await tester.binding.setSurfaceSize(const Size(900, 1200));
          addTearDown(() => tester.binding.setSurfaceSize(null));

          await LifeCounterSettingsStore().save(
            LifeCounterSettings.defaults.copyWith(
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
            '{"type":"open-native-player-state","source":"player_state_surface_pressed","targetPlayerIndex":1}',
          );
          await tester.pumpAndSettle();

          await tester.tap(find.text('Partner commander'));
          await tester.pumpAndSettle();

          await tester.tap(
            find.byKey(const Key('life-counter-native-player-state-apply')),
          );
          await tester.pumpAndSettle();

          final session = await LifeCounterSessionStore().load();
          expect(session, isNotNull);
          expect(session!.partnerCommanders[1], isTrue);
          expect(
            session.playerSpecialStates[1],
            LifeCounterPlayerSpecialState.none,
          );
          expect(host.loadBundleCallCount, 1);
          expect(
            logs.any(
              (message) =>
                  message.contains('message=native_player_state_applied') &&
                  message.contains('apply_strategy: canonical_store_sync') &&
                  message.contains('reload_required: false') &&
                  message.contains('sync_blockers: []'),
            ),
            isTrue,
          );
        });
      },
    );

    testWidgets(
      'keeps partner commander canonical sync through the player state hub when player cards stay on but regular counters stay hidden',
      (tester) async {
        late _FakeLotusHost host;
        await _captureDebugLogs((logs) async {
          await tester.binding.setSurfaceSize(const Size(900, 1200));
          addTearDown(() => tester.binding.setSurfaceSize(null));

          await LifeCounterSettingsStore().save(
            LifeCounterSettings.defaults.copyWith(
              showCountersOnPlayerCard: true,
              showRegularCounters: false,
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
            '{"type":"open-native-player-state","source":"player_state_surface_pressed","targetPlayerIndex":1}',
          );
          await tester.pumpAndSettle();

          await tester.tap(find.text('Partner commander'));
          await tester.pumpAndSettle();

          await tester.tap(
            find.byKey(const Key('life-counter-native-player-state-apply')),
          );
          await tester.pumpAndSettle();

          final session = await LifeCounterSessionStore().load();
          expect(session, isNotNull);
          expect(session!.partnerCommanders[1], isTrue);
          expect(host.loadBundleCallCount, 1);
          expect(
            logs.any(
              (message) =>
                  message.contains('message=native_player_state_applied') &&
                  message.contains('apply_strategy: canonical_store_sync') &&
                  message.contains('reload_required: false') &&
                  message.contains('sync_blockers: []'),
            ),
            isTrue,
          );
        });
      },
    );

    testWidgets(
      'keeps partner commander on reload fallback through the player state hub when partner background image is present',
      (tester) async {
        late _FakeLotusHost host;
        await _captureDebugLogs((logs) async {
          await tester.binding.setSurfaceSize(const Size(900, 1200));
          addTearDown(() => tester.binding.setSurfaceSize(null));

          await LifeCounterSettingsStore().save(
            LifeCounterSettings.defaults.copyWith(
              showCountersOnPlayerCard: true,
              showRegularCounters: false,
            ),
          );
          await LifeCounterSessionStore().save(
            LifeCounterSession.initial(playerCount: 4).copyWith(
              lives: const [40, 32, 25, 11],
              playerAppearances: const [
                LifeCounterPlayerAppearance(background: 'white'),
                LifeCounterPlayerAppearance(
                  background: 'blue',
                  backgroundImagePartner: 'https://example.com/partner.png',
                ),
                LifeCounterPlayerAppearance(background: 'black'),
                LifeCounterPlayerAppearance(background: 'red'),
              ],
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
            '{"type":"open-native-player-state","source":"player_state_surface_pressed","targetPlayerIndex":1}',
          );
          await tester.pumpAndSettle();

          await tester.tap(find.text('Partner commander'));
          await tester.pumpAndSettle();

          await tester.tap(
            find.byKey(const Key('life-counter-native-player-state-apply')),
          );
          await tester.pumpAndSettle();

          final session = await LifeCounterSessionStore().load();
          expect(session, isNotNull);
          expect(session!.partnerCommanders[1], isTrue);
          expect(host.loadBundleCallCount, 2);
          expect(
            logs.any(
              (message) =>
                  message.contains('message=native_player_state_applied') &&
                  message.contains('apply_strategy: reload_fallback') &&
                  message.contains('partner_background_image_present'),
            ),
            isTrue,
          );
        });
      },
    );

    testWidgets(
      'resets the Lotus player surface after canonical sync apply from option-card takeover',
      (tester) async {
        late _FakeLotusHost host;
        await _captureDebugLogs((logs) async {
          await tester.binding.setSurfaceSize(const Size(900, 1200));
          addTearDown(() => tester.binding.setSurfaceSize(null));

          await LifeCounterSettingsStore().save(
            LifeCounterSettings.defaults.copyWith(
              showCountersOnPlayerCard: true,
              showRegularCounters: false,
            ),
          );
          await LifeCounterSessionStore().save(
            LifeCounterSession.initial(
              playerCount: 4,
            ).copyWith(lives: const [40, 32, 25, 11]),
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
            '{"type":"open-native-player-state","source":"player_option_card_presented","targetPlayerIndex":1}',
          );
          await tester.pumpAndSettle();

          await tester.tap(find.text('Partner commander'));
          await tester.pumpAndSettle();

          await tester.tap(
            find.byKey(const Key('life-counter-native-player-state-apply')),
          );
          await tester.pumpAndSettle();

          final session = await LifeCounterSessionStore().load();
          expect(session, isNotNull);
          expect(session!.partnerCommanders[1], isTrue);
          expect(host.loadBundleCallCount, 2);
          expect(
            logs.any(
              (message) =>
                  message.contains('message=native_player_state_applied') &&
                  message.contains('apply_strategy: canonical_store_sync') &&
                  message.contains('reload_required: false') &&
                  message.contains('surface_reset_required: true') &&
                  message.contains('surface_reset_strategy: bundle_reload'),
            ),
            isTrue,
          );
        });
      },
    );

    testWidgets('rolls player d20 from the player state hub', (tester) async {
      late _FakeLotusHost host;
      await _captureDebugLogs((logs) async {
        await tester.binding.setSurfaceSize(const Size(900, 1200));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await LifeCounterSessionStore().save(
          LifeCounterSession.initial(playerCount: 4),
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
          '{"type":"open-native-player-state","source":"player_state_surface_pressed","targetPlayerIndex":0}',
        );
        await tester.pumpAndSettle();

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

        final session = await LifeCounterSessionStore().load();
        expect(session, isNotNull);
        expect(session!.lastPlayerRolls[0], isNotNull);
        expect(session.lastTableEvent, startsWith('Player 1 rolou D20: '));
        expect(host.loadBundleCallCount, 1);
        expect(
          logs.any(
            (message) =>
                message.contains('message=native_player_state_applied') &&
                message.contains('apply_strategy: canonical_store_sync') &&
                message.contains('reload_required: false') &&
                message.contains('surface_reset_strategy: none') &&
                message.contains('sync_blockers: []'),
          ),
          isTrue,
        );
      });
    });

    testWidgets('opens native set life from shell shortcut', (tester) async {
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
            lastTableEvent: 'D20: 18',
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

        expect(
          find.byKey(const Key('life-counter-native-set-life-apply')),
          findsOneWidget,
        );

        await tester.ensureVisible(
          find.byKey(const Key('life-counter-native-set-life-clear')),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const Key('life-counter-native-set-life-clear')),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const Key('life-counter-native-set-life-digit-4')),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const Key('life-counter-native-set-life-digit-0')),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const Key('life-counter-native-set-life-apply')),
        );
        await tester.pumpAndSettle();

        final session = await LifeCounterSessionStore().load();
        expect(session, isNotNull);
        expect(session!.lives[1], 40);
        expect(session.lastTableEvent, isNull);
        expect(host.loadBundleCallCount, 1);
        expect(
          host.executedScripts.any(
            (script) => script.contains('.increase-button.life'),
          ),
          isTrue,
        );
        expect(
          logs.any(
            (message) =>
                message.contains('message=native_set_life_opened') &&
                message.contains('surface_strategy: native_fallback'),
          ),
          isTrue,
        );
        expect(
          logs.any(
            (message) =>
                message.contains('message=native_set_life_applied') &&
                message.contains('apply_strategy: live_runtime') &&
                message.contains('reload_required: false') &&
                message.contains('sync_blockers: []'),
          ),
          isTrue,
        );
      });
    });

    testWidgets('keeps native set life on fallback above the live delta limit', (
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
            lastTableEvent: 'D20: 18',
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

        await tester.ensureVisible(
          find.byKey(const Key('life-counter-native-set-life-clear')),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const Key('life-counter-native-set-life-clear')),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const Key('life-counter-native-set-life-digit-4')),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const Key('life-counter-native-set-life-digit-5')),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const Key('life-counter-native-set-life-apply')),
        );
        await tester.pumpAndSettle();

        final session = await LifeCounterSessionStore().load();
        expect(session, isNotNull);
        expect(session!.lives[1], 45);
        expect(session.lastTableEvent, isNull);
        expect(host.loadBundleCallCount, 2);
        expect(
          logs.any(
            (message) =>
                message.contains('message=native_set_life_applied') &&
                message.contains('apply_strategy: reload_fallback') &&
                message.contains('reload_required: true') &&
                message.contains(
                  'sync_blockers: [life_delta_exceeds_live_limit]',
                ),
          ),
          isTrue,
        );
      });
    });

    testWidgets('applies short native set life live without reload', (
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
            lastTableEvent: 'D20: 18',
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

        await tester.ensureVisible(
          find.byKey(const Key('life-counter-native-set-life-clear')),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const Key('life-counter-native-set-life-clear')),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const Key('life-counter-native-set-life-digit-3')),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const Key('life-counter-native-set-life-digit-5')),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const Key('life-counter-native-set-life-apply')),
        );
        await tester.pumpAndSettle();

        final session = await LifeCounterSessionStore().load();
        expect(session, isNotNull);
        expect(session!.lives[1], 35);
        expect(session.lastTableEvent, isNull);
        expect(host.loadBundleCallCount, 1);
        expect(
          host.executedScripts.any(
            (script) => script.contains('.increase-button.life'),
          ),
          isTrue,
        );
        expect(
          logs.any(
            (message) =>
                message.contains('message=native_set_life_applied') &&
                message.contains('apply_strategy: live_runtime') &&
                message.contains('reload_required: false') &&
                message.contains('sync_blockers: []'),
          ),
          isTrue,
        );
      });
    });

    testWidgets('opens native set life from the player state hub', (
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
            lastTableEvent: 'D20: 18',
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
          '{"type":"open-native-player-state","source":"player_state_surface_pressed","targetPlayerIndex":1}',
        );
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(
          find.byKey(const Key('life-counter-native-player-state-set-life')),
          250,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.ensureVisible(
          find.byKey(const Key('life-counter-native-player-state-set-life')),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const Key('life-counter-native-player-state-set-life')),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('life-counter-native-set-life-apply')),
          findsOneWidget,
        );

        await tester.ensureVisible(
          find.byKey(const Key('life-counter-native-set-life-clear')),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const Key('life-counter-native-set-life-clear')),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const Key('life-counter-native-set-life-digit-3')),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const Key('life-counter-native-set-life-digit-5')),
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

        final session = await LifeCounterSessionStore().load();
        expect(session, isNotNull);
        expect(session!.lives[1], 35);
        expect(session.lastTableEvent, isNull);
        expect(host.loadBundleCallCount, 1);
        expect(
          host.executedScripts.any(
            (script) => script.contains('.increase-button.life'),
          ),
          isTrue,
        );
        expect(
          logs.any(
            (message) =>
                message.contains('message=native_player_state_applied') &&
                message.contains('apply_strategy: live_runtime') &&
                message.contains('reload_required: false') &&
                message.contains('sync_blockers: []'),
          ),
          isTrue,
        );
      });
    });

    testWidgets(
      'keeps hidden player counter canonical sync through the player state hub',
      (tester) async {
        late _FakeLotusHost host;
        await _captureDebugLogs((logs) async {
          await tester.binding.setSurfaceSize(const Size(900, 1200));
          addTearDown(() => tester.binding.setSurfaceSize(null));

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
            '{"type":"open-native-player-state","source":"player_state_surface_pressed","targetPlayerIndex":0}',
          );
          await tester.pumpAndSettle();

          await tester.scrollUntilVisible(
            find.byKey(
              const Key('life-counter-native-player-state-manage-counters'),
            ),
            250,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.ensureVisible(
            find.byKey(
              const Key('life-counter-native-player-state-manage-counters'),
            ),
          );
          await tester.pumpAndSettle();
          await tester.tap(
            find.byKey(
              const Key('life-counter-native-player-state-manage-counters'),
            ),
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

          expect(find.text('Player State'), findsOneWidget);

          await tester.tap(
            find.byKey(const Key('life-counter-native-player-state-apply')),
          );
          await tester.pumpAndSettle();

          final session = await LifeCounterSessionStore().load();
          expect(session, isNotNull);
          expect(session!.poison[0], 1);
          expect(host.loadBundleCallCount, 1);
          expect(
            logs.any(
              (message) =>
                  message.contains('message=native_player_state_applied') &&
                  message.contains('apply_strategy: canonical_store_sync') &&
                  message.contains('reload_required: false') &&
                  message.contains('sync_blockers: []'),
            ),
            isTrue,
          );
        });
      },
    );

    testWidgets(
      'keeps hidden player counter canonical sync through the player state hub when player cards stay on but regular counters stay hidden',
      (tester) async {
        late _FakeLotusHost host;
        await _captureDebugLogs((logs) async {
          await tester.binding.setSurfaceSize(const Size(900, 1200));
          addTearDown(() => tester.binding.setSurfaceSize(null));

          await LifeCounterSettingsStore().save(
            LifeCounterSettings.defaults.copyWith(
              autoKill: false,
              showCountersOnPlayerCard: true,
              showRegularCounters: false,
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
            '{"type":"open-native-player-state","source":"player_state_surface_pressed","targetPlayerIndex":0}',
          );
          await tester.pumpAndSettle();

          await tester.scrollUntilVisible(
            find.byKey(
              const Key('life-counter-native-player-state-manage-counters'),
            ),
            250,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.ensureVisible(
            find.byKey(
              const Key('life-counter-native-player-state-manage-counters'),
            ),
          );
          await tester.pumpAndSettle();
          await tester.tap(
            find.byKey(
              const Key('life-counter-native-player-state-manage-counters'),
            ),
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

          expect(find.text('Player State'), findsOneWidget);

          await tester.tap(
            find.byKey(const Key('life-counter-native-player-state-apply')),
          );
          await tester.pumpAndSettle();

          final session = await LifeCounterSessionStore().load();
          expect(session, isNotNull);
          expect(session!.poison[0], 1);
          expect(host.loadBundleCallCount, 1);
          expect(
            logs.any(
              (message) =>
                  message.contains('message=native_player_state_applied') &&
                  message.contains('apply_strategy: canonical_store_sync') &&
                  message.contains('reload_required: false') &&
                  message.contains('sync_blockers: []'),
            ),
            isTrue,
          );
        });
      },
    );

    testWidgets(
      'keeps hidden commander damage canonical sync through the player state hub',
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
            '{"type":"open-native-player-state","source":"player_state_surface_pressed","targetPlayerIndex":0}',
          );
          await tester.pumpAndSettle();

          await tester.scrollUntilVisible(
            find.byKey(
              const Key(
                'life-counter-native-player-state-manage-commander-damage',
              ),
            ),
            250,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.ensureVisible(
            find.byKey(
              const Key(
                'life-counter-native-player-state-manage-commander-damage',
              ),
            ),
          );
          await tester.pumpAndSettle();
          await tester.tap(
            find.byKey(
              const Key(
                'life-counter-native-player-state-manage-commander-damage',
              ),
            ),
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

          expect(find.text('Player State'), findsOneWidget);

          await tester.tap(
            find.byKey(const Key('life-counter-native-player-state-apply')),
          );
          await tester.pumpAndSettle();

          final session = await LifeCounterSessionStore().load();
          expect(session, isNotNull);
          expect(session!.commanderDamage[0][1], 1);
          expect(host.loadBundleCallCount, 1);
          expect(
            logs.any(
              (message) =>
                  message.contains('message=native_player_state_applied') &&
                  message.contains('apply_strategy: canonical_store_sync') &&
                  message.contains('reload_required: false') &&
                  message.contains('sync_blockers: []'),
            ),
            isTrue,
          );
        });
      },
    );

    testWidgets(
      'keeps hidden commander damage canonical sync through the player state hub when player cards stay on but commander damage counters stay hidden',
      (tester) async {
        late _FakeLotusHost host;
        await _captureDebugLogs((logs) async {
          await tester.binding.setSurfaceSize(const Size(900, 1200));
          addTearDown(() => tester.binding.setSurfaceSize(null));

          await LifeCounterSettingsStore().save(
            LifeCounterSettings.defaults.copyWith(
              autoKill: false,
              lifeLossOnCommanderDamage: false,
              showCountersOnPlayerCard: true,
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
            '{"type":"open-native-player-state","source":"player_state_surface_pressed","targetPlayerIndex":0}',
          );
          await tester.pumpAndSettle();

          await tester.scrollUntilVisible(
            find.byKey(
              const Key(
                'life-counter-native-player-state-manage-commander-damage',
              ),
            ),
            250,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.ensureVisible(
            find.byKey(
              const Key(
                'life-counter-native-player-state-manage-commander-damage',
              ),
            ),
          );
          await tester.pumpAndSettle();
          await tester.tap(
            find.byKey(
              const Key(
                'life-counter-native-player-state-manage-commander-damage',
              ),
            ),
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

          expect(find.text('Player State'), findsOneWidget);

          await tester.tap(
            find.byKey(const Key('life-counter-native-player-state-apply')),
          );
          await tester.pumpAndSettle();

          final session = await LifeCounterSessionStore().load();
          expect(session, isNotNull);
          expect(session!.commanderDamage[0][1], 1);
          expect(host.loadBundleCallCount, 1);
          expect(
            logs.any(
              (message) =>
                  message.contains('message=native_player_state_applied') &&
                  message.contains('apply_strategy: canonical_store_sync') &&
                  message.contains('reload_required: false') &&
                  message.contains('sync_blockers: []'),
            ),
            isTrue,
          );
        });
      },
    );

    testWidgets(
      'resets the Lotus player surface when native player state is dismissed from option-card takeover',
      (tester) async {
        late _FakeLotusHost host;
        await _captureDebugLogs((logs) async {
          await LifeCounterSessionStore().save(
            LifeCounterSession.initial(playerCount: 4),
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
            '{"type":"open-native-player-state","source":"player_option_card_presented","targetPlayerIndex":2}',
          );
          await tester.pumpAndSettle();

          expect(find.text('Player State'), findsOneWidget);

          await tester.tap(find.text('Cancel'));
          await tester.pumpAndSettle();

          expect(find.text('Player State'), findsNothing);
          expect(host.loadBundleCallCount, 2);
          expect(
            logs.any(
              (message) =>
                  message.contains('message=native_player_state_dismissed') &&
                  message.contains('source: player_option_card_presented') &&
                  message.contains('changed: false') &&
                  message.contains('surface_reset_required: true') &&
                  message.contains('surface_reset_strategy: bundle_reload'),
            ),
            isTrue,
          );
        });
      },
    );
  });
}
