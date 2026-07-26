import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

import '../../../lib/ai/battle_engine_config.dart';
import '../../../lib/ai/battle_learning_evidence_support.dart';
import '../../../lib/ai/battle_replay_event_support.dart';
import '../../../lib/ai/battle_simulation_request_support.dart';
import '../../../lib/ai/goldfish_simulator.dart';
import '../../../lib/battle/battle_execution_runtime.dart';
import '../../../lib/battle/battle_simulation_persistence_service.dart';
import '../../../lib/battle/battle_simulation_attempt_service.dart';
import '../../../lib/http_responses.dart';
import '../../../lib/json_object_support.dart';
import '../../../lib/logger.dart';
import '../../../lib/observability.dart';

final _uuidPattern = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);

/// POST /ai/simulate
/// Simula performance de um deck
///
/// Body:
/// {
///   "deck_id": "uuid",           // Deck para simular
///   "opponent_deck_id": "uuid",  // Opcional: para matchup ou battle
///   "simulations": 1000,         // Opcional: número de simulações (goldfish)
///   "type": "goldfish"           // "goldfish", "matchup" ou "battle"
/// }
///
/// Types:
/// - goldfish: Monte Carlo de mãos iniciais (rápido, 1000 simulações)
/// - matchup: Análise heurística de matchup entre dois decks
/// - battle: XMage, Forge para gap estruturado e runtime nativo residual
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return methodNotAllowed();
  }

  final pool = context.read<Pool>();
  final userId = context.read<String>();
  final attemptService = BattleSimulationAttemptService(pool);
  _RouteBattleAttempt? activeAttempt;

  try {
    final body = await context.request.body();
    final data = requireJsonObject(jsonDecode(body));

    final routeRequest = parseBattleSimulationRequest(data);
    if (routeRequest.validationError != null) {
      return badRequest(routeRequest.validationError!);
    }
    final deckId = routeRequest.deckId;
    if (deckId == null || deckId.isEmpty) {
      return badRequest('deck_id is required');
    }
    if (!_uuidPattern.hasMatch(deckId)) {
      return badRequest('deck_id must be a valid UUID');
    }

    final simType = routeRequest.type;
    final simCount = routeRequest.simulations;

    // Busca cartas do deck principal sempre dentro do escopo do usuário.
    final deckCards = await _fetchDeckCards(pool, deckId, userId: userId);
    if (deckCards.isEmpty) {
      return notFound('Deck not found or empty');
    }

    if (simType == 'battle') {
      final opponentId = routeRequest.opponentDeckId;
      if (opponentId == null || opponentId.isEmpty) {
        return badRequest('opponent_deck_id is required for battle simulation');
      }
      if (!_uuidPattern.hasMatch(opponentId)) {
        return badRequest('opponent_deck_id must be a valid UUID');
      }

      final opponentCards = await _fetchDeckCards(
        pool,
        opponentId,
        userId: userId,
        allowPublic: true,
      );
      if (opponentCards.isEmpty) {
        return notFound('Opponent deck not found or empty');
      }

      final seed =
          routeRequest.seed ??
          DateTime.now().microsecondsSinceEpoch % 2147483647;
      final timeoutMs = routeRequest.timeoutMs;
      final requestId = 'api-${DateTime.now().microsecondsSinceEpoch}';
      final deckAPayload = _externalDeckPayload(deckId, deckCards);
      final deckBPayload = _externalDeckPayload(opponentId, opponentCards);
      data['max_turns'] = routeRequest.maxTurns;
      data['test_objective'] = routeRequest.testObjective;
      data['focus_cards'] = routeRequest.focusCards;
      data['force_focus_access_mode'] = routeRequest.forceFocusAccessMode;
      data['same_lane'] = routeRequest.sameLane;
      data['natural_sample'] = routeRequest.naturalSample;
      final battleRequest = <String, dynamic>{
        'request_id': requestId,
        'seed': seed,
        'timeout_ms': timeoutMs,
        'max_turns': routeRequest.maxTurns,
        'test_objective': routeRequest.testObjective,
        'focus_cards': routeRequest.focusCards,
        'force_focus_access_mode': routeRequest.forceFocusAccessMode,
        'same_lane': routeRequest.sameLane,
        'natural_sample': routeRequest.naturalSample,
        'deck_a': deckAPayload,
        'deck_b': deckBPayload,
      };
      final attemptStart = await attemptService.start(
        userId: userId,
        deckAId: deckId,
        deckBId: opponentId,
        simulationType: 'battle',
        testObjective: routeRequest.testObjective,
        requestId: requestId,
        deckAHash: canonicalExternalBattleDeckHash(deckAPayload),
        deckBHash: canonicalExternalBattleDeckHash(deckBPayload),
        deckHashSchema: externalBattleDeckHashSchema,
        timeoutMs: timeoutMs,
        engine: (Platform.environment['BATTLE_ENGINE'] ?? 'auto').trim(),
        provenance: {
          'seed': seed,
          'max_turns': routeRequest.maxTurns,
          'test_objective': routeRequest.testObjective,
          'focus_card_count': routeRequest.focusCards.length,
          'same_lane': routeRequest.sameLane,
          'natural_sample': routeRequest.naturalSample,
          'force_focus_access_mode': routeRequest.forceFocusAccessMode,
        },
      );
      if (!attemptStart.isStarted) {
        return _attemptPersistenceFailure(attemptStart.errorCode);
      }
      activeAttempt = _RouteBattleAttempt(attemptService, attemptStart.handle!);

      final requestedEngine =
          (Platform.environment['BATTLE_ENGINE'] ?? 'auto')
              .trim()
              .toLowerCase();
      late final BattleExecutionRuntime runtime;
      try {
        runtime = BattleExecutionRuntime.fromEnvironment(
          Platform.environment,
          requestedEngine: requestedEngine,
        );
      } on BattleEngineConfigurationException catch (error) {
        return _finishFailedAttemptAndReturn(
          activeAttempt,
          outcome: BattleSimulationAttemptOutcome.engineError,
          reason: 'engine_configuration_rejected',
          errorCode: error.code,
          response: _engineConfigurationFailure(error),
        );
      }
      late final BattleExecutionRuntimeResult runtimeResult;
      try {
        runtimeResult = await runtime.execute(
          request: battleRequest,
          requestedEngine: requestedEngine,
        );
      } on BattleExecutionRuntimeFailure catch (error) {
        return _finishFailedAttemptAndReturn(
          activeAttempt,
          outcome: error.outcome,
          reason: error.reason,
          errorCode: error.code,
          response: _battleRuntimeFailure(error),
          result: error.partialResult,
          engineRequestSchemaVersion:
              error.correlation?.engineRequestSchemaVersion,
          engineRequestHash: error.correlation?.engineRequestHash,
          engineRequestCorrelationSource: error.correlation?.correlationSource,
          provenance: {
            'dispatch_trace': error.dispatchTrace
                .map((record) => record.toJson())
                .toList(growable: false),
          },
        );
      }
      Map<String, dynamic> result = runtimeResult.result;

      result = normalizeBattleReplayResultEvents(
        result: result,
        deckAId: deckId,
        deckAName: deckAPayload['name']?.toString() ?? deckId,
        deckBId: opponentId,
        deckBName: deckBPayload['name']?.toString() ?? opponentId,
      );
      result['test_objective'] = routeRequest.testObjective;
      final deckAEvidence = buildBattleLearningEvidence(
        result,
        subjectDeckKey: 'deck_a',
        focusCards: _stringList(data['focus_cards']),
        sameLane: data['same_lane'] == true,
        naturalSample: _isNaturalBattleResult(data, result),
      );
      final deckBEvidence = buildBattleLearningEvidence(
        result,
        subjectDeckKey: 'deck_b',
        sameLane: data['same_lane'] == true,
        naturalSample: _isNaturalBattleResult(data, result),
      );
      result['battle_learning_evidence'] = deckAEvidence;
      result['battle_learning_evidence_by_subject'] = {
        'deck_a': deckAEvidence,
        'deck_b': deckBEvidence,
      };
      final winnerDeckId = canonicalBattleWinnerDeckId(
        result: result,
        deckAId: deckId,
        deckBId: opponentId,
      );

      final persistence = await BattleSimulationPersistenceService(pool).save(
        deckAId: deckId,
        deckBId: opponentId,
        type: 'battle',
        result: result,
      );
      if (!persistence.isSaved) {
        return _finishFailedAttemptAndReturn(
          activeAttempt,
          outcome: BattleSimulationAttemptOutcome.persistenceError,
          reason: 'replay_persistence_failed',
          errorCode: persistence.errorCode,
          response: _simulationPersistenceFailure(persistence),
          result: result,
        );
      }
      final attemptOutcome =
          result['status'] == 'censored'
              ? BattleSimulationAttemptOutcome.censored
              : BattleSimulationAttemptOutcome.completed;
      final attemptFinish = await activeAttempt.finish(
        outcome: attemptOutcome,
        replayId: persistence.replayId,
        reason:
            attemptOutcome == BattleSimulationAttemptOutcome.censored
                ? 'engine_max_turns_censored'
                : 'engine_completed',
        result: result,
        engineRequestSchemaVersion:
            runtimeResult.correlation.engineRequestSchemaVersion,
        engineRequestHash: runtimeResult.correlation.engineRequestHash,
        engineRequestCorrelationSource:
            runtimeResult.correlation.correlationSource,
      );
      if (!attemptFinish.isFinished) {
        return _attemptPersistenceFailure(attemptFinish.errorCode);
      }

      return Response.json(
        body: {
          ...result,
          'type': 'battle',
          'deck_a_id': deckId,
          'deck_b_id': opponentId,
          'winner_deck_id': winnerDeckId,
          'attempt_id': activeAttempt.handle.id,
          'outcome': attemptOutcome.value,
          'replay_id': persistence.replayId,
          'persistence': persistence.toJson(),
        },
      );
    } else if (simType == 'matchup') {
      // Análise heurística de matchup
      final opponentId = routeRequest.opponentDeckId;
      if (opponentId == null || opponentId.isEmpty) {
        return badRequest(
          'opponent_deck_id is required for matchup simulation',
        );
      }
      if (!_uuidPattern.hasMatch(opponentId)) {
        return badRequest('opponent_deck_id must be a valid UUID');
      }

      final opponentCards = await _fetchDeckCards(
        pool,
        opponentId,
        userId: userId,
        allowPublic: true,
      );
      if (opponentCards.isEmpty) {
        return notFound('Opponent deck not found or empty');
      }

      final deckAPayload = _externalDeckPayload(deckId, deckCards);
      final deckBPayload = _externalDeckPayload(opponentId, opponentCards);
      final attemptStart = await attemptService.start(
        userId: userId,
        deckAId: deckId,
        deckBId: opponentId,
        simulationType: 'matchup',
        testObjective: routeRequest.testObjective,
        requestId: 'api-${DateTime.now().microsecondsSinceEpoch}',
        deckAHash: canonicalExternalBattleDeckHash(deckAPayload),
        deckBHash: canonicalExternalBattleDeckHash(deckBPayload),
        deckHashSchema: externalBattleDeckHashSchema,
        timeoutMs: routeRequest.timeoutMs,
        engine: 'matchup_heuristic',
        provenance: {'simulation_count': simCount},
      );
      if (!attemptStart.isStarted) {
        return _attemptPersistenceFailure(attemptStart.errorCode);
      }
      activeAttempt = _RouteBattleAttempt(attemptService, attemptStart.handle!);
      final result = MatchupAnalyzer.analyze(deckCards, opponentCards);
      final resultJson = result.toJson();
      resultJson['test_objective'] = routeRequest.testObjective;

      // Salva resultado para treinamento futuro
      final persistence = await BattleSimulationPersistenceService(pool).save(
        deckAId: deckId,
        deckBId: opponentId,
        type: 'matchup',
        result: resultJson,
      );
      if (!persistence.isSaved) {
        return _finishFailedAttemptAndReturn(
          activeAttempt,
          outcome: BattleSimulationAttemptOutcome.persistenceError,
          reason: 'replay_persistence_failed',
          errorCode: persistence.errorCode,
          response: _simulationPersistenceFailure(persistence),
          result: resultJson,
        );
      }
      final attemptFinish = await activeAttempt.finish(
        outcome: BattleSimulationAttemptOutcome.completed,
        replayId: persistence.replayId,
        reason: 'matchup_completed',
        result: resultJson,
      );
      if (!attemptFinish.isFinished) {
        return _attemptPersistenceFailure(attemptFinish.errorCode);
      }

      return Response.json(
        body: {
          ...resultJson,
          'type': 'matchup',
          'deck_a_id': deckId,
          'deck_b_id': opponentId,
          'attempt_id': activeAttempt.handle.id,
          'outcome': BattleSimulationAttemptOutcome.completed.value,
          'replay_id': persistence.replayId,
          'persistence': persistence.toJson(),
        },
      );
    } else {
      // Simulação goldfish (padrão)
      final deckAPayload = _externalDeckPayload(deckId, deckCards);
      final attemptStart = await attemptService.start(
        userId: userId,
        deckAId: deckId,
        simulationType: 'goldfish',
        testObjective: routeRequest.testObjective,
        requestId: 'api-${DateTime.now().microsecondsSinceEpoch}',
        deckAHash: canonicalExternalBattleDeckHash(deckAPayload),
        deckHashSchema: externalBattleDeckHashSchema,
        timeoutMs: routeRequest.timeoutMs,
        engine: 'goldfish_monte_carlo',
        provenance: {'simulation_count': simCount},
      );
      if (!attemptStart.isStarted) {
        return _attemptPersistenceFailure(attemptStart.errorCode);
      }
      activeAttempt = _RouteBattleAttempt(attemptService, attemptStart.handle!);
      final simulator = GoldfishSimulator(deckCards, simulations: simCount);
      final result = simulator.simulate();
      final resultJson = result.toJson();
      resultJson['test_objective'] = routeRequest.testObjective;

      // Salva resultado para treinamento futuro
      final persistence = await BattleSimulationPersistenceService(
        pool,
      ).save(deckAId: deckId, type: 'goldfish', result: resultJson);
      if (!persistence.isSaved) {
        return _finishFailedAttemptAndReturn(
          activeAttempt,
          outcome: BattleSimulationAttemptOutcome.persistenceError,
          reason: 'replay_persistence_failed',
          errorCode: persistence.errorCode,
          response: _simulationPersistenceFailure(persistence),
          result: resultJson,
        );
      }
      final attemptFinish = await activeAttempt.finish(
        outcome: BattleSimulationAttemptOutcome.completed,
        replayId: persistence.replayId,
        reason: 'goldfish_completed',
        result: resultJson,
      );
      if (!attemptFinish.isFinished) {
        return _attemptPersistenceFailure(attemptFinish.errorCode);
      }

      return Response.json(
        body: {
          ...resultJson,
          'type': 'goldfish',
          'deck_id': deckId,
          'attempt_id': activeAttempt.handle.id,
          'outcome': BattleSimulationAttemptOutcome.completed.value,
          'replay_id': persistence.replayId,
          'persistence': persistence.toJson(),
        },
      );
    }
  } on JsonObjectValidationException catch (e) {
    Log.w('[ai-simulate] invalid request type=${e.runtimeType}');
    return badRequest(e.message);
  } on FormatException catch (e) {
    Log.w('[ai-simulate] invalid JSON type=${e.runtimeType}');
    return badRequest('Invalid JSON: ${e.message}');
  } catch (e, st) {
    if (activeAttempt != null && !activeAttempt.isFinished) {
      await activeAttempt.finish(
        outcome: BattleSimulationAttemptOutcome.engineError,
        reason: 'unhandled_route_exception',
        errorCode: 'internal_server_error',
      );
    }
    Log.e('[ai-simulate] request failed type=${e.runtimeType}');
    await captureRouteException(
      context,
      e,
      stackTrace: st,
      tags: const {'route': 'ai_simulate'},
    );
    return internalServerError('Internal server error');
  }
}

