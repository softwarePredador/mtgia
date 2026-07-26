import 'dart:io';

import '../ai/battle_engine_config.dart';
import '../ai/forge_battle_client.dart';
import '../ai/native_battle_client.dart';
import '../ai/xmage_battle_client.dart';
import 'battle_request_correlation.dart';
import 'battle_simulation_attempt_service.dart';

const battleExternalClientGrace = Duration(seconds: 8);

typedef BattleRuntimeCheckpoint =
    Future<void> Function(String stage, int current, int total);
typedef BattleRuntimeCancellationCheck = Future<bool> Function();

class BattleExecutionRuntimeResult {
  const BattleExecutionRuntimeResult({
    required this.result,
    required this.correlation,
  });

  final Map<String, dynamic> result;
  final BattleRequestCorrelation correlation;
}

class BattleExecutionRuntimeFailure implements Exception {
  const BattleExecutionRuntimeFailure({
    required this.outcome,
    required this.code,
    required this.reason,
    required this.message,
    required this.engine,
    required this.dispatchTrace,
    this.upstreamStatusCode,
    this.unsupportedCards = const [],
    this.fallbackReason = 'none',
    this.engineSelectionReason,
    this.fallbackChain = const [],
    this.partialResult = const {},
    this.correlation,
  });

  final BattleSimulationAttemptOutcome outcome;
  final String code;
  final String reason;
  final String message;
  final String engine;
  final int? upstreamStatusCode;
  final List<Map<String, dynamic>> unsupportedCards;
  final String fallbackReason;
  final String? engineSelectionReason;
  final List<String> fallbackChain;
  final List<BattleEngineDispatchRecord> dispatchTrace;
  final Map<String, dynamic> partialResult;
  final BattleRequestCorrelation? correlation;

  bool get timedOut => outcome == BattleSimulationAttemptOutcome.timeout;
}

abstract interface class BattleEngineDispatchAdapter {
  Future<Map<String, dynamic>> simulateXmage({
    required BattleEngineConfig config,
    required Map<String, dynamic> request,
    required int timeoutMs,
  });

  Future<Map<String, dynamic>> simulateForge({
    required BattleEngineConfig config,
    required Map<String, dynamic> request,
    required int timeoutMs,
  });

  Future<Map<String, dynamic>> simulateNative({
    required BattleEngineConfig config,
    required Map<String, dynamic> request,
    required int timeoutMs,
  });
}

class HttpBattleEngineDispatchAdapter implements BattleEngineDispatchAdapter {
  const HttpBattleEngineDispatchAdapter();

  @override
  Future<Map<String, dynamic>> simulateXmage({
    required BattleEngineConfig config,
    required Map<String, dynamic> request,
    required int timeoutMs,
  }) async {
    final client = XmageBattleClient(
      baseUrl: config.xmageSidecarUrl,
      timeout: Duration(milliseconds: timeoutMs) + battleExternalClientGrace,
      expectedIdentity: config.xmageIdentity,
      allowLegacyIdentity: config.allowLegacySidecarIdentity,
    );
    try {
      return await client.simulate(request);
    } finally {
      client.close();
    }
  }

  @override
  Future<Map<String, dynamic>> simulateForge({
    required BattleEngineConfig config,
    required Map<String, dynamic> request,
    required int timeoutMs,
  }) async {
    final client = ForgeBattleClient(
      baseUrl: config.forgeSidecarUrl,
      timeout: Duration(milliseconds: timeoutMs) + battleExternalClientGrace,
      expectedIdentity: config.forgeIdentity,
      allowLegacyIdentity: config.allowLegacySidecarIdentity,
    );
    try {
      return await client.simulate(request);
    } finally {
      client.close();
    }
  }

  @override
  Future<Map<String, dynamic>> simulateNative({
    required BattleEngineConfig config,
    required Map<String, dynamic> request,
    required int timeoutMs,
  }) async {
    final client = NativeBattleClient(
      baseUrl: config.nativeSidecarUrl,
      timeout: Duration(milliseconds: timeoutMs) + battleExternalClientGrace,
    );
    try {
      return await client.simulate(request);
    } finally {
      client.close();
    }
  }
}

