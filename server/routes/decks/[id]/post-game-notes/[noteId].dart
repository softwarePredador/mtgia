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
      baseRevision: _ifMatchRevision(context.request.headers),
    );
    if (!deleted) return notFound('Nota pos-jogo nao encontrada.');
    return Response(statusCode: HttpStatus.noContent);
  } on PostGameValidationException catch (error) {
    return badRequest(error.message);
  } on PostGameConflictException catch (error) {
    return Response.json(
      statusCode: HttpStatus.conflict,
      body: {
        'error': 'post_game_conflict',
        'message':
            'A nota mudou em outro dispositivo. Atualize antes de excluir.',
        if (error.currentNote != null) 'current_note': error.currentNote,
      },
    );
  } catch (error) {
    return internalServerError(
      'Falha ao excluir nota pos-jogo',
      details: error,
    );
  }
}

int? _ifMatchRevision(Map<String, String> headers) {
  String? raw;
  for (final entry in headers.entries) {
    if (entry.key.toLowerCase() == 'if-match') raw = entry.value;
  }
  if (raw == null || raw.trim().isEmpty || raw.trim() == '*') return null;
  final normalized = raw
      .trim()
      .replaceFirst(RegExp(r'^W/'), '')
      .replaceAll('"', '');
  final revision = int.tryParse(normalized);
  if (revision == null || revision <= 0) {
    throw const PostGameValidationException(
      'If-Match deve conter uma revision positiva.',
    );
  }
  return revision;
}
