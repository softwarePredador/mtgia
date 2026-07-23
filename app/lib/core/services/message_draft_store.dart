import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

typedef MessageDraftPreferencesLoader = Future<SharedPreferences> Function();

class MessageDraft {
  const MessageDraft({required this.text, this.clientRequestId});

  final String text;
  final String? clientRequestId;

  bool get isEmpty => text.isEmpty;
}

class MessageDraftStore {
  MessageDraftStore({MessageDraftPreferencesLoader? preferencesLoader})
    : _preferencesLoader = preferencesLoader ?? SharedPreferences.getInstance;

  static const _keyPrefix = 'manaloom.social_message_draft.v1.';
  final MessageDraftPreferencesLoader _preferencesLoader;

  Future<MessageDraft> load(String channelKey) async {
    final preferences = await _preferencesLoader();
    final encoded = preferences.getString(_key(channelKey));
    if (encoded == null || encoded.isEmpty) {
      return const MessageDraft(text: '');
    }
    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! Map) return const MessageDraft(text: '');
      return MessageDraft(
        text: decoded['text']?.toString() ?? '',
        clientRequestId:
            decoded['client_request_id']?.toString().trim().isEmpty == false
            ? decoded['client_request_id'].toString().trim()
            : null,
      );
    } catch (_) {
      await preferences.remove(_key(channelKey));
      return const MessageDraft(text: '');
    }
  }

  Future<void> save(String channelKey, MessageDraft draft) async {
    final preferences = await _preferencesLoader();
    if (draft.isEmpty) {
      await preferences.remove(_key(channelKey));
      return;
    }
    await preferences.setString(
      _key(channelKey),
      jsonEncode({
        'text': draft.text,
        if (draft.clientRequestId != null)
          'client_request_id': draft.clientRequestId,
      }),
    );
  }

  Future<void> clear(String channelKey) async {
    final preferences = await _preferencesLoader();
    await preferences.remove(_key(channelKey));
  }

  String _key(String channelKey) {
    final encoded = base64Url.encode(utf8.encode(channelKey));
    return '$_keyPrefix$encoded';
  }
}
