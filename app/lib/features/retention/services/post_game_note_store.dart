import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/api/api_client.dart';
import '../models/post_game_note.dart';

typedef PostGamePreferencesLoader = Future<SharedPreferences> Function();

abstract class PostGameNoteRemoteClient {
  Future<List<PostGameNote>> loadNotes(String deckId);
  Future<void> upsertNote(PostGameNote note);
  Future<void> deleteNote(String deckId, String noteId);
}

class ApiPostGameNoteRemoteClient implements PostGameNoteRemoteClient {
  ApiPostGameNoteRemoteClient({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  @override
  Future<List<PostGameNote>> loadNotes(String deckId) async {
    final response = await _apiClient.get(
      '/decks/${Uri.encodeComponent(deckId)}/post-game-notes',
    );
    if (response.statusCode != 200 || response.data is! Map<String, dynamic>) {
      throw StateError('Falha ao carregar pos-jogo remoto.');
    }
    final payload = response.data as Map<String, dynamic>;
    final data = payload['data'];
    if (data is! List) return const <PostGameNote>[];
    final notes =
        data
            .whereType<Map>()
            .map((entry) => PostGameNote.fromJson(entry.cast()))
            .where((note) => note.deckId == deckId)
            .toList();
    notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return notes;
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

  Future<List<PostGameNote>> loadNotes(String deckId) async {
    final localNotes = await _loadLocalNotes(deckId);
    final remoteClient = _remoteClient;
    if (remoteClient == null) return localNotes;

    try {
      final remoteNotes = await remoteClient.loadNotes(deckId);
      final merged = _mergeNotes(remoteNotes, localNotes);
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

  Future<void> addNote(PostGameNote note) async {
    final notes = await _loadLocalNotes(note.deckId);
    final next = [note, ...notes.where((item) => item.id != note.id)];
    await _saveNotes(note.deckId, next);
    try {
      await _remoteClient?.upsertNote(note);
    } catch (_) {}
  }

  Future<void> deleteNote(String deckId, String noteId) async {
    final notes = await _loadLocalNotes(deckId);
    await _saveNotes(
      deckId,
      notes.where((note) => note.id != noteId).toList(growable: false),
    );
    try {
      await _remoteClient?.deleteNote(deckId, noteId);
    } catch (_) {}
  }

  Future<DeckEvolutionSummary> summarize(String deckId) async {
    final notes = await loadNotes(deckId);
    return DeckEvolutionSummary.fromNotes(notes);
  }

  Future<void> _saveNotes(String deckId, List<PostGameNote> notes) async {
    final prefs = await _preferencesLoader();
    final encoded = jsonEncode(notes.map((note) => note.toJson()).toList());
    await prefs.setString(_key(deckId), encoded);
  }

  static String _key(String deckId) => 'manaloom.post_game_notes.$deckId';

  static List<PostGameNote> _mergeNotes(
    List<PostGameNote> primary,
    List<PostGameNote> secondary,
  ) {
    final byId = <String, PostGameNote>{
      for (final note in secondary) note.id: note,
      for (final note in primary) note.id: note,
    };
    final merged =
        byId.values.toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return merged;
  }
}
