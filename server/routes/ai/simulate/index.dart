import 'dart:convert';

import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

import '../../../lib/ai/battle_simulator.dart';
import '../../../lib/ai/goldfish_simulator.dart';
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
/// - battle: Simulação turno-a-turno simplificada/experimental
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
      // Simulação turno-a-turno simplificada/experimental.
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

      final simulator = BattleSimulator(
        deckACards: deckCards,
        deckBCards: opponentCards,
        maxTurns: (data['max_turns'] as int?) ?? 30,
      );
      final result = simulator.simulate();

      // Salva resultado para treinamento futuro
      await _saveSimulation(
        pool: pool,
        deckAId: deckId,
        deckBId: opponentId,
        type: 'battle',
        result: result.toJson(),
      );

      return Response.json(
        body: {
          'type': 'battle',
          'deck_a_id': deckId,
          'deck_b_id': opponentId,
          ...result.toJson(),
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
        dc.quantity,
        dc.is_commander
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
      'quantity': row[8],
      'is_commander': row[9],
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
          AND column_name IN ('simulation_type', 'metrics')
      ''');
      final availableColumns =
          columns.map((row) => row[0]?.toString()).whereType<String>().toSet();
      final hasSimulationType = availableColumns.contains('simulation_type');
      final hasMetrics = availableColumns.contains('metrics');
      final payload = {'type': type, ...result};

      await pool.execute(
        Sql.named(
          '''
          INSERT INTO battle_simulations (
            deck_a_id,
            deck_b_id,
            game_log
            ${hasSimulationType ? ', simulation_type' : ''}
            ${hasMetrics ? ', metrics' : ''}
          )
          VALUES (
            @deckAId,
            @deckBId,
            @gameLog::jsonb
            ${hasSimulationType ? ', @simulationType' : ''}
            ${hasMetrics ? ', @metrics::jsonb' : ''}
          )
          ''',
        ),
        parameters: {
          'deckAId': deckAId,
          'deckBId': deckBId,
          'gameLog': jsonEncode(payload),
          if (hasSimulationType) 'simulationType': type,
          if (hasMetrics) 'metrics': jsonEncode(payload),
        },
      );
    }
  } catch (e) {
    print('[ERROR] handler: $e');
    // Não falha a request se não conseguir salvar
    Log.w('Could not save simulation: $e');
  }
}
