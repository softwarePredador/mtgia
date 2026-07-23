import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:manaloom/core/api/api_client.dart';
import 'package:manaloom/core/services/performance_service.dart';
import 'package:manaloom/main.dart' as app;
import 'package:shared_preferences/shared_preferences.dart';

import 'runtime_test_helpers.dart';

const _email = String.fromEnvironment('MANALOOM_PERF_EMAIL');
const _password = String.fromEnvironment('MANALOOM_PERF_PASSWORD');
const _deckId = String.fromEnvironment('MANALOOM_PERF_DECK_ID');
const _cardId = String.fromEnvironment('MANALOOM_PERF_CARD_ID');
const _sampleCount = 7;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  }

  testWidgets('core surfaces stay inside p50/p95 runtime budgets', (
    tester,
  ) async {
    void reportStage(String stage, {int? sample}) {
      binding.reportData = <String, dynamic>{
        'stage': stage,
        if (sample != null) 'sample': sample,
      };
    }

    reportStage('fixture_preflight');
    expect(
      <String>[_email, _password, _deckId, _cardId],
      everyElement(isNotEmpty),
      reason: 'Performance fixture coordinates are required.',
    );
    if (!kIsWeb) {
      await binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => binding.setSurfaceSize(null));
    }

    // ignore: avoid_print
    print('MANALOOM_CORE_PERFORMANCE_STAGE authenticate');
    reportStage('authenticate');
    await _authenticateFixture();
    // ignore: avoid_print
    print('MANALOOM_CORE_PERFORMANCE_STAGE sample');
    final samples = <String, List<int>>{
      'app_rebuild': <int>[],
      'home': <int>[],
      'deck_list': <int>[],
      'set_search': <int>[],
      'card_detail': <int>[],
      'deck_detail': <int>[],
      'optimize_sheet': <int>[],
      'battle_replays': <int>[],
    };

    for (var index = 0; index < _sampleCount; index++) {
      reportStage('app_rebuild', sample: index + 1);
      samples['app_rebuild']!.add(await _restartApp(tester));
    }
    await _leaveMeasuredRoute(tester);

    for (var index = 0; index < _sampleCount; index++) {
      reportStage('home', sample: index + 1);
      samples['home']!.add(
        await _measureRoute(
          tester,
          '/home',
          find.byKey(const Key('home-hero-frame')),
        ),
      );
      await _leaveMeasuredRoute(tester);

      reportStage('deck_list', sample: index + 1);
      samples['deck_list']!.add(
        await _measureRoute(
          tester,
          '/decks',
          find.text('S3-07 Visual Fixture'),
        ),
      );
      await _leaveMeasuredRoute(tester);

      reportStage('set_search', sample: index + 1);
      samples['set_search']!.add(
        await _measureRoute(
          tester,
          '/collection/sets',
          find.text('S3-07 Visual Fixture Set'),
        ),
      );
      await _leaveMeasuredRoute(tester);

      reportStage('card_detail', sample: index + 1);
      samples['card_detail']!.add(
        await _measureRoute(
          tester,
          '/cards/$_cardId',
          find.byKey(const Key('card-detail-image-frame')),
        ),
      );
      await _leaveMeasuredRoute(tester);

      reportStage('deck_detail', sample: index + 1);
      samples['deck_detail']!.add(
        await _measureRoute(
          tester,
          '/decks/$_deckId',
          find.byKey(const Key('deck-overview-hero')),
        ),
      );
      await _leaveMeasuredRoute(tester);

      reportStage('battle_replays', sample: index + 1);
      samples['battle_replays']!.add(
        await _measureRoute(
          tester,
          '/decks/$_deckId/battle-replays',
          find.byKey(const Key('battle-replays-empty-state')),
        ),
      );
      await _leaveMeasuredRoute(tester);
    }

    // Three independent user-path samples provide p50/p95 while keeping the
    // benchmark well below the fixture's free-beta quota.
    for (var index = 0; index < 3; index++) {
      reportStage('optimize_sheet', sample: index + 1);
      samples['optimize_sheet']!.add(await _measureOptimizeSheet(tester));
      final sheetContext = tester.element(
        find.byKey(const Key('optimize-sheet-body')),
      );
      Navigator.of(sheetContext, rootNavigator: true).pop();
      await tester.pump();
      await _leaveMeasuredRoute(tester);
    }

    final budgets = _budgetsForPlatform();
    final summary = <String, dynamic>{
      'platform': kIsWeb ? 'web' : defaultTargetPlatform.name,
      'sample_count': _sampleCount,
      'metrics': <String, dynamic>{},
    };
    for (final entry in samples.entries) {
      final metric = _summarize(entry.value, budgetMs: budgets[entry.key]!);
      (summary['metrics'] as Map<String, dynamic>)[entry.key] = metric;
    }
    binding.reportData = <String, dynamic>{'core_performance': summary};

    for (final entry in (summary['metrics'] as Map<String, dynamic>).entries) {
      final metric = (entry.value as Map).cast<String, dynamic>();
      expect(
        metric['p95_ms'] as int,
        lessThanOrEqualTo(metric['budget_ms'] as int),
        reason: '${entry.key} exceeded its p95 budget: $metric',
      );
    }

    // ignore: avoid_print
    print('MANALOOM_CORE_PERFORMANCE ${jsonEncode(summary)}');
  });
}

