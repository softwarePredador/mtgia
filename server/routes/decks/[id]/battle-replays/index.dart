import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

import '../../../../lib/battle/battle_replay_read_service.dart';
import '../../../../lib/http_responses.dart';
import '../../../../lib/logger.dart';
import '../../../../lib/observability.dart';

Future<Response> onRequest(RequestContext context, String deckId) async {
  if (context.request.method != HttpMethod.get) {
    return methodNotAllowed();
  }
  if (!isBattleReplayUuid(deckId)) {
    return notFound('Deck nao encontrado.');
  }

  final userId = context.read<String>();
  final service = BattleReplayReadService(context.read<Pool>());

  try {
    if (!await service.ownsDeck(userId: userId, deckId: deckId)) {
      return notFound('Deck nao encontrado.');
    }

    final limit = _limitFromQuery(context.request.uri.queryParameters['limit']);
    final page = await service.listReplayPage(
      userId: userId,
      deckId: deckId,
      limit: limit,
      cursor: context.request.uri.queryParameters['cursor'],
    );
    final replays = page.items;
    final hasAdvisoryReplay = replays.any(
      (replay) =>
          (replay['simulation_contract'] as Map?)?['advisory_only'] == true,
    );
    return Response.json(
      body: {
        'data': replays,
        'source': 'battle_simulations',
        'pagination': {
          'schema_version': battleReplayCursorSchema,
          'limit': limit,
          'has_more': page.hasMore,
          if (page.nextCursor != null) 'next_cursor': page.nextCursor,
        },
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
  } on BattleReplayCursorException {
    return badRequest('Cursor de replay invalido.');
  } catch (error, stackTrace) {
    Log.e('[battle-replays] list failed type=${error.runtimeType}');
    await captureRouteException(
      context,
      StateError('Battle replay list failed'),
      stackTrace: stackTrace,
      tags: {
        'route': 'battle_replays_list',
        'error_type': '${error.runtimeType}',
      },
    );
    return internalServerError('Falha ao carregar replays de battle');
  }
}

int _limitFromQuery(String? value) {
  final parsed = int.tryParse(value ?? '') ?? 30;
  return parsed.clamp(1, 100);
}
