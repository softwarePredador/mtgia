import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/api/api_client.dart';
import '../../home/life_counter/life_counter_account_scope.dart';
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

/// A non-2xx answer the server gave to a post-game write (LC-P0-06). Transport
/// failures are thrown as other errors and keep the outbox entry.
class PostGameRemoteRejection implements Exception {
  const PostGameRemoteRejection({
    required this.statusCode,
    this.error,
    this.errorCode,
    this.message,
    this.currentNote,
  });

  factory PostGameRemoteRejection.fromResponse(ApiResponse response) {
    final body = response.data;
    final json = body is Map ? body.cast<String, dynamic>() : null;
    final currentNote = json?['current_note'];
    return PostGameRemoteRejection(
      statusCode: response.statusCode,
      error: _text(json?['error']),
      errorCode: _text(json?['error_code']),
      message: _text(json?['message']),
      currentNote: currentNote is Map
          ? PostGameNote.fromJson(currentNote.cast<String, dynamic>())
          : null,
    );
  }

  /// Legacy 404 phrase of a note the server never had, from before
  /// `error_code` (server/lib/retention/post_game_error_contract.dart).
  static const legacyNoteNotFoundPhrase = 'Nota pos-jogo nao encontrada.';

  final int statusCode;
  final String? error;
  final String? errorCode;
  final String? message;
  final PostGameNote? currentNote;

  bool get isCapabilityUnavailable => error == 'capability_unavailable';

  /// The server never had this note: deleting it there is already done.
  bool get isNoteNotFound =>
      statusCode == 404 &&
      (errorCode == 'post_game_note_not_found' ||
          (errorCode == null && error == legacyNoteNotFoundPhrase));

  bool get isNoteDeleted =>
      statusCode == 409 && errorCode == 'post_game_note_deleted';

  /// Another note of the same match already exists in this deck. Older
  /// servers sent no `error_code` and no `current_note` for this case.
  bool get isPlaySessionConflict =>
      statusCode == 409 &&
      (errorCode == 'post_game_play_session_conflict' ||
          (errorCode == null && currentNote == null));

  /// The server will refuse this same request again: retrying is pointless.
  /// Session (401), capability gate, throttling and 5xx stay retryable.
  bool get isDefinitive {
    if (isCapabilityUnavailable) return false;
    return statusCode == 400 ||
        statusCode == 404 ||
        statusCode == 409 ||
        statusCode == 413 ||
        statusCode == 422;
  }

  /// Portuguese sentence for the person, from the server when it sent one.
  String get userMessage {
    if (isPlaySessionConflict) {
      return message ??
          'Esta partida já tem um pós-jogo registrado. Para trocar o '
              'registro, apague o anterior e salve de novo.';
    }
    if (isNoteDeleted) {
      return message ??
          'Esta nota foi excluída em outro dispositivo. Atualize o '
              'histórico antes de salvar de novo.';
    }
    final serverText =
        message ?? (error != null && error!.contains(' ') ? error : null);
    return serverText ??
        'Sua conta recusou este pós-jogo. Revise o registro e tente de novo.';
  }

  static String? _text(Object? value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  @override
  String toString() =>
      'PostGameRemoteRejection($statusCode, ${errorCode ?? error})';
}

/// Thrown by [PostGameNoteStore.addNote] when the account refused the note for
/// good. The note is not kept on the device, so the form still owns the data.
class PostGameNoteRejectedException implements Exception {
  const PostGameNoteRejectedException(this.rejection);

  final PostGameRemoteRejection rejection;

  String get userMessage => rejection.userMessage;

  @override
  String toString() => 'PostGameNoteRejectedException($rejection)';
}

/// A queued note the account refused while syncing in the background.
class PostGameSyncRejection {
  const PostGameSyncRejection({
    required this.noteId,
    required this.statusCode,
    required this.message,
    this.errorCode,
  });

  final String noteId;
  final int statusCode;
  final String? errorCode;
  final String message;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'note_id': noteId,
    'status_code': statusCode,
    'error_code': errorCode,
    'message': message,
  };

