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
//
// O servidor é a autoridade do perfil: se ele mudou desde o login (nome e
// avatar trocados em outro aparelho, por exemplo), o app adota o usuário da
// resposta, e não o que tinha guardado. Por isso a resposta da troca traz um
// usuário diferente do login.

/// O perfil completo, com as mesmas chaves que o servidor devolve.
Map<String, dynamic> _fullProfile({
  String displayName = 'Jogadora Um',
  String avatarUrl = 'https://example.invalid/avatar.png',
  String locationCity = 'Campinas',
  String updatedAt = '2026-09-23T00:00:00.000Z',
}) => <String, dynamic>{
  'id': '44444444-4444-4444-8444-444444444444',
  'username': 'jogadora',
  'email': 'jogadora@example.invalid',
  'display_name': displayName,
  'avatar_url': avatarUrl,
  'location_state': 'SP',
  'location_city': locationCity,
  'trade_notes': 'Troco commander',
  'profile_visibility': 'private',
  'binder_visibility': 'public',
  'location_visibility': 'trade_only',
  'message_visibility': 'followers',
  'trade_visibility': 'everyone',
  'trade_notes_visibility': 'trade_only',
  'email_verified': true,
  'created_at': '2026-09-01T00:00:00.000Z',
  'updated_at': updatedAt,
};

const _nameAfterRotation = 'Jogadora Renomeada';
const _avatarAfterRotation = 'https://example.invalid/avatar-novo.png';
const _cityAfterRotation = 'Santos';

/// O usuário que o servidor devolve na troca: o mesmo id, com o perfil
/// mudado desde o login.
Map<String, dynamic> _profileAfterRotation() => _fullProfile(
  displayName: _nameAfterRotation,
  avatarUrl: _avatarAfterRotation,
  locationCity: _cityAfterRotation,
  updatedAt: '2026-10-10T00:00:00.000Z',
);

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
          'user': _profileAfterRotation(),
        });
      case '/auth/revoke-sessions':
        return ApiResponse(200, {
          'token': 'rotated-token',
          'sessions_revoked': true,
          'user': _profileAfterRotation(),
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
  expect(auth.user!.displayName, 'Jogadora Um');
  expect(auth.user!.avatarUrl, 'https://example.invalid/avatar.png');
  return auth;
}

Future<void> _expectServerUserAdopted(AuthProvider auth) async {
  expect(auth.token, 'rotated-token');
  final user = auth.user!;
  expect(user.emailVerified, isTrue, reason: 'e-mail verificado');
  expect(user.displayName, _nameAfterRotation, reason: 'nome do servidor');
  expect(user.avatarUrl, _avatarAfterRotation, reason: 'avatar do servidor');
  expect(user.locationCity, _cityAfterRotation, reason: 'cidade do servidor');
  expect(user.profileVisibility, 'private');
  expect(user.tradeNotesVisibility, 'trade_only');

  // O usuário guardado no aparelho é o que o próximo boot carrega.
  final prefs = await SharedPreferences.getInstance();
  final stored =
      jsonDecode(prefs.getString('user_data')!) as Map<String, dynamic>;
  expect(
    stored['email_verified'],
    isTrue,
    reason: 'e-mail verificado guardado',
  );
  expect(
    stored['display_name'],
    _nameAfterRotation,
    reason: 'nome do servidor guardado',
  );
  expect(
    stored['avatar_url'],
    _avatarAfterRotation,
    reason: 'avatar do servidor guardado',
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ApiClient.resetForTesting();
  });
  tearDown(ApiClient.resetForTesting);

  test('trocar a senha adota o usuário do servidor, com e-mail verificado, '
      'nome e avatar (BT-AUTH-007)', () async {
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
    await _expectServerUserAdopted(auth);
  });

  test('encerrar as outras sessões adota o usuário do servidor, com e-mail '
      'verificado, nome e avatar (BT-AUTH-007)', () async {
    final api = _AccountSecurityApi();
    final auth = await _signedIn(api);

    expect(
      await auth.revokeOtherSessions(currentPassword: 'Senha!Atual-Forte-2026'),
      isTrue,
    );

    expect(api.endpoints.last, '/auth/revoke-sessions');
    await _expectServerUserAdopted(auth);
  });
}
