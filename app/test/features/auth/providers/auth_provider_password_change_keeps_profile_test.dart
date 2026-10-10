import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/api/api_client.dart';
import 'package:manaloom/core/security/auth_token_store.dart';
import 'package:manaloom/features/auth/providers/auth_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// BT-AUTH-007: trocar a senha, ou encerrar as outras sessões, não pode apagar
// no app o e-mail verificado, o nome e o avatar.
//
// O servidor devolve o usuário completo, no formato de `GET /users/me`
// (`server/test/account_security_full_user_test.dart` fixa as chaves). O app
// troca o usuário guardado pelo da resposta, na memória e no aparelho. Com o
// `user` truncado de antes (só id, nome de usuário e e-mail), os três campos
// sumiam até o próximo login.

/// O perfil completo, com as mesmas chaves que o servidor devolve.
Map<String, dynamic> _fullProfile() => <String, dynamic>{
  'id': '44444444-4444-4444-8444-444444444444',
  'username': 'jogadora',
  'email': 'jogadora@example.invalid',
  'display_name': 'Jogadora Um',
  'avatar_url': 'https://example.invalid/avatar.png',
  'location_state': 'SP',
  'location_city': 'Campinas',
  'trade_notes': 'Troco commander',
  'profile_visibility': 'private',
  'binder_visibility': 'public',
  'location_visibility': 'trade_only',
  'message_visibility': 'followers',
  'trade_visibility': 'everyone',
  'trade_notes_visibility': 'trade_only',
  'email_verified': true,
  'created_at': '2026-09-01T00:00:00.000Z',
  'updated_at': '2026-09-23T00:00:00.000Z',
};

class _MemoryTokenBackend implements SecureTokenBackend {
  String? value;

  @override
  Future<void> delete(String key) async => value = null;

  @override
  Future<String?> read(String key) async => value;

  @override
  Future<void> write(String key, String value) async => this.value = value;
}

/// Responde ao login e às duas rotas de segurança da conta como o servidor.
class _AccountSecurityApi extends ApiClient {
  final List<String> endpoints = <String>[];

  @override
  Future<ApiResponse> post(
    String endpoint,
    Map<String, dynamic> body, {
    Duration? timeout,
  }) async {
    endpoints.add(endpoint);
    switch (endpoint) {
      case '/auth/login':
        return ApiResponse(200, {
          'token': 'login-token',
          'user': _fullProfile(),
        });
      case '/auth/change-password':
        return ApiResponse(200, {
          'token': 'rotated-token',
          'user': _fullProfile(),
        });
      case '/auth/revoke-sessions':
        return ApiResponse(200, {
          'token': 'rotated-token',
          'sessions_revoked': true,
          'user': _fullProfile(),
        });
    }
    return ApiResponse(404, {'error': 'not_found'});
  }
}

Future<AuthProvider> _signedIn(_AccountSecurityApi api) async {
  final auth = AuthProvider(
    apiClient: api,
    tokenStore: AuthTokenStore(secureBackend: _MemoryTokenBackend()),
  );
  expect(
    await auth.login('jogadora@example.invalid', 'Senha!Atual-Forte-2026'),
    isTrue,
  );
  expect(auth.user!.emailVerified, isTrue);
  return auth;
}

Future<void> _expectProfileKept(AuthProvider auth) async {
  expect(auth.token, 'rotated-token');
  final user = auth.user!;
  expect(user.emailVerified, isTrue, reason: 'e-mail verificado');
  expect(user.displayName, 'Jogadora Um', reason: 'nome');
  expect(
    user.avatarUrl,
    'https://example.invalid/avatar.png',
    reason: 'avatar',
  );
  expect(user.profileVisibility, 'private');
  expect(user.tradeNotesVisibility, 'trade_only');
  expect(user.locationCity, 'Campinas');

  // O usuário guardado no aparelho é o que o próximo boot carrega.
  final prefs = await SharedPreferences.getInstance();
  final stored =
      jsonDecode(prefs.getString('user_data')!) as Map<String, dynamic>;
  expect(
    stored['email_verified'],
    isTrue,
    reason: 'e-mail verificado guardado',
  );
  expect(stored['display_name'], 'Jogadora Um', reason: 'nome guardado');
  expect(
    stored['avatar_url'],
    'https://example.invalid/avatar.png',
    reason: 'avatar guardado',
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ApiClient.resetForTesting();
  });
  tearDown(ApiClient.resetForTesting);

  test(
    'trocar a senha mantém e-mail verificado, nome e avatar (BT-AUTH-007)',
    () async {
      final api = _AccountSecurityApi();
      final auth = await _signedIn(api);

      expect(
        await auth.changePassword(
          currentPassword: 'Senha!Atual-Forte-2026',
          newPassword: 'kX9#vQ2!mZr7@Lp4',
        ),
        isTrue,
      );

      expect(api.endpoints.last, '/auth/change-password');
      await _expectProfileKept(auth);
    },
  );

  test('encerrar as outras sessões mantém e-mail verificado, nome e avatar '
      '(BT-AUTH-007)', () async {
    final api = _AccountSecurityApi();
    final auth = await _signedIn(api);

    expect(
      await auth.revokeOtherSessions(currentPassword: 'Senha!Atual-Forte-2026'),
      isTrue,
    );

    expect(api.endpoints.last, '/auth/revoke-sessions');
    await _expectProfileKept(auth);
  });
}
