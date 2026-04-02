import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:manaloom/features/home/life_counter/life_counter_player_appearance_profile_store.dart';
import 'package:manaloom/features/home/life_counter/life_counter_player_appearance_transfer.dart';
import 'package:manaloom/features/home/life_counter/life_counter_session.dart';
import 'package:manaloom/features/home/life_counter/life_counter_session_store.dart';
import 'package:manaloom/features/home/life_counter/life_counter_settings.dart';
import 'package:manaloom/features/home/life_counter/life_counter_settings_store.dart';
import 'package:manaloom/features/home/life_counter_route.dart';
import 'package:manaloom/features/home/lotus/lotus_host.dart';
import 'package:manaloom/features/home/lotus/lotus_js_bridges.dart';
import 'package:manaloom/features/home/lotus/lotus_life_counter_session_adapter.dart';
import 'package:manaloom/features/home/lotus/lotus_storage_snapshot_store.dart';
import 'package:manaloom/features/home/lotus_life_counter_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeLotusHost implements LotusHost {
  _FakeLotusHost({
    required this.onShellMessageRequested,
    this.onLoadBundle,
  });

  final LotusShellMessageCallback onShellMessageRequested;
  final Future<void> Function(_FakeLotusHost host)? onLoadBundle;

  @override
  final ValueNotifier<bool> isLoading = ValueNotifier<bool>(true);

  @override
  final ValueNotifier<String?> errorMessage = ValueNotifier<String?>(null);

  int loadBundleCallCount = 0;
  bool isDisposed = false;
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
    await onLoadBundle?.call(this);
  }

  @override
  Future<void> runJavaScript(String script) async {
    executedScripts.add(script);
  }

  @override
  Future<Object?> runJavaScriptReturningResult(String script) async {
    if (script.contains('.planechase-overlay')) {
      return jsonEncode(<String, Object>{
        'planechaseAvailable': true,
        'planechaseActive': true,
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

  void failLoad(String message) {
    errorMessage.value = message;
    isLoading.value = false;
  }

  void emitShellMessage(String message) {
    onShellMessageRequested(message);
  }

  @override
  void dispose() {
    isDisposed = true;
    isLoading.dispose();
    errorMessage.dispose();
  }
}

void main() {
  group('LotusLifeCounterScreen host and backend behavior', () {
    String? clipboardText;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      clipboardText = null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
            if (call.method == 'Clipboard.setData') {
              final arguments = call.arguments;
              if (arguments is Map) {
                clipboardText = arguments['text']?.toString();
              }
            }
            return null;
          });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    testWidgets('shows the owned loading overlay on boot', (tester) async {
      late _FakeLotusHost host;

      await tester.pumpWidget(
        MaterialApp(
          home: LotusLifeCounterScreen(
            hostFactory: ({
              required onAppReviewRequested,
              required onShellMessageRequested,
            }) {
              host = _FakeLotusHost(
                onShellMessageRequested: onShellMessageRequested,
              );
              return host;
            },
          ),
        ),
      );

      await tester.pump();

      expect(find.byType(LotusLifeCounterScreen), findsOneWidget);
      expect(find.byKey(const Key('fake-lotus-host-view')), findsOneWidget);
      expect(find.text('Preparing the life counter'), findsOneWidget);
      expect(host.loadBundleCallCount, 1);
    });

    testWidgets('shows error state and retries bundle load', (tester) async {
      late _FakeLotusHost host;

      await tester.pumpWidget(
        MaterialApp(
          home: LotusLifeCounterScreen(
            hostFactory: ({
              required onAppReviewRequested,
              required onShellMessageRequested,
            }) {
              host = _FakeLotusHost(
                onShellMessageRequested: onShellMessageRequested,
                onLoadBundle: (host) async {
                  if (host.loadBundleCallCount == 1) {
                    host.failLoad('Test bundle load failure');
                    return;
                  }

                  host.completeSuccessfulLoad();
                },
              );
              return host;
            },
          ),
        ),
      );

      await tester.pump();
      await tester.pump();

      expect(find.text('Life counter unavailable'), findsOneWidget);
      expect(find.text('Test bundle load failure'), findsOneWidget);
      expect(host.loadBundleCallCount, 1);

      await tester.tap(find.text('Retry'));
      await tester.pump();
      await tester.pump();

      expect(host.loadBundleCallCount, 2);
      expect(find.text('Life counter unavailable'), findsNothing);
      expect(find.text('Test bundle load failure'), findsNothing);
    });

    testWidgets('opens native commander damage from shell shortcut', (
      tester,
    ) async {
      late _FakeLotusHost host;
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
        find.byKey(const Key('life-counter-native-commander-damage-plus-1-c1')),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(
        find.byKey(const Key('life-counter-native-commander-damage-plus-1-c1')),
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
    });

    testWidgets('opens native player counter from shell shortcut', (
      tester,
    ) async {
      late _FakeLotusHost host;

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
    });

    testWidgets('opens native player state from shell shortcut', (
      tester,
    ) async {
      late _FakeLotusHost host;
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
    });

    testWidgets('rolls player d20 from the player state hub', (tester) async {
      late _FakeLotusHost host;
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
      expect(host.loadBundleCallCount, 2);
    });

    testWidgets('opens native set life from shell shortcut', (tester) async {
      late _FakeLotusHost host;
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
      expect(host.loadBundleCallCount, 2);
    });

    testWidgets('opens native table state from shell shortcut', (tester) async {
      late _FakeLotusHost host;
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
        '{"type":"open-native-table-state","source":"monarch_surface_pressed"}',
      );
      await tester.pumpAndSettle();

      expect(find.text('Table State'), findsOneWidget);

      await tester.tap(
        find.byKey(
          const Key('life-counter-native-table-state-monarch-player-2'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(
          const Key('life-counter-native-table-state-initiative-player-1'),
        ),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(
        find.byKey(
          const Key('life-counter-native-table-state-initiative-player-1'),
        ),
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
      await tester.pumpAndSettle();
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
      expect(session!.monarchPlayer, 2);
      expect(session.initiativePlayer, 1);
      expect(session.stormCount, 1);
      expect(host.loadBundleCallCount, 2);
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

    testWidgets('opens native player appearance from shell shortcut', (
      tester,
    ) async {
      late _FakeLotusHost host;
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
          playerAppearances: [
            LifeCounterPlayerAppearance(background: '#FFB51E'),
            LifeCounterPlayerAppearance(background: '#FF0A5B'),
            LifeCounterPlayerAppearance(background: '#CF7AEF'),
            LifeCounterPlayerAppearance(background: '#4B57FF'),
          ],
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
        '{"type":"open-native-player-appearance","source":"player_background_surface_pressed","targetPlayerIndex":1}',
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(
          const Key('life-counter-native-player-appearance-apply'),
        ),
        findsOneWidget,
      );

      await tester.enterText(
        find.byKey(
          const Key('life-counter-native-player-appearance-nickname'),
        ),
        'Partner Pilot',
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(
        find.byKey(
          const Key('life-counter-native-player-appearance-preset-2'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(
          const Key('life-counter-native-player-appearance-preset-2'),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(
          const Key('life-counter-native-player-appearance-apply'),
        ),
      );
      await tester.pumpAndSettle();

      final session = await LifeCounterSessionStore().load();
      expect(session, isNotNull);
      expect(session!.resolvedPlayerAppearances[1].nickname, 'Partner Pilot');
      expect(session.resolvedPlayerAppearances[1].background, '#CF7AEF');
      expect(host.loadBundleCallCount, 2);
    });

    testWidgets(
      'opens native player appearance from the player state hub',
      (tester) async {
        late _FakeLotusHost host;
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
            playerAppearances: [
              LifeCounterPlayerAppearance(background: '#FFB51E'),
              LifeCounterPlayerAppearance(background: '#FF0A5B'),
              LifeCounterPlayerAppearance(background: '#CF7AEF'),
              LifeCounterPlayerAppearance(background: '#4B57FF'),
            ],
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

        await tester.enterText(
          find.byKey(
            const Key('life-counter-native-player-appearance-nickname'),
          ),
          'State Hub Pilot',
        );
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(
            const Key('life-counter-native-player-appearance-apply'),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Player State'), findsOneWidget);

        await tester.tap(
          find.byKey(const Key('life-counter-native-player-state-apply')),
        );
        await tester.pumpAndSettle();

        final session = await LifeCounterSessionStore().load();
        expect(session, isNotNull);
        expect(session!.resolvedPlayerAppearances[1].nickname, 'State Hub Pilot');
        expect(host.loadBundleCallCount, 2);
      },
    );

    testWidgets('opens native set life from the player state hub', (
      tester,
    ) async {
      late _FakeLotusHost host;
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
        find.byKey(const Key('life-counter-native-set-life-digit-4')),
      );
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
      expect(session!.lives[1], 45);
      expect(session.lastTableEvent, isNull);
      expect(host.loadBundleCallCount, 2);
    });

    testWidgets(
      'auto-knocks out a player when set life is applied from the player state hub',
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

        await tester.tap(
          find.byKey(const Key('life-counter-native-set-life-adjust-minus-10')),
        );
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(const Key('life-counter-native-set-life-apply')),
        );
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(const Key('life-counter-native-player-state-apply')),
        );
        await tester.pumpAndSettle();

        final session = await LifeCounterSessionStore().load();
        expect(session, isNotNull);
        expect(session!.lives[1], 0);
        expect(session.lastTableEvent, 'Jogador 2 foi nocauteado');
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

    testWidgets('auto-knocks out a player from native set life when enabled', (
      tester,
    ) async {
      late _FakeLotusHost host;
      await tester.binding.setSurfaceSize(const Size(900, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

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
        '{"type":"open-native-set-life","source":"player_life_total_surface_pressed","targetPlayerIndex":1}',
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(
        find.byKey(
          const Key('life-counter-native-set-life-adjust-minus-10'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(
          const Key('life-counter-native-set-life-adjust-minus-10'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('life-counter-native-set-life-apply')),
      );
      await tester.pumpAndSettle();

      final session = await LifeCounterSessionStore().load();
      expect(session, isNotNull);
      expect(session!.lives[1], 0);
      expect(session.lastTableEvent, 'Jogador 2 foi nocauteado');
      expect(host.loadBundleCallCount, 2);
    });

    testWidgets('exports native player appearance to clipboard', (
      tester,
    ) async {
      late _FakeLotusHost host;

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
          playerAppearances: [
            LifeCounterPlayerAppearance(background: '#FFB51E'),
            LifeCounterPlayerAppearance(
              background: '#CF7AEF',
              nickname: 'Partner Pilot',
              backgroundImage: 'main-image-ref',
              backgroundImagePartner: 'partner-image-ref',
            ),
            LifeCounterPlayerAppearance(background: '#4B57FF'),
            LifeCounterPlayerAppearance(background: '#44E063'),
          ],
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
        '{"type":"open-native-player-appearance","source":"player_background_surface_pressed","targetPlayerIndex":1}',
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(
          const Key('life-counter-native-player-appearance-export'),
        ),
      );
      await tester.pumpAndSettle();

      final transfer = LifeCounterPlayerAppearanceTransfer.tryParse(
        clipboardText,
      );
      expect(transfer, isNotNull);
      expect(transfer!.appearance.nickname, 'Partner Pilot');
      expect(transfer.appearance.background, '#CF7AEF');
      expect(transfer.appearance.backgroundImage, 'main-image-ref');
      expect(transfer.appearance.backgroundImagePartner, 'partner-image-ref');
    });

    testWidgets('imports native player appearance from payload', (
      tester,
    ) async {
      late _FakeLotusHost host;

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
          playerAppearances: [
            LifeCounterPlayerAppearance(background: '#FFB51E'),
            LifeCounterPlayerAppearance(background: '#FF0A5B'),
            LifeCounterPlayerAppearance(background: '#CF7AEF'),
            LifeCounterPlayerAppearance(background: '#4B57FF'),
          ],
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

      final transfer = LifeCounterPlayerAppearanceTransfer.fromAppearance(
        const LifeCounterPlayerAppearance(
          background: '#40B9FF',
          nickname: 'Imported Pilot',
          backgroundImage: 'imported-main-image',
          backgroundImagePartner: 'imported-partner-image',
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
        '{"type":"open-native-player-appearance","source":"player_background_surface_pressed","targetPlayerIndex":1}',
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(
          const Key('life-counter-native-player-appearance-import'),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(
          const Key('life-counter-native-player-appearance-import-input'),
        ),
        transfer.toJsonString(),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(
          const Key('life-counter-native-player-appearance-import-confirm'),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(
          const Key('life-counter-native-player-appearance-apply'),
        ),
      );
      await tester.pumpAndSettle();

      final session = await LifeCounterSessionStore().load();
      expect(session, isNotNull);
      expect(session!.resolvedPlayerAppearances[1].nickname, 'Imported Pilot');
      expect(session.resolvedPlayerAppearances[1].background, '#40B9FF');
      expect(
        session.resolvedPlayerAppearances[1].backgroundImage,
        'imported-main-image',
      );
      expect(
        session.resolvedPlayerAppearances[1].backgroundImagePartner,
        'imported-partner-image',
      );
      expect(host.loadBundleCallCount, 2);
    });

    testWidgets('saves native player appearance profiles', (tester) async {
      late _FakeLotusHost host;
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
          playerAppearances: [
            LifeCounterPlayerAppearance(background: '#FFB51E'),
            LifeCounterPlayerAppearance(
              background: '#CF7AEF',
              nickname: 'Partner Pilot',
            ),
            LifeCounterPlayerAppearance(background: '#4B57FF'),
            LifeCounterPlayerAppearance(background: '#44E063'),
          ],
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
        '{"type":"open-native-player-appearance","source":"player_background_surface_pressed","targetPlayerIndex":1}',
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.byKey(
          const Key('life-counter-native-player-appearance-profile-name'),
        ),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(
          const Key('life-counter-native-player-appearance-profile-name'),
        ),
        'Partner Pod',
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(
          const Key('life-counter-native-player-appearance-save-profile'),
        ),
      );
      await tester.pumpAndSettle();

      final profiles = await LifeCounterPlayerAppearanceProfileStore().load();
      expect(profiles, hasLength(1));
      expect(profiles.first.name, 'Partner Pod');
      expect(profiles.first.appearance.nickname, 'Partner Pilot');
    });

    testWidgets(
      'resets the Lotus player surface when native player state is dismissed from option-card takeover',
      (tester) async {
        late _FakeLotusHost host;

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
      },
    );

    testWidgets(
      'resets the Lotus appearance surface when native player appearance is dismissed from color-card takeover',
      (tester) async {
        late _FakeLotusHost host;

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
          '{"type":"open-native-player-appearance","source":"player_background_color_card_presented","targetPlayerIndex":2}',
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(
            const Key('life-counter-native-player-appearance-apply'),
          ),
          findsOneWidget,
        );

        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        expect(
          find.byKey(
            const Key('life-counter-native-player-appearance-apply'),
          ),
          findsNothing,
        );
        expect(host.loadBundleCallCount, 2);
      },
    );

    testWidgets('resolves the live /life-counter route', (tester) async {
      late _FakeLotusHost host;
      final router = GoRouter(
        initialLocation: lifeCounterRoutePath,
        routes: [
          GoRoute(
            path: lifeCounterRoutePath,
            builder:
                (context, state) => LotusLifeCounterScreen(
                  hostFactory: ({
                    required onAppReviewRequested,
                    required onShellMessageRequested,
                  }) {
                    host = _FakeLotusHost(
                      onShellMessageRequested: onShellMessageRequested,
                    );
                    return host;
                  },
                ),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();

      expect(find.byType(LotusLifeCounterScreen), findsOneWidget);
      expect(find.byKey(const Key('fake-lotus-host-view')), findsOneWidget);
      expect(host.loadBundleCallCount, 1);
    });
  });
}