class BattleExecutionRuntime {
  const BattleExecutionRuntime({
    required this.config,
    this.adapter = const HttpBattleEngineDispatchAdapter(),
  });

  factory BattleExecutionRuntime.fromEnvironment(
    Map<String, String> environment, {
    required String requestedEngine,
    BattleEngineDispatchAdapter adapter =
        const HttpBattleEngineDispatchAdapter(),
  }) {
    return BattleExecutionRuntime(
      config: BattleEngineConfig.fromEnvironment({
        ...environment,
        'BATTLE_ENGINE': requestedEngine,
      }),
      adapter: adapter,
    );
  }

  final BattleEngineConfig config;
  final BattleEngineDispatchAdapter adapter;

  Future<BattleExecutionRuntimeResult> execute({
    required Map<String, dynamic> request,
    required String requestedEngine,
    String? jobRequestSchemaVersion,
    String? jobRequestHash,
    BattleRuntimeCheckpoint? checkpoint,
    BattleRuntimeCancellationCheck? cancellationRequested,
  }) async {
    if (!const {'auto', 'xmage', 'forge', 'native'}.contains(requestedEngine)) {
      throw ArgumentError.value(requestedEngine, 'requestedEngine');
    }
    if (requestedEngine != 'native' &&
        request['force_focus_access_mode']?.toString() != 'none') {
      throw BattleExecutionRuntimeFailure(
        outcome: BattleSimulationAttemptOutcome.cancelled,
        code: 'external_battle_control_unsupported',
        reason: 'external_battle_control_unsupported',
        message:
            'Forced card access is available only in the reviewed native engine.',
        engine: requestedEngine,
        dispatchTrace: const [],
      );
    }

    final trace = <BattleEngineDispatchRecord>[];
    await _checkCancelled(
      cancellationRequested,
      trace: trace,
      engine: requestedEngine,
    );

    if (requestedEngine == 'native') {
      return _native(
        request: request,
        trace: trace,
        jobRequestSchemaVersion: jobRequestSchemaVersion,
        jobRequestHash: jobRequestHash,
        checkpoint: checkpoint,
        cancellationRequested: cancellationRequested,
        selectionReason: 'strict_native_mode',
        fallbackReason: 'none',
        fallbackChain: const ['native'],
      );
    }
    if (requestedEngine == 'forge') {
      try {
        return await _forge(
          request: request,
          trace: trace,
          jobRequestSchemaVersion: jobRequestSchemaVersion,
          jobRequestHash: jobRequestHash,
          checkpoint: checkpoint,
          cancellationRequested: cancellationRequested,
          selectionReason: 'strict_forge_mode',
          fallbackReason: 'none',
          fallbackChain: const ['forge'],
        );
      } on ForgeCoverageIncomplete catch (error) {
        throw _coverageFailure(
          engine: 'forge',
          code: 'forge_coverage_incomplete',
          reason: 'forge_coverage_incomplete',
          message: error.message,
          unsupportedCards: error.unsupportedCards,
          trace: trace,
          jobRequestSchemaVersion: jobRequestSchemaVersion,
          jobRequestHash: jobRequestHash,
          selectionReason: 'strict_forge_mode',
          fallbackChain: const ['forge:coverage_incomplete'],
        );
      }
    }

    try {
      return await _xmage(
        request: request,
        trace: trace,
        jobRequestSchemaVersion: jobRequestSchemaVersion,
        jobRequestHash: jobRequestHash,
        checkpoint: checkpoint,
        cancellationRequested: cancellationRequested,
        selectionReason:
            requestedEngine == 'xmage'
                ? 'strict_xmage_mode'
                : 'auto_primary_xmage',
      );
    } on XmageCoverageIncomplete catch (error) {
      if (requestedEngine == 'xmage') {
        throw _coverageFailure(
          engine: 'xmage',
          code: 'xmage_coverage_incomplete',
          reason: 'xmage_coverage_incomplete',
          message: error.message,
          unsupportedCards: error.unsupportedCards,
          trace: trace,
          jobRequestSchemaVersion: jobRequestSchemaVersion,
          jobRequestHash: jobRequestHash,
          selectionReason: 'strict_xmage_mode',
          fallbackChain: const ['xmage:coverage_incomplete'],
        );
      }
      await _checkCancelled(
        cancellationRequested,
        trace: trace,
        engine: 'xmage',
      );
      try {
        return await _forge(
          request: request,
          trace: trace,
          jobRequestSchemaVersion: jobRequestSchemaVersion,
          jobRequestHash: jobRequestHash,
          checkpoint: checkpoint,
          cancellationRequested: cancellationRequested,
          selectionReason: 'auto_secondary_forge_after_coverage_gap',
          fallbackReason: 'xmage_coverage_incomplete',
          fallbackChain: const ['xmage:coverage_incomplete', 'forge'],
          xmageUnsupportedCards: error.unsupportedCards,
        );
      } on ForgeCoverageIncomplete catch (forgeError) {
        await _checkCancelled(
          cancellationRequested,
          trace: trace,
          engine: 'forge',
        );
        return _native(
          request: request,
          trace: trace,
          jobRequestSchemaVersion: jobRequestSchemaVersion,
          jobRequestHash: jobRequestHash,
          checkpoint: checkpoint,
          cancellationRequested: cancellationRequested,
          selectionReason: 'auto_native_after_external_coverage_gaps',
          fallbackReason: 'xmage_coverage_incomplete_forge_coverage_incomplete',
          fallbackChain: const [
            'xmage:coverage_incomplete',
            'forge:coverage_incomplete',
            'native',
          ],
          xmageUnsupportedCards: error.unsupportedCards,
          forgeUnsupportedCards: forgeError.unsupportedCards,
        );
      }
    }
  }

