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
import '../../../lib/http_responses.dart';
import '../../../lib/json_object_support.dart';
import '../../../lib/logger.dart';
import '../../../lib/observability.dart';

const _externalClientGraceMs = 8000;

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

      await _saveSimulation(
        pool: pool,
        deckAId: deckId,
        deckBId: opponentId,
        type: 'battle',
        result: result,
      );

      return Response.json(
        body: {
          'type': 'battle',
          'deck_a_id': deckId,
          'deck_b_id': opponentId,
          ...result,
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
      await _saveSimulation(
        pool: pool,
        deckAId: deckId,
        deckBId: opponentId,
        type: 'matchup',
        result: result.toJson(),
      );

      return Response.json(
        body: {
          'type': 'matchup',
          'deck_a_id': deckId,
          'deck_b_id': opponentId,
          ...result.toJson(),
        },
      );
    } else {
      // Simulação goldfish (padrão)
      final simulator = GoldfishSimulator(deckCards, simulations: simCount);
      final result = simulator.simulate();

      // Salva resultado para treinamento futuro
      await _saveSimulation(
        pool: pool,
        deckAId: deckId,
        type: 'goldfish',
        result: result.toJson(),
      );

      return Response.json(
        body: {'type': 'goldfish', 'deck_id': deckId, ...result.toJson()},
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

/// Salva resultado da simulação para treinamento de ML
Future<void> _saveSimulation({
  required Pool pool,
  required String deckAId,
  String? deckBId,
  required String type,
  required Map<String, dynamic> result,
}) async {
  try {
    // Verifica se a tabela existe
    final tableExists = await pool.execute('''
      SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_name = 'battle_simulations'
      )
    ''');

    if (tableExists.isNotEmpty && tableExists.first[0] == true) {
      final columns = await pool.execute('''
        SELECT column_name
        FROM information_schema.columns
        WHERE table_name = 'battle_simulations'
          AND column_name IN (
            'simulation_type',
            'metrics',
            'winner_deck_id',
            'turns_played'
          )
      ''');
      final availableColumns =
          columns.map((row) => row[0]?.toString()).whereType<String>().toSet();
      final hasSimulationType = availableColumns.contains('simulation_type');
      final hasMetrics = availableColumns.contains('metrics');
      final hasWinnerDeckId = availableColumns.contains('winner_deck_id');
      final hasTurnsPlayed = availableColumns.contains('turns_played');
      final payload = {'type': type, ...result};
      final winnerDeckId = _winnerDeckId(result, deckAId, deckBId);
      final turnsPlayed = (result['turns'] as num?)?.toInt();

      await pool.execute(
        Sql.named('''
          INSERT INTO battle_simulations (
            deck_a_id,
            deck_b_id,
            game_log
            ${hasSimulationType ? ', simulation_type' : ''}
            ${hasMetrics ? ', metrics' : ''}
            ${hasWinnerDeckId ? ', winner_deck_id' : ''}
            ${hasTurnsPlayed ? ', turns_played' : ''}
          )
          VALUES (
            @deckAId,
            @deckBId,
            @gameLog::jsonb
            ${hasSimulationType ? ', @simulationType' : ''}
            ${hasMetrics ? ', @metrics::jsonb' : ''}
            ${hasWinnerDeckId ? ', @winnerDeckId' : ''}
            ${hasTurnsPlayed ? ', @turnsPlayed' : ''}
          )
          '''),
        parameters: {
          'deckAId': deckAId,
          'deckBId': deckBId,
          'gameLog': jsonEncode(payload),
          if (hasSimulationType) 'simulationType': type,
          if (hasMetrics) 'metrics': jsonEncode(_simulationMetrics(result)),
          if (hasWinnerDeckId) 'winnerDeckId': winnerDeckId,
          if (hasTurnsPlayed) 'turnsPlayed': turnsPlayed,
        },
      );
    }
  } catch (e) {
    // Não falha a request se não conseguir salvar
    Log.w('[ai-simulate] persistence unavailable type=${e.runtimeType}');
  }
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

String? _winnerDeckId(
  Map<String, dynamic> result,
  String deckAId,
  String? deckBId,
) {
  final explicit = result['winner_deck_id']?.toString();
  if (explicit != null && explicit.isNotEmpty) return explicit;
  return switch (result['winner']?.toString()) {
    'Deck A' => deckAId,
    'Deck B' => deckBId,
    _ => null,
  };
}

Map<String, dynamic> _simulationMetrics(Map<String, dynamic> result) {
  final nested = result['metrics'];
  return {
    if (nested is Map) ...nested.cast<String, dynamic>(),
    'engine': result['engine'],
    'engine_contract': result['engine_contract'],
    'duration_ms': result['duration_ms'],
    'turns': result['turns'],
    'winner_deck_id': result['winner_deck_id'],
    'event_count':
        (result['events'] as List?)?.length ??
        (result['game_log'] as List?)?.length,
    'snapshot_count': (result['visual_snapshots'] as List?)?.length,
  }..removeWhere((_, value) => value == null);
}