  static PostGameSyncRejection? fromJson(Object? json) {
    if (json is! Map) return null;
    final noteId = json['note_id']?.toString() ?? '';
    final message = json['message']?.toString() ?? '';
    final statusCode = json['status_code'];
    if (noteId.isEmpty || message.isEmpty || statusCode is! int) return null;
    return PostGameSyncRejection(
      noteId: noteId,
      statusCode: statusCode,
      errorCode: json['error_code']?.toString(),
      message: message,
    );
  }
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
      throw PostGameRemoteRejection.fromResponse(response);
    }
  }

  @override
  Future<void> deleteNote(String deckId, String noteId) async {
    final response = await _apiClient.delete(
      '/decks/${Uri.encodeComponent(deckId)}/post-game-notes/${Uri.encodeComponent(noteId)}',
    );
    // A 404 is not success: it is also the capability gate and a deck of
    // another account. The store decides from the body (LC-P0-06, A3).
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw PostGameRemoteRejection.fromResponse(response);
    }
  }
}

class PostGameNoteStore {
  PostGameNoteStore({
    PostGamePreferencesLoader? preferencesLoader,
    PostGameNoteRemoteClient? remoteClient,
    LifeCounterStorageNamespace? namespace,
  }) : _binding = LifeCounterStorageBinding.resolve(
         // Keys are per deck; the binding only supplies the account prefix.
         baseKey: 'post_game_notes',
         namespace: namespace,
         preferencesLoader: preferencesLoader,
       ),
       _remoteClient = remoteClient;

  /// Notes and outbox live in the signed-in account's namespace (LC-P0-01),
  /// so another account on this device never reads or flushes them.
  final LifeCounterStorageBinding _binding;
  final PostGameNoteRemoteClient? _remoteClient;
  static final Map<String, Future<void>> _deckOperationTails =
      <String, Future<void>>{};

  Future<List<PostGameNote>> loadNotes(String deckId) {
    return _serializeDeckOperation(deckId, () => _loadNotesUnlocked(deckId));
  }

  Future<List<PostGameNote>> _loadNotesUnlocked(String deckId) async {
    var localNotes = await _loadLocalNotes(deckId);
    final remoteClient = _remoteClient;
    if (remoteClient == null) return localNotes;

    try {
      await _flushPendingOperations(deckId, remoteClient);
      // The flush may have dropped notes the account refused for good.
      localNotes = await _loadLocalNotes(deckId);
      final remotePage = await remoteClient.loadNotes(deckId);
      for (final deletedId in remotePage.deletedNoteIds) {
        await _removePendingUpsert(deckId, deletedId);
      }
      final pendingUpserts = await _loadPendingUpserts(deckId);
      final pendingDeletes = await _loadPendingDeletes(deckId);
      final mergedById =
          <String, PostGameNote>{
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
      final merged = mergedById.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      await _saveNotes(deckId, merged);
      return merged;
    } catch (_) {
      return localNotes;
    }
  }

  Future<List<PostGameNote>> _loadLocalNotes(String deckId) async {
    final prefs = await _binding.preferences();
    final raw = prefs.getString(_key(deckId));
    if (raw == null || raw.trim().isEmpty) return const <PostGameNote>[];
    final dynamic decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (_) {
      return const <PostGameNote>[];
    }
    if (decoded is! List) return const <PostGameNote>[];
    final notes = decoded
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
    } on PostGameRemoteRejection catch (rejection) {
      if (!rejection.isDefinitive) return;
      // The account refused this note for good (LC-P0-06, A1): undo the local
      // save so it is not retried forever, and let the screen say why.
      await _removePendingUpsert(note.deckId, note.id);
      await _saveNotes(note.deckId, notes);
      throw PostGameNoteRejectedException(rejection);
    } catch (_) {
      // Offline or a retryable answer: the outbox keeps the note.
    }
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
    await _tryRemoteDelete(deckId, noteId, remoteClient);
  }

