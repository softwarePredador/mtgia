import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

import '../../../../lib/http_responses.dart';
import '../../../../lib/retention/post_game_note_service.dart';

Future<Response> onRequest(
  RequestContext context,
  String deckId,
  String noteId,
) async {
  if (context.request.method != HttpMethod.delete) {
    return methodNotAllowed();
  }

  final userId = context.read<String>();
  final service = PostGameNoteService(context.read<Pool>());

  try {
    if (!await service.ownsDeck(userId: userId, deckId: deckId)) {
      return notFound('Deck nao encontrado.');
    }
    final deleted = await service.deleteNote(
      userId: userId,
      deckId: deckId,
      noteId: noteId,
    );
    if (!deleted) return notFound('Nota pos-jogo nao encontrada.');
    return Response(statusCode: HttpStatus.noContent);
  } catch (error) {
    return internalServerError(
      'Falha ao excluir nota pos-jogo',
      details: error,
    );
  }
}