/// Busca cartas de um deck com todos os dados necessários
Future<List<Map<String, dynamic>>> _fetchDeckCards(
  Pool pool,
  String deckId, {
  required String userId,
  bool allowPublic = false,
}) async {
  final result = await pool.execute(
    Sql.named('''
      SELECT 
        c.id,
        c.name,
        c.mana_cost,
        c.cmc,
        c.type_line,
        c.oracle_text,
        c.colors,
        c.color_identity,
        c.image_url,
        c.power,
        c.toughness,
        c.set_code,
        c.collector_number,
        dc.quantity,
        dc.is_commander,
        d.name AS deck_name
      FROM deck_cards dc
      JOIN decks d ON d.id = dc.deck_id
      JOIN cards c ON c.id = dc.card_id
      WHERE dc.deck_id = CAST(@deckId AS uuid)
        AND d.deleted_at IS NULL
        AND (
          d.user_id = CAST(@userId AS uuid)
          OR (CAST(@allowPublic AS boolean) AND d.is_public = true)
        )
      ORDER BY
        dc.is_commander DESC,
        LOWER(c.name) ASC,
        COALESCE(c.oracle_id::text, '') ASC,
        COALESCE(c.scryfall_id::text, '') ASC,
        c.id::text ASC
    '''),
    parameters: {
      'deckId': deckId,
      'userId': userId,
      'allowPublic': allowPublic,
    },
  );

  return result.map((row) {
    return {
      'id': row[0],
      'name': row[1],
      'mana_cost': row[2],
      'cmc': row[3],
      'type_line': row[4],
      'oracle_text': row[5],
      'colors': row[6],
      'color_identity': row[7],
      'image_url': row[8],
      'power': row[9],
      'toughness': row[10],
      'set_code': row[11],
      'collector_number': row[12],
      'quantity': row[13],
      'is_commander': row[14],
      'deck_name': row[15],
    };
  }).toList();
}