Future<void> _authenticateFixture() async {
  await clearRuntimeAuth();
  PerformanceService.reset();
  final response = await ApiClient().post('/auth/login', <String, String>{
    'email': _email,
    'password': _password,
  });
  if (response.statusCode != 200) {
    fail('Performance fixture login returned HTTP ${response.statusCode}.');
  }
  final payload = (response.data as Map).cast<String, dynamic>();
  final token = payload['token']?.toString();
  final user = (payload['user'] as Map?)?.cast<String, dynamic>();
  expect(token, isNotNull);
  expect(user, isNotNull);

  ApiClient.setToken(token);
  final preferences = await SharedPreferences.getInstance();
  await preferences.setString('auth_token', token!);
  await preferences.setString('user_data', jsonEncode(user));
  await markRuntimeOnboardingSettled(user!['id']?.toString() ?? '');
}

Future<int> _restartApp(WidgetTester tester) async {
  await tester.pumpAndSettle(
    const Duration(milliseconds: 50),
    EnginePhase.sendSemanticsUpdate,
    const Duration(seconds: 5),
  );
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpAndSettle(
    const Duration(milliseconds: 50),
    EnginePhase.sendSemanticsUpdate,
    const Duration(seconds: 5),
  );
  final stopwatch = Stopwatch()..start();
  await tester.pumpWidget(app.ManaLoomApp(key: UniqueKey()));
  await tester.pump();
  await pumpUntilFound(
    tester,
    find.byKey(const Key('home-hero-frame')),
    attempts: 160,
    step: const Duration(milliseconds: 50),
  );
  stopwatch.stop();
  PerformanceService.instance.recordLocalDuration(
    'core_app_rebuild',
    stopwatch.elapsedMilliseconds,
  );
  expect(tester.takeException(), isNull);
  return stopwatch.elapsedMilliseconds;
}

Future<int> _measureRoute(
  WidgetTester tester,
  String location,
  Finder ready,
) async {
  final context = tester.element(find.byType(Scaffold).first);
  final stopwatch = Stopwatch()..start();
  GoRouter.of(context).go(location);
  await tester.pump();
  await pumpUntilFound(
    tester,
    ready,
    attempts: 200,
    step: const Duration(milliseconds: 50),
  );
  stopwatch.stop();
  PerformanceService.instance.recordLocalDuration(
    'core_route_${_metricSafeLocation(location)}',
    stopwatch.elapsedMilliseconds,
  );
  expectNoRawTechnicalErrorText(tester);
  expect(tester.takeException(), isNull, reason: 'route=$location');
  return stopwatch.elapsedMilliseconds;
}

Future<int> _measureOptimizeSheet(WidgetTester tester) async {
  final binding = IntegrationTestWidgetsFlutterBinding.instance;
  final context = tester.element(find.byType(Scaffold).first);
  final stopwatch = Stopwatch()..start();
  binding.reportData = <String, dynamic>{'stage': 'optimize_navigate'};
  GoRouter.of(context).go('/decks/$_deckId');
  await tester.pump();
  await pumpUntilFound(
    tester,
    find.byKey(const Key('deck-overview-hero')),
    attempts: 200,
    step: const Duration(milliseconds: 50),
  );
  final optimizeButton = find.byKey(const Key('deck-optimize-button'));
  binding.reportData = <String, dynamic>{'stage': 'optimize_reveal_button'};
  await tester.ensureVisible(optimizeButton);
  await tester.pumpAndSettle(const Duration(milliseconds: 50));
  expect(optimizeButton.hitTestable(), findsOneWidget);
  binding.reportData = <String, dynamic>{'stage': 'optimize_tap_button'};
  await tester.tap(optimizeButton.hitTestable());
  await tester.pump();
  binding.reportData = <String, dynamic>{'stage': 'optimize_wait_sheet'};
  await pumpUntilFound(
    tester,
    find.byKey(const Key('optimize-sheet-body')),
    attempts: 400,
    step: const Duration(milliseconds: 50),
  );
  stopwatch.stop();
  PerformanceService.instance.recordLocalDuration(
    'core_optimize_sheet',
    stopwatch.elapsedMilliseconds,
  );
  expectNoRawTechnicalErrorText(tester);
  expect(tester.takeException(), isNull);
  return stopwatch.elapsedMilliseconds;
}

Future<void> _leaveMeasuredRoute(WidgetTester tester) async {
  await tester.pumpAndSettle(
    const Duration(milliseconds: 50),
    EnginePhase.sendSemanticsUpdate,
    const Duration(seconds: 5),
  );
  final context = tester.element(find.byType(Scaffold).first);
  GoRouter.of(context).go('/legal');
  await tester.pump();
  await pumpUntilFound(
    tester,
    find.byKey(const Key('legal-content')),
    attempts: 80,
    step: const Duration(milliseconds: 25),
  );
  await tester.pumpAndSettle(
    const Duration(milliseconds: 50),
    EnginePhase.sendSemanticsUpdate,
    const Duration(seconds: 5),
  );
}

Map<String, int> _budgetsForPlatform() {
  final routeBudget = kIsWeb ? 3500 : 4000;
  return <String, int>{
    'app_rebuild': kIsWeb ? 4500 : 5500,
    'home': routeBudget,
    'deck_list': routeBudget,
    'set_search': routeBudget,
    'card_detail': routeBudget,
    'deck_detail': routeBudget,
    'optimize_sheet': kIsWeb ? 4000 : 4500,
    'battle_replays': routeBudget,
  };
}

Map<String, Object> _summarize(List<int> values, {required int budgetMs}) {
  final sorted = List<int>.of(values)..sort();
  return <String, Object>{
    'samples': sorted.length,
    'values_ms': sorted,
    'p50_ms': _percentile(sorted, 0.50),
    'p95_ms': _percentile(sorted, 0.95),
    'max_ms': sorted.last,
    'budget_ms': budgetMs,
  };
}

int _percentile(List<int> sorted, double percentile) {
  final rank = (percentile * sorted.length).ceil();
  return sorted[(rank - 1).clamp(0, sorted.length - 1)];
}

String _metricSafeLocation(String location) {
  return location
      .split('?')
      .first
      .replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
}
