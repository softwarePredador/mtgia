import 'package:server/ai/battle_engine_config.dart';
import 'package:server/ai/forge_battle_client.dart';
import 'package:server/ai/xmage_battle_client.dart';
import 'package:server/battle/battle_execution_runtime.dart';
import 'package:server/battle/battle_request_correlation.dart';
import 'package:server/battle/battle_simulation_attempt_service.dart';
import 'package:test/test.dart';

void main() {
  test(
    'auto fallback records every engine request and its trust source',
    () async {
      final adapter = _FakeAdapter(
        xmage:
            (_, _) async =>
                throw XmageCoverageIncomplete(const [
                  {'name': 'Unsupported X'},
                ], 'xmage gap'),
        forge:
            (_, _) async =>
                throw ForgeCoverageIncomplete(const [
                  {'name': 'Unsupported F'},
                ], 'forge gap'),
        native:
            (_, _) async => {
              'status': 'completed',
              'engine': 'manaloom_native_reviewed',
              'engine_contract': 'native_reviewed_rules_execution',
              'turns': 4,
              'sidecar_process_id': 'native:123',
            },
      );
      final runtime = BattleExecutionRuntime(
        config: _config('auto'),
        adapter: adapter,
      );

      final result = await runtime.execute(
        request: _request(),
        requestedEngine: 'auto',
        jobRequestSchemaVersion: battleJobRequestSchema,
        jobRequestHash: 'a' * 64,
      );

      expect(adapter.calls, ['xmage', 'forge', 'native']);
      expect(result.correlation.jobRequestHash, 'a' * 64);
      expect(result.correlation.dispatchTrace, hasLength(3));
      expect(result.correlation.dispatchTrace.map((entry) => entry.outcome), [
        'coverage_incomplete',
        'coverage_incomplete',
        'completed',
      ]);
      expect(
        result.correlation.dispatchTrace
            .take(2)
            .every(
              (entry) =>
                  entry.correlationSource == sidecarEchoValidatedCorrelation,
            ),
        isTrue,
      );
      expect(
        result.correlation.dispatchTrace.last.correlationSource,
        serverDispatchRecordedCorrelation,
      );
      expect(
        result.correlation.dispatchTrace
            .map((entry) => entry.requestHash)
            .toSet(),
        hasLength(3),
      );
      expect(result.result['request_correlation'], result.correlation.toJson());
    },
  );

  test('operational failure never silently falls back', () async {
    final adapter = _FakeAdapter(
      xmage:
          (_, _) async =>
              throw XmageServiceException('connection failed', statusCode: 502),
    );
    final runtime = BattleExecutionRuntime(
      config: _config('auto'),
      adapter: adapter,
    );

    try {
      await runtime.execute(
        request: _request(),
        requestedEngine: 'auto',
        jobRequestSchemaVersion: battleJobRequestSchema,
        jobRequestHash: 'c' * 64,
      );
      fail('The operational XMage failure must be terminal.');
    } on BattleExecutionRuntimeFailure catch (error) {
      expect(error.outcome, BattleSimulationAttemptOutcome.engineError);
      expect(error.code, 'xmage_unavailable');
      expect(error.dispatchTrace, hasLength(1));
      expect(
        error.dispatchTrace.single.correlationSource,
        serverDispatchRecordedCorrelation,
        reason:
            'A failed response cannot be described as a sidecar-echoed hash.',
      );
      expect(error.correlation?.jobRequestHash, 'c' * 64);
      expect(
        error.correlation?.engineRequestHash,
        error.dispatchTrace.single.requestHash,
      );
      expect(error.partialResult['engine'], 'xmage');
      expect(
        error.partialResult['request_correlation'],
        error.correlation?.toJson(),
      );
    }
    expect(adapter.calls, ['xmage']);
  });

  test('strict Forge coverage gap is a typed terminal outcome', () async {
    final adapter = _FakeAdapter(
      forge:
          (_, _) async =>
              throw ForgeCoverageIncomplete(const [
                {'name': 'Unsupported Forge card'},
              ], 'forge gap'),
    );
    final runtime = BattleExecutionRuntime(
      config: _config('forge'),
      adapter: adapter,
    );

    await expectLater(
      runtime.execute(request: _request(), requestedEngine: 'forge'),
      throwsA(
        isA<BattleExecutionRuntimeFailure>()
            .having(
              (error) => error.outcome,
              'outcome',
              BattleSimulationAttemptOutcome.coverageError,
            )
            .having((error) => error.code, 'code', 'forge_coverage_incomplete'),
      ),
    );
    expect(adapter.calls, ['forge']);
  });

  test('cancellation before dispatch does not contact an engine', () async {
    final adapter = _FakeAdapter();
    final runtime = BattleExecutionRuntime(
      config: _config('native'),
      adapter: adapter,
    );

    await expectLater(
      runtime.execute(
        request: _request(),
        requestedEngine: 'native',
        cancellationRequested: () async => true,
      ),
      throwsA(
        isA<BattleExecutionRuntimeFailure>().having(
          (error) => error.reason,
          'reason',
          'cancelled_before_engine_dispatch',
        ),
      ),
    );
    expect(adapter.calls, isEmpty);
  });

  test(
    'native correlation is explicitly server-recorded, not sidecar-echoed',
    () async {
      late Map<String, dynamic> dispatched;
      final adapter = _FakeAdapter(
        native: (request, _) async {
          dispatched = request;
          return {
            'status': 'completed',
            'engine': 'manaloom_native_reviewed',
            'engine_contract': 'native_reviewed_rules_execution',
            'turns': 3,
            'sidecar_process_id': 'native:456',
          };
        },
      );
      final runtime = BattleExecutionRuntime(
        config: _config('native'),
        adapter: adapter,
      );

      final result = await runtime.execute(
        request: _request(),
        requestedEngine: 'native',
        jobRequestSchemaVersion: battleJobRequestSchema,
        jobRequestHash: 'b' * 64,
      );

      expect(dispatched['request_schema_version'], nativeBattleDispatchSchema);
      expect(
        dispatched['request_hash'],
        canonicalNativeBattleDispatchHash(dispatched),
      );
      expect(
        result.correlation.correlationSource,
        serverDispatchRecordedCorrelation,
      );
      expect(
        result.result.containsKey('request_hash'),
        isFalse,
        reason: 'The native sidecar did not echo this field.',
      );
    },
  );
}

