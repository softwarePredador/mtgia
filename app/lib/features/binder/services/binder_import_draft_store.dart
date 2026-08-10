import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/binder_import_models.dart';

class BinderImportDraft {
  const BinderImportDraft({
    required this.sourceText,
    required this.candidates,
    required this.updatedAt,
  });

  final String sourceText;
  final List<BinderImportCandidate> candidates;
  final DateTime updatedAt;
}

class BinderImportDraftStore {
  static const _draftPrefix = 'manaloom.binder_import_draft.v1';
  static const _historyPrefix = 'manaloom.binder_import_history.v1';
  static const historyLimit = 10;

  Future<BinderImportDraft?> loadDraft(String ownerId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(_draftPrefix, ownerId));
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final map = decoded.cast<String, dynamic>();
      return BinderImportDraft(
        sourceText: map['source_text']?.toString() ?? '',
        candidates: (map['candidates'] as List? ?? const [])
            .whereType<Map>()
            .map(
              (candidate) => BinderImportCandidate.fromJson(
                candidate.cast<String, dynamic>(),
              ),
            )
            .toList(growable: false),
        updatedAt:
            DateTime.tryParse(map['updated_at']?.toString() ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      );
    } on FormatException {
      await prefs.remove(_key(_draftPrefix, ownerId));
      return null;
    }
  }

  Future<void> saveDraft(
    String ownerId, {
    required String sourceText,
    required List<BinderImportCandidate> candidates,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key(_draftPrefix, ownerId),
      jsonEncode({
        'source_text': sourceText,
        'candidates': candidates
            .map((candidate) => candidate.toJson())
            .toList(growable: false),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }),
    );
  }

  Future<void> clearDraft(String ownerId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(_draftPrefix, ownerId));
  }

  Future<List<BinderImportBatchHistory>> loadHistory(String ownerId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(_historyPrefix, ownerId));
    if (raw == null || raw.trim().isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map(
            (entry) => BinderImportBatchHistory.fromJson(
              entry.cast<String, dynamic>(),
            ),
          )
          .take(historyLimit)
          .toList(growable: false);
    } on FormatException {
      await prefs.remove(_key(_historyPrefix, ownerId));
      return const [];
    }
  }

  Future<void> addHistory(
    String ownerId,
    BinderImportBatchHistory entry,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await loadHistory(ownerId);
    final next = <BinderImportBatchHistory>[
      entry,
      ...current.where((item) => item.batchId != entry.batchId),
    ].take(historyLimit).toList(growable: false);
    await prefs.setString(
      _key(_historyPrefix, ownerId),
      jsonEncode(next.map((item) => item.toJson()).toList(growable: false)),
    );
  }

  String _key(String prefix, String ownerId) {
    final normalized = ownerId.trim().isEmpty ? 'anonymous' : ownerId.trim();
    return '$prefix.${Uri.encodeComponent(normalized)}';
  }
}
