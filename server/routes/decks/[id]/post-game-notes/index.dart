import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

import '../../../../lib/http_responses.dart';
import '../../../../lib/retention/post_game_note_service.dart';

Future<Response> onRequest(RequestContext context, String deckId) async {
  if (context.request.method == HttpMethod.get) {
    return _list(context, deckId);
  }
  if (context.request.method == HttpMethod.post) {
    return _upsert(context, deckId);
  }
  return methodNotAllowed();
}

Future<Response> _list(RequestContext context, String deckId) async {
  final userId = context.read<String>();
  final service = PostGameNoteService(context.read<Pool>());

  try {
    if (!await service.ownsDeck(userId: userId, deckId: deckId)) {
      return notFound('Deck nao encontrado.');
    }
    final params = context.request.uri.queryParameters;
    final includeDeleted = params['include_deleted'] == 'true';
    final sinceRaw = params['since']?.trim();
    final since =
        sinceRaw == null || sinceRaw.isEmpty
            ? null
            : DateTime.tryParse(sinceRaw)?.toUtc();
    if (sinceRaw != null && sinceRaw.isNotEmpty && since == null) {
      return badRequest('since deve usar ISO-8601.');
    }
    final page = await service.listNotes(
      userId: userId,
      deckId: deckId,
      includeDeleted: includeDeleted,
      updatedSince: since,
    );
    return Response.json(
      body: {
        'data': page.notes,
        'sync_cursor': page.syncCursor.toIso8601String(),
      },
    );
  } catch (error) {
    return internalServerError(
      'Falha ao carregar historico pos-jogo',
      details: error,
    );
  }
}

Future<Response> _upsert(RequestContext context, String deckId) async {
  final userId = context.read<String>();
  final service = PostGameNoteService(context.read<Pool>());

  Map<String, dynamic> body;
  try {
    body = await context.request.json() as Map<String, dynamic>;
  } catch (_) {
    return badRequest('JSON invalido.');
  }

  try {
    if (!await service.ownsDeck(userId: userId, deckId: deckId)) {
      return notFound('Deck nao encontrado.');
    }
    final note = await service.upsertNote(
      userId: userId,
      deckId: deckId,
      note: body,
    );
    return Response.json(statusCode: HttpStatus.created, body: {'note': note});
  } on PostGameValidationException catch (error) {
    return badRequest(error.message);
  } on PostGameConflictException catch (error) {
    return _conflict(error);
  } on PostGameNoteNotFoundException {
    return notFound('Nota pos-jogo nao encontrada.');
  } catch (error) {
    return internalServerError('Falha ao salvar nota pos-jogo', details: error);
  }
}

Response _conflict(PostGameConflictException error) {
  return Response.json(
    statusCode: HttpStatus.conflict,
    body: {
      'error': 'post_game_conflict',
      'message':
          'A nota mudou em outro dispositivo ou já foi excluída. Atualize antes de tentar novamente.',
      if (error.currentNote != null) 'current_note': error.currentNote,
    },
  );
}
