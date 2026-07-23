import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:manaloom/core/api/api_client.dart';
import 'package:manaloom/core/security/auth_token_store.dart';
import 'package:manaloom/features/auth/providers/auth_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MemorySecureTokenBackend implements SecureTokenBackend {
  final values = <String, String>{};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    values.remove(key);
  }
}

class _TokenValidationApiClient extends ApiClient {
  _TokenValidationApiClient.response(int statusCode)
    : response = ApiResponse(statusCode, const <String, dynamic>{}),
      error = null;

  _TokenValidationApiClient.error(this.error) : response = null;

  final ApiResponse? response;
  final Object? error;
  int getCalls = 0;

  @override
  Future<ApiResponse> get(String endpoint) async {
    getCalls++;
    expect(endpoint, '/auth/me');
    final failure = error;
    if (failure != null) throw failure;
    return response!;
  }
}

const _savedToken = 'saved-token';
const _savedUser = <String, dynamic>{
  'id': 'user-saved',
  'username': 'saved_user',
  'email': 'saved_user@example.com',
};

({
  AuthProvider provider,
  AuthTokenStore tokenStore,
  _MemorySecureTokenBackend secureBackend,
})
_buildProvider(_TokenValidationApiClient apiClient) {
  SharedPreferences.setMockInitialValues({'user_data': jsonEncode(_savedUser)});
  final secureBackend = _MemorySecureTokenBackend()
    ..values[AuthTokenStore.secureKey] = _savedToken;
  final tokenStore = AuthTokenStore(secureBackend: secureBackend);
  return (
    provider: AuthProvider(apiClient: apiClient, tokenStore: tokenStore),
    tokenStore: tokenStore,
    secureBackend: secureBackend,
  );
}

({
  AuthProvider provider,
  AuthTokenStore tokenStore,
  _MemorySecureTokenBackend secureBackend,
})
_buildProviderWithStoredValues(
  _TokenValidationApiClient apiClient, {
  String? token,
  String? userData,
}) {
  SharedPreferences.setMockInitialValues({
    if (userData != null) 'user_data': userData,
  });
  final secureBackend = _MemorySecureTokenBackend();
  if (token != null) {
    secureBackend.values[AuthTokenStore.secureKey] = token;
  }
  final tokenStore = AuthTokenStore(secureBackend: secureBackend);
  return (
    provider: AuthProvider(apiClient: apiClient, tokenStore: tokenStore),
    tokenStore: tokenStore,
    secureBackend: secureBackend,
  );
}

Future<void> _expectSessionPreserved(
  ({
    AuthProvider provider,
    AuthTokenStore tokenStore,
    _MemorySecureTokenBackend secureBackend,
  })
  fixture,
) async {
  expect(fixture.provider.status, AuthStatus.authenticated);
  expect(fixture.provider.token, _savedToken);
  expect(fixture.provider.user?.id, _savedUser['id']);
  expect(await fixture.tokenStore.read(), _savedToken);
  expect(fixture.secureBackend.values[AuthTokenStore.secureKey], _savedToken);
  final prefs = await SharedPreferences.getInstance();
  expect(prefs.getString('user_data'), jsonEncode(_savedUser));
  expect(ApiClient.hasAuthenticationToken, isTrue);
}

void main() {
  setUp(ApiClient.resetForTesting);
  tearDown(ApiClient.resetForTesting);

  test(
    'initialize clears saved credentials when /auth/me returns 401',
    () async {
      final apiClient = _TokenValidationApiClient.response(401);
      final fixture = _buildProvider(apiClient);

      await fixture.provider.initialize();

      expect(apiClient.getCalls, 1);
      expect(fixture.provider.status, AuthStatus.unauthenticated);
      expect(fixture.provider.token, isNull);
      expect(fixture.provider.user, isNull);
      expect(await fixture.tokenStore.read(), isNull);
      expect(fixture.secureBackend.values[AuthTokenStore.secureKey], isNull);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('user_data'), isNull);
      expect(ApiClient.hasAuthenticationToken, isFalse);
    },
  );

  for (final statusCode in const [429, 500, 503]) {
    test(
      'initialize preserves saved credentials when /auth/me returns $statusCode',
      () async {
        final apiClient = _TokenValidationApiClient.response(statusCode);
        final fixture = _buildProvider(apiClient);

        await fixture.provider.initialize();

        expect(apiClient.getCalls, 1);
        await _expectSessionPreserved(fixture);
      },
    );
  }

  final transientErrors = <String, Object>{
    'timeout': TimeoutException('auth validation timed out'),
    'network failure': http.ClientException('network unavailable'),
  };
  for (final entry in transientErrors.entries) {
    test('initialize preserves saved credentials after ${entry.key}', () async {
      final apiClient = _TokenValidationApiClient.error(entry.value);
      final fixture = _buildProvider(apiClient);

      await fixture.provider.initialize();

      expect(apiClient.getCalls, 1);
      await _expectSessionPreserved(fixture);
    });
  }

  for (final storedValues
      in <({String label, String? token, String? userData})>[
        (label: 'token sem usuário', token: _savedToken, userData: null),
        (
          label: 'usuário sem token',
          token: null,
          userData: jsonEncode(_savedUser),
        ),
        (
          label: 'JSON de usuário malformado',
          token: _savedToken,
          userData: '{',
        ),
      ]) {
    test(
      'initialize remove ${storedValues.label} com copy explícita',
      () async {
        final apiClient = _TokenValidationApiClient.response(200);
        final fixture = _buildProviderWithStoredValues(
          apiClient,
          token: storedValues.token,
          userData: storedValues.userData,
        );

        await fixture.provider.initialize();

        expect(fixture.provider.status, AuthStatus.unauthenticated);
        expect(fixture.provider.token, isNull);
        expect(fixture.provider.user, isNull);
        expect(
          fixture.provider.errorMessage,
          AuthProvider.invalidSavedSessionMessage,
        );
        expect(await fixture.tokenStore.read(), isNull);
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('user_data'), isNull);
        expect(ApiClient.hasAuthenticationToken, isFalse);
      },
    );
  }
}
