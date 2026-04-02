import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:manaloom/features/home/life_counter_route.dart';
import 'package:manaloom/features/home/lotus/lotus_host.dart';
import 'package:manaloom/features/home/lotus/lotus_js_bridges.dart';
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
    setUp(() {
      SharedPreferences.setMockInitialValues({});
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