  Future<BattleExecutionRuntimeResult> _xmage({
    required Map<String, dynamic> request,
    required List<BattleEngineDispatchRecord> trace,
    required String? jobRequestSchemaVersion,
    required String? jobRequestHash,
    required BattleRuntimeCheckpoint? checkpoint,
    required BattleRuntimeCancellationCheck? cancellationRequested,
    required String selectionReason,
  }) async {
    final envelope = buildExternalBattleRequestEnvelope(
      request: request,
      identity: config.xmageIdentity,
    );
    final requestHash = envelope['request_hash']! as String;
    await _checkpoint(checkpoint, 'starting_engine', 15, 100);
    try {
      final result = await adapter.simulateXmage(
        config: config,
        request: envelope,
        timeoutMs: _timeoutMs(request),
      );
      trace.add(
        BattleEngineDispatchRecord(
          engine: 'xmage',
          requestSchemaVersion: externalBattleRequestSchema,
          requestHash: requestHash,
          correlationSource: sidecarEchoValidatedCorrelation,
          outcome: 'completed',
        ),
      );
      await _checkCancelled(
        cancellationRequested,
        trace: trace,
        engine: 'xmage',
        result: result,
        correlation: _correlation(
          trace,
          envelope,
          jobRequestSchemaVersion,
          jobRequestHash,
          sidecarEchoValidatedCorrelation,
        ),
      );
      result['engine_contract'] = 'canonical_rules_execution';
      result['fallback_reason'] = 'none';
      result['engine_selection_reason'] = selectionReason;
      result['fallback_chain'] = const ['xmage'];
      await _checkpoint(checkpoint, 'running', 75, 100);
      return _success(
        result,
        trace,
        envelope,
        jobRequestSchemaVersion,
        jobRequestHash,
        sidecarEchoValidatedCorrelation,
      );
    } on XmageCoverageIncomplete {
      trace.add(
        BattleEngineDispatchRecord(
          engine: 'xmage',
          requestSchemaVersion: externalBattleRequestSchema,
          requestHash: requestHash,
          correlationSource: sidecarEchoValidatedCorrelation,
          outcome: 'coverage_incomplete',
          errorCode: 'xmage_coverage_incomplete',
        ),
      );
      rethrow;
    } on XmageServiceException catch (error) {
      trace.add(
        BattleEngineDispatchRecord(
          engine: 'xmage',
          requestSchemaVersion: externalBattleRequestSchema,
          requestHash: requestHash,
          correlationSource: serverDispatchRecordedCorrelation,
          outcome: _operationalOutcome(error.statusCode),
          errorCode: _operationalCode('xmage', error.statusCode),
        ),
      );
      throw _operationalFailure(
        engine: 'xmage',
        message: error.message,
        statusCode: error.statusCode,
        trace: trace,
        jobRequestSchemaVersion: jobRequestSchemaVersion,
        jobRequestHash: jobRequestHash,
      );
    }
  }

