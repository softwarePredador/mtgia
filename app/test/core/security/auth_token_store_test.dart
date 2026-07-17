import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/security/auth_token_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MemorySecureTokenBackend implements SecureTokenBackend {
  final values = <String, String>{};
  bool failReads = false;
  bool failWrites = false;
  bool failDeletes = false;

  @override
  Future<String?> read(String key) async {
    if (failReads) throw StateError('secure read unavailable');
    return values[key];
  }

  @override
  Future<void> write(String key, String value) async {
    if (failWrites) throw StateError('secure write unavailable');
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    if (failDeletes) throw StateError('secure delete unavailable');
    values.remove(key);
  }
}

void main() {
  group('AuthTokenStore', () {
    test(
      'migrates a legacy token only after confirming the secure write',
      () async {
        SharedPreferences.setMockInitialValues({
          AuthTokenStore.legacyPreferencesKey: ' legacy-token ',
        });
        final backend = _MemorySecureTokenBackend();
        final store = AuthTokenStore(secureBackend: backend);

        expect(await store.read(), 'legacy-token');

        final prefs = await SharedPreferences.getInstance();
        expect(
          backend.values[AuthTokenStore.secureKey],
          equals('legacy-token'),
        );
        expect(prefs.containsKey(AuthTokenStore.legacyPreferencesKey), isFalse);
      },
    );

    test(
      'keeps the legacy token when secure migration is unavailable',
      () async {
        SharedPreferences.setMockInitialValues({
          AuthTokenStore.legacyPreferencesKey: 'legacy-token',
        });
        final backend = _MemorySecureTokenBackend()..failWrites = true;
        final store = AuthTokenStore(secureBackend: backend);

        expect(await store.read(), 'legacy-token');

        final prefs = await SharedPreferences.getInstance();
        expect(
          prefs.getString(AuthTokenStore.legacyPreferencesKey),
          'legacy-token',
        );
      },
    );

    test(
      'new writes use only secure storage and clear the legacy token',
      () async {
        SharedPreferences.setMockInitialValues({
          AuthTokenStore.legacyPreferencesKey: 'stale-token',
        });
        final backend = _MemorySecureTokenBackend();
        final store = AuthTokenStore(secureBackend: backend);

        await store.write(' next-token ');

        final prefs = await SharedPreferences.getInstance();
        expect(backend.values[AuthTokenStore.secureKey], 'next-token');
        expect(prefs.containsKey(AuthTokenStore.legacyPreferencesKey), isFalse);
      },
    );

    test(
      'delete clears the legacy token even when secure deletion fails',
      () async {
        SharedPreferences.setMockInitialValues({
          AuthTokenStore.legacyPreferencesKey: 'legacy-token',
        });
        final backend = _MemorySecureTokenBackend()..failDeletes = true;
        final store = AuthTokenStore(secureBackend: backend);

        await expectLater(store.delete(), throwsStateError);

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.containsKey(AuthTokenStore.legacyPreferencesKey), isFalse);
      },
    );

    test('conditional cleanup never deletes a newer secure token', () async {
      SharedPreferences.setMockInitialValues({
        AuthTokenStore.legacyPreferencesKey: 'old-token',
      });
      final backend =
          _MemorySecureTokenBackend()
            ..values[AuthTokenStore.secureKey] = 'new-token';
      final store = AuthTokenStore(secureBackend: backend);

      await store.deleteIfMatches('old-token');

      final prefs = await SharedPreferences.getInstance();
      expect(backend.values[AuthTokenStore.secureKey], 'new-token');
      expect(prefs.containsKey(AuthTokenStore.legacyPreferencesKey), isFalse);
    });
  });
}
