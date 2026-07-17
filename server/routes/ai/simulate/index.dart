import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

import '../../../lib/ai/battle_engine_config.dart';
import '../../../lib/ai/battle_learning_evidence_support.dart';
import '../../../lib/ai/battle_simulation_request_support.dart';
import '../../../lib/ai/forge_battle_client.dart';
import '../../../lib/ai/goldfish_simulator.dart';
import '../../../lib/ai/native_battle_client.dart';
import '../../../lib/ai/xmage_battle_client.dart';
import '../../../lib/battle/battle_simulation_persistence_service.dart';
import '../../../lib/http_responses.dart';
import '../../../lib/json_object_support.dart';
import '../../../lib/logger.dart';
import '../../../lib/observability.dart';

const _externalClientGraceMs = 8000;
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

      late final BattleEngineConfig engineConfig;
      try {
        engineConfig = BattleEngineConfig.fromEnvironment(Platform.environment);
      } on BattleEngineConfigurationException catch (error) {
        return _engineConfigurationFailure(error);
      }
      final xmageSidecarUrl = engineConfig.xmageSidecarUrl;
      final forgeSidecarUrl = engineConfig.forgeSidecarUrl;
      final nativeSidecarUrl = engineConfig.nativeSidecarUrl;
      final strictXmage = engineConfig.isStrictXmage;
      final strictForge = engineConfig.isStrictForge;
      final seed =
          routeRequest.seed ??
          DateTime.now().microsecondsSinceEpoch % 2147483647;
      final timeoutMs = routeRequest.timeoutMs;
      data['max_turns'] = routeRequest.maxTurns;
      data['focus_cards'] = routeRequest.focusCards;
      data['force_focus_access_mode'] = routeRequest.forceFocusAccessMode;
      data['same_lane'] = routeRequest.sameLane;
      data['natural_sample'] = routeRequest.naturalSample;
      final externalRequest = {
        'request_id': 'api-${DateTime.now().microsecondsSinceEpoch}',
        'seed': seed,
        'timeout_ms': timeoutMs,
        'deck_a': _externalDeckPayload(deckId, deckCards),
        'deck_b': _externalDeckPayload(opponentId, opponentCards),
      };
      Map<String, dynamic> result;

      if (engineConfig.isNative) {
        try {
          result = await _simulateNative(
            nativeSidecarUrl,
            _withNativeRequirements(
              externalRequest,
              requiredRuleCards: _allDeckCardRows(externalRequest),
              data: data,
            ),
            timeoutMs,
          );
          result['fallback_reason'] = 'native_mode_configured';
        } on NativeBattleCoverageIncomplete catch (error) {
          return _nativeCoverageFailure(error);
        } on NativeBattleServiceException catch (error) {
          return _externalEngineFailure(
            'native_battle',
            error.message,
            upstreamStatusCode: error.statusCode,
          );
        }
      } else if (strictForge) {
        try {
          result = await _simulateForge(
            forgeSidecarUrl,
            externalRequest,
            timeoutMs,
          );
          result['engine_contract'] = 'canonical_rules_execution_secondary';
          result['fallback_reason'] = 'forge_mode_configured';
        } on ForgeCoverageIncomplete catch (error) {
          return Response.json(
            statusCode: HttpStatus.unprocessableEntity,
            body: {
              'error': 'forge_coverage_incomplete',
              'unsupported_cards': error.unsupportedCards,
            },
          );
        } on ForgeServiceException catch (error) {
          return _externalEngineFailure(
            'forge',
            error.message,
            upstreamStatusCode: error.statusCode,
          );
        }
      } else {
        try {
          result = await _simulateXmage(
            xmageSidecarUrl,
            externalRequest,
            timeoutMs,
          );
          result['engine_contract'] = 'canonical_rules_execution';
        } on XmageCoverageIncomplete catch (error) {
          if (strictXmage) {
            return Response.json(
              statusCode: HttpStatus.unprocessableEntity,
              body: {
                'error': 'xmage_coverage_incomplete',
                'unsupported_cards': error.unsupportedCards,
              },
            );
          }
          try {
            result = await _forgeOrNativeFallback(
              forgeSidecarUrl: forgeSidecarUrl,
              nativeSidecarUrl: nativeSidecarUrl,
              externalRequest: externalRequest,
              timeoutMs: timeoutMs,
              fallbackReason: 'xmage_coverage_incomplete',
              xmageUnsupportedCards: error.unsupportedCards,
              data: data,
            );
          } on ForgeServiceException catch (forgeError) {
            return _externalEngineFailure(
              'forge',
              forgeError.message,
              upstreamStatusCode: forgeError.statusCode,
            );
          } on NativeBattleCoverageIncomplete catch (nativeError) {
            return _nativeCoverageFailure(nativeError);
          } on NativeBattleServiceException catch (nativeError) {
            return _externalEngineFailure(
              'native_battle',
              nativeError.message,
              upstreamStatusCode: nativeError.statusCode,
            );
          }
        } on XmageServiceException catch (error) {
          return _externalEngineFailure(
            'xmage',
            error.message,
            upstreamStatusCode: error.statusCode,
          );
        }
      }

      result['battle_learning_evidence'] = buildBattleLearningEvidence(
        result,
        focusCards: _stringList(data['focus_cards']),
        sameLane: data['same_lane'] == true,
        naturalSample: _isNaturalBattleResult(data, result),
      );
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
        return _simulationPersistenceFailure(persistence);
      }

      return Response.json(
        body: {
          ...result,
          'type': 'battle',
          'deck_a_id': deckId,
          'deck_b_id': opponentId,
          'winner_deck_id': winnerDeckId,
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

      final result = MatchupAnalyzer.analyze(deckCards, opponentCards);

      // Salva resultado para treinamento futuro
      final persistence = await BattleSimulationPersistenceService(pool).save(
        deckAId: deckId,
        deckBId: opponentId,
        type: 'matchup',
        result: result.toJson(),
      );
      if (!persistence.isSaved) {
        return _simulationPersistenceFailure(persistence);
      }

      return Response.json(
        body: {
          ...result.toJson(),
          'type': 'matchup',
          'deck_a_id': deckId,
          'deck_b_id': opponentId,
          'replay_id': persistence.replayId,
          'persistence': persistence.toJson(),
        },
      );
    } else {
      // Simulação goldfish (padrão)
      final simulator = GoldfishSimulator(deckCards, simulations: simCount);
      final result = simulator.simulate();

      // Salva resultado para treinamento futuro
      final persistence = await BattleSimulationPersistenceService(
        pool,
      ).save(deckAId: deckId, type: 'goldfish', result: result.toJson());
      if (!persistence.isSaved) {
        return _simulationPersistenceFailure(persistence);
      }

      return Response.json(
        body: {
          ...result.toJson(),
          'type': 'goldfish',
          'deck_id': deckId,
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

Future<Map<String, dynamic>> _simulateXmage(
  String sidecarUrl,
  Map<String, dynamic> request,
  int timeoutMs,
) async {
  final client = XmageBattleClient(
    baseUrl: sidecarUrl,
    timeout: Duration(milliseconds: timeoutMs + _externalClientGraceMs),
  );
  try {
    return await client.simulate(request);
  } finally {
    client.close();
  }
}

Future<Map<String, dynamic>> _simulateForge(
  String sidecarUrl,
  Map<String, dynamic> request,
  int timeoutMs,
) async {
  final client = ForgeBattleClient(
    baseUrl: sidecarUrl,
    timeout: Duration(milliseconds: timeoutMs + _externalClientGraceMs),
  );
  try {
    return await client.simulate(request);
  } finally {
    client.close();
  }
}

Future<Map<String, dynamic>> _simulateNative(
  String sidecarUrl,
  Map<String, dynamic> request,
  int timeoutMs,
) async {
  final client = NativeBattleClient(
    baseUrl: sidecarUrl,
    timeout: Duration(milliseconds: timeoutMs + _externalClientGraceMs),
  );
  try {
    return await client.simulate(request);
  } finally {
    client.close();
  }
}

Future<Map<String, dynamic>> _forgeOrNativeFallback({
  required String forgeSidecarUrl,
  required String nativeSidecarUrl,
  required Map<String, dynamic> externalRequest,
  required int timeoutMs,
  required String fallbackReason,
  List<Map<String, dynamic>> xmageUnsupportedCards = const [],
  Map<String, dynamic> data = const {},
}) async {
  try {
    final result = await _simulateForge(
      forgeSidecarUrl,
      externalRequest,
      timeoutMs,
    );
    result['engine_contract'] = 'canonical_rules_execution_secondary';
    result['fallback_reason'] = fallbackReason;
    if (xmageUnsupportedCards.isNotEmpty) {
      result['xmage_unsupported_cards'] = xmageUnsupportedCards;
    }
    return result;
  } on ForgeCoverageIncomplete catch (error) {
    final result = await _simulateNative(
      nativeSidecarUrl,
      _withNativeRequirements(
        externalRequest,
        requiredRuleCards: _allDeckCardRows(externalRequest),
        data: data,
      ),
      timeoutMs,
    );
    result['fallback_reason'] = '${fallbackReason}_forge_coverage_incomplete';
    if (xmageUnsupportedCards.isNotEmpty) {
      result['xmage_unsupported_cards'] = xmageUnsupportedCards;
    }
    result['forge_unsupported_cards'] = error.unsupportedCards;
    return result;
  }
}

Map<String, dynamic> _withNativeRequirements(
  Map<String, dynamic> request, {
  required List<Map<String, dynamic>> requiredRuleCards,
  required Map<String, dynamic> data,
}) => {
  ...request,
  'required_rule_cards': requiredRuleCards,
  'max_turns': (data['max_turns'] as int?) ?? 30,
  if (data['focus_cards'] is List) 'focus_cards': data['focus_cards'],
  if (data['force_focus_access_mode'] is String)
    'force_focus_access_mode': data['force_focus_access_mode'],
  'natural_sample': data['natural_sample'] != false,
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

Response _externalEngineFailure(
  String engine,
  String message, {
  int? upstreamStatusCode,
}) {
  final timedOut = upstreamStatusCode == HttpStatus.gatewayTimeout;
  Log.e('$engine battle failed');
  return Response.json(
    statusCode: timedOut ? HttpStatus.gatewayTimeout : HttpStatus.badGateway,
    body: {
      'error': timedOut ? '${engine}_timeout' : '${engine}_unavailable',
      'details':
          timedOut
              ? 'The battle engine timed out.'
              : 'The battle engine is temporarily unavailable.',
    },
  );
}

Response _nativeCoverageFailure(NativeBattleCoverageIncomplete error) =>
    Response.json(
      statusCode: HttpStatus.unprocessableEntity,
      body: {
        'error': 'native_coverage_incomplete',
        'unsupported_cards': error.unsupportedCards,
      },
    );

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