  Future<BattleExecutionRuntimeResult> _forge({
    required Map<String, dynamic> request,
    required List<BattleEngineDispatchRecord> trace,
    required String? jobRequestSchemaVersion,
    required String? jobRequestHash,
    required BattleRuntimeCheckpoint? checkpoint,
    required BattleRuntimeCancellationCheck? cancellationRequested,
    required String selectionReason,
    required String fallbackReason,
    required List<String> fallbackChain,
    List<Map<String, dynamic>> xmageUnsupportedCards = const [],
  }) async {
    final envelope = buildExternalBattleRequestEnvelope(
      request: request,
      identity: config.forgeIdentity,
    );
    final requestHash = envelope['request_hash']! as String;
    await _checkpoint(checkpoint, 'starting_engine', 35, 100);
    try {
      final result = await adapter.simulateForge(
        config: config,
        request: envelope,
        timeoutMs: _timeoutMs(request),
      );
      trace.add(
        BattleEngineDispatchRecord(
          engine: 'forge',
          requestSchemaVersion: externalBattleRequestSchema,
          requestHash: requestHash,
          correlationSource: sidecarEchoValidatedCorrelation,
          outcome: 'completed',
        ),
      );
      final correlation = _correlation(
        trace,
        envelope,
        jobRequestSchemaVersion,
        jobRequestHash,
        sidecarEchoValidatedCorrelation,
      );
      await _checkCancelled(
        cancellationRequested,
        trace: trace,
        engine: 'forge',
        result: result,
        correlation: correlation,
      );
      result['engine_contract'] = 'canonical_rules_execution_secondary';
      result['fallback_reason'] = fallbackReason;
      result['engine_selection_reason'] = selectionReason;
      result['fallback_chain'] = fallbackChain;
      if (xmageUnsupportedCards.isNotEmpty) {
        result['xmage_unsupported_cards'] = xmageUnsupportedCards;
      }
      await _checkpoint(checkpoint, 'running', 80, 100);
      return BattleExecutionRuntimeResult(
        result: _attachCorrelation(result, correlation),
        correlation: correlation,
      );
    } on ForgeCoverageIncomplete {
      trace.add(
        BattleEngineDispatchRecord(
          engine: 'forge',
          requestSchemaVersion: externalBattleRequestSchema,
          requestHash: requestHash,
          correlationSource: sidecarEchoValidatedCorrelation,
          outcome: 'coverage_incomplete',
          errorCode: 'forge_coverage_incomplete',
        ),
      );
      rethrow;
    } on ForgeServiceException catch (error) {
      trace.add(
        BattleEngineDispatchRecord(
          engine: 'forge',
          requestSchemaVersion: externalBattleRequestSchema,
          requestHash: requestHash,
          correlationSource: serverDispatchRecordedCorrelation,
          outcome: _operationalOutcome(error.statusCode),
          errorCode: _operationalCode('forge', error.statusCode),
        ),
      );
      throw _operationalFailure(
        engine: 'forge',
        message: error.message,
        statusCode: error.statusCode,
        trace: trace,
        jobRequestSchemaVersion: jobRequestSchemaVersion,
        jobRequestHash: jobRequestHash,
        fallbackReason: fallbackReason,
        selectionReason: selectionReason,
      );
    }
  }

