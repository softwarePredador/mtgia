import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

import '../../../../lib/decks/deck_revision_support.dart';
import '../../../../lib/decks/deck_trash_support.dart';
import '../../../../lib/logger.dart';

/// POST /decks/:id/restore
///
/// Tira o deck da lixeira (DCK-P0-06; decisão D-30 do dono), íntegro e
/// privado: cartas, histórico e o resto nunca saíram do banco; o deck volta
/// com `is_public` falso e os relatórios seguem despublicados. Sobe a
/// revisão e grava `deck_restore` no ledger. `If-Match` vale como no
/// `DELETE`. É a única rota de `/decks/:id` que enxerga deck na lixeira.
///
/// - 200 `{ok, deck_id, revision, revision_before, change_event_id,
///   change_operation: deck_restore, is_public: false}`, com o `ETag`;
/// - 404 `deck_not_in_trash` quando o deck não está na lixeira do dono
///   (vivo, de outra pessoa, já purgado ou inexistente);
/// - 409 `deck_revision_conflict` com `If-Match` de outra revisão.
Future<Response> onRequest(RequestContext context, String deckId) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }
  final userId = context.read<String>();
  final pool = context.read<Pool>();
  final ifMatch = readDeckIfMatch(context.request.headers);
  if (ifMatch.malformed) {
    return const DeckRevisionException(
      code: deckIfMatchInvalidCode,
      message: 'If-Match precisa trazer a revisão do deck, como "7".',
      statusCode: HttpStatus.badRequest,
    ).toResponse();
  }
  if (!ifMatch.present && deckRevisionPolicyOf(context).requireIfMatch) {
    return const DeckRevisionException(
      code: deckRevisionRequiredCode,
      message: 'Envie If-Match com a revisão do deck para alterá-lo.',
      statusCode: HttpStatus.preconditionRequired,
    ).toResponse();
  }

  try {
    final outcome = await restoreDeckFromTrash(
      pool,
      userId: userId,
      deckId: deckId,
      expectedRevision: ifMatch.revision,
    );
    switch (outcome.result) {
      case DeckRestoreResult.notInTrash:
        return Response.json(
          statusCode: HttpStatus.notFound,
          body: const {
            'ok': false,
            'error': 'Este deck não está na lixeira.',
            'error_code': deckNotInTrashCode,
          },
        );
      case DeckRestoreResult.staleRevision:
        return DeckRevisionException(
          code: deckRevisionConflictCode,
          message:
              'O deck mudou desde a última leitura. Atualize e tente de novo.',
          statusCode: HttpStatus.conflict,
          currentRevision: outcome.revision,
        ).toResponse();
      case DeckRestoreResult.restored:
        return Response.json(
          body: {
            'ok': true,
            'deck_id': deckId,
            'revision': outcome.revision,
            'revision_before': outcome.revisionBefore,
            'change_event_id': outcome.eventId,
            'change_operation': 'deck_restore',
            'is_public': false,
          },
          headers: {'ETag': deckRevisionEtag(outcome.revision!)},
        );
    }
  } catch (error) {
    Log.e('[ERROR] restore deck failed: ${error.runtimeType}');
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: const {
        'ok': false,
        'error': 'Não foi possível restaurar o deck agora.',
        'error_code': 'deck_restore_failed',
      },
    );
  }
}
