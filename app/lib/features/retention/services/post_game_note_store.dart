import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/api/api_client.dart';
import '../models/post_game_note.dart';

typedef PostGamePreferencesLoader = Future<SharedPreferences> Function();

abstract class PostGameNoteRemoteClient {
  Future<PostGameNoteSyncPage> loadNotes(String deckId);
  Future<void> upsertNote(PostGameNote note);
  Future<void> deleteNote(String deckId, String noteId);
}

class PostGameNoteSyncPage {
  const PostGameNoteSyncPage({
    this.notes = const <PostGameNote>[],
    this.deletedNoteIds = const <String>{},
    this.syncCursor,
  });

  final List<PostGameNote> notes;
  final Set<String> deletedNoteIds;
  final DateTime? syncCursor;
}

class ApiPostGameNoteRemoteClient implements PostGameNoteRemoteClient {
  ApiPostGameNoteRemoteClient({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  @override
  Future<PostGameNoteSyncPage> loadNotes(String deckId) async {
    final response = await _apiClient.get(
      '/decks/${Uri.encodeComponent(deckId)}/post-game-notes?include_deleted=true',
    );
    if (response.statusCode != 200 || response.data is! Map<String, dynamic>) {
      throw StateError('Falha ao carregar pos-jogo remoto.');
    }
    final payload = response.data as Map<String, dynamic>;
    final data = payload['data'];
    if (data is! List) return const PostGameNoteSyncPage();
    final notes = <PostGameNote>[];
    final deletedNoteIds = <String>{};
    for (final entry in data.whereType<Map>()) {
      final json = entry.cast<String, dynamic>();
      if (json['is_deleted'] == true || json['deleted_at'] != null) {
        final id = json['id']?.toString().trim() ?? '';
        final entryDeckId = json['deck_id']?.toString() ?? deckId;
        if (id.isNotEmpty && entryDeckId == deckId) deletedNoteIds.add(id);
        continue;
      }
      final note = PostGameNote.fromJson(json);
      if (note.deckId == deckId) notes.add(note);
    }
    notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return PostGameNoteSyncPage(
      notes: notes,
      deletedNoteIds: Set<String>.unmodifiable(deletedNoteIds),
      syncCursor: DateTime.tryParse(payload['sync_cursor']?.toString() ?? ''),
    );
  }

  @override
  Future<void> upsertNote(PostGameNote note) async {
    final response = await _apiClient.post(
      '/decks/${Uri.encodeComponent(note.deckId)}/post-game-notes',
      note.toJson(),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('Falha ao salvar pos-jogo remoto.');
    }
  }

  @override
  Future<void> deleteNote(String deckId, String noteId) async {
    final response = await _apiClient.delete(
      '/decks/${Uri.encodeComponent(deckId)}/post-game-notes/${Uri.encodeComponent(noteId)}',
    );
    if (response.statusCode != 204 && response.statusCode != 404) {
      throw StateError('Falha ao excluir pos-jogo remoto.');
    }
  }
}

class PostGameNoteStore {
  PostGameNoteStore({
    PostGamePreferencesLoader? preferencesLoader,
    PostGameNoteRemoteClient? remoteClient,
  }) : _preferencesLoader = preferencesLoader ?? SharedPreferences.getInstance,
       _remoteClient = remoteClient;

  final PostGamePreferencesLoader _preferencesLoader;
  final PostGameNoteRemoteClient? _remoteClient;
  static final Map<String, Future<void>> _deckOperationTails =
      <String, Future<void>>{};

  Future<List<PostGameNote>> loadNotes(String deckId) {
    return _serializeDeckOperation(deckId, () => _loadNotesUnlocked(deckId));
  }

  Future<List<PostGameNote>> _loadNotesUnlocked(String deckId) async {
    final localNotes = await _loadLocalNotes(deckId);
    final remoteClient = _remoteClient;
    if (remoteClient == null) return localNotes;

    try {
      await _flushPendingOperations(deckId, remoteClient);
      final remotePage = await remoteClient.loadNotes(deckId);
      for (final deletedId in remotePage.deletedNoteIds) {
        await _removePendingUpsert(deckId, deletedId);
      }
      final pendingUpserts = await _loadPendingUpserts(deckId);
      final pendingDeletes = await _loadPendingDeletes(deckId);
      final mergedById = <String, PostGameNote>{
        for (final note in _mergeNotes(
          remotePage.notes,
          localNotes
              .where((note) => !remotePage.deletedNoteIds.contains(note.id))
              .toList(growable: false),
        ))
          note.id: note,
        for (final note in pendingUpserts) note.id: note,
      }..removeWhere(
        (id, _) =>
            pendingDeletes.contains(id) ||
            remotePage.deletedNoteIds.contains(id),
      );
      final merged =
          mergedById.values.toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      await _saveNotes(deckId, merged);
      return merged;
    } catch (_) {
      return localNotes;
    }
  }

  Future<List<PostGameNote>> _loadLocalNotes(String deckId) async {
    final prefs = await _preferencesLoader();
    final raw = prefs.getString(_key(deckId));
    if (raw == null || raw.trim().isEmpty) return const <PostGameNote>[];
    final dynamic decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (_) {
      return const <PostGameNote>[];
    }
    if (decoded is! List) return const <PostGameNote>[];
    final notes =
        decoded
            .whereType<Map>()
            .map((entry) => PostGameNote.fromJson(entry.cast()))
            .where((note) => note.deckId == deckId)
            .toList();
    notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return notes;
  }

  Future<void> addNote(PostGameNote note) {
    return _serializeDeckOperation(note.deckId, () => _addNoteUnlocked(note));
  }

  Future<void> _addNoteUnlocked(PostGameNote note) async {
    final notes = await _loadLocalNotes(note.deckId);
    final next = [note, ...notes.where((item) => item.id != note.id)];
    await _saveNotes(note.deckId, next);
    final remoteClient = _remoteClient;
    if (remoteClient == null) return;

    await _enqueueUpsert(note);
    try {
      await remoteClient.upsertNote(note);
      await _removePendingUpsert(note.deckId, note.id);
    } catch (_) {}
  }

  Future<void> deleteNote(String deckId, String noteId) {
    return _serializeDeckOperation(
      deckId,
      () => _deleteNoteUnlocked(deckId, noteId),
    );
  }

  Future<void> _deleteNoteUnlocked(String deckId, String noteId) async {
    final notes = await _loadLocalNotes(deckId);
    await _saveNotes(
      deckId,
      notes.where((note) => note.id != noteId).toList(growable: false),
    );
    final remoteClient = _remoteClient;
    if (remoteClient == null) return;

    await _removePendingUpsert(deckId, noteId);
    await _enqueueDelete(deckId, noteId);
    try {
      await remoteClient.deleteNote(deckId, noteId);
      await _removePendingDelete(deckId, noteId);
    } catch (_) {}
  }

  /// Number of local mutations that still need to reach the signed-in
  /// account. The UI can use this to distinguish "saved on this device" from
  /// fully synchronized data without exposing transport errors.
  Future<int> pendingOperationCount(String deckId) {
    return _serializeDeckOperation(
      deckId,
      () => _pendingOperationCountUnlocked(deckId),
    );
  }

  Future<int> _pendingOperationCountUnlocked(String deckId) async {
    final upserts = await _loadPendingUpserts(deckId);
    final deletes = await _loadPendingDeletes(deckId);
    return upserts.length + deletes.length;
  }

  Future<DeckEvolutionSummary> summarize(String deckId) async {
    final notes = await loadNotes(deckId);
    return DeckEvolutionSummary.fromNotes(notes);
  }

  Future<T> _serializeDeckOperation<T>(
    String deckId,
    Future<T> Function() operation,
  ) {
    final result = Completer<T>();
    final previous = _deckOperationTails[deckId] ?? Future<void>.value();
    final tail = previous.then<void>((_) async {
      try {
        result.complete(await operation());
      } catch (error, stackTrace) {
        result.completeError(error, stackTrace);
      }
    });
    _deckOperationTails[deckId] = tail;
    unawaited(
      tail.whenComplete(() {
        if (identical(_deckOperationTails[deckId], tail)) {
          _deckOperationTails.remove(deckId);
        }
      }),
    );
    return result.future;
  }

  Future<void> _saveNotes(String deckId, List<PostGameNote> notes) async {
    final prefs = await _preferencesLoader();
    final encoded = jsonEncode(notes.map((note) => note.toJson()).toList());
    await prefs.setString(_key(deckId), encoded);
  }

  Future<void> _flushPendingOperations(
    String deckId,
    PostGameNoteRemoteClient remoteClient,
  ) async {
    for (final noteId in await _loadPendingDeletes(deckId)) {
      try {
        await remoteClient.deleteNote(deckId, noteId);
        await _removePendingDelete(deckId, noteId);
      } catch (_) {
        // Keep the tombstone. It prevents a stale remote note from being
        // merged back into the local history and will be retried next load.
      }
    }

    for (final note in await _loadPendingUpserts(deckId)) {
      try {
        await remoteClient.upsertNote(note);
        await _removePendingUpsert(deckId, note.id);
      } catch (_) {
        // Keep the local mutation for the next automatic synchronization.
      }
    }
  }

  Future<List<PostGameNote>> _loadPendingUpserts(String deckId) async {
    final prefs = await _preferencesLoader();
    final raw = prefs.getString(_pendingUpsertsKey(deckId));
    if (raw == null || raw.trim().isEmpty) return const <PostGameNote>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const <PostGameNote>[];
      return decoded
          .whereType<Map>()
          .map((entry) => PostGameNote.fromJson(entry.cast()))
          .where((note) => note.deckId == deckId && note.id.isNotEmpty)
          .toList(growable: false);
    } catch (_) {
      return const <PostGameNote>[];
    }
  }

  Future<Set<String>> _loadPendingDeletes(String deckId) async {
    final prefs = await _preferencesLoader();
    return (prefs.getStringList(_pendingDeletesKey(deckId)) ?? const <String>[])
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet();
  }

  Future<void> _enqueueUpsert(PostGameNote note) async {
    final pending = await _loadPendingUpserts(note.deckId);
    final next = [note, ...pending.where((item) => item.id != note.id)];
    final prefs = await _preferencesLoader();
    await prefs.setString(
      _pendingUpsertsKey(note.deckId),
      jsonEncode(next.map((item) => item.toJson()).toList()),
    );
  }

  Future<void> _removePendingUpsert(String deckId, String noteId) async {
    final pending = await _loadPendingUpserts(deckId);
    final next = pending.where((note) => note.id != noteId).toList();
    final prefs = await _preferencesLoader();
    if (next.isEmpty) {
      await prefs.remove(_pendingUpsertsKey(deckId));
    } else {
      await prefs.setString(
        _pendingUpsertsKey(deckId),
        jsonEncode(next.map((note) => note.toJson()).toList()),
      );
    }
  }

  Future<void> _enqueueDelete(String deckId, String noteId) async {
    final pending = await _loadPendingDeletes(deckId)
      ..add(noteId);
    final prefs = await _preferencesLoader();
    await prefs.setStringList(_pendingDeletesKey(deckId), pending.toList());
  }

  Future<void> _removePendingDelete(String deckId, String noteId) async {
    final pending = await _loadPendingDeletes(deckId)
      ..remove(noteId);
    final prefs = await _preferencesLoader();
    if (pending.isEmpty) {
      await prefs.remove(_pendingDeletesKey(deckId));
    } else {
      await prefs.setStringList(_pendingDeletesKey(deckId), pending.toList());
    }
  }

  static String _key(String deckId) => 'manaloom.post_game_notes.$deckId';
  static String _pendingUpsertsKey(String deckId) =>
      'manaloom.post_game_notes.pending_upserts.$deckId';
  static String _pendingDeletesKey(String deckId) =>
      'manaloom.post_game_notes.pending_deletes.$deckId';

  static List<PostGameNote> _mergeNotes(
    List<PostGameNote> primary,
    List<PostGameNote> secondary,
  ) {
    final byId = <String, PostGameNote>{
      for (final note in secondary) note.id: note,
    };
    for (final note in primary) {
      final local = byId[note.id];
      byId[note.id] =
          local == null ? note : _preserveLocalSessionMetadata(note, local);
    }
    final merged =
        byId.values.toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return merged;
  }

  static PostGameNote _preserveLocalSessionMetadata(
    PostGameNote remote,
    PostGameNote local,
  ) {
    final playSessionId = remote.playSessionId ?? local.playSessionId;
    final sessionStartedAt = remote.sessionStartedAt ?? local.sessionStartedAt;
    final sessionEndedAt = remote.sessionEndedAt ?? local.sessionEndedAt;
    if (playSessionId == remote.playSessionId &&
        sessionStartedAt == remote.sessionStartedAt &&
        sessionEndedAt == remote.sessionEndedAt) {
      return remote;
    }
    return PostGameNote(
      id: remote.id,
      deckId: remote.deckId,
      createdAt: remote.createdAt,
      result: remote.result,
      tableLevel: remote.tableLevel,
      notes: remote.notes,
      performedWell: remote.performedWell,
      underperformed: remote.underperformed,
      issues: remote.issues,
      playSessionId: playSessionId,
      sessionStartedAt: sessionStartedAt,
      sessionEndedAt: sessionEndedAt,
    );
  }
}