  Future<BattleExecutionRuntimeResult> _native({
    required Map<String, dynamic> request,
    required List<BattleEngineDispatchRecord> trace,
    required String? jobRequestSchemaVersion,
    required String? jobRequestHash,
    required BattleRuntimeCheckpoint? checkpoint,
    required BattleRuntimeCancellationCheck? cancellationRequested,
    required String selectionReason,
    required String fallbackReason,
    required List<String> fallbackChain,
    List<Map<String, dynamic>> xmageUnsupportedCards = const [],
    List<Map<String, dynamic>> forgeUnsupportedCards = const [],
  }) async {
    final envelope = <String, dynamic>{
      ...request,
      'request_schema_version': nativeBattleDispatchSchema,
      if (jobRequestSchemaVersion != null)
        'job_request_schema_version': jobRequestSchemaVersion,
      if (jobRequestHash != null) 'job_request_hash': jobRequestHash,
      'required_rule_cards': _allDeckCardRows(request),
      'natural_sample': request['natural_sample'] != false,
    };
    final requestHash = canonicalNativeBattleDispatchHash(envelope);
    envelope['request_hash'] = requestHash;
    await _checkpoint(checkpoint, 'starting_engine', 55, 100);
    try {
      final result = await adapter.simulateNative(
        config: config,
        request: envelope,
        timeoutMs: _timeoutMs(request),
      );
      trace.add(
        BattleEngineDispatchRecord(
          engine: 'native',
          requestSchemaVersion: nativeBattleDispatchSchema,
          requestHash: requestHash,
          correlationSource: serverDispatchRecordedCorrelation,
          outcome: 'completed',
        ),
      );
      final correlation = _correlation(
        trace,
        envelope,
        jobRequestSchemaVersion,
        jobRequestHash,
        serverDispatchRecordedCorrelation,
      );
      await _checkCancelled(
        cancellationRequested,
        trace: trace,
        engine: 'native',
        result: result,
        correlation: correlation,
      );
      result['fallback_reason'] = fallbackReason;
      result['engine_selection_reason'] = selectionReason;
      result['fallback_chain'] = fallbackChain;
      if (xmageUnsupportedCards.isNotEmpty) {
        result['xmage_unsupported_cards'] = xmageUnsupportedCards;
      }
      if (forgeUnsupportedCards.isNotEmpty) {
        result['forge_unsupported_cards'] = forgeUnsupportedCards;
      }
      await _checkpoint(checkpoint, 'running', 85, 100);
      return BattleExecutionRuntimeResult(
        result: _attachCorrelation(result, correlation),
        correlation: correlation,
      );
    } on NativeBattleCoverageIncomplete catch (error) {
      trace.add(
        BattleEngineDispatchRecord(
          engine: 'native',
          requestSchemaVersion: nativeBattleDispatchSchema,
          requestHash: requestHash,
          correlationSource: serverDispatchRecordedCorrelation,
          outcome: 'coverage_incomplete',
          errorCode: 'native_coverage_incomplete',
        ),
      );
      throw _coverageFailure(
        engine: 'native',
        code: 'native_coverage_incomplete',
        reason:
            trace.length > 1
                ? 'all_engines_coverage_incomplete'
                : 'native_coverage_incomplete',
        message: error.message,
        unsupportedCards: error.unsupportedCards,
        trace: trace,
        jobRequestSchemaVersion: jobRequestSchemaVersion,
        jobRequestHash: jobRequestHash,
        fallbackReason: fallbackReason,
        selectionReason: selectionReason,
        fallbackChain: [
          ...fallbackChain.take(fallbackChain.length - 1),
          'native:coverage_incomplete',
        ],
      );
    } on NativeBattleServiceException catch (error) {
      trace.add(
        BattleEngineDispatchRecord(
          engine: 'native',
          requestSchemaVersion: nativeBattleDispatchSchema,
          requestHash: requestHash,
          correlationSource: serverDispatchRecordedCorrelation,
          outcome: _operationalOutcome(error.statusCode),
          errorCode: _operationalCode('native', error.statusCode),
        ),
      );
      throw _operationalFailure(
        engine: 'native',
        message: error.message,
        statusCode: error.statusCode,
        trace: trace,
        jobRequestSchemaVersion: jobRequestSchemaVersion,
        jobRequestHash: jobRequestHash,
        fallbackReason: fallbackReason,
        selectionReason: selectionReason,
      );
    }
  }

