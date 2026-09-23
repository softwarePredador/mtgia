import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:test/test.dart';

import '../lib/auth_service.dart';
import '../lib/database.dart';
import '../routes/auth/change-password.dart' as change_password_route;
import '../routes/auth/revoke-sessions.dart' as revoke_sessions_route;
import 'support/scripted_pool.dart';

const _userId = '44444444-4444-4444-8444-444444444444';
const _currentPassword = 'Senha!Atual-Forte-2026';

/// Campos que `GET /users/me` devolve e que o `User.fromJson` do app lê.
const _profileKeys = {
  'id',
  'username',
  'email',
  'display_name',
  'avatar_url',
  'location_state',
  'location_city',
  'trade_notes',
  'profile_visibility',
  'binder_visibility',
  'location_visibility',
  'message_visibility',
  'trade_visibility',
  'trade_notes_visibility',
  'email_verified',
  'created_at',
  'updated_at',
};

/// BT-AUTH-007: trocar a senha (e encerrar as outras sessões) devolve o
/// usuário completo. O app substitui o usuário guardado pelo da resposta; com
/// o `user` truncado, e-mail verificado, nome e avatar sumiam.
void main() {
  late String storedHash;

  setUpAll(() {
    AuthService.resetForTesting();
    storedHash = AuthService().hashPassword(_currentPassword);
  });

  tearDown(Database.resetForTesting);

  List<Object> rotationSteps({required bool resetTokens}) => [
    // getUserFromToken
    scriptedResult(
      rows: [
        [
          _userId,
          'jogadora',
          'jogadora@example.invalid',
          'Jogadora Um',
          'https://example.invalid/avatar.png',
          3,
          DateTime.utc(2026, 9, 2),
        ],
      ],
    ),
    // SELECT ... FOR UPDATE
    scriptedResult(
      rows: [
        ['jogadora', 'jogadora@example.invalid', storedHash, 3],
      ],
    ),
    // UPDATE users ... RETURNING
    scriptedResult(
      columns: const [
        'id',
        'username',
        'email',
        'display_name',
        'avatar_url',
        'location_state',
        'location_city',
        'trade_notes',
        'profile_visibility',
        'binder_visibility',
        'location_visibility',
        'message_visibility',
        'trade_visibility',
        'trade_notes_visibility',
        'created_at',
        'updated_at',
        'email_verified_at',
      ],
      rows: [
        [
          _userId,
          'jogadora',
          'jogadora@example.invalid',
          'Jogadora Um',
          'https://example.invalid/avatar.png',
          'SP',
          'Campinas',
          'Troco commander',
          'private',
          'public',
          'trade_only',
          'followers',
          'everyone',
          'trade_only',
          DateTime.utc(2026, 9, 1),
          DateTime.utc(2026, 9, 23),
          DateTime.utc(2026, 9, 2),
        ],
      ],
    ),
    if (resetTokens) scriptedResult(),
  ];

  RequestContext context(String path, Map<String, Object?> body) {
    final token = AuthService().generateToken(
      _userId,
      'jogadora',
      authVersion: 3,
    );
    return ScriptedRequestContext(
      Request.post(
        Uri.parse('http://localhost$path'),
        headers: {
          'content-type': 'application/json',
          HttpHeaders.authorizationHeader: 'Bearer $token',
        },
        body: jsonEncode(body),
      ),
    );
  }

  void expectFullUser(Map<String, dynamic> user) {
    expect(user.keys.toSet(), _profileKeys);
    expect(user['email_verified'], isTrue);
    expect(user['display_name'], 'Jogadora Um');
    expect(user['avatar_url'], 'https://example.invalid/avatar.png');
    expect(user['profile_visibility'], 'private');
    expect(user['trade_notes_visibility'], 'trade_only');
    expect(user['location_city'], 'Campinas');
  }

  test('trocar a senha devolve o usuário completo', () async {
    final pool = ScriptedPool(rotationSteps(resetTokens: true));
    Database.useConnectionForTesting(pool);

    final response = await change_password_route.onRequest(
      context('/auth/change-password', {
        'current_password': _currentPassword,
        'new_password': 'kX9#vQ2!mZr7@Lp4',
      }),
    );
    final body = jsonDecode(await response.body()) as Map<String, dynamic>;

    expect(response.statusCode, HttpStatus.ok, reason: '$body');
    expect(body['token'], isA<String>());
    expectFullUser(body['user'] as Map<String, dynamic>);
    expect(pool.exhausted, isTrue);
    expect(pool.queries[2], contains('RETURNING id, username, email'));
  });

  test(
    'encerrar as outras sessões também devolve o usuário completo',
    () async {
      final pool = ScriptedPool(rotationSteps(resetTokens: false));
      Database.useConnectionForTesting(pool);

      final response = await revoke_sessions_route.onRequest(
        context('/auth/revoke-sessions', {
          'current_password': _currentPassword,
        }),
      );
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;

      expect(response.statusCode, HttpStatus.ok, reason: '$body');
      expect(body['sessions_revoked'], isTrue);
      expectFullUser(body['user'] as Map<String, dynamic>);
    },
  );

  test('senha atual errada continua sem tocar o perfil', () async {
    final pool = ScriptedPool(
      rotationSteps(resetTokens: false).take(2).toList(),
    );
    Database.useConnectionForTesting(pool);

    final response = await change_password_route.onRequest(
      context('/auth/change-password', {
        'current_password': 'Senha!Errada-Forte-2026',
        'new_password': 'kX9#vQ2!mZr7@Lp4',
      }),
    );
    final body = jsonDecode(await response.body()) as Map<String, dynamic>;

    expect(response.statusCode, HttpStatus.badRequest);
    expect(body['error'], 'current_password_invalid');
    expect(pool.exhausted, isTrue, reason: 'nenhum UPDATE rodou');
  });

  test('o perfil tem o mesmo formato de GET /users/me', () {
    final source = File('routes/users/me/index.dart').readAsStringSync();
    for (final key in _profileKeys) {
      expect(source, contains("'$key':"), reason: key);
    }
  });
}
