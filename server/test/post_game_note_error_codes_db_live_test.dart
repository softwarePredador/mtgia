@Tags(['live', 'live_db_write'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import '../lib/release_capability_policy.dart';
import '../routes/decks/[id]/post-game-notes/[noteId].dart' as delete_route;
import '../routes/decks/[id]/post-game-notes/index.dart' as notes_route;
import '../routes/decks/[id]/post-game-timeline/index.dart' as timeline_route;
import 'support/release_capability_matrix.dart';
import 'support/scripted_pool.dart';

/// LC-P0-06 (decisão 23 da coordenação) em PostgreSQL descartável: pelas
/// rotas reais, cada 404 e 409 do pós-jogo diz o motivo em `error_code`. O
/// app só apaga o tombstone com o 404 da própria nota, e separa "esta partida
/// já tem nota" de "a nota mudou ou foi apagada em outro aparelho".
///
/// Requer `RUN_DECK_DB_TESTS=1` e as variáveis `DB_*` de um banco descartável
/// já migrado.
void main() {
  final enabled = Platform.environment['RUN_DECK_DB_TESTS'] == '1';
  final skipReason =
      enabled ? null : 'Requer PostgreSQL descartavel explicitamente isolado.';
  final suffix = DateTime.now().microsecondsSinceEpoch;
  late Pool pool;
  late String owner;
  late String stranger;

  setUpAll(() async {
    if (!enabled) return;
    pool = Pool.withEndpoints([
      Endpoint(
        host: Platform.environment['DB_HOST'] ?? '127.0.0.1',
        port: int.parse(Platform.environment['DB_PORT'] ?? '5432'),
        database: Platform.environment['DB_NAME']!,
        username: Platform.environment['DB_USER']!,
        password: Platform.environment['DB_PASS'] ?? '',
      ),
    ], settings: const PoolSettings(sslMode: SslMode.disable));
    Future<String> user(String name) async {
      final row = await pool.execute(
        Sql.named('''
          INSERT INTO users (username, email, password_hash)
          VALUES (@username, @email, 'x')
          RETURNING id::text
        '''),
        parameters: {
          'username': '${name}_$suffix',
          'email': '${name}_$suffix@example.invalid',
        },
      );
      return row.single.single! as String;
    }

    owner = await user('lc06err_owner');
    stranger = await user('lc06err_stranger');
  });

  tearDownAll(() async {
    if (!enabled) return;
    await pool.execute(
      Sql.named('DELETE FROM users WHERE username IN (@owner, @stranger)'),
      parameters: {
        'owner': 'lc06err_owner_$suffix',
        'stranger': 'lc06err_stranger_$suffix',
      },
    );
    await pool.close();
  });

  RequestContext context(
    String userId,
    String method,
    String path, {
    Object? body,
    Map<String, String> headers = const {},
  }) => ScriptedRequestContext(
    Request(
      method,
      Uri.parse('http://localhost$path'),
      headers: {'content-type': 'application/json', ...headers},
      body: body == null ? null : jsonEncode(body),
    ),
    providers: {
      Pool: pool,
      String: userId,
      ReleaseCapabilityPolicy: releaseCapabilityPolicyWith(
        betaCoreCapabilities,
      ),
    },
  );

  Future<String> seedDeck(String userId) async {
    final deck = await pool.execute(
      Sql.named('''
        INSERT INTO decks (user_id, name, format)
        VALUES (CAST(@userId AS uuid), @name, 'commander')
        RETURNING id::text
      '''),
      parameters: {'userId': userId, 'name': 'Pós-jogo $suffix'},
    );
    return deck.single.single! as String;
  }

  Map<String, dynamic> note(String id, {String? session, int? baseRevision}) =>
      {
        'id': id,
        'result': 'vitória',
        'table_level': 'casual',
        'notes': 'Nota $id',
        'issues': <String>[],
        'performed_well': <Object>[],
        'underperformed': <Object>[],
        if (session != null) 'play_session_id': session,
        if (baseRevision != null) 'base_revision': baseRevision,
      };

  Future<(int, Map<String, dynamic>)> post(
    String userId,
    String deckId,
    Map<String, dynamic> body,
  ) async {
    final response = await notes_route.onRequest(
      context(userId, 'POST', '/decks/$deckId/post-game-notes', body: body),
      deckId,
    );
    final raw = await response.body();
    return (
      response.statusCode,
      raw.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(raw) as Map<String, dynamic>,
    );
  }

  Future<(int, Map<String, dynamic>)> delete(
    String userId,
    String deckId,
    String noteId, {
    Map<String, String> headers = const {},
  }) async {
    final response = await delete_route.onRequest(
      context(
        userId,
        'DELETE',
        '/decks/$deckId/post-game-notes/$noteId',
        headers: headers,
      ),
      deckId,
      noteId,
    );
    final raw = await response.body();
    return (
      response.statusCode,
      raw.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(raw) as Map<String, dynamic>,
    );
  }

  test(
    'a segunda nota da mesma partida é 409 post_game_play_session_conflict',
    () async {
      final deckId = await seedDeck(owner);
      final (firstStatus, _) = await post(
        owner,
        deckId,
        note('lc06err-a-$suffix', session: 'play-$suffix'),
      );
      expect(firstStatus, HttpStatus.created);

      final (status, body) = await post(
        owner,
        deckId,
        note('lc06err-b-$suffix', session: 'play-$suffix'),
      );

      expect(status, HttpStatus.conflict);
      expect(body['error'], 'post_game_conflict');
      expect(body['error_code'], 'post_game_play_session_conflict');
      expect(body['message'], contains('já tem um pós-jogo registrado'));
    },
    skip: skipReason,
  );

  test(
    'salvar uma nota apagada em outro aparelho é 409 post_game_note_deleted',
    () async {
      final deckId = await seedDeck(owner);
      final id = 'lc06err-del-$suffix';
      expect((await post(owner, deckId, note(id))).$1, HttpStatus.created);
      expect((await delete(owner, deckId, id)).$1, HttpStatus.noContent);

      final (status, body) = await post(owner, deckId, note(id));

      expect(status, HttpStatus.conflict);
      expect(body['error'], 'post_game_conflict');
      expect(body['error_code'], 'post_game_note_deleted');
      expect(body['current_note'], isA<Map<String, dynamic>>());
    },
    skip: skipReason,
  );

  test(
    'revisão antiga no upsert e no DELETE é 409 post_game_revision_conflict',
    () async {
      final deckId = await seedDeck(owner);
      final id = 'lc06err-rev-$suffix';
      expect((await post(owner, deckId, note(id))).$1, HttpStatus.created);

      final (upsertStatus, upsertBody) = await post(
        owner,
        deckId,
        note(id, baseRevision: 7),
      );
      final (deleteStatus, deleteBody) = await delete(
        owner,
        deckId,
        id,
        headers: const {'if-match': '7'},
      );

      expect(upsertStatus, HttpStatus.conflict);
      expect(upsertBody['error_code'], 'post_game_revision_conflict');
      expect(deleteStatus, HttpStatus.conflict);
      expect(deleteBody['error'], 'post_game_conflict');
      expect(deleteBody['error_code'], 'post_game_revision_conflict');
      expect(deleteBody['message'], contains('antes de excluir'));
    },
    skip: skipReason,
  );

  test('deck de outra conta é 404 deck_not_found no GET, no POST, no DELETE e '
      'na linha do tempo', () async {
    final deckId = await seedDeck(owner);
    final id = 'lc06err-owner-$suffix';
    expect((await post(owner, deckId, note(id))).$1, HttpStatus.created);

    final list = await notes_route.onRequest(
      context(stranger, 'GET', '/decks/$deckId/post-game-notes'),
      deckId,
    );
    final timeline = await timeline_route.onRequest(
      context(stranger, 'GET', '/decks/$deckId/post-game-timeline'),
      deckId,
    );
    final (postStatus, postBody) = await post(stranger, deckId, note(id));
    final (deleteStatus, deleteBody) = await delete(stranger, deckId, id);

    for (final (status, body) in [
      (list.statusCode, jsonDecode(await list.body()) as Map<String, dynamic>),
      (
        timeline.statusCode,
        jsonDecode(await timeline.body()) as Map<String, dynamic>,
      ),
      (postStatus, postBody),
      (deleteStatus, deleteBody),
    ]) {
      expect(status, HttpStatus.notFound);
      expect(body, {
        'error': 'Deck nao encontrado.',
        'error_code': 'deck_not_found',
      });
    }
  }, skip: skipReason);

  test(
    'nota que não existe neste deck é 404 post_game_note_not_found',
    () async {
      final deckId = await seedDeck(owner);
      final strangerDeck = await seedDeck(stranger);
      final id = 'lc06err-taken-$suffix';
      expect((await post(owner, deckId, note(id))).$1, HttpStatus.created);

      // DELETE de uma nota que nunca chegou ao servidor: o app pode apagar o
      // tombstone só com este código.
      final (neverStatus, neverBody) = await delete(
        owner,
        deckId,
        'lc06err-never-$suffix',
      );
      // O mesmo id já usado por outra conta (achado A11) no deck de quem pede.
      final (takenStatus, takenBody) = await post(
        stranger,
        strangerDeck,
        note(id),
      );

      expect(neverStatus, HttpStatus.notFound);
      expect(neverBody, {
        'error': 'Nota pos-jogo nao encontrada.',
        'error_code': 'post_game_note_not_found',
      });
      expect(takenStatus, HttpStatus.notFound);
      expect(takenBody['error_code'], 'post_game_note_not_found');
    },
    skip: skipReason,
  );
}
