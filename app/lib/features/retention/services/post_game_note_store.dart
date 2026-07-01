import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/post_game_note.dart';

typedef PostGamePreferencesLoader = Future<SharedPreferences> Function();

class PostGameNoteStore {
  PostGameNoteStore({PostGamePreferencesLoader? preferencesLoader})
    : _preferencesLoader = preferencesLoader ?? SharedPreferences.getInstance;

  final PostGamePreferencesLoader _preferencesLoader;

  Future<List<PostGameNote>> loadNotes(String deckId) async {
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
    final notes = await loadNotes(note.deckId);
    final next = [note, ...notes.where((item) => item.id != note.id)];
    await _saveNotes(note.deckId, next);
  }

  Future<void> deleteNote(String deckId, String noteId) async {
    final notes = await loadNotes(deckId);
    await _saveNotes(
      deckId,
      notes.where((note) => note.id != noteId).toList(growable: false),
    );
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
}
