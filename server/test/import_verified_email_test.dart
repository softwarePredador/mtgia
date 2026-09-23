import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:test/test.dart';

import '../lib/auth_service.dart';
import '../lib/database.dart';
import '../lib/verified_email_middleware.dart';
import '../routes/binder/_middleware.dart' as binder_middleware;
import '../routes/import/_middleware.dart' as import_middleware;
import 'support/scripted_pool.dart';

const _userId = '55555555-5555-4555-8555-555555555555';

/// BT-AUTH-010 (achado 11 dos fluxos): `/import` e `/import/*` passam pela
/// mesma verificação de e-mail do fichário. Com a exigência ligada (em
/// produção ela é sempre), conta não verificada não importa.
void main() {
  setUpAll(AuthService.resetForTesting);

  setUp(() => overrideVerifiedEmailRequirementForTesting(true));

  tearDown(() {
    overrideVerifiedEmailRequirementForTesting(null);
    Database.resetForTesting();
  });

  // O authMiddleware e o portão de e-mail leem o usuário do token.
  ScriptedPool accountLookups({required bool verified, int requests = 1}) =>
      ScriptedPool([
        for (var i = 0; i < requests * 2; i++)
          scriptedResult(
            rows: [
              [
                _userId,
                'importadora',
                'importadora@example.invalid',
                null,
                null,
                0,
                verified ? DateTime.utc(2026, 9, 2) : null,
              ],
            ],
          ),
      ]);

  RequestContext post(String path) => ScriptedRequestContext(
    Request.post(
      Uri.parse('http://localhost$path'),
      headers: {
        'content-type': 'application/json',
        HttpHeaders.authorizationHeader:
            'Bearer ${AuthService().generateToken(_userId, 'importadora')}',
      },
      body: jsonEncode({'list': '1 Sol Ring', 'format': 'commander'}),
    ),
  );

  test('conta não verificada não importa', () async {
    for (final path in const [
      '/import',
      '/import/to-deck',
      '/import/validate',
    ]) {
      Database.useConnectionForTesting(accountLookups(verified: false));
      var handlerCalls = 0;
      final handler = import_middleware.middleware((_) {
        handlerCalls++;
        return Response.json(body: const {'imported': true});
      });

      final response = await handler(post(path));
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;

      expect(response.statusCode, HttpStatus.forbidden, reason: path);
      expect(body['error'], 'email_verification_required', reason: path);
      expect(handlerCalls, 0, reason: path);
    }
  });

  test('conta verificada importa', () async {
    Database.useConnectionForTesting(accountLookups(verified: true));
    var handlerCalls = 0;
    final handler = import_middleware.middleware((_) {
      handlerCalls++;
      return Response.json(body: const {'imported': true});
    });

    final response = await handler(post('/import'));

    expect(response.statusCode, HttpStatus.ok);
    expect(handlerCalls, 1);
  });

  test('o portão do import é o mesmo do fichário', () async {
    Database.useConnectionForTesting(accountLookups(verified: false));
    final binder = binder_middleware.middleware(
      (_) => Response.json(body: const {'created': true}),
    );

    final response = await binder(post('/binder'));

    expect(response.statusCode, HttpStatus.forbidden);
    expect(
      File('routes/import/_middleware.dart').readAsStringSync(),
      contains(
        'handler.use(verifiedEmailForMutations()).use(authMiddleware())',
      ),
    );
  });
}