  /// Sends one queued delete. The tombstone goes away only when the server
  /// confirms the note is gone: 204, a note it never had, or a note already
  /// deleted elsewhere. Any other 404 (capability gate, deck of another
  /// account) keeps it, so the note can't come back on the next load (A3).
  Future<void> _tryRemoteDelete(
    String deckId,
    String noteId,
    PostGameNoteRemoteClient remoteClient,
  ) async {
    try {
      await remoteClient.deleteNote(deckId, noteId);
    } on PostGameRemoteRejection catch (rejection) {
      if (!rejection.isNoteNotFound && !rejection.isNoteDeleted) return;
    } catch (_) {
      return;
    }
    await _removePendingDelete(deckId, noteId);
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
    final tailKey = _key(deckId);
    final previous = _deckOperationTails[tailKey] ?? Future<void>.value();
    final tail = previous.then<void>((_) async {
      try {
        result.complete(await operation());
      } catch (error, stackTrace) {
        result.completeError(error, stackTrace);
      }
    });
    _deckOperationTails[tailKey] = tail;
    unawaited(
      tail.whenComplete(() {
        if (identical(_deckOperationTails[tailKey], tail)) {
          _deckOperationTails.remove(tailKey);
        }
      }),
    );
    return result.future;
  }

  Future<void> _saveNotes(String deckId, List<PostGameNote> notes) async {
    final prefs = await _binding.preferences();
    final encoded = jsonEncode(notes.map((note) => note.toJson()).toList());
    await prefs.setString(_key(deckId), encoded);
  }

  Future<void> _flushPendingOperations(
    String deckId,
    PostGameNoteRemoteClient remoteClient,
  ) async {
    // A kept tombstone prevents a stale remote note from being merged back
    // into the local history and is retried on the next load.
    for (final noteId in await _loadPendingDeletes(deckId)) {
      await _tryRemoteDelete(deckId, noteId, remoteClient);
    }

    for (final note in await _loadPendingUpserts(deckId)) {
      try {
        await remoteClient.upsertNote(note);
        await _removePendingUpsert(deckId, note.id);
      } on PostGameRemoteRejection catch (rejection) {
        if (!rejection.isDefinitive) continue;
        // Refused for good while offline-queued: stop retrying, drop the
        // local copy and keep the reason for the screen to show once.
        await _removePendingUpsert(deckId, note.id);
        final notes = await _loadLocalNotes(deckId);
        await _saveNotes(
          deckId,
          notes.where((item) => item.id != note.id).toList(growable: false),
        );
        await _recordRejection(
          deckId,
          PostGameSyncRejection(
            noteId: note.id,
            statusCode: rejection.statusCode,
            errorCode: rejection.errorCode,
            message: rejection.userMessage,
          ),
        );
      } catch (_) {
        // Keep the local mutation for the next automatic synchronization.
      }
    }
  }

  Future<void> _recordRejection(
    String deckId,
    PostGameSyncRejection rejection,
  ) async {
    final current = await _loadRejections(deckId);
    final next = [
      ...current.where((item) => item.noteId != rejection.noteId),
      rejection,
    ];
    final prefs = await _binding.preferences();
    await prefs.setString(
      _rejectionsKey(deckId),
      jsonEncode(next.map((item) => item.toJson()).toList()),
    );
  }

  Future<List<PostGameSyncRejection>> _loadRejections(String deckId) async {
    final prefs = await _binding.preferences();
    final raw = prefs.getString(_rejectionsKey(deckId));
    if (raw == null || raw.trim().isEmpty) {
      return const <PostGameSyncRejection>[];
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const <PostGameSyncRejection>[];
      return decoded
          .map(PostGameSyncRejection.fromJson)
          .whereType<PostGameSyncRejection>()
          .toList(growable: false);
    } catch (_) {
      return const <PostGameSyncRejection>[];
    }
  }

  /// Returns, and forgets, the queued notes the account refused while
  /// syncing in the background, so the screen can say so once.
  Future<List<PostGameSyncRejection>> takeSyncRejections(String deckId) {
    return _serializeDeckOperation(deckId, () async {
      final rejections = await _loadRejections(deckId);
      if (rejections.isNotEmpty) {
        final prefs = await _binding.preferences();
        await prefs.remove(_rejectionsKey(deckId));
      }
      return rejections;
    });
  }

  Future<List<PostGameNote>> _loadPendingUpserts(String deckId) async {
    final prefs = await _binding.preferences();
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
    final prefs = await _binding.preferences();
    return (prefs.getStringList(_pendingDeletesKey(deckId)) ?? const <String>[])
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet();
  }

