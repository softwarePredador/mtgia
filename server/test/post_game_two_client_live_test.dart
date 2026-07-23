@Tags(['live', 'live_backend', 'live_db_write'])
library;

import 'dart:convert';
import 'dart:io' show Platform;

import 'package:http/http.dart' as http;
import 'package:test/test.dart';

void main() {
  final skipIntegration =
      Platform.environment['RUN_INTEGRATION_TESTS'] == '0'
          ? 'Teste live desativado por RUN_INTEGRATION_TESTS=0.'
          : null;
  final baseUrl =
      Platform.environment['TEST_API_BASE_URL'] ?? 'http://127.0.0.1:8082';

  Map<String, String> headers(String? token, {String? ifMatch}) => {
    'Content-Type': 'application/json',
    'X-Request-Id':
        'post-game-two-client-${DateTime.now().microsecondsSinceEpoch}',
    if (token != null) 'Authorization': 'Bearer $token',
    if (ifMatch != null) 'If-Match': ifMatch,
  };

  Map<String, dynamic> objectBody(http.Response response) {
    final decoded = jsonDecode(response.body);
    expect(decoded, isA<Map<String, dynamic>>(), reason: response.body);
    return decoded as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> register(String suffix) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: headers(null),
      body: jsonEncode({
        'username': 'post_game_$suffix',
        'email': 'post_game_$suffix@example.invalid',
        'password': 'BetaQa!2026-Deck',
      }),
    );
    expect(response.statusCode, 201, reason: response.body);
    return objectBody(response);
  }

  Future<String> login(String email) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: headers(null),
      body: jsonEncode({'email': email, 'password': 'BetaQa!2026-Deck'}),
    );
    expect(response.statusCode, 200, reason: response.body);
    return objectBody(response)['token'] as String;
  }

  Future<Map<String, dynamic>> listNotes(
    String deckId,
    String token, {
    bool includeDeleted = true,
    String? since,
  }) async {
    final query = <String>[
      'include_deleted=$includeDeleted',
      if (since != null) 'since=${Uri.encodeQueryComponent(since)}',
    ].join('&');
    final response = await http.get(
      Uri.parse('$baseUrl/decks/$deckId/post-game-notes?$query'),
      headers: headers(token),
    );
    expect(response.statusCode, 200, reason: response.body);
    return objectBody(response);
  }

  Map<String, dynamic> notePayload({
    required String id,
    required String deckId,
    required String notes,
    int? baseRevision,
    String playSessionId = 's1-session-shared',
    String? deckSnapshotHash,
    String? deckVersionAt,
  }) => {
    'id': id,
    'deck_id': deckId,
    'created_at': '2026-07-21T18:00:00Z',
    'result': 'vitória',
    'table_level': 'optimized',
    'notes': notes,
    'performed_well': ['Sol Ring'],
    'underperformed': ['Carta lenta'],
    'issues': ['draw'],
    'play_session_id': playSessionId,
    'session_started_at': '2026-07-21T17:00:00Z',
    'session_ended_at': '2026-07-21T18:00:00Z',
    if (deckSnapshotHash != null) 'deck_snapshot_hash': deckSnapshotHash,
    if (deckVersionAt != null) 'deck_version_at': deckVersionAt,
    if (baseRevision != null) 'base_revision': baseRevision,
  };

  test(
    'two clients converge through retry conflict cursor and tombstone',
    () async {
      final suffix = DateTime.now().microsecondsSinceEpoch.toRadixString(16);
      final account = await register('${suffix}_owner');
      final accountUser = account['user'] as Map<String, dynamic>;
      final tokenA = account['token'] as String;
      final tokenB = await login(accountUser['email'] as String);
      final outsider = await register('${suffix}_outsider');
      final outsiderToken = outsider['token'] as String;

      final createDeck = await http.post(
        Uri.parse('$baseUrl/decks'),
        headers: headers(tokenA),
        body: jsonEncode({
          'name': 'Post-game two-client $suffix',
          'format': 'commander',
          'cards': const [],
        }),
      );
      expect(createDeck.statusCode, anyOf(200, 201), reason: createDeck.body);
      final deckId = objectBody(createDeck)['id'] as String;

      final sessionDeck = await http.get(
        Uri.parse('$baseUrl/decks/$deckId'),
        headers: headers(tokenA),
      );
      expect(sessionDeck.statusCode, 200, reason: sessionDeck.body);
      final sessionDeckBody = objectBody(sessionDeck);
      final sessionDeckSnapshotHash =
          sessionDeckBody['deck_snapshot_hash'] as String;
      final sessionDeckVersionAt = sessionDeckBody['deck_version_at'] as String;
      expect(sessionDeckSnapshotHash, hasLength(64));
      expect(DateTime.tryParse(sessionDeckVersionAt), isNotNull);

      final mutateDeck = await http.put(
        Uri.parse('$baseUrl/decks/$deckId'),
        headers: headers(tokenA),
        body: jsonEncode({'name': 'Post-game changed after start $suffix'}),
      );
      expect(mutateDeck.statusCode, 200, reason: mutateDeck.body);

      final changedDeck = await http.get(
        Uri.parse('$baseUrl/decks/$deckId'),
        headers: headers(tokenA),
      );
      expect(changedDeck.statusCode, 200, reason: changedDeck.body);
      final changedDeckBody = objectBody(changedDeck);
      final changedDeckSnapshotHash =
          changedDeckBody['deck_snapshot_hash'] as String;
      final changedDeckVersionAt = changedDeckBody['deck_version_at'] as String;
      expect(changedDeckSnapshotHash, isNot(sessionDeckSnapshotHash));

      final initial = await listNotes(deckId, tokenA);
      expect(initial['data'], isEmpty);
      final initialCursor = initial['sync_cursor'] as String;

      final incompleteSnapshot = await http.post(
        Uri.parse('$baseUrl/decks/$deckId/post-game-notes'),
        headers: headers(tokenA),
        body: jsonEncode(
          notePayload(
            id: 's1-incomplete-snapshot',
            deckId: deckId,
            notes: 'Metadado incompleto deve falhar.',
            playSessionId: 's1-incomplete-session',
            baseRevision: 0,
            deckSnapshotHash: sessionDeckSnapshotHash,
          ),
        ),
      );
      expect(
        incompleteSnapshot.statusCode,
        400,
        reason: incompleteSnapshot.body,
      );
      expect(
        objectBody(incompleteSnapshot)['error'],
        contains('devem ser enviados juntos'),
      );

      const noteId = 's1-two-client-note';
      final create = await http.post(
        Uri.parse('$baseUrl/decks/$deckId/post-game-notes'),
        headers: headers(tokenA),
        body: jsonEncode(
          notePayload(
            id: noteId,
            deckId: deckId,
            notes: 'Criada no cliente A.',
            baseRevision: 0,
            deckSnapshotHash: sessionDeckSnapshotHash,
            deckVersionAt: sessionDeckVersionAt,
          ),
        ),
      );
      expect(create.statusCode, 201, reason: create.body);
      final created = objectBody(create)['note'] as Map<String, dynamic>;
      expect(created['id'], noteId);
      expect(created['revision'], 1);
      expect(created['play_session_id'], 's1-session-shared');
      expect(created['deck_snapshot_hash'], sessionDeckSnapshotHash);
      expect(
        DateTime.parse(created['deck_version_at'] as String),
        DateTime.parse(sessionDeckVersionAt),
      );

      final clientBDelta = await listNotes(
        deckId,
        tokenB,
        since: initialCursor,
      );
      final clientBRows = clientBDelta['data'] as List<dynamic>;
      expect(clientBRows, hasLength(1));
      expect((clientBRows.single as Map)['revision'], 1);

      final retry = await http.post(
        Uri.parse('$baseUrl/decks/$deckId/post-game-notes'),
        headers: headers(tokenA),
        body: jsonEncode(
          notePayload(
            id: noteId,
            deckId: deckId,
            notes: 'Criada no cliente A.',
            deckSnapshotHash: changedDeckSnapshotHash,
            deckVersionAt: changedDeckVersionAt,
          ),
        ),
      );
      expect(retry.statusCode, 201, reason: retry.body);
      final retried = objectBody(retry)['note'] as Map<String, dynamic>;
      expect(retried['id'], noteId);
      expect(retried['revision'], 2);
      expect(retried['deck_snapshot_hash'], sessionDeckSnapshotHash);
      expect(
        DateTime.parse(retried['deck_version_at'] as String),
        DateTime.parse(sessionDeckVersionAt),
      );

      final duplicateSession = await http.post(
        Uri.parse('$baseUrl/decks/$deckId/post-game-notes'),
        headers: headers(tokenB),
        body: jsonEncode(
          notePayload(
            id: 's1-duplicate-session-note',
            deckId: deckId,
            notes: 'Não pode duplicar a sessão.',
            baseRevision: 0,
          ),
        ),
      );
      expect(duplicateSession.statusCode, 409, reason: duplicateSession.body);
      expect(objectBody(duplicateSession)['error'], 'post_game_conflict');

      final beforeUpdate = await listNotes(deckId, tokenA);
      final beforeUpdateCursor = beforeUpdate['sync_cursor'] as String;
      expect(beforeUpdate['data'], hasLength(1));

      final updateB = await http.post(
        Uri.parse('$baseUrl/decks/$deckId/post-game-notes'),
        headers: headers(tokenB),
        body: jsonEncode(
          notePayload(
            id: noteId,
            deckId: deckId,
            notes: 'Atualizada no cliente B.',
            baseRevision: 2,
          ),
        ),
      );
      expect(updateB.statusCode, 201, reason: updateB.body);
      final updatedByB = objectBody(updateB)['note'] as Map<String, dynamic>;
      expect(updatedByB['revision'], 3);
      expect(updatedByB['deck_snapshot_hash'], sessionDeckSnapshotHash);

      final staleUpdateA = await http.post(
        Uri.parse('$baseUrl/decks/$deckId/post-game-notes'),
        headers: headers(tokenA),
        body: jsonEncode(
          notePayload(
            id: noteId,
            deckId: deckId,
            notes: 'Atualização stale do cliente A.',
            baseRevision: 2,
          ),
        ),
      );
      expect(staleUpdateA.statusCode, 409, reason: staleUpdateA.body);
      final staleBody = objectBody(staleUpdateA);
      expect(staleBody['error'], 'post_game_conflict');
      expect((staleBody['current_note'] as Map)['revision'], 3);

      final updateDelta = await listNotes(
        deckId,
        tokenA,
        since: beforeUpdateCursor,
      );
      final updateRows = updateDelta['data'] as List<dynamic>;
      expect(updateRows, hasLength(1));
      expect((updateRows.single as Map)['notes'], 'Atualizada no cliente B.');
      expect((updateRows.single as Map)['revision'], 3);

      final beforeDeleteCursor = updateDelta['sync_cursor'] as String;
      final deleteB = await http.delete(
        Uri.parse('$baseUrl/decks/$deckId/post-game-notes/$noteId'),
        headers: headers(tokenB, ifMatch: '"3"'),
      );
      expect(deleteB.statusCode, 204, reason: deleteB.body);

      final deleteDelta = await listNotes(
        deckId,
        tokenA,
        since: beforeDeleteCursor,
      );
      final tombstones = deleteDelta['data'] as List<dynamic>;
      expect(tombstones, hasLength(1));
      final tombstone = tombstones.single as Map<String, dynamic>;
      expect(tombstone['id'], noteId);
      expect(tombstone['deck_id'], deckId);
      expect(tombstone['revision'], 4);
      expect(tombstone['is_deleted'], isTrue);
      expect(tombstone['deleted_at'], isA<String>());
      expect(tombstone, isNot(contains('notes')));

      final resurrectA = await http.post(
        Uri.parse('$baseUrl/decks/$deckId/post-game-notes'),
        headers: headers(tokenA),
        body: jsonEncode(
          notePayload(
            id: noteId,
            deckId: deckId,
            notes: 'Não pode ressuscitar.',
            baseRevision: 3,
          ),
        ),
      );
      expect(resurrectA.statusCode, 409, reason: resurrectA.body);
      final resurrectBody = objectBody(resurrectA);
      expect(resurrectBody['error'], 'post_game_conflict');
      expect((resurrectBody['current_note'] as Map)['is_deleted'], isTrue);

      final retryDelete = await http.delete(
        Uri.parse('$baseUrl/decks/$deckId/post-game-notes/$noteId'),
        headers: headers(tokenA),
      );
      expect(retryDelete.statusCode, 204, reason: retryDelete.body);

      final activeOnly = await listNotes(deckId, tokenA, includeDeleted: false);
      expect(activeOnly['data'], isEmpty);
      final withDeleted = await listNotes(deckId, tokenA);
      expect(withDeleted['data'], hasLength(1));

      final outsiderRead = await http.get(
        Uri.parse('$baseUrl/decks/$deckId/post-game-notes'),
        headers: headers(outsiderToken),
      );
      expect(outsiderRead.statusCode, 404, reason: outsiderRead.body);
    },
    skip: skipIntegration,
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
