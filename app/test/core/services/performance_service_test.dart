import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:manaloom/core/services/performance_service.dart';

void main() {
  setUp(() {
    PerformanceService.reset();
  });

  test(
    'traceAsync records local latency when Firebase is unavailable',
    () async {
      final service = PerformanceService.instance;

      final result = await service.traceAsync('web_core_probe', () async {
        await Future<void>.delayed(const Duration(milliseconds: 2));
        return 42;
      });

      expect(result, 42);
      final stats = service.getLocalStats()['web_core_probe'];
      expect(stats?['count'], 1);
      expect(stats?['error_count'], 0);
      expect(stats?['p50_ms'], isA<int>());
      expect(stats?['p95_ms'], isA<int>());
    },
  );

  test('traceAsync records failed operations and rethrows', () async {
    final service = PerformanceService.instance;

    await expectLater(
      service.traceAsync<void>('failed_probe', () async {
        throw StateError('expected');
      }),
      throwsStateError,
    );

    final stats = service.getLocalStats()['failed_probe'];
    expect(stats?['count'], 1);
    expect(stats?['error_count'], 1);
  });

  test('uses nearest-rank p50/p95 over a bounded rolling window', () {
    final service = PerformanceService.instance;
    for (var value = 1; value <= 120; value++) {
      service.recordLocalDuration('bounded_probe', value);
    }

    final stats = service.getLocalStats()['bounded_probe'];
    expect(stats?['count'], PerformanceService.maxSamplesPerSeries);
    expect(stats?['min_ms'], 21);
    expect(stats?['max_ms'], 120);
    expect(stats?['p50_ms'], 70);
    expect(stats?['p95_ms'], 115);
  });

  test('caps metric cardinality and aggregates overflow safely', () {
    final service = PerformanceService.instance;
    for (
      var index = 0;
      index < PerformanceService.maxLocalSeries + 3;
      index++
    ) {
      service.recordLocalDuration('dynamic_$index', index);
    }

    final stats = service.getLocalStats();
    expect(stats, hasLength(PerformanceService.maxLocalSeries + 1));
    expect(stats[PerformanceService.overflowSeriesName]?['count'], 3);
  });

  test('screen and custom traces keep local timing without Firebase', () async {
    final service = PerformanceService.instance;

    service.startScreenTrace('home');
    service.startTrace('fetch_decks');
    await Future<void>.delayed(const Duration(milliseconds: 2));
    service.stopScreenTrace('home');
    service.stopTrace('fetch_decks');

    final stats = service.getLocalStats();
    expect(stats['screen_home']?['count'], 1);
    expect(stats['fetch_decks']?['count'], 1);
  });

  test('navigator traces only the visible top route and resumes on pop', () {
    final observer = PerformanceNavigatorObserver();
    final home = MaterialPageRoute<void>(
      settings: const RouteSettings(name: '/home'),
      builder: (_) => const SizedBox.shrink(),
    );
    final decks = MaterialPageRoute<void>(
      settings: const RouteSettings(name: '/decks'),
      builder: (_) => const SizedBox.shrink(),
    );
    final legal = MaterialPageRoute<void>(
      settings: const RouteSettings(name: '/legal'),
      builder: (_) => const SizedBox.shrink(),
    );

    observer.didChangeTop(home, null);
    observer.didChangeTop(decks, home);
    observer.didChangeTop(home, decks);
    observer.didChangeTop(legal, home);

    final stats = PerformanceService.instance.getLocalStats();
    expect(stats['screen_home']?['count'], 2);
    expect(stats['screen_decks']?['count'], 1);
    expect(stats['screen_legal'], isNull);
  });
}
