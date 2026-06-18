import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import '../lib/ai/optimize_runtime_support.dart' as runtime;
import '../lib/ai/optimize_swap_candidate_support.dart';

Pool _unusedPool() {
  return Pool.withEndpoints(
    [
      Endpoint(
        host: '127.0.0.1',
        port: 65535,
        database: 'unused',
        username: 'unused',
        password: 'unused',
      ),
    ],
    settings: const PoolSettings(maxConnectionCount: 1),
  );
}

void main() {
  group('optimize swap candidate support', () {
    test('returns no swaps for empty deck without touching database', () async {
      final pool = _unusedPool();
      addTearDown(pool.close);

      final result = await buildDeterministicOptimizeSwapCandidates(
        pool: pool,
        allCardData: const [],
        commanders: const ['Talrand, Sky Summoner'],
        commanderColorIdentity: const {'U'},
        targetArchetype: 'control',
        bracket: 2,
        keepTheme: true,
        detectedTheme: null,
        coreCards: const [],
        commanderPriorityNames: const [],
      );

      expect(result, isEmpty);
    });

    test('runtime re-export keeps existing swap builder API compatible',
        () async {
      final pool = _unusedPool();
      addTearDown(pool.close);

      final result = await runtime.buildDeterministicOptimizeSwapCandidates(
        pool: pool,
        allCardData: const [],
        commanders: const ['Talrand, Sky Summoner'],
        commanderColorIdentity: const {'U'},
        targetArchetype: 'control',
        bracket: 2,
        keepTheme: true,
        detectedTheme: null,
        coreCards: const [],
        commanderPriorityNames: const [],
      );

      expect(result, isEmpty);
      expect(runtime.findSynergyReplacements, isA<Function>());
    });
  });
}
