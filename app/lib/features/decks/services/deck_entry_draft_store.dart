import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class DeckEntryDraftStore {
  static const _generatePrefix = 'manaloom.deck_generate_draft.v1';
  static const _importPrefix = 'manaloom.deck_import_draft.v1';
  static const _editDescriptionPrefix =
      'manaloom.deck_edit_description_draft.v1';

  Future<Map<String, String>?> loadGenerate(String ownerId) =>
      _load(_key(_generatePrefix, ownerId));

  Future<void> saveGenerate(
    String ownerId, {
    required String format,
    required String commander,
    required String prompt,
    required String deckName,
    String? activeJobId,
    String? requestKey,
    bool preferCollection = false,
    bool collectionOnly = false,
    String budgetLimitBrl = '',
  }) => _save(_key(_generatePrefix, ownerId), {
    'format': format,
    'commander': commander,
    'prompt': prompt,
    'deck_name': deckName,
    'prefer_collection': preferCollection.toString(),
    'collection_only': collectionOnly.toString(),
    if (budgetLimitBrl.trim().isNotEmpty)
      'budget_limit_brl': budgetLimitBrl.trim(),
    if (activeJobId != null && activeJobId.trim().isNotEmpty)
      'active_job_id': activeJobId.trim(),
    if (requestKey != null && requestKey.trim().isNotEmpty)
      'request_key': requestKey.trim(),
  });

  Future<void> clearGenerate(String ownerId) =>
      _clear(_key(_generatePrefix, ownerId));

  Future<Map<String, String>?> loadImport(String ownerId) =>
      _load(_key(_importPrefix, ownerId));

  Future<void> saveImport(
    String ownerId, {
    required String format,
    required String name,
    required String description,
    required String commander,
    required String cardList,
  }) => _save(_key(_importPrefix, ownerId), {
    'format': format,
    'name': name,
    'description': description,
    'commander': commander,
    'card_list': cardList,
  });

  Future<void> clearImport(String ownerId) =>
      _clear(_key(_importPrefix, ownerId));

  Future<String?> loadEditDescription(String ownerId, String deckId) async {
    final draft = await _load(
      _resourceKey(_editDescriptionPrefix, ownerId, deckId),
    );
    return draft?['description'];
  }

  Future<void> saveEditDescription(
    String ownerId,
    String deckId,
    String description,
  ) => _save(
    _resourceKey(_editDescriptionPrefix, ownerId, deckId),
    <String, String>{'description': description},
  );

  Future<void> clearEditDescription(String ownerId, String deckId) =>
      _clear(_resourceKey(_editDescriptionPrefix, ownerId, deckId));

  String _key(String prefix, String ownerId) {
    final normalizedOwner = ownerId.trim().isEmpty
        ? 'anonymous'
        : ownerId.trim();
    return '$prefix.${Uri.encodeComponent(normalizedOwner)}';
  }

  String _resourceKey(String prefix, String ownerId, String resourceId) {
    return '${_key(prefix, ownerId)}.${Uri.encodeComponent(resourceId.trim())}';
  }

  Future<Map<String, String>?> _load(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return decoded.map(
        (field, value) => MapEntry(field.toString(), value?.toString() ?? ''),
      );
    } on FormatException {
      await prefs.remove(key);
      return null;
    }
  }

  Future<void> _save(String key, Map<String, String> fields) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(fields));
  }

  Future<void> _clear(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }
}
