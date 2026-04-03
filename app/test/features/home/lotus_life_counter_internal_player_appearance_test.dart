import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/features/home/life_counter/life_counter_player_appearance_profile_store.dart';
import 'package:manaloom/features/home/life_counter/life_counter_player_appearance_transfer.dart';
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
  Future<void> runJavaScript(String script) async {
    executedScripts.add(script);
  }

  @override
  Future<Object?> runJavaScriptReturningResult(String script) async {
    executedScripts.add(script);

    if (script.contains('receivePatch')) {
      return jsonEncode(<String, Object>{'ok': true});
    }

    if (script.contains(".player-card")) {
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
  group('LotusLifeCounterScreen internal player appearance fallback', () {
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

    testWidgets('opens native player appearance from shell shortcut', (
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
          find.byKey(const Key('life-counter-native-player-appearance-apply')),
          findsOneWidget,
        );

        await tester.scrollUntilVisible(
          find.byKey(
            const Key('life-counter-native-player-appearance-nickname'),
          ),
          250,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.ensureVisible(
          find.byKey(
            const Key('life-counter-native-player-appearance-nickname'),
          ),
        );
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(
            const Key('life-counter-native-player-appearance-nickname'),
          ),
          'Partner Pilot',
        );
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(const Key('life-counter-native-player-appearance-apply')),
        );
        await tester.pumpAndSettle();

        final session = await LifeCounterSessionStore().load();
        expect(session, isNotNull);
        expect(session!.resolvedPlayerAppearances[1].background, '#FF0A5B');
        expect(session.resolvedPlayerAppearances[1].nickname, 'Partner Pilot');
        expect(host.loadBundleCallCount, 2);
        expect(
          logs.any(
            (message) =>
                message.contains('message=native_player_appearance_opened') &&
                message.contains('surface_strategy: native_fallback'),
          ),
          isTrue,
        );
        expect(
          logs.any(
            (message) =>
                message.contains('message=native_player_appearance_applied') &&
                message.contains('apply_strategy: reload_fallback') &&
                message.contains('live_patch_eligible: false') &&
                message.contains('reload_required: true') &&
                message.contains('sync_blockers: [nickname_changed]'),
          ),
          isTrue,
        );
      });
    });

    testWidgets('opens native player appearance from the player state hub', (
      tester,
    ) async {
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
        find.byKey(const Key('life-counter-native-player-appearance-apply')),
        findsOneWidget,
      );

      await tester.enterText(
        find.byKey(const Key('life-counter-native-player-appearance-nickname')),
        'State Hub Pilot',
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('life-counter-native-player-appearance-apply')),
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
    });

    testWidgets(
      'keeps solid player appearance live through the player state hub without reloading the Lotus bundle',
      (tester) async {
        late _FakeLotusHost host;
        await tester.binding.setSurfaceSize(const Size(900, 1200));
        addTearDown(() => tester.binding.setSurfaceSize(null));

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

          await tester.scrollUntilVisible(
            find.byKey(
              const Key('life-counter-native-player-appearance-preset-2'),
            ),
            250,
            scrollable: find.byType(Scrollable).first,
          );
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

          expect(find.text('Player State'), findsOneWidget);

          await tester.tap(
            find.byKey(const Key('life-counter-native-player-state-apply')),
          );
          await tester.pumpAndSettle();

          final session = await LifeCounterSessionStore().load();
          expect(session, isNotNull);
          expect(session!.resolvedPlayerAppearances[1].background, '#CF7AEF');
          expect(host.loadBundleCallCount, 1);
          expect(
            logs.any(
              (message) =>
                  message.contains('message=native_player_state_applied') &&
                  message.contains('apply_strategy: live_runtime') &&
                  message.contains('live_patch_eligible: true') &&
                  message.contains('reload_required: false') &&
                  message.contains('sync_blockers: []'),
            ),
            isTrue,
          );
        });
      },
    );

    testWidgets(
      'resets the Lotus option-card surface after solid player appearance live apply from player state takeover',
      (tester) async {
        late _FakeLotusHost host;
        await tester.binding.setSurfaceSize(const Size(900, 1200));
        addTearDown(() => tester.binding.setSurfaceSize(null));

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
            '{"type":"open-native-player-state","source":"player_option_card_presented","targetPlayerIndex":1}',
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

          await tester.scrollUntilVisible(
            find.byKey(
              const Key('life-counter-native-player-appearance-preset-2'),
            ),
            250,
            scrollable: find.byType(Scrollable).first,
          );
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

          expect(find.text('Player State'), findsOneWidget);

          await tester.tap(
            find.byKey(const Key('life-counter-native-player-state-apply')),
          );
          await tester.pumpAndSettle();

          final session = await LifeCounterSessionStore().load();
          expect(session, isNotNull);
          expect(session!.resolvedPlayerAppearances[1].background, '#CF7AEF');
          expect(host.loadBundleCallCount, 1);
          expect(
            host.executedScripts.any(
              (script) => script.contains('.player-card-inner.option-card'),
            ),
            isTrue,
          );
          expect(
            logs.any(
              (message) =>
                  message.contains('message=native_player_state_applied') &&
                  message.contains('apply_strategy: live_runtime') &&
                  message.contains('reload_required: false') &&
                  message.contains('surface_reset_required: true') &&
                  message.contains('surface_reset_strategy: live_dom_reset') &&
                  message.contains('sync_blockers: []'),
            ),
            isTrue,
          );
        });
      },
    );

    testWidgets('exports native player appearance to clipboard', (
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
          find.byKey(const Key('life-counter-native-player-appearance-export')),
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
        expect(
          logs.any(
            (message) =>
                message.contains('message=native_player_appearance_exported') &&
                message.contains('surface_strategy: native_fallback') &&
                message.contains('transfer_strategy: clipboard_export'),
          ),
          isTrue,
        );
      });
    });

    testWidgets('imports native player appearance from payload', (
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
          find.byKey(const Key('life-counter-native-player-appearance-import')),
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
          find.byKey(const Key('life-counter-native-player-appearance-apply')),
        );
        await tester.pumpAndSettle();

        final session = await LifeCounterSessionStore().load();
        expect(session, isNotNull);
        expect(
          session!.resolvedPlayerAppearances[1].nickname,
          'Imported Pilot',
        );
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
        expect(
          logs.any(
            (message) =>
                message.contains('message=native_player_appearance_imported') &&
                message.contains('surface_strategy: native_fallback') &&
                message.contains('transfer_strategy: clipboard_import'),
          ),
          isTrue,
        );
      });
    });

    testWidgets('saves native player appearance profiles', (tester) async {
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
        expect(
          logs.any(
            (message) =>
                message.contains(
                  'message=native_player_appearance_profile_saved',
                ) &&
                message.contains('surface_strategy: native_fallback') &&
                message.contains('persistence_strategy: owned_profile_store') &&
                message.contains('source: player_background_surface_pressed') &&
                message.contains('profile_count: 1'),
          ),
          isTrue,
        );
      });
    });

    testWidgets('deletes native player appearance profiles', (tester) async {
      late _FakeLotusHost host;
      await _captureDebugLogs((logs) async {
        await tester.binding.setSurfaceSize(const Size(900, 1200));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await LifeCounterSessionStore().save(
          LifeCounterSession.initial(playerCount: 4),
        );

        final store = LifeCounterPlayerAppearanceProfileStore();
        final seededProfiles = await store.saveProfile(
          name: 'Partner Pod',
          appearance: const LifeCounterPlayerAppearance(
            background: '#CF7AEF',
            nickname: 'Partner Pilot',
          ),
        );
        final profileId = seededProfiles.single.id;

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
            Key(
              'life-counter-native-player-appearance-delete-profile-$profileId',
            ),
          ),
          250,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(
            Key(
              'life-counter-native-player-appearance-delete-profile-$profileId',
            ),
          ),
        );
        await tester.pumpAndSettle();

        final profiles = await store.load();
        expect(profiles, isEmpty);
        expect(
          find.byKey(
            Key('life-counter-native-player-appearance-profile-$profileId'),
          ),
          findsNothing,
        );
        expect(
          logs.any(
            (message) =>
                message.contains(
                  'message=native_player_appearance_profile_deleted',
                ) &&
                message.contains('surface_strategy: native_fallback') &&
                message.contains('persistence_strategy: owned_profile_store') &&
                message.contains('source: player_background_surface_pressed') &&
                message.contains('profile_id: $profileId') &&
                message.contains('profile_count: 0'),
          ),
          isTrue,
        );
      });
    });

    testWidgets('selects native player appearance profiles into draft', (
      tester,
    ) async {
      late _FakeLotusHost host;
      await _captureDebugLogs((logs) async {
        await tester.binding.setSurfaceSize(const Size(900, 1200));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await LifeCounterSessionStore().save(
          LifeCounterSession.initial(playerCount: 4),
        );

        final store = LifeCounterPlayerAppearanceProfileStore();
        final seededProfiles = await store.saveProfile(
          name: 'Partner Pod',
          appearance: const LifeCounterPlayerAppearance(
            background: '#CF7AEF',
            nickname: 'Partner Pilot',
          ),
        );
        final profileId = seededProfiles.single.id;

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
          '{"type":"open-native-player-appearance","source":"player_background_surface_pressed","targetPlayerIndex":2}',
        );
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(
          find.byKey(
            Key(
              'life-counter-native-player-appearance-apply-profile-$profileId',
            ),
          ),
          250,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(
            Key(
              'life-counter-native-player-appearance-apply-profile-$profileId',
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          logs.any(
            (message) =>
                message.contains(
                  'message=native_player_appearance_profile_selected',
                ) &&
                message.contains('surface_strategy: native_fallback') &&
                message.contains('persistence_strategy: owned_profile_store') &&
                message.contains('source: player_background_surface_pressed') &&
                message.contains('target_player_index: 2') &&
                message.contains('profile_id: $profileId') &&
                message.contains('profile_name: Partner Pod'),
          ),
          isTrue,
        );
      });
    });

    testWidgets(
      'resets the Lotus appearance surface when native player appearance is dismissed from color-card takeover',
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
          expect(host.loadBundleCallCount, 1);
          expect(
            host.executedScripts.any(
              (script) => script.contains('.player-card-inner.option-card'),
            ),
            isTrue,
          );
          expect(
            logs.any(
              (message) =>
                  message.contains(
                    'message=native_player_appearance_dismissed',
                  ) &&
                  message.contains(
                    'source: player_background_color_card_presented',
                  ) &&
                  message.contains('changed: false') &&
                  message.contains('surface_reset_required: true') &&
                  message.contains('surface_reset_strategy: live_dom_reset'),
            ),
            isTrue,
          );
        });
      },
    );

    testWidgets(
      'keeps solid player appearance live when applying from color-card takeover',
      (tester) async {
        late _FakeLotusHost host;
        await tester.binding.setSurfaceSize(const Size(900, 1200));
        addTearDown(() => tester.binding.setSurfaceSize(null));

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
            '{"type":"open-native-player-appearance","source":"player_background_color_card_presented","targetPlayerIndex":2}',
          );
          await tester.pumpAndSettle();

          await tester.scrollUntilVisible(
            find.byKey(
              const Key('life-counter-native-player-appearance-preset-2'),
            ),
            250,
            scrollable: find.byType(Scrollable).first,
          );
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
          expect(session!.resolvedPlayerAppearances[2].background, '#CF7AEF');
          expect(host.loadBundleCallCount, 1);
          expect(
            host.executedScripts.any(
              (script) => script.contains('.player-card-inner.option-card'),
            ),
            isTrue,
          );
        });
      },
    );
  });
}
