import 'dart:convert';

import 'package:dart_frog/dart_frog.dart';
import 'package:test/test.dart';

import '../lib/retention/post_game_error_contract.dart';

/// LC-P0-06 (decisão 23 da coordenação): os 404 e 409 do pós-jogo levam um
/// código estável em `error_code`, na forma de erro dos decks, e o 409 não
/// perde o `error: post_game_conflict` que o cliente antigo compara.
void main() {
  final stableCode = RegExp(r'^[a-z][a-z0-9_]{2,63}$');

  Future<Map<String, dynamic>> body(Response response) async =>
      jsonDecode(await response.body()) as Map<String, dynamic>;

  test('os códigos são estáveis (snake_case do contrato D-21)', () {
    for (final code in const [
      postGameDeckNotFoundCode,
      postGameNoteNotFoundCode,
      postGameConflictCode,
      postGamePlaySessionConflictCode,
      postGameNoteDeletedCode,
      postGameRevisionConflictCode,
    ]) {
      expect(stableCode.hasMatch(code), isTrue, reason: code);
    }
    expect(postGameDeckNotFoundCode, 'deck_not_found');
    expect(postGameNoteNotFoundCode, 'post_game_note_not_found');
  });

  test('404 do deck e 404 da nota têm códigos diferentes', () async {
    final deck = postGameDeckNotFound();
    final note = postGameNoteNotFound();

    expect(deck.statusCode, 404);
    expect(await body(deck), {
      'error': 'Deck nao encontrado.',
      'error_code': 'deck_not_found',
    });
    expect(note.statusCode, 404);
    expect(await body(note), {
      'error': 'Nota pos-jogo nao encontrada.',
      'error_code': 'post_game_note_not_found',
    });
    expect(
      await body(postGameNotFoundFor(postGameDeckNotFoundCode)),
      containsPair('error_code', 'deck_not_found'),
    );
    expect(
      await body(postGameNotFoundFor(postGameNoteNotFoundCode)),
      containsPair('error_code', 'post_game_note_not_found'),
    );
  });

  test(
    '409 mantém post_game_conflict em error e o motivo em error_code',
    () async {
      final current = {'id': 'n1', 'is_deleted': true, 'revision': 2};
      final cases = {
        postGamePlaySessionConflictCode: 'já tem um pós-jogo registrado',
        postGameNoteDeletedCode: 'excluída em outro dispositivo',
        postGameRevisionConflictCode: 'mudou em outro dispositivo',
      };
      for (final entry in cases.entries) {
        final response = postGameConflict(
          code: entry.key,
          currentNote: current,
        );
        final json = await body(response);
        expect(response.statusCode, 409, reason: entry.key);
        expect(json['error'], 'post_game_conflict', reason: entry.key);
        expect(json['error_code'], entry.key);
        expect(json['message'], contains(entry.value), reason: entry.key);
        expect(json['current_note'], current, reason: entry.key);
      }

      final withoutNote = await body(
        postGameConflict(
          code: postGamePlaySessionConflictCode,
          currentNote: null,
        ),
      );
      expect(withoutNote.containsKey('current_note'), isFalse);

      final deleting = await body(
        postGameConflict(
          code: postGameRevisionConflictCode,
          currentNote: null,
          deleting: true,
        ),
      );
      expect(deleting['message'], contains('antes de excluir'));
    },
  );

  test('violação de unicidade: índice da partida ou corrida no id', () {
    expect(
      postGameConflictCodeForUniqueViolation('uq_post_game_notes_play_session'),
      postGamePlaySessionConflictCode,
    );
    expect(
      postGameConflictCodeForUniqueViolation(null),
      postGamePlaySessionConflictCode,
    );
    expect(
      postGameConflictCodeForUniqueViolation('post_game_notes_pkey'),
      postGameRevisionConflictCode,
    );
  });
}
