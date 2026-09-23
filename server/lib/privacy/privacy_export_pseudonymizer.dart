import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// Chaves que nunca saem na exportação, em qualquer profundidade do JSON
/// (D-22: sem hashes, fingerprints nem chaves internas). Espelha
/// `export_policy.nested_forbidden_keys.exact` do inventário
/// (`docs/privacy/data_retention_inventory.json`).
const privacyExportForbiddenKeys = <String>{
  'access_token',
  'cache_key',
  'deck_signature',
  'fcm_token',
  'fingerprint',
  'idempotency_key',
  'jwt',
  'lease_owner',
  'lease_token',
  'password_hash',
  'refresh_token',
  'request_fingerprint',
  'request_key',
  'token_hash',
};

/// Sufixos proibidos em qualquer chave. Espelha
/// `export_policy.nested_forbidden_keys.suffixes` do inventário.
const privacyExportForbiddenKeySuffixes = <String>['_fingerprint', '_hash'];

bool isPrivacyExportForbiddenKey(String key) {
  final normalized = key.toLowerCase();
  return privacyExportForbiddenKeys.contains(normalized) ||
      privacyExportForbiddenKeySuffixes.any(normalized.endsWith);
}

final _uuidPattern = RegExp(
  r'[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-'
  r'[0-9a-fA-F]{12}',
);

/// Troca IDs de outras pessoas por pseudônimos (D-22).
///
/// O pseudônimo é HMAC-SHA256 com uma chave aleatória desta exportação: a
/// mesma pessoa ou deck de terceiro recebe o mesmo pseudônimo em todas as
/// seções do arquivo e outro na próxima exportação, sem como voltar ao ID.
class PrivacyExportPseudonymizer {
  PrivacyExportPseudonymizer({
    required String subjectUserId,
    Iterable<String> ownDeckIds = const [],
    Iterable<String> sharedEntityIds = const [],
    List<int>? key,
  }) : _subject = subjectUserId.toLowerCase(),
       _ownDecks = {for (final id in ownDeckIds) id.toLowerCase()},
       _shared = {for (final id in sharedEntityIds) id.toLowerCase()},
       _key = key ?? _randomKey();

  final String _subject;
  final Set<String> _ownDecks;
  final Set<String> _shared;
  final List<int> _key;
  final Map<String, String> _pseudonyms = {};

  /// IDs de terceiros já trocados, com o pseudônimo de cada um.
  Map<String, String> get replacements => Map.unmodifiable(_pseudonyms);

  /// UUID de pessoa: fica se for o titular.
  Object? person(Object? value) =>
      _apply(value, 'pessoa', (id) => id == _subject);

  /// UUID de deck: fica se o deck for do titular.
  Object? deck(Object? value) => _apply(value, 'deck', _ownDecks.contains);

  /// Referência genérica: fica se for do titular ou de uma troca ou conversa
  /// de que ele participa.
  Object? entity(Object? value) => _apply(
    value,
    'ref',
    (id) => id == _subject || _ownDecks.contains(id) || _shared.contains(id),
  );

  /// Limpa um valor JSON em qualquer profundidade: tira as chaves proibidas e
  /// troca, dentro de textos, todo ID de terceiro já pseudonimizado.
  Object? scrub(Object? value) {
    if (value is Map) {
      return <String, dynamic>{
        for (final MapEntry(key: entryKey, value: entryValue) in value.entries)
          if (!isPrivacyExportForbiddenKey(entryKey.toString()))
            entryKey.toString(): scrub(entryValue),
      };
    }
    if (value is List) return [for (final item in value) scrub(item)];
    if (value is String && _pseudonyms.isNotEmpty) {
      return value.replaceAllMapped(
        _uuidPattern,
        (match) => _pseudonyms[match[0]!.toLowerCase()] ?? match[0]!,
      );
    }
    return value;
  }

  Object? _apply(Object? value, String kind, bool Function(String id) isOwn) {
    if (value == null) return null;
    final raw = value.toString();
    final normalized = raw.toLowerCase();
    if (isOwn(normalized)) return raw;
    return _pseudonyms.putIfAbsent(
      normalized,
      () => _pseudonym(kind, normalized),
    );
  }

  String _pseudonym(String kind, String id) {
    final digest = Hmac(sha256, _key).convert(utf8.encode('$kind:$id'));
    return '$kind-${digest.toString().substring(0, 16)}';
  }

  static List<int> _randomKey() {
    final random = Random.secure();
    return List<int>.generate(32, (_) => random.nextInt(256));
  }
}
