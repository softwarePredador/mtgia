import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/api/api_client.dart';
import 'package:manaloom/core/security/auth_token_store.dart';
import 'package:manaloom/features/auth/providers/auth_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MemoryTokenBackend implements SecureTokenBackend {
  String? value;

  @override
  Future<void> delete(String key) async => value = null;

  @override
  Future<String?> read(String key) async => value;

  @override
  Future<void> write(String key, String value) async => this.value = value;
}

class _SecurityProviderApi extends ApiClient {
  ApiResponse securityResponse = ApiResponse(200, {
    'token': 'rotated-token',
    'user': {
      'id': 'user-1',
      'username': 'player',
      'email': 'player@example.com',
    },
  });
  String? securityEndpoint;
  Map<String, dynamic>? securityBody;

  @override
  Future<ApiResponse> post(
    String endpoint,
    Map<String, dynamic> body, {
    Duration? timeout,
  }) async {
    if (endpoint == '/auth/login') {
      return ApiResponse(200, {
        'token': 'original-token',
        'user': {
          'id': 'user-1',
          'username': 'player',
          'email': 'player@example.com',
        },
      });
    }
    securityEndpoint = endpoint;
    securityBody = body;
    return securityResponse;
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ApiClient.resetForTesting();
  });
  tearDown(ApiClient.resetForTesting);

  test('successful password change atomically replaces local token', () async {
    final backend = _MemoryTokenBackend();
    final api = _SecurityProviderApi();
    final auth = AuthProvider(
      apiClient: api,
      tokenStore: AuthTokenStore(secureBackend: backend),
    );
    expect(
      await auth.login('player@example.com', 'Current!Password-2026'),
      isTrue,
    );

    expect(
      await auth.changePassword(
        currentPassword: 'Current!Password-2026',
        newPassword: 'New!Password-Deck-2026',
      ),
      isTrue,
    );
    expect(api.securityEndpoint, '/auth/change-password');
    expect(backend.value, 'rotated-token');
    expect(auth.token, 'rotated-token');
    expect(auth.isAuthenticated, isTrue);
  });

  test('failed revocation preserves the authenticated local session', () async {
    final backend = _MemoryTokenBackend();
    final api = _SecurityProviderApi()
      ..securityResponse = ApiResponse(400, {
        'error': 'current_password_invalid',
        'message': 'Senha atual incorreta.',
      });
    final auth = AuthProvider(
      apiClient: api,
      tokenStore: AuthTokenStore(secureBackend: backend),
    );
    expect(
      await auth.login('player@example.com', 'Current!Password-2026'),
      isTrue,
    );

    expect(await auth.revokeOtherSessions(currentPassword: 'wrong'), isFalse);
    expect(api.securityEndpoint, '/auth/revoke-sessions');
    expect(backend.value, 'original-token');
    expect(auth.token, 'original-token');
    expect(auth.isAuthenticated, isTrue);
    expect(auth.errorMessage, 'Senha atual incorreta.');
  });

  test('logout clears stale authenticated-operation errors', () async {
    final backend = _MemoryTokenBackend();
    final api = _SecurityProviderApi()
      ..securityResponse = ApiResponse(400, {
        'error': 'current_password_invalid',
        'message': 'Senha atual incorreta.',
      });
    final auth = AuthProvider(
      apiClient: api,
      tokenStore: AuthTokenStore(secureBackend: backend),
    );
    expect(
      await auth.login('player@example.com', 'Current!Password-2026'),
      isTrue,
    );
    expect(await auth.revokeOtherSessions(currentPassword: 'wrong'), isFalse);
    expect(auth.errorMessage, 'Senha atual incorreta.');

    await auth.logout();

    expect(auth.status, AuthStatus.unauthenticated);
    expect(auth.errorMessage, isNull);
    expect(backend.value, isNull);
  });

  test(
    'runtime expiry clears only the expired authenticated session',
    () async {
      final backend = _MemoryTokenBackend();
      final api = _SecurityProviderApi();
      final auth = AuthProvider(
        apiClient: api,
        tokenStore: AuthTokenStore(secureBackend: backend),
      );
      expect(
        await auth.login('player@example.com', 'Current!Password-2026'),
        isTrue,
      );

      auth.expireSession();
      await Future<void>.delayed(Duration.zero);

      expect(auth.status, AuthStatus.unauthenticated);
      expect(auth.token, isNull);
      expect(auth.user, isNull);
      expect(auth.errorMessage, AuthProvider.expiredSessionMessage);
      expect(backend.value, isNull);
      expect(ApiClient.hasAuthenticationToken, isFalse);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('user_data'), isNull);
    },
  );
}