Map<String, dynamic> _externalDeckPayload(
  String deckId,
  List<Map<String, dynamic>> cards,
) => {
  'id': deckId,
  'name': cards.first['deck_name']?.toString() ?? deckId,
  'cards': cards
      .map(
        (card) => {
          'name': card['name'],
          'set_code': card['set_code'],
          'collector_number': card['collector_number'],
          'quantity': card['quantity'],
          'is_commander': card['is_commander'],
        },
      )
      .toList(growable: false),
};

bool _isNaturalBattleResult(
  Map<String, dynamic> request,
  Map<String, dynamic> result,
) {
  if (request['natural_sample'] == false) return false;
  final forcedMode =
      result['forced_access_mode']?.toString().trim().toLowerCase();
  return forcedMode == null || forcedMode.isEmpty || forcedMode == 'none';
}

List<String> _stringList(Object? value) =>
    value is List
        ? value
            .map((item) => item?.toString().trim() ?? '')
            .where((item) => item.isNotEmpty)
            .toList(growable: false)
        : const [];

Response _engineConfigurationFailure(
  BattleEngineConfigurationException error,
) => Response.json(
  statusCode: HttpStatus.serviceUnavailable,
  body: {'error': error.code, 'details': error.message},
);

Response _battleRuntimeFailure(BattleExecutionRuntimeFailure error) {
  final coverage =
      error.outcome == BattleSimulationAttemptOutcome.coverageError;
  final cancelled = error.outcome == BattleSimulationAttemptOutcome.cancelled;
  Log.e('${error.engine} battle failed code=${error.code}');
  return Response.json(
    statusCode:
        coverage || cancelled
            ? HttpStatus.unprocessableEntity
            : error.timedOut
            ? HttpStatus.gatewayTimeout
            : HttpStatus.badGateway,
    body: {
      'error': error.code,
      if (error.unsupportedCards.isNotEmpty)
        'unsupported_cards': error.unsupportedCards,
      'fallback_allowed': false,
      'fallback_reason': error.fallbackReason,
      'fallback_eligibility_reason':
          coverage
              ? 'coverage_fallback_exhausted_or_strict'
              : error.timedOut
              ? 'operational_timeout_not_eligible'
              : 'operational_failure_not_eligible',
      if (error.engineSelectionReason != null)
        'engine_selection_reason': error.engineSelectionReason,
      if (error.fallbackChain.isNotEmpty) 'fallback_chain': error.fallbackChain,
      'details': error.message,
    },
  );
}

