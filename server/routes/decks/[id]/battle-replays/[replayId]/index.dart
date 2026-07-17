import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

import '../../../../../lib/battle/battle_replay_read_service.dart';
import '../../../../../lib/http_responses.dart';
import '../../../../../lib/logger.dart';
import '../../../../../lib/observability.dart';

Future<Response> onRequest(
  RequestContext context,
  String deckId,
  String replayId,
) async {
  if (context.request.method != HttpMethod.get) {
    return methodNotAllowed();
  }

  final userId = context.read<String>();
  final service = BattleReplayReadService(context.read<Pool>());

  try {
    if (!await service.ownsDeck(userId: userId, deckId: deckId)) {
      return notFound('Deck nao encontrado.');
    }

    final replay = await service.fetchReplay(
      userId: userId,
      deckId: deckId,
      replayId: replayId,
    );
    if (replay == null) {
      return notFound('Replay nao encontrado.');
    }
    return Response.json(body: {'replay': replay});
  } catch (error, stackTrace) {
    Log.e('[battle-replays] detail failed type=${error.runtimeType}');
    await captureRouteException(
      context,
      error,
      stackTrace: stackTrace,
      tags: const {'route': 'battle_replay_detail'},
    );
    return internalServerError('Falha ao carregar replay de battle');
  }
}
