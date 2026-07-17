import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/api/api_client.dart';
import 'package:manaloom/features/retention/models/post_game_note.dart';
import 'package:manaloom/features/retention/services/post_game_note_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('stores notes and builds deck evolution summary', () async {
    final store = PostGameNoteStore();
    final note = PostGameNote.create(
      deckId: 'deck-1',
      result: '2º lugar',
      tableLevel: 'upgraded',
      notes: 'Faltou compra no meio do jogo.',
      performedWell: const ['Sol Ring', 'Esper Sentinel'],
      underperformed: const ['Carta Lenta'],
      issues: const [PostGameIssue.draw, PostGameIssue.winCondition],
      createdAt: DateTime.parse('2026-07-01T12:00:00Z'),
    );

    await store.addNote(note);

    final notes = await store.loadNotes('deck-1');
    expect(notes, hasLength(1));
    expect(notes.single.result, '2º lugar');

    final summary = await store.summarize('deck-1');
    expect(summary.totalMatches, 1);
    expect(summary.issueCounts[PostGameIssue.draw], 1);
    expect(summary.topPerformers, contains('Sol Ring'));
    expect(summary.reviewCandidates, contains('Carta Lenta'));
    expect(
      summary.suggestions,
      contains('Adicionar ou priorizar fontes de compra e seleção de cartas.'),
    );
  });

  test('corrupted local payload does not crash note loading', () async {
    SharedPreferences.setMockInitialValues({
      'manaloom.post_game_notes.deck-1': '{bad json',
    });
    final store = PostGameNoteStore();

    expect(await store.loadNotes('deck-1'), isEmpty);
    expect((await store.summarize('deck-1')).totalMatches, 0);
  });

  test('remote notes are merged with local offline notes', () async {
    final localNote = PostGameNote.create(
      deckId: 'deck-1',
      result: 'vitória',
      tableLevel: 'casual',
      notes: 'A base de mana segurou bem.',
      issues: const [PostGameIssue.protection],
      createdAt: DateTime.parse('2026-07-01T12:00:00Z'),
    );
    final remoteNote = PostGameNote.create(
      deckId: 'deck-1',
      result: 'derrota',
      tableLevel: 'optimized',
      notes: 'Faltou interação.',
      issues: const [PostGameIssue.removal],
      createdAt: DateTime.parse('2026-07-02T12:00:00Z'),
    );
    final remote = _FakePostGameRemoteClient([remoteNote]);
    final store = PostGameNoteStore(remoteClient: remote);

    await store.addNote(localNote);

    final notes = await store.loadNotes('deck-1');
    expect(
      notes.map((note) => note.id),
      containsAll([localNote.id, remoteNote.id]),
    );
    expect(remote.saved.map((note) => note.id), contains(localNote.id));
  });

  test(
    'remote merge preserves session metadata absent from the server',
    () async {
      final createdAt = DateTime.parse('2026-07-02T14:00:00Z');
      final startedAt = DateTime.parse('2026-07-02T12:00:00Z');
      final endedAt = DateTime.parse('2026-07-02T13:30:00Z');
      final local = PostGameNote.create(
        deckId: 'deck-session',
        result: 'vitória local',
        tableLevel: 'optimized',
        notes: 'Contexto local.',
        playSessionId: 'session-42',
        sessionStartedAt: startedAt,
        sessionEndedAt: endedAt,
        createdAt: createdAt,
      );
      final remote = PostGameNote.create(
        deckId: 'deck-session',
        result: 'vitória sincronizada',
        tableLevel: 'optimized',
        notes: 'Conteúdo confirmado pelo servidor.',
        createdAt: createdAt,
      );
      await PostGameNoteStore().addNote(local);

      final merged = await PostGameNoteStore(
        remoteClient: _FakePostGameRemoteClient([remote]),
      ).loadNotes('deck-session');

      expect(merged, hasLength(1));
      expect(merged.single.result, 'vitória sincronizada');
      expect(merged.single.playSessionId, 'session-42');
      expect(merged.single.sessionStartedAt, startedAt);
      expect(merged.single.sessionEndedAt, endedAt);
    },
  );

  test(
    'failed upsert stays queued and retries automatically on load',
    () async {
      final note = PostGameNote.create(
        deckId: 'deck-1',
        result: 'vitória',
        tableLevel: 'casual',
        notes: 'Salva sem rede.',
        createdAt: DateTime.parse('2026-07-03T12:00:00Z'),
      );
      final remote = _FakePostGameRemoteClient(const <PostGameNote>[])
        ..upsertFailuresRemaining = 1;
      final store = PostGameNoteStore(remoteClient: remote);

      await store.addNote(note);
      expect(await store.pendingOperationCount('deck-1'), 1);
      expect((await store.loadNotes('deck-1')).single.id, note.id);
      expect(await store.pendingOperationCount('deck-1'), 0);
      expect(remote.upsertAttempts, 2);
    },
  );

  test(
    'failed delete tombstone prevents a remote note from reappearing',
    () async {
      final note = PostGameNote.create(
        deckId: 'deck-1',
        result: 'derrota',
        tableLevel: 'casual',
        notes: 'Será removida.',
        createdAt: DateTime.parse('2026-07-04T12:00:00Z'),
      );
      final remote = _FakePostGameRemoteClient([note])
        ..deleteFailuresRemaining = 2;
      final store = PostGameNoteStore(remoteClient: remote);

      await store.deleteNote('deck-1', note.id);
      expect(await store.pendingOperationCount('deck-1'), 1);
      expect(await store.loadNotes('deck-1'), isEmpty);
      expect(await store.pendingOperationCount('deck-1'), 1);

      remote.deleteFailuresRemaining = 0;
      expect(await store.loadNotes('deck-1'), isEmpty);
      expect(await store.pendingOperationCount('deck-1'), 0);
    },
  );

  test(
    'server tombstone removes stale local note from another device',
    () async {
      final note = PostGameNote.create(
        deckId: 'deck-cross-device',
        result: 'vitória',
        tableLevel: 'casual',
        notes: 'Excluída em outro dispositivo.',
        createdAt: DateTime.parse('2026-07-04T18:00:00Z'),
      );
      await PostGameNoteStore().addNote(note);

      final remote = _FakePostGameRemoteClient(
        const <PostGameNote>[],
        deletedNoteIds: {note.id},
      );
      final synchronized = await PostGameNoteStore(
        remoteClient: remote,
      ).loadNotes(note.deckId);

      expect(synchronized, isEmpty);
      expect(await PostGameNoteStore().loadNotes(note.deckId), isEmpty);
    },
  );

  test(
    'API solicita e interpreta tombstones com cursor de sincronização',
    () async {
      final api = _PostGameApiClient();
      final page = await ApiPostGameNoteRemoteClient(
        apiClient: api,
      ).loadNotes('deck-api');

      expect(
        api.lastEndpoint,
        '/decks/deck-api/post-game-notes?include_deleted=true',
      );
      expect(page.notes, hasLength(1));
      expect(page.notes.single.id, 'active-note');
      expect(page.deletedNoteIds, {'deleted-note'});
      expect(page.syncCursor, DateTime.parse('2026-07-16T12:30:00Z'));
    },
  );

  test(
    'simultaneous adds across stores preserve every note and pending upsert',
    () async {
      final preferences = await SharedPreferences.getInstance();
      final remote = _FakePostGameRemoteClient(<PostGameNote>[])
        ..upsertFailuresRemaining = 2;
      final firstStore = PostGameNoteStore(
        preferencesLoader: _yieldingLoader(preferences),
        remoteClient: remote,
      );
      final secondStore = PostGameNoteStore(
        preferencesLoader: _yieldingLoader(preferences),
        remoteClient: remote,
      );
      final first = PostGameNote.create(
        deckId: 'deck-race',
        result: 'vitória',
        tableLevel: 'casual',
        notes: 'Primeira nota concorrente.',
        createdAt: DateTime.parse('2026-07-05T12:00:00Z'),
      );
      final second = PostGameNote.create(
        deckId: 'deck-race',
        result: 'derrota',
        tableLevel: 'casual',
        notes: 'Segunda nota concorrente.',
        createdAt: DateTime.parse('2026-07-05T13:00:00Z'),
      );

      await Future.wait([
        firstStore.addNote(first),
        secondStore.addNote(second),
      ]);

      final localOnlyStore = PostGameNoteStore(
        preferencesLoader: _yieldingLoader(preferences),
      );
      final stored = await localOnlyStore.loadNotes('deck-race');
      expect(stored.map((note) => note.id), containsAll([first.id, second.id]));
      expect(await firstStore.pendingOperationCount('deck-race'), 2);
    },
  );

  test(
    'simultaneous deletes cannot resurrect notes or lose tombstones',
    () async {
      final preferences = await SharedPreferences.getInstance();
      final first = PostGameNote.create(
        deckId: 'deck-delete-race',
        result: 'vitória',
        tableLevel: 'casual',
        notes: 'Excluir primeira.',
        createdAt: DateTime.parse('2026-07-06T12:00:00Z'),
      );
      final second = PostGameNote.create(
        deckId: 'deck-delete-race',
        result: 'derrota',
        tableLevel: 'casual',
        notes: 'Excluir segunda.',
        createdAt: DateTime.parse('2026-07-06T13:00:00Z'),
      );
      final seedStore = PostGameNoteStore();
      await seedStore.addNote(first);
      await seedStore.addNote(second);

      final remote = _FakePostGameRemoteClient([first, second])
        ..deleteFailuresRemaining = 2;
      final firstStore = PostGameNoteStore(
        preferencesLoader: _yieldingLoader(preferences),
        remoteClient: remote,
      );
      final secondStore = PostGameNoteStore(
        preferencesLoader: _yieldingLoader(preferences),
        remoteClient: remote,
      );

      await Future.wait([
        firstStore.deleteNote('deck-delete-race', first.id),
        secondStore.deleteNote('deck-delete-race', second.id),
      ]);

      final localOnlyStore = PostGameNoteStore(
        preferencesLoader: _yieldingLoader(preferences),
      );
      expect(await localOnlyStore.loadNotes('deck-delete-race'), isEmpty);
      expect(await firstStore.pendingOperationCount('deck-delete-race'), 2);
    },
  );
}