  BattleExecutionRuntimeResult _success(
    Map<String, dynamic> result,
    List<BattleEngineDispatchRecord> trace,
    Map<String, dynamic> envelope,
    String? jobRequestSchemaVersion,
    String? jobRequestHash,
    String correlationSource,
  ) {
    final correlation = _correlation(
      trace,
      envelope,
      jobRequestSchemaVersion,
      jobRequestHash,
      correlationSource,
    );
    return BattleExecutionRuntimeResult(
      result: _attachCorrelation(result, correlation),
      correlation: correlation,
    );
  }

  BattleRequestCorrelation _correlation(
    List<BattleEngineDispatchRecord> trace,
    Map<String, dynamic> envelope,
    String? jobRequestSchemaVersion,
    String? jobRequestHash,
    String correlationSource,
  ) => BattleRequestCorrelation(
    jobRequestSchemaVersion: jobRequestSchemaVersion,
    jobRequestHash: jobRequestHash,
    engineRequestSchemaVersion:
        envelope['request_schema_version']?.toString() ?? '',
    engineRequestHash: envelope['request_hash']?.toString() ?? '',
    correlationSource: correlationSource,
    dispatchTrace: List.unmodifiable(trace),
  );

  Map<String, dynamic> _attachCorrelation(
    Map<String, dynamic> result,
    BattleRequestCorrelation correlation,
  ) => {...result, 'request_correlation': correlation.toJson()};

  Future<void> _checkCancelled(
    BattleRuntimeCancellationCheck? cancellationRequested, {
    required List<BattleEngineDispatchRecord> trace,
    required String engine,
    Map<String, dynamic> result = const {},
    BattleRequestCorrelation? correlation,
  }) async {
    if (cancellationRequested == null || !await cancellationRequested()) {
      return;
    }
    throw BattleExecutionRuntimeFailure(
      outcome: BattleSimulationAttemptOutcome.cancelled,
      code: 'battle_job_cancelled',
      reason:
          trace.isEmpty
              ? 'cancelled_before_engine_dispatch'
              : 'cancelled_at_engine_boundary',
      message:
          'Cancellation was observed at a supported engine dispatch boundary.',
      engine: engine,
      dispatchTrace: List.unmodifiable(trace),
      partialResult:
          correlation == null
              ? result
              : _attachCorrelation(result, correlation),
      correlation: correlation,
    );
  }

  Future<void> _checkpoint(
    BattleRuntimeCheckpoint? checkpoint,
    String stage,
    int current,
    int total,
  ) async {
    if (checkpoint != null) await checkpoint(stage, current, total);
  }

