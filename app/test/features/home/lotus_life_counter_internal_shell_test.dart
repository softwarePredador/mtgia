import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
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
    });

    testWidgets('opens native history from a shell fallback shortcut', (
      tester,
    ) async {
      late _FakeLotusHost host;

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
    });

    testWidgets('exports native history from a shell fallback shortcut', (
      tester,
    ) async {
      late _FakeLotusHost host;

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
    });

    testWidgets('opens native card search from a shell fallback shortcut', (
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
        '{"type":"open-native-card-search","source":"card_search_shortcut_pressed"}',
      );
      await tester.pumpAndSettle();

      expect(find.text('Card Search'), findsOneWidget);
      expect(
        find.byKey(const Key('life-counter-native-card-search-input')),
        findsOneWidget,
      );
      expect(find.text('SOL RING'), findsOneWidget);
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