Response _simulationPersistenceFailure(
  BattleSimulationPersistenceOutcome persistence,
) {
  Log.w(
    '[ai-simulate] replay persistence failed code=${persistence.errorCode}',
  );
  return Response.json(
    statusCode: HttpStatus.serviceUnavailable,
    body: {
      'error': 'simulation_persistence_failed',
      'message':
          'A simulacao terminou, mas o replay nao pode ser salvo. Tente novamente.',
      'persistence': persistence.toJson(),
    },
  );
}

class _RouteBattleAttempt {
  _RouteBattleAttempt(this._service, this.handle);

  final BattleSimulationAttemptService _service;
  final BattleSimulationAttemptHandle handle;
  bool isFinished = false;

  Future<BattleSimulationAttemptFinishResult> finish({
    required BattleSimulationAttemptOutcome outcome,
    String? replayId,
    String? reason,
    String? errorCode,
    String? engineRequestSchemaVersion,
    String? engineRequestHash,
    String? engineRequestCorrelationSource,
    Map<String, dynamic> result = const {},
    Map<String, dynamic> provenance = const {},
  }) async {
    if (isFinished) {
      return const BattleSimulationAttemptFinishResult.failed(
        'battle_attempt_not_open',
      );
    }
    final finish = await _service.finish(
      attempt: handle,
      outcome: outcome,
      replayId: replayId,
      reason: reason,
      errorCode: errorCode,
      engineRequestSchemaVersion: engineRequestSchemaVersion,
      engineRequestHash: engineRequestHash,
      engineRequestCorrelationSource: engineRequestCorrelationSource,
      result: result,
      provenance: provenance,
    );
    if (finish.isFinished) isFinished = true;
    return finish;
  }
}

