import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/features/home/life_counter/life_counter_history_store.dart';
import 'package:manaloom/features/home/life_counter/life_counter_history_transfer.dart';
import 'package:manaloom/features/home/life_counter/life_counter_session.dart';
import 'package:manaloom/features/home/life_counter/life_counter_session_store.dart';
import 'package:manaloom/features/home/life_counter/life_counter_settings_store.dart';
import 'package:manaloom/features/home/lotus/lotus_host.dart';
import 'package:manaloom/features/home/lotus/lotus_js_bridges.dart';
import 'package:manaloom/features/home/lotus/lotus_storage_snapshot.dart';
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
  group('LotusLifeCounterScreen internal shell fallback', () {
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

    testWidgets('opens native settings from a shell fallback shortcut', (
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
          '{"type":"open-native-settings","source":"settings_shortcut_pressed"}',
        );
        await tester.pumpAndSettle();

        expect(find.text('Life Counter Settings'), findsOneWidget);

        await tester.tap(find.text('Auto-kill'));
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(const Key('life-counter-native-settings-save')),
        );
        await tester.pumpAndSettle();

        final settings = await LifeCounterSettingsStore().load();
        expect(settings, isNotNull);
        expect(settings!.autoKill, isFalse);
        expect(host.loadBundleCallCount, 2);
        expect(
          logs.any(
            (message) =>
                message.contains('message=native_settings_opened') &&
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
                message.contains('message=native_settings_applied') &&
                message.contains('apply_strategy: reload_fallback') &&
                message.contains('live_patch_eligible: false') &&
                message.contains('reload_required: true') &&
                message.contains(
                  'sync_blockers: [lotus_settings_runtime_in_memory]',
                ),
          ),
          isTrue,
        );
      });
    });

    testWidgets('opens native history from a shell fallback shortcut', (
      tester,
    ) async {
      late _FakeLotusHost host;
      await _captureDebugLogs((logs) async {
        final session = LifeCounterSession.tryFromJson({
          ...LifeCounterSession.initial(playerCount: 4).toJson(),
          'last_table_event': 'Player 1 lost 3 life',
        });
        expect(session, isNotNull);
        await LifeCounterSessionStore().save(session!);
        await LotusStorageSnapshotStore().save(
          const LotusStorageSnapshot(
            values: {
              'currentGameMeta': '{"name":"Game #12"}',
              'gameHistory':
                  '[{"message":"Player 2 gained 2 life","timestamp":1711800000000}]',
              'allGamesHistory':
                  '[{"name":"Game #11","history":[{"message":"Player 3 was eliminated"}]}]',
            },
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
          '{"type":"open-native-history","source":"history_shortcut_pressed"}',
        );
        await tester.pumpAndSettle();

        expect(find.text('Life Counter History'), findsOneWidget);
        expect(
          find.byKey(const Key('life-counter-native-history-last-event')),
          findsOneWidget,
        );
        expect(find.text('Player 1 lost 3 life'), findsOneWidget);
        expect(find.text('Player 2 gained 2 life'), findsOneWidget);
        expect(
          find.text('Player 3 was eliminated', skipOffstage: false),
          findsOneWidget,
        );
        expect(
          logs.any(
            (message) =>
                message.contains(
                  'message=native_fallback_surface_requested',
                ) &&
                message.contains('message_type: open-native-history') &&
                message.contains('domain_key: history') &&
                message.contains(
                  'fallback_classification: support_utility',
                ) &&
                message.contains('review_status: support_utility'),
          ),
          isTrue,
        );
        expect(
          logs.any(
            (message) =>
                message.contains('message=native_history_opened') &&
                message.contains('surface_strategy: native_fallback') &&
                message.contains(
                  'fallback_classification: support_utility',
                ) &&
                message.contains('history_domain_present: true'),
          ),
          isTrue,
        );
      });
    });

    testWidgets('uses shared default source for history fallback requests', (
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

        host.emitShellMessage('{"type":"open-native-history"}');
        await tester.pumpAndSettle();

        expect(
          logs.any(
            (message) =>
                message.contains(
                  'message=native_fallback_surface_requested',
                ) &&
                message.contains('message_type: open-native-history') &&
                message.contains('source: shell_shortcut') &&
                message.contains('used_default_source: true'),
          ),
          isTrue,
        );
        expect(
          logs.any(
            (message) =>
                message.contains('message=native_history_opened') &&
                message.contains('source: shell_shortcut'),
          ),
          isTrue,
        );
      });
    });

    testWidgets('rejects unsupported native fallback requests explicitly', (
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
          '{"type":"open-native-quick-actions","source":"shell_shortcut"}',
        );
        await tester.pumpAndSettle();

        expect(
          logs.any(
            (message) =>
                message.contains(
                  'message=native_fallback_surface_rejected',
                ) &&
                message.contains('message_type: open-native-quick-actions') &&
                message.contains('reason: unknown_surface_type'),
          ),
          isTrue,
        );
      });
    });

    testWidgets('rejects player counter requests without counter key', (
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
          '{"type":"open-native-player-counter","targetPlayerIndex":2}',
        );
        await tester.pumpAndSettle();

        expect(
          logs.any(
            (message) =>
                message.contains(
                  'message=native_fallback_surface_rejected',
                ) &&
                message.contains('message_type: open-native-player-counter') &&
                message.contains('domain_key: player_counter') &&
                message.contains('target_player_index: 2') &&
                message.contains('reason: missing_counter_key'),
          ),
          isTrue,
        );
      });
    });

    testWidgets('rejects player fallback requests without target player index', (
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
          '{"type":"open-native-player-state","source":"player_option_card_presented"}',
        );
        await tester.pumpAndSettle();

        expect(
          logs.any(
            (message) =>
                message.contains(
                  'message=native_fallback_surface_rejected',
                ) &&
                message.contains('message_type: open-native-player-state') &&
                message.contains('domain_key: player_state') &&
                message.contains('source: player_option_card_presented') &&
                message.contains('reason: missing_target_player_index'),
          ),
          isTrue,
        );
      });
    });

    testWidgets('exports native history from a shell fallback shortcut', (
      tester,
    ) async {
      late _FakeLotusHost host;
      await _captureDebugLogs((logs) async {
        final session = LifeCounterSession.tryFromJson({
          ...LifeCounterSession.initial(playerCount: 4).toJson(),
          'last_table_event': 'Player 1 lost 3 life',
        });
        expect(session, isNotNull);
        await LifeCounterSessionStore().save(session!);
        await LotusStorageSnapshotStore().save(
          const LotusStorageSnapshot(
            values: {
              'currentGameMeta': '{"name":"Game #12"}',
              'gameHistory':
                  '[{"message":"Player 2 gained 2 life","timestamp":1711800000000}]',
            },
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
          '{"type":"open-native-history","source":"history_shortcut_pressed"}',
        );
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(const Key('life-counter-native-history-export')),
        );
        await tester.pumpAndSettle();

        expect(clipboardText, isNotNull);
        expect(clipboardText, contains('Player 2 gained 2 life'));
        expect(clipboardText, contains('Game #12'));
        expect(
          logs.any(
            (message) =>
                message.contains('message=native_history_exported') &&
                message.contains('surface_strategy: native_fallback') &&
                message.contains('transfer_strategy: clipboard_export') &&
                message.contains('history_domain_present: true'),
          ),
          isTrue,
        );
      });
    });

    testWidgets(
      'imports native history into canonical stores from fallback shell',
      (tester) async {
        late _FakeLotusHost host;
        await _captureDebugLogs((logs) async {
          await LifeCounterSessionStore().save(
            LifeCounterSession.initial(playerCount: 4),
          );

          final transfer = LifeCounterHistoryTransfer(
            version: lifeCounterHistoryTransferVersion,
            exportedAt: DateTime.utc(2026, 4, 2, 12),
            archivedGameCount: 3,
            currentGameName: 'Imported Game',
            currentGameMeta: const {
              'id': 'import-42',
              'name': 'Imported Game',
              'startDate': 1711802000000,
              'gameMode': 'commander',
            },
            gameCounter: 42,
            lastTableEvent: 'Player 4 ganhou o monarchy',
            currentGameEntries: const [
              LifeCounterHistoryTransferEntry(
                message: 'Player 1 perdeu 2 de vida',
              ),
            ],
            archiveEntries: const [
              LifeCounterHistoryTransferEntry(
                message: 'Player 3 foi eliminado',
              ),
            ],
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
            '{"type":"open-native-history","source":"history_shortcut_pressed"}',
          );
          await tester.pumpAndSettle();

          await tester.tap(
            find.byKey(const Key('life-counter-native-history-import')),
          );
          await tester.pumpAndSettle();

          await tester.enterText(
            find.byKey(const Key('life-counter-native-history-import-input')),
            transfer.toJsonString(),
          );
          await tester.pumpAndSettle();

          await tester.tap(
            find.byKey(const Key('life-counter-native-history-import-confirm')),
          );
          await tester.pumpAndSettle();

          final historyState = await LifeCounterHistoryStore().load();
          final session = await LifeCounterSessionStore().load();
          expect(historyState, isNotNull);
          expect(historyState!.currentGameName, 'Imported Game');
          expect(historyState.currentGameMeta?['id'], 'import-42');
          expect(historyState.archivedGameCount, 3);
          expect(historyState.gameCounter, 42);
          expect(
            historyState.currentGameEntries.single.message,
            'Player 1 perdeu 2 de vida',
          );
          expect(
            historyState.archiveEntries.single.message,
            'Player 3 foi eliminado',
          );
          expect(session, isNotNull);
          expect(session!.lastTableEvent, 'Player 4 ganhou o monarchy');
          expect(host.loadBundleCallCount, 1);
          expect(
            logs.any(
              (message) =>
                  message.contains('message=native_history_imported') &&
                  message.contains('surface_strategy: native_fallback') &&
                  message.contains('transfer_strategy: clipboard_import') &&
                  message.contains('apply_strategy: canonical_store_sync') &&
                  message.contains('reload_required: false') &&
                  message.contains('history_domain_present: true') &&
                  message.contains('archived_games: 3'),
            ),
            isTrue,
          );
        });
      },
    );

    testWidgets('opens native card search from a shell fallback shortcut', (
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
          '{"type":"open-native-card-search","source":"card_search_shortcut_pressed"}',
        );
        await tester.pumpAndSettle();

        expect(find.text('Card Search'), findsOneWidget);
        expect(
          find.byKey(const Key('life-counter-native-card-search-input')),
          findsOneWidget,
        );
        expect(find.text('SOL RING'), findsOneWidget);
        expect(
          logs.any(
            (message) =>
                message.contains('message=native_card_search_opened') &&
                message.contains('surface_strategy: native_fallback') &&
                message.contains(
                  'fallback_classification: support_utility',
                ),
          ),
          isTrue,
        );
      });
    });

    testWidgets('shows ManaLoom-owned feedback for blocked external links', (
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
        'ManaLoom blocked an external link: https://play.google.com/store/apps/details?id=com.vanilla.mtgcounter',
      );
      await tester.pump();

      expect(
        find.text(
          'External shortcut disabled while ManaLoom owns the life counter shell.',
        ),
        findsOneWidget,
      );
    });
  });
}
