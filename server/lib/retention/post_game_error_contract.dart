import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

/// Erros tipados do pós-jogo (BT-AUTH-001, D-21; LC-P0-06).
///
/// Os 404 e 409 de `/decks/:id/post-game-notes` levam um código estável em
/// `error_code`, na forma de erro dos decks: a frase continua em `error` no
/// 404 (o app a mostra), e o 409 mantém o código geral `post_game_conflict` em
/// `error`, com a frase em `message` e o motivo em `error_code`. O app usa o
/// código para separar "nota que nunca chegou ao servidor" (pode apagar o
/// tombstone) de "deck que não é desta conta" ou "capability desligada" (não
/// pode), e "esta partida já tem nota" de "a nota mudou em outro aparelho".
const postGameDeckNotFoundCode = 'deck_not_found';
const postGameNoteNotFoundCode = 'post_game_note_not_found';

/// Código geral do 409, em `error` (o cliente antigo já compara com ele).
const postGameConflictCode = 'post_game_conflict';

/// A partida (`play_session_id`) já tem uma nota viva neste deck
/// (`uq_post_game_notes_play_session`).
const postGamePlaySessionConflictCode = 'post_game_play_session_conflict';

/// A nota foi apagada (tombstone) em outro aparelho.
const postGameNoteDeletedCode = 'post_game_note_deleted';

/// A revisão mandada (`base_revision` ou `If-Match`) não é a atual.
const postGameRevisionConflictCode = 'post_game_revision_conflict';

const postGameDeckNotFoundMessage = 'Deck nao encontrado.';
const postGameNoteNotFoundMessage = 'Nota pos-jogo nao encontrada.';

/// Motivo do 409 para uma violação de unicidade (`23505`) no insert da nota:
/// o índice único da partida, ou a corrida no id da nota (chave primária).
String postGameConflictCodeForUniqueViolation(String? constraintName) {
  if (constraintName == null || constraintName.contains('play_session')) {
    return postGamePlaySessionConflictCode;
  }
  return postGameRevisionConflictCode;
}

Response postGameDeckNotFound() =>
    _notFound(postGameDeckNotFoundMessage, postGameDeckNotFoundCode);

Response postGameNoteNotFound() =>
    _notFound(postGameNoteNotFoundMessage, postGameNoteNotFoundCode);

/// 404 pelo código da exceção do serviço (nota de outra conta, ou o deck que
/// sumiu no meio do upsert).
Response postGameNotFoundFor(String code) =>
    code == postGameDeckNotFoundCode
        ? postGameDeckNotFound()
        : postGameNoteNotFound();

/// 409 do upsert (`deleting: false`) ou da exclusão (`deleting: true`).
Response postGameConflict({
  required String code,
  required Map<String, dynamic>? currentNote,
  bool deleting = false,
}) {
  return Response.json(
    statusCode: HttpStatus.conflict,
    body: {
      'error': postGameConflictCode,
      'error_code': code,
      'message': _conflictMessage(code, deleting: deleting),
      if (currentNote != null) 'current_note': currentNote,
    },
  );
}

String _conflictMessage(String code, {required bool deleting}) {
  switch (code) {
    case postGamePlaySessionConflictCode:
      return 'Esta partida já tem um pós-jogo registrado. Para trocar o '
          'registro, apague o anterior e salve de novo.';
    case postGameNoteDeletedCode:
      return 'Esta nota foi excluída em outro dispositivo. Atualize o '
          'histórico antes de salvar de novo.';
    default:
      return deleting
          ? 'A nota mudou em outro dispositivo. Atualize antes de excluir.'
          : 'A nota mudou em outro dispositivo. Atualize antes de tentar '
              'novamente.';
  }
}

Response _notFound(String message, String code) => Response.json(
  statusCode: HttpStatus.notFound,
  body: {'error': message, 'error_code': code},
);
