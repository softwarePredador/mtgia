import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

import '../../../../lib/http_responses.dart';
import '../../../../lib/retention/post_game_note_service.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  if (context.request.method != HttpMethod.get) {
    return methodNotAllowed();
  }

  final userId = context.read<String>();
  final service = PostGameNoteService(context.read<Pool>());

  try {
    if (!await service.ownsDeck(userId: userId, deckId: id)) {
      return notFound('Deck nao encontrado.');
    }
    final timeline = await service.buildTimeline(userId: userId, deckId: id);
    return Response.json(body: timeline);
  } catch (error) {
    return internalServerError(
      'Falha ao carregar evolucao pos-jogo',
      details: error,
    );
  }
}