  BattleExecutionRuntimeFailure _coverageFailure({
    required String engine,
    required String code,
    required String reason,
    required String message,
    required List<Map<String, dynamic>> unsupportedCards,
    required List<BattleEngineDispatchRecord> trace,
    required String? jobRequestSchemaVersion,
    required String? jobRequestHash,
    required String selectionReason,
    required List<String> fallbackChain,
    String fallbackReason = 'none',
  }) {
    final correlation = _traceCorrelation(
      trace,
      jobRequestSchemaVersion,
      jobRequestHash,
    );
    return BattleExecutionRuntimeFailure(
      outcome: BattleSimulationAttemptOutcome.coverageError,
      code: code,
      reason: reason,
      message: message,
      engine: engine,
      unsupportedCards: unsupportedCards,
      dispatchTrace: List.unmodifiable(trace),
      fallbackReason: fallbackReason,
      engineSelectionReason: selectionReason,
      fallbackChain: fallbackChain,
      partialResult: _failurePartialResult(engine, correlation),
      correlation: correlation,
    );
  }

  BattleExecutionRuntimeFailure _operationalFailure({
    required String engine,
    required String message,
    required int? statusCode,
    required List<BattleEngineDispatchRecord> trace,
    required String? jobRequestSchemaVersion,
    required String? jobRequestHash,
    String fallbackReason = 'none',
    String? selectionReason,
  }) {
    final correlation = _traceCorrelation(
      trace,
      jobRequestSchemaVersion,
      jobRequestHash,
    );
    return BattleExecutionRuntimeFailure(
      outcome:
          statusCode == HttpStatus.gatewayTimeout
              ? BattleSimulationAttemptOutcome.timeout
              : BattleSimulationAttemptOutcome.engineError,
      code: _operationalCode(engine, statusCode),
      reason: '${engine}_battle_operational_failure',
      message: message,
      engine: engine,
      upstreamStatusCode: statusCode,
      dispatchTrace: List.unmodifiable(trace),
      fallbackReason: fallbackReason,
      engineSelectionReason: selectionReason,
      fallbackChain: trace
          .map(
            (record) =>
                '${record.engine}:${record.outcome == 'completed' ? 'completed' : record.outcome}',
          )
          .toList(growable: false),
      partialResult: _failurePartialResult(engine, correlation),
      correlation: correlation,
    );
  }

  BattleRequestCorrelation? _traceCorrelation(
    List<BattleEngineDispatchRecord> trace,
    String? jobRequestSchemaVersion,
    String? jobRequestHash,
  ) {
    if (trace.isEmpty) return null;
    final terminalDispatch = trace.last;
    return BattleRequestCorrelation(
      jobRequestSchemaVersion: jobRequestSchemaVersion,
      jobRequestHash: jobRequestHash,
      engineRequestSchemaVersion: terminalDispatch.requestSchemaVersion,
      engineRequestHash: terminalDispatch.requestHash,
      correlationSource: terminalDispatch.correlationSource,
      dispatchTrace: List.unmodifiable(trace),
    );
  }

  Map<String, dynamic> _failurePartialResult(
    String engine,
    BattleRequestCorrelation? correlation,
  ) => {
    'engine': engine == 'native' ? 'manaloom_native_reviewed' : engine,
    if (correlation != null) 'request_correlation': correlation.toJson(),
  };
}

String _operationalCode(String engine, int? statusCode) {
  final prefix = engine == 'native' ? 'native_battle' : engine;
  return statusCode == HttpStatus.gatewayTimeout
      ? '${prefix}_timeout'
      : '${prefix}_unavailable';
}

String _operationalOutcome(int? statusCode) =>
    statusCode == HttpStatus.gatewayTimeout ? 'timeout' : 'engine_error';

int _timeoutMs(Map<String, dynamic> request) {
  final value = request['timeout_ms'];
  if (value is int && value > 0) return value;
  throw ArgumentError.value(value, 'request.timeout_ms');
}

List<Map<String, dynamic>> _allDeckCardRows(Map<String, dynamic> request) {
  final rows = <Map<String, dynamic>>[];
  for (final deckKey in const ['deck_a', 'deck_b']) {
    final deck = request[deckKey];
    if (deck is! Map || deck['cards'] is! List) continue;
    rows.addAll(
      (deck['cards'] as List).whereType<Map>().map(
        (row) => row.cast<String, dynamic>(),
      ),
    );
  }
  return rows;
}