typedef _Dispatch =
    Future<Map<String, dynamic>> Function(
      Map<String, dynamic> request,
      int timeoutMs,
    );

class _FakeAdapter implements BattleEngineDispatchAdapter {
  _FakeAdapter({_Dispatch? xmage, _Dispatch? forge, _Dispatch? native})
    : _xmage = xmage ?? _unexpected('xmage'),
      _forge = forge ?? _unexpected('forge'),
      _native = native ?? _unexpected('native');

  final _Dispatch _xmage;
  final _Dispatch _forge;
  final _Dispatch _native;
  final List<String> calls = [];

  static _Dispatch _unexpected(String engine) =>
      (_, _) async => throw StateError('$engine dispatch was unexpected');

  @override
  Future<Map<String, dynamic>> simulateXmage({
    required BattleEngineConfig config,
    required Map<String, dynamic> request,
    required int timeoutMs,
  }) {
    calls.add('xmage');
    return _xmage(request, timeoutMs);
  }

  @override
  Future<Map<String, dynamic>> simulateForge({
    required BattleEngineConfig config,
    required Map<String, dynamic> request,
    required int timeoutMs,
  }) {
    calls.add('forge');
    return _forge(request, timeoutMs);
  }

  @override
  Future<Map<String, dynamic>> simulateNative({
    required BattleEngineConfig config,
    required Map<String, dynamic> request,
    required int timeoutMs,
  }) {
    calls.add('native');
    return _native(request, timeoutMs);
  }
}

BattleEngineConfig _config(String mode) => BattleEngineConfig.fromEnvironment({
  'BATTLE_ENGINE': mode,
  'XMAGE_SIDECAR_URL': 'http://xmage.invalid',
  'FORGE_SIDECAR_URL': 'http://forge.invalid',
  'NATIVE_BATTLE_SIDECAR_URL': 'http://native.invalid',
});

Map<String, dynamic> _request() => {
  'request_id': 'battle-job-33333333-3333-4333-8333-333333333333',
  'seed': 7,
  'timeout_ms': 12000,
  'max_turns': 30,
  'test_objective': 'general',
  'focus_cards': const <String>[],
  'force_focus_access_mode': 'none',
  'same_lane': false,
  'natural_sample': true,
  'deck_a': {
    'id': '11111111-1111-4111-8111-111111111111',
    'name': 'A',
    'cards': [
      {
        'name': 'Card A',
        'set_code': 'TST',
        'collector_number': '1',
        'quantity': 100,
        'is_commander': false,
      },
    ],
  },
  'deck_b': {
    'id': '22222222-2222-4222-8222-222222222222',
    'name': 'B',
    'cards': [
      {
        'name': 'Card B',
        'set_code': 'TST',
        'collector_number': '2',
        'quantity': 100,
        'is_commander': false,
      },
    ],
  },
};