Future<Response> _finishFailedAttemptAndReturn(
  _RouteBattleAttempt? attempt, {
  required BattleSimulationAttemptOutcome outcome,
  required String reason,
  required String? errorCode,
  required Response response,
  Map<String, dynamic> result = const {},
  Map<String, dynamic> provenance = const {},
  String? engineRequestSchemaVersion,
  String? engineRequestHash,
  String? engineRequestCorrelationSource,
}) async {
  if (attempt != null && !attempt.isFinished) {
    await attempt.finish(
      outcome: outcome,
      reason: reason,
      errorCode: errorCode,
      engineRequestSchemaVersion: engineRequestSchemaVersion,
      engineRequestHash: engineRequestHash,
      engineRequestCorrelationSource: engineRequestCorrelationSource,
      result: result,
      provenance: provenance,
    );
  }
  return response;
}

Response _attemptPersistenceFailure(String? errorCode) {
  Log.w(
    '[ai-simulate] attempt persistence failed '
    'code=${errorCode ?? 'unknown'}',
  );
  return Response.json(
    statusCode: HttpStatus.serviceUnavailable,
    body: {
      'error': 'battle_attempt_persistence_failed',
      'message':
          'A tentativa nao pode ser registrada com seguranca. Tente novamente.',
      if (errorCode != null) 'persistence_code': errorCode,
    },
  );
}
