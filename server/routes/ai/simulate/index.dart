import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

import '../../../lib/ai/battle_engine_config.dart';
import '../../../lib/ai/battle_simulator.dart';
import '../../../lib/ai/forge_battle_client.dart';
import '../../../lib/ai/goldfish_simulator.dart';
import '../../../lib/ai/xmage_battle_client.dart';
import '../../../lib/http_responses.dart';
import '../../../lib/logger.dart';

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
    final data = jsonDecode(body) as Map<String, dynamic>;

    final deckId = data['deck_id'] as String?;
    if (deckId == null || deckId.isEmpty) {
      return badRequest('deck_id is required');
    }

    final simType = (data['type'] as String?) ?? 'goldfish';
    final simCount = _normalizedSimulationCount(
      data['simulations'],
      defaultValue: 1000,
    );

    // Busca cartas do deck principal sempre dentro do escopo do usuário.
    final deckCards = await _fetchDeckCards(
      pool,
      deckId,
      userId: userId,
    );
    if (deckCards.isEmpty) {
      return notFound('Deck not found or empty');
    }

    if (simType == 'battle') {
      final opponentId = data['opponent_deck_id'] as String?;
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
      final strictXmage = engineConfig.isStrictXmage;
      final strictForge = engineConfig.isStrictForge;
      final seed = data['seed'] is int
          ? data['seed'] as int
          : DateTime.now().microsecondsSinceEpoch % 2147483647;
      final timeoutMs = _normalizedSimulationCount(
        data['timeout_ms'],
        defaultValue: 120000,
        min: 1000,
        max: 900000,
      );
      final externalRequest = {
        'request_id': 'api-${DateTime.now().microsecondsSinceEpoch}',
        'seed': seed,
        'timeout_ms': timeoutMs,
        'deck_a': _externalDeckPayload(deckId, deckCards),
        'deck_b': _externalDeckPayload(opponentId, opponentCards),
      };
      Map<String, dynamic> result;

      if (engineConfig.isNative) {
        result = _nativeBattle(
          deckCards,
          opponentCards,
          maxTurns: (data['max_turns'] as int?) ?? 30,
          fallbackReason: 'native_mode_configured',
        );
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
          return _externalEngineFailure('forge', error.message);
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
              externalRequest: externalRequest,
              timeoutMs: timeoutMs,
              deckCards: deckCards,
              opponentCards: opponentCards,
              maxTurns: (data['max_turns'] as int?) ?? 30,
              fallbackReason: 'xmage_coverage_incomplete',
              xmageUnsupportedCards: error.unsupportedCards,
            );
          } on ForgeServiceException catch (forgeError) {
            return _externalEngineFailure('forge', forgeError.message);
          }
        } on XmageServiceException catch (error) {
          return _externalEngineFailure('xmage', error.message);
        }
      }

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
      final opponentId = data['opponent_deck_id'] as String?;
      if (opponentId == null || opponentId.isEmpty) {
        return badRequest(
            'opponent_deck_id is required for matchup simulation');
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
        body: {
          'type': 'goldfish',
          'deck_id': deckId,
          ...result.toJson(),
        },
      );
    }
  } on FormatException catch (e) {
    print('[ERROR] Invalid JSON: ${e.message}: $e');
    return badRequest('Invalid JSON: ${e.message}');
  } catch (e, st) {
    Log.e('Error in /ai/simulate: $e\n$st');
    return internalServerError('Internal server error');
  }
}

int _normalizedSimulationCount(
  Object? value, {
  required int defaultValue,
  int min = 1,
  int max = 5000,
}) {
  final parsed = value is int ? value : defaultValue;
  return parsed.clamp(min, max);
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
        Sql.named(
          '''
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
          ''',
        ),
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
    print('[ERROR] handler: $e');
    // Não falha a request se não conseguir salvar
    Log.w('Could not save simulation: $e');
  }
}

Map<String, dynamic> _externalDeckPayload(
  String deckId,
  List<Map<String, dynamic>> cards,
) =>
    {
      'id': deckId,
      'name': cards.first['deck_name']?.toString() ?? deckId,
      'cards': cards
          .map((card) => {
                'name': card['name'],
                'set_code': card['set_code'],
                'collector_number': card['collector_number'],
                'quantity': card['quantity'],
                'is_commander': card['is_commander'],
              })
          .toList(growable: false),
    };

Map<String, dynamic> _nativeBattle(
  List<Map<String, dynamic>> deckCards,
  List<Map<String, dynamic>> opponentCards, {
  required int maxTurns,
  required String fallbackReason,
  List<Map<String, dynamic>> xmageUnsupportedCards = const [],
  List<Map<String, dynamic>> forgeUnsupportedCards = const [],
}) {
  final native = BattleSimulator(
    deckACards: deckCards,
    deckBCards: opponentCards,
    maxTurns: maxTurns,
  ).simulate();
  return {
    'engine': 'manaloom_native_legacy',
    'engine_contract': 'experimental_advisory',
    'fallback_reason': fallbackReason,
    if (xmageUnsupportedCards.isNotEmpty)
      'xmage_unsupported_cards': xmageUnsupportedCards,
    if (forgeUnsupportedCards.isNotEmpty)
      'forge_unsupported_cards': forgeUnsupportedCards,
    ...native.toJson(),
  };
}

Future<Map<String, dynamic>> _simulateXmage(
  String sidecarUrl,
  Map<String, dynamic> request,
  int timeoutMs,
) async {
  final client = XmageBattleClient(
    baseUrl: sidecarUrl,
    timeout: Duration(milliseconds: timeoutMs + 30000),
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
    timeout: Duration(milliseconds: timeoutMs + 45000),
  );
  try {
    return await client.simulate(request);
  } finally {
    client.close();
  }
}

Future<Map<String, dynamic>> _forgeOrNativeFallback({
  required String forgeSidecarUrl,
  required Map<String, dynamic> externalRequest,
  required int timeoutMs,
  required List<Map<String, dynamic>> deckCards,
  required List<Map<String, dynamic>> opponentCards,
  required int maxTurns,
  required String fallbackReason,
  List<Map<String, dynamic>> xmageUnsupportedCards = const [],
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
    return _nativeBattle(
      deckCards,
      opponentCards,
      maxTurns: maxTurns,
      fallbackReason: '${fallbackReason}_forge_coverage_incomplete',
      xmageUnsupportedCards: xmageUnsupportedCards,
      forgeUnsupportedCards: error.unsupportedCards,
    );
  }
}

Response _engineConfigurationFailure(
  BattleEngineConfigurationException error,
) =>
    Response.json(
      statusCode: HttpStatus.serviceUnavailable,
      body: {
        'error': error.code,
        'details': error.message,
      },
    );

Response _externalEngineFailure(String engine, String message) {
  Log.e('$engine battle failed: $message');
  return Response.json(
    statusCode: HttpStatus.badGateway,
    body: {
      'error': '${engine}_unavailable',
      'details': message,
    },
  );
}

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
    'event_count': (result['events'] as List?)?.length ??
        (result['game_log'] as List?)?.length,
    'snapshot_count': (result['visual_snapshots'] as List?)?.length,
  }..removeWhere((_, value) => value == null);
}
