import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/features/home/life_counter/life_counter_day_night_state_store.dart';
import 'package:manaloom/features/home/lotus/lotus_host.dart';
import 'package:manaloom/features/home/lotus/lotus_js_bridges.dart';
import 'package:manaloom/features/home/lotus_life_counter_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeLotusHost implements LotusHost {
  _FakeLotusHost({
    required this.onShellMessageRequested,
    this.onRunJavaScriptReturningResult,
  });

  final LotusShellMessageCallback onShellMessageRequested;
  final Object? Function(String script)? onRunJavaScriptReturningResult;

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
    final isGameModesAvailabilityQuery =
        script.contains('planechaseAvailable:') &&
        script.contains('archenemyAvailable:') &&
        script.contains('bountyAvailable:');

    if (script.contains('.day-night-switcher') ||
        (!isGameModesAvailabilityQuery &&
            (script.contains('.planechase-btn') ||
                script.contains('.archenemy-btn') ||
                script.contains('.bounty-btn') ||
                script.contains('.edit-planechase-cards') ||
                script.contains('.edit-archenemy-cards') ||
                script.contains('.edit-bounty-cards') ||
                script.contains('.close-planechase-overlay-btn') ||
                script.contains('.close-archenemy-overlay-btn') ||
                script.contains('.close-bounty-overlay-btn') ||
                script.contains('.close-edit-planechase-cards-overlay') ||
                script.contains('.close-edit-archenemy-cards-overlay') ||
                script.contains('.close-edit-bounty-cards-overlay')))) {
      executedScripts.add(script);
    }

    if (onRunJavaScriptReturningResult != null) {
      final overriddenResult = onRunJavaScriptReturningResult!(script);
      if (overriddenResult != null) {
        return overriddenResult;
      }
    }

    if (script.contains('.day-night-switcher')) {
      return jsonEncode(<String, Object>{
        'ok': true,
        'isNight': script.contains("toggle('night', true)"),
      });
    }

    if (!isGameModesAvailabilityQuery &&
        (script.contains('.planechase-btn') ||
            script.contains('.archenemy-btn') ||
            script.contains('.bounty-btn') ||
            script.contains('.edit-planechase-cards') ||
            script.contains('.edit-archenemy-cards') ||
            script.contains('.edit-bounty-cards') ||
            script.contains('.close-planechase-overlay-btn') ||
            script.contains('.close-archenemy-overlay-btn') ||
            script.contains('.close-bounty-overlay-btn') ||
            script.contains('.close-edit-planechase-cards-overlay') ||
            script.contains('.close-edit-archenemy-cards-overlay') ||
            script.contains('.close-edit-bounty-cards-overlay'))) {
      return jsonEncode(<String, Object>{'ok': true});
    }

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
      'archenemyAvailable': false,
      'archenemyActive': false,
      'bountyAvailable': true,
      'bountyActive': false,
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
  group('LotusLifeCounterScreen internal actions fallback', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('opens native day night from a shell fallback shortcut', (
      tester,
    ) async {
      late _FakeLotusHost host;

      await _captureDebugLogs((logs) async {
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
          '{"type":"open-native-day-night","source":"day_night_surface_pressed"}',
        );
        await tester.pumpAndSettle();

        expect(find.text('Day / Night'), findsOneWidget);

        await tester.tap(find.text('Night'));
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(const Key('life-counter-native-day-night-apply')),
        );
        await tester.pumpAndSettle();

        final state = await LifeCounterDayNightStateStore().load();
        expect(state, isNotNull);
        expect(state!.isNight, isTrue);
        expect(
          host.executedScripts.any(
            (script) =>
                script.contains('__manaloom_day_night_mode') &&
                script.contains('.day-night-switcher'),
          ),
          isTrue,
        );
        expect(host.loadBundleCallCount, 1);
        expect(
          logs.any(
            (message) =>
                message.contains('message=native_day_night_opened') &&
                message.contains('surface_strategy: native_fallback'),
          ),
          isTrue,
        );
        expect(
          logs.any(
            (message) =>
                message.contains('message=native_day_night_applied') &&
                message.contains('apply_strategy: live_runtime') &&
                message.contains('live_patch_eligible: true'),
          ),
          isTrue,
        );
      });
    });

    testWidgets(
      'reloads the Lotus bundle when day night live sync cannot confirm the switcher',
      (tester) async {
        late _FakeLotusHost host;

        await _captureDebugLogs((logs) async {
          await tester.pumpWidget(
            MaterialApp(
              home: LotusLifeCounterScreen(
                hostFactory: ({
                  required onAppReviewRequested,
                  required onShellMessageRequested,
                }) {
                  host = _FakeLotusHost(
                    onShellMessageRequested: onShellMessageRequested,
                    onRunJavaScriptReturningResult: (script) {
                      if (script.contains('.day-night-switcher')) {
                        return jsonEncode(<String, Object>{
                          'ok': false,
                          'reason': 'switcher_missing',
                        });
                      }

                      if (!script.contains('planechaseAvailable:')) {
                        return null;
                      }

                      return jsonEncode(<String, Object>{
                        'planechaseAvailable': true,
                        'planechaseActive': false,
                        'archenemyAvailable': false,
                        'archenemyActive': false,
                        'bountyAvailable': true,
                        'bountyActive': false,
                      });
                    },
                  )..completeSuccessfulLoad();
                  return host;
                },
              ),
            ),
          );

          await tester.pump();
          await tester.pump();

          host.emitShellMessage(
            '{"type":"open-native-day-night","source":"day_night_surface_pressed"}',
          );
          await tester.pumpAndSettle();

          await tester.tap(find.text('Night'));
          await tester.pumpAndSettle();

          await tester.tap(
            find.byKey(const Key('life-counter-native-day-night-apply')),
          );
          await tester.pumpAndSettle();

          expect(host.loadBundleCallCount, 2);
          expect(
            host.executedScripts.any(
              (script) =>
                  script.contains('__manaloom_day_night_mode') &&
                  script.contains('.day-night-switcher'),
            ),
            isTrue,
          );
          expect(
            logs.any(
              (message) =>
                  message.contains('message=native_day_night_applied') &&
                  message.contains('apply_strategy: reload_fallback') &&
                  message.contains('live_patch_eligible: true'),
            ),
            isTrue,
          );
        });
      },
    );

    testWidgets('opens native game modes from a direct planechase shortcut', (
      tester,
    ) async {
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
              )..completeSuccessfulLoad();
              return host;
            },
          ),
        ),
      );

      await tester.pump();
      await tester.pump();

      host.emitShellMessage(
        '{"type":"open-native-game-modes","source":"planechase_mode_pressed","preferredMode":"planechase"}',
      );
      await tester.pumpAndSettle();

      expect(find.text('Game Modes'), findsOneWidget);
      expect(find.text('Selected Surface'), findsOneWidget);
      expect(find.text('Continue With Planechase'), findsOneWidget);

      await tester.tap(
        find.byKey(const Key('life-counter-native-game-modes-planechase-open')),
      );
      await tester.pumpAndSettle();

      expect(
        host.executedScripts.any(
          (script) =>
              script.contains("document.querySelector('.planechase-btn')") &&
              script.contains('button.click()'),
        ),
        isTrue,
      );
    });

    testWidgets(
      'opens native game modes from an active planechase overlay settings shortcut',
      (tester) async {
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
                )..completeSuccessfulLoad();
                return host;
              },
            ),
          ),
        );

        await tester.pump();
        await tester.pump();

        host.emitShellMessage(
          '{"type":"open-native-game-modes","source":"planechase_overlay_settings_pressed","preferredMode":"planechase"}',
        );
        await tester.pumpAndSettle();

        expect(find.text('Game Modes'), findsOneWidget);
        expect(find.text('Continue With Planechase'), findsOneWidget);
        expect(find.text('Active Now'), findsOneWidget);
      },
    );

    testWidgets(
      'hands off planechase card pool editing through the owned game modes shell',
      (tester) async {
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
                )..completeSuccessfulLoad();
                return host;
              },
            ),
          ),
        );

        await tester.pump();
        await tester.pump();

        host.emitShellMessage(
          '{"type":"open-native-game-modes","source":"planechase_cards_pressed","preferredMode":"planechase","intent":"edit-cards"}',
        );
        await tester.pumpAndSettle();

        expect(find.text('Continue To Embedded Card Pool'), findsOneWidget);

        await tester.ensureVisible(
          find.byKey(
            const Key('life-counter-native-game-modes-planechase-open'),
          ),
        );
        await tester.tap(
          find.byKey(
            const Key('life-counter-native-game-modes-planechase-open'),
          ),
          warnIfMissed: false,
        );
        await tester.pumpAndSettle();

        expect(
          host.executedScripts.any(
            (script) =>
                script.contains("document.querySelector('.planechase-btn')") &&
                script.contains('button.click()'),
          ),
          isTrue,
        );
        expect(
          host.executedScripts.any(
            (script) =>
                script.contains(
                  "document.querySelector('.edit-planechase-cards')",
                ) &&
                script.contains('button.click()'),
          ),
          isTrue,
        );
      },
    );

    testWidgets(
      'offers explicit close action for an active embedded planechase card pool editor',
      (tester) async {
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
                  onRunJavaScriptReturningResult: (script) {
                    if (!script.contains('planechaseAvailable:')) {
                      return null;
                    }

                    return jsonEncode(<String, bool>{
                      'planechaseAvailable': true,
                      'planechaseActive': false,
                      'planechaseCardPoolActive': true,
                      'archenemyAvailable': true,
                      'archenemyActive': false,
                      'archenemyCardPoolActive': false,
                      'bountyAvailable': true,
                      'bountyActive': false,
                      'bountyCardPoolActive': false,
                    });
                  },
                )..completeSuccessfulLoad();
                return host;
              },
            ),
          ),
        );

        await tester.pump();
        await tester.pump();

        host.emitShellMessage(
          '{"type":"open-native-game-modes","source":"planechase_cards_pressed","preferredMode":"planechase","intent":"edit-cards"}',
        );
        await tester.pumpAndSettle();

        expect(find.text('Card Pool Open'), findsOneWidget);
        expect(find.text('Return To Embedded Card Pool'), findsOneWidget);

        await tester.ensureVisible(
          find.byKey(
            const Key(
              'life-counter-native-game-modes-planechase-close-card-pool',
            ),
          ),
        );
        await tester.tap(
          find.byKey(
            const Key(
              'life-counter-native-game-modes-planechase-close-card-pool',
            ),
          ),
          warnIfMissed: false,
        );
        await tester.pumpAndSettle();

        expect(
          host.executedScripts.any(
            (script) => script.contains(
              "document.querySelector('.close-edit-planechase-cards-overlay')",
            ),
          ),
          isTrue,
        );
      },
    );

    testWidgets(
      'offers explicit edit card pool action from the internal game modes shell',
      (tester) async {
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
                )..completeSuccessfulLoad();
                return host;
              },
            ),
          ),
        );

        await tester.pump();
        await tester.pump();

        host.emitShellMessage(
          '{"type":"open-native-game-modes","source":"internal_game_modes_fallback"}',
        );
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

        expect(
          host.executedScripts.any(
            (script) =>
                script.contains("document.querySelector('.planechase-btn')") &&
                script.contains('button.click()'),
          ),
          isTrue,
        );
        expect(
          host.executedScripts.any(
            (script) =>
                script.contains(
                  "document.querySelector('.edit-planechase-cards')",
                ) &&
                script.contains('button.click()'),
          ),
          isTrue,
        );
      },
    );

    testWidgets(
      'records failed game mode delivery when the edit cards follow up selector is missing',
      (tester) async {
        late _FakeLotusHost host;
        final logs = <String>[];
        final originalDebugPrint = debugPrint;
        debugPrint = (String? message, {int? wrapWidth}) {
          if (message != null) {
            logs.add(message);
          }
        };
        try {
          await tester.pumpWidget(
            MaterialApp(
              home: LotusLifeCounterScreen(
                hostFactory: ({
                  required onAppReviewRequested,
                  required onShellMessageRequested,
                }) {
                  host = _FakeLotusHost(
                    onShellMessageRequested: onShellMessageRequested,
                    onRunJavaScriptReturningResult: (script) {
                      if (script.contains(
                        "document.querySelector('.edit-planechase-cards')",
                      )) {
                        return jsonEncode(<String, Object>{
                          'ok': false,
                          'reason': 'button_missing',
                        });
                      }
                      return null;
                    },
                  )..completeSuccessfulLoad();
                  return host;
                },
              ),
            ),
          );

          await tester.pump();
          await tester.pump();

          host.emitShellMessage(
            '{"type":"open-native-game-modes","source":"planechase_cards_pressed","preferredMode":"planechase","intent":"edit-cards"}',
          );
          await tester.pumpAndSettle();

          await tester.tap(
            find.byKey(
              const Key('life-counter-native-game-modes-planechase-open'),
            ),
          );
          await tester.pumpAndSettle();

          expect(
            logs.any(
              (message) => message.contains(
                'message=embedded_game_mode_follow_up_failed',
              ),
            ),
            isTrue,
          );
          expect(
            logs.any(
              (message) =>
                  message.contains('message=native_game_modes_action_failed'),
            ),
            isTrue,
          );
          expect(
            logs.any(
              (message) =>
                  message.contains('message=native_game_modes_dismissed') &&
                  message.contains('action_delivered: false'),
            ),
            isTrue,
          );
        } finally {
          debugPrint = originalDebugPrint;
        }
      },
    );

    testWidgets('routes unavailable direct game modes to native settings', (
      tester,
    ) async {
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
                onRunJavaScriptReturningResult: (script) {
                  if (!script.contains('planechaseAvailable:')) {
                    return null;
                  }

                  return jsonEncode(<String, bool>{
                    'planechaseAvailable': true,
                    'planechaseActive': false,
                    'archenemyAvailable': false,
                    'archenemyActive': false,
                    'bountyAvailable': true,
                    'bountyActive': false,
                  });
                },
              )..completeSuccessfulLoad();
              return host;
            },
          ),
        ),
      );

      await tester.pump();
      await tester.pump();

      host.emitShellMessage(
        '{"type":"open-native-game-modes","source":"archenemy_mode_pressed","preferredMode":"archenemy"}',
      );
      await tester.pumpAndSettle();

      expect(find.text('Open Settings'), findsOneWidget);

      await tester.ensureVisible(
        find.byKey(
          const Key('life-counter-native-game-modes-archenemy-settings'),
        ),
      );
      await tester.tap(
        find.byKey(
          const Key('life-counter-native-game-modes-archenemy-settings'),
        ),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();

      expect(find.text('Life Counter Settings'), findsOneWidget);
    });

    testWidgets(
      'blocks opening a third game mode when the active limit is reached',
      (tester) async {
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
                  onRunJavaScriptReturningResult: (script) {
                    if (!script.contains('planechaseAvailable:')) {
                      return null;
                    }

                    return jsonEncode(<String, Object>{
                      'planechaseAvailable': true,
                      'planechaseActive': true,
                      'planechaseCardPoolActive': false,
                      'archenemyAvailable': true,
                      'archenemyActive': true,
                      'archenemyCardPoolActive': false,
                      'bountyAvailable': true,
                      'bountyActive': false,
                      'bountyCardPoolActive': false,
                      'maxActiveModes': 2,
                    });
                  },
                )..completeSuccessfulLoad();
                return host;
              },
            ),
          ),
        );

        await tester.pump();
        await tester.pump();

        host.emitShellMessage(
          '{"type":"open-native-game-modes","source":"bounty_mode_pressed","preferredMode":"bounty"}',
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('life-counter-native-game-modes-limit-warning')),
          findsOneWidget,
        );
        expect(find.text('Close One Active Mode First'), findsOneWidget);

        await tester.ensureVisible(
          find.byKey(const Key('life-counter-native-game-modes-bounty-open')),
        );
        await tester.tap(
          find.byKey(const Key('life-counter-native-game-modes-bounty-open')),
          warnIfMissed: false,
        );
        await tester.pumpAndSettle();

        expect(
          host.executedScripts.any(
            (script) =>
                script.contains("document.querySelector('.bounty-btn')"),
          ),
          isFalse,
        );
      },
    );
  });
}
