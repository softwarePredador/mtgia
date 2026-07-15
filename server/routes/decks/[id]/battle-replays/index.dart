import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

import '../../../../lib/battle/battle_replay_read_service.dart';
import '../../../../lib/http_responses.dart';

Future<Response> onRequest(RequestContext context, String deckId) async {
  if (context.request.method != HttpMethod.get) {
    return methodNotAllowed();
  }

  final userId = context.read<String>();
  final service = BattleReplayReadService(context.read<Pool>());

  try {
    if (!await service.ownsDeck(userId: userId, deckId: deckId)) {
      return notFound('Deck nao encontrado.');
    }

    final limit = _limitFromQuery(context.request.uri.queryParameters['limit']);
    final replays = await service.listReplays(
      userId: userId,
      deckId: deckId,
      limit: limit,
    );
    final hasAdvisoryReplay = replays.any(
      (replay) =>
          (replay['simulation_contract'] as Map?)?['advisory_only'] == true,
    );
    return Response.json(
      body: {
        'data': replays,
        'source': 'battle_simulations',
        'advisory': hasAdvisoryReplay,
        'simulation_contract': const {
          'status': 'per_replay_engine_contract',
          'advisory_only': false,
          'rules_execution_status': 'per_replay',
          'canonical_legality_source': false,
          'event_stream_completeness': 'per_replay_learning_contract',
          'absence_proves_nonuse': false,
          'strategy_or_swap_proof': false,
        },
      },
    );
  } catch (error) {
    return internalServerError(
      'Falha ao carregar replays de battle',
      details: error,
    );
  }
}

int _limitFromQuery(String? value) {
  final parsed = int.tryParse(value ?? '') ?? 30;
  return parsed.clamp(1, 100);
}