PostGamePreferencesLoader _yieldingLoader(SharedPreferences preferences) {
  return () async {
    await Future<void>.delayed(Duration.zero);
    return preferences;
  };
}

class _FakePostGameRemoteClient implements PostGameNoteRemoteClient {
  _FakePostGameRemoteClient(
    this.notes, {
    Set<String> deletedNoteIds = const <String>{},
  }) : deletedNoteIds = Set<String>.from(deletedNoteIds);

  final List<PostGameNote> notes;
  final Set<String> deletedNoteIds;
  final List<PostGameNote> saved = <PostGameNote>[];
  final List<String> deleted = <String>[];
  int upsertFailuresRemaining = 0;
  int deleteFailuresRemaining = 0;
  int upsertAttempts = 0;

  @override
  Future<PostGameNoteSyncPage> loadNotes(String deckId) async {
    return PostGameNoteSyncPage(
      notes: notes
          .where((note) => note.deckId == deckId)
          .toList(growable: false),
      deletedNoteIds: Set<String>.unmodifiable(deletedNoteIds),
      syncCursor: DateTime.parse('2026-07-16T12:00:00Z'),
    );
  }

  @override
  Future<void> upsertNote(PostGameNote note) async {
    upsertAttempts += 1;
    if (upsertFailuresRemaining > 0) {
      upsertFailuresRemaining -= 1;
      throw StateError('offline');
    }
    saved.add(note);
  }

  @override
  Future<void> deleteNote(String deckId, String noteId) async {
    if (deleteFailuresRemaining > 0) {
      deleteFailuresRemaining -= 1;
      throw StateError('offline');
    }
    deleted.add('$deckId:$noteId');
    notes.removeWhere((note) => note.id == noteId);
    deletedNoteIds.add(noteId);
  }
}

class _PostGameApiClient extends ApiClient {
  String? lastEndpoint;

  @override
  Future<ApiResponse> get(String endpoint) async {
    lastEndpoint = endpoint;
    return ApiResponse(200, {
      'data': [
        {
          'id': 'active-note',
          'deck_id': 'deck-api',
          'created_at': '2026-07-16T11:00:00Z',
          'result': 'vitória',
          'table_level': 'casual',
          'notes': 'Sincronizada.',
          'is_deleted': false,
          'deleted_at': null,
        },
        {
          'id': 'deleted-note',
          'deck_id': 'deck-api',
          'revision': 2,
          'updated_at': '2026-07-16T12:00:00Z',
          'deleted_at': '2026-07-16T12:00:00Z',
          'is_deleted': true,
        },
      ],
      'sync_cursor': '2026-07-16T12:30:00Z',
    });
  }
}
