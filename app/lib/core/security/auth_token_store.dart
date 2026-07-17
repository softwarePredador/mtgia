import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef AuthPreferencesLoader = Future<SharedPreferences> Function();

/// Backend mínimo para manter o contrato testável sem acoplar autenticação ao
/// MethodChannel do armazenamento seguro.
abstract interface class SecureTokenBackend {
  Future<String?> read(String key);

  Future<void> write(String key, String value);

  Future<void> delete(String key);
}

class FlutterSecureTokenBackend implements SecureTokenBackend {
  const FlutterSecureTokenBackend({FlutterSecureStorage? storage})
    : _storage = storage ?? _defaultStorage;

  static const FlutterSecureStorage _defaultStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      storageNamespace: 'manaloom_auth',
      migrateWithBackup: true,
    ),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.unlocked),
    webOptions: WebOptions(
      dbName: 'ManaLoomAuth',
      publicKey: 'ManaLoomAuthPublicKey',
    ),
  );

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

/// Fonte canônica do bearer token.
///
/// Android usa Keystore + AES-GCM, Apple usa Keychain e web usa a implementação
/// WebCrypto do plugin no mesmo origin HTTPS/localhost. A migração lê a chave
/// histórica de SharedPreferences uma única vez, confirma a gravação segura e
/// só então remove o valor legado. Novos tokens nunca são gravados em texto
/// simples.
class AuthTokenStore {
  AuthTokenStore({
    SecureTokenBackend? secureBackend,
    AuthPreferencesLoader? preferencesLoader,
  }) : _secureBackend = secureBackend ?? const FlutterSecureTokenBackend(),
       _preferencesLoader = preferencesLoader ?? SharedPreferences.getInstance;

  static const secureKey = 'manaloom.auth.token.v1';
  static const legacyPreferencesKey = 'auth_token';

  final SecureTokenBackend _secureBackend;
  final AuthPreferencesLoader _preferencesLoader;
  Future<void> _tail = Future<void>.value();

  Future<String?> read() => _synchronized(_readAndMigrate);

  Future<void> write(String token) => _synchronized(() async {
    final normalized = token.trim();
    if (normalized.isEmpty) {
      throw ArgumentError.value(token, 'token', 'não pode ser vazio');
    }

    await _secureBackend.write(secureKey, normalized);
    final persisted = await _secureBackend.read(secureKey);
    if (persisted != normalized) {
      throw StateError('O token não foi confirmado no armazenamento seguro.');
    }

    final prefs = await _preferencesLoader();
    await prefs.remove(legacyPreferencesKey);
  });

  Future<void> delete() => _synchronized(() async {
    Object? secureError;
    StackTrace? secureStackTrace;
    try {
      await _secureBackend.delete(secureKey);
    } catch (error, stackTrace) {
      secureError = error;
      secureStackTrace = stackTrace;
    }

    final prefs = await _preferencesLoader();
    await prefs.remove(legacyPreferencesKey);
    if (secureError != null) {
      Error.throwWithStackTrace(secureError, secureStackTrace!);
    }
  });

  Future<void> deleteIfMatches(String expectedToken) => _synchronized(() async {
    Object? secureError;
    StackTrace? secureStackTrace;
    try {
      final secureToken = await _secureBackend.read(secureKey);
      if (secureToken == expectedToken) {
        await _secureBackend.delete(secureKey);
      }
    } catch (error, stackTrace) {
      secureError = error;
      secureStackTrace = stackTrace;
    }

    final prefs = await _preferencesLoader();
    if (prefs.getString(legacyPreferencesKey) == expectedToken) {
      await prefs.remove(legacyPreferencesKey);
    }
    if (secureError != null) {
      Error.throwWithStackTrace(secureError, secureStackTrace!);
    }
  });

  Future<String?> _readAndMigrate() async {
    final secureToken = await _secureBackend.read(secureKey);
    if (secureToken?.trim().isNotEmpty == true) {
      return secureToken!.trim();
    }

    final prefs = await _preferencesLoader();
    final legacyToken = prefs.getString(legacyPreferencesKey)?.trim();
    if (legacyToken == null || legacyToken.isEmpty) return null;

    try {
      await _secureBackend.write(secureKey, legacyToken);
      final migrated = await _secureBackend.read(secureKey);
      if (migrated == legacyToken) {
        await prefs.remove(legacyPreferencesKey);
      }
    } catch (_) {
      // Compatibilidade de atualização: preserve o login existente e tente a
      // migração novamente no próximo boot. Nenhuma nova gravação usa o legado.
    }
    return legacyToken;
  }

  Future<T> _synchronized<T>(Future<T> Function() operation) {
    final completer = Completer<T>();
    _tail = _tail.then((_) async {
      try {
        completer.complete(await operation());
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    return completer.future;
  }
}