  Future<void> _enqueueUpsert(PostGameNote note) async {
    final pending = await _loadPendingUpserts(note.deckId);
    final next = [note, ...pending.where((item) => item.id != note.id)];
    final prefs = await _binding.preferences();
    await prefs.setString(
      _pendingUpsertsKey(note.deckId),
      jsonEncode(next.map((item) => item.toJson()).toList()),
    );
  }

  Future<void> _removePendingUpsert(String deckId, String noteId) async {
    final pending = await _loadPendingUpserts(deckId);
    final next = pending.where((note) => note.id != noteId).toList();
    final prefs = await _binding.preferences();
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
    final prefs = await _binding.preferences();
    await prefs.setStringList(_pendingDeletesKey(deckId), pending.toList());
  }

  Future<void> _removePendingDelete(String deckId, String noteId) async {
    final pending = await _loadPendingDeletes(deckId)
      ..remove(noteId);
    final prefs = await _binding.preferences();
    if (pending.isEmpty) {
      await prefs.remove(_pendingDeletesKey(deckId));
    } else {
      await prefs.setStringList(_pendingDeletesKey(deckId), pending.toList());
    }
  }

  String _key(String deckId) =>
      _binding.namespace.keyFor('post_game_notes.$deckId');
  String _pendingUpsertsKey(String deckId) =>
      _binding.namespace.keyFor('post_game_notes.pending_upserts.$deckId');
  String _pendingDeletesKey(String deckId) =>
      _binding.namespace.keyFor('post_game_notes.pending_deletes.$deckId');
  String _rejectionsKey(String deckId) =>
      _binding.namespace.keyFor('post_game_notes.rejections.$deckId');

  static List<PostGameNote> _mergeNotes(
    List<PostGameNote> primary,
    List<PostGameNote> secondary,
  ) {
    final byId = <String, PostGameNote>{
      for (final note in secondary) note.id: note,
    };
    for (final note in primary) {
      final local = byId[note.id];
      byId[note.id] = local == null
          ? note
          : _preserveLocalSessionMetadata(note, local);
    }
    final merged = byId.values.toList()
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
    final deckSnapshotHash = remote.deckSnapshotHash ?? local.deckSnapshotHash;
    final deckVersionAt = remote.deckVersionAt ?? local.deckVersionAt;
    return PostGameNote(
      id: remote.id,
      deckId: remote.deckId,
      createdAt: remote.createdAt,
      result: remote.result,
      tableLevel: remote.tableLevel,
      notes: remote.notes,
      performedWellEvidence: _mergeCardEvidence(
        remote.performedWellEvidence,
        local.performedWellEvidence,
      ),
      underperformedEvidence: _mergeCardEvidence(
        remote.underperformedEvidence,
        local.underperformedEvidence,
      ),
      issues: remote.issues,
      playSessionId: playSessionId,
      sessionStartedAt: sessionStartedAt,
      sessionEndedAt: sessionEndedAt,
      deckSnapshotHash: deckSnapshotHash,
      deckVersionAt: deckVersionAt,
      revision: remote.revision,
    );
  }

  static List<PostGameCardEvidence> _mergeCardEvidence(
    List<PostGameCardEvidence> remote,
    List<PostGameCardEvidence> local,
  ) {
    final localByKey = <String, PostGameCardEvidence>{
      for (final card in local) _cardEvidenceKey(card): card,
    };
    return remote
        .map((card) {
          final localCard = localByKey[_cardEvidenceKey(card)];
          if (localCard == null || card.imageUrl?.trim().isNotEmpty == true) {
            return card;
          }
          return PostGameCardEvidence(
            name: card.name,
            cardId: card.cardId ?? localCard.cardId,
            imageUrl: localCard.imageUrl,
            setCode: card.setCode ?? localCard.setCode,
            collectorNumber: card.collectorNumber ?? localCard.collectorNumber,
            quantity: card.quantity,
            isCommander: card.isCommander || localCard.isCommander,
          );
        })
        .toList(growable: false);
  }

  static String _cardEvidenceKey(PostGameCardEvidence card) {
    final id = card.cardId?.trim().toLowerCase();
    return id == null || id.isEmpty
        ? 'name:${card.name.trim().toLowerCase()}'
        : 'id:$id';
  }
}
