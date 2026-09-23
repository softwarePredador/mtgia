import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

// Imports relativos, como os das rotas (mesma cópia dos singletons).
import '../lib/auth_service.dart';
import '../lib/rate_limit_middleware.dart';
import '../lib/release_capability_policy.dart';
import '../routes/users/_middleware.dart' as users_middleware;
import '../routes/users/me/export/index.dart' as export_route;
import '../routes/users/me/index.dart' as me_route;
import 'support/scripted_pool.dart';

const _userId = '22222222-2222-4222-8222-222222222222';

/// BT-AUTH-004, buracos 1 e 2 da D-19, com a D-20: exportação e exclusão
/// pedem a senha a cada requisição, contam no bucket de credenciais por IP e
/// têm limite por conta; a troca de e-mail não existe fora dessa regra.
void main() {
  const password = 'Senha!Atual-2026';
  late String storedHash;

  setUpAll(() {
    AuthService.resetForTesting();
    storedHash = AuthService().hashPassword(password);
  });

  tearDown(() {
    overrideAccountReverificationRateLimiterForTesting(null);
  });

  Result passwordRow() => scriptedResult(
    columns: const ['password_hash'],
    rows: [
      [storedHash],
    ],
  );

  group('exportação exige a senha a cada requisição', () {
    test('só com o token de sessão não exporta', () async {
      final pool = ScriptedPool(const []);

      for (final body in <Object?>[
        null,
        <String, Object?>{},
        {'password': ''},
      ]) {
        final response = await export_route.onRequest(
          _context('POST', '/users/me/export', pool: pool, body: body),
        );
        final json = jsonDecode(await response.body()) as Map<String, dynamic>;

        expect(response.statusCode, HttpStatus.badRequest, reason: '$body');
        expect(json['error'], 'password_required');
      }
      expect(pool.executedCount, 0, reason: 'nada foi lido do banco');
    });

    test('GET, o contrato antigo, não exporta mais', () async {
      final pool = ScriptedPool(const []);
      final response = await export_route.onRequest(
        _context('GET', '/users/me/export', pool: pool),
      );

      expect(response.statusCode, HttpStatus.methodNotAllowed);
      expect(pool.executedCount, 0);
      expect(
        isReleaseCapabilityControlPlaneRequest(
          path: '/users/me/export',
          method: 'GET',
        ),
        isFalse,
      );
      expect(
        isReleaseCapabilityControlPlaneRequest(
          path: '/users/me/export',
          method: 'POST',
        ),
        isTrue,
      );
    });

    test('senha errada devolve 401 e não monta a exportação', () async {
      final pool = ScriptedPool([passwordRow()]);
      final response = await export_route.onRequest(
        _context(
          'POST',
          '/users/me/export',
          pool: pool,
          body: {'password': 'Senha!Errada-2026'},
        ),
      );
      final json = jsonDecode(await response.body()) as Map<String, dynamic>;

      expect(response.statusCode, HttpStatus.unauthorized);
      expect(json['error'], 'invalid_password');
      expect(pool.executedCount, 1);
      expect(pool.queries.single, contains('password_hash'));
    });

    test('senha certa segue para a exportação', () async {
      // A primeira consulta da exportação volta vazia: 404 prova que ela só
      // começou depois da senha conferida.
      final pool = ScriptedPool([passwordRow(), scriptedResult()]);
      final response = await export_route.onRequest(
        _context(
          'POST',
          '/users/me/export',
          pool: pool,
          body: {'password': password},
        ),
      );

      expect(response.statusCode, HttpStatus.notFound);
      expect(pool.executedCount, 2);
      expect(pool.queries.first, contains('password_hash'));
      expect(pool.queries.last, contains('jsonb_build_object'));
    });

    test('o limite por conta barra antes de conferir a senha', () async {
      overrideAccountReverificationRateLimiterForTesting(
        RateLimiter(maxRequests: 1, windowSeconds: 900),
      );
      final pool = ScriptedPool([passwordRow()]);

      final first = await export_route.onRequest(
        _context(
          'POST',
          '/users/me/export',
          pool: pool,
          body: {'password': 'Senha!Errada-2026'},
        ),
      );
      final second = await export_route.onRequest(
        _context(
          'POST',
          '/users/me/export',
          pool: pool,
          body: {'password': 'Outra!Errada-2026'},
        ),
      );
      final json = jsonDecode(await second.body()) as Map<String, dynamic>;

      expect(first.statusCode, HttpStatus.unauthorized);
      expect(second.statusCode, HttpStatus.tooManyRequests);
      expect(json['rate_limit_bucket'], accountReverificationRateLimitBucket);
      expect(pool.executedCount, 1);
    });
  });

  group('exclusão da conta', () {
    test('o limite por conta barra o oráculo de senha', () async {
      overrideAccountReverificationRateLimiterForTesting(
        RateLimiter(maxRequests: 1, windowSeconds: 900),
      );
      final pool = ScriptedPool([
        scriptedResult(
          columns: const ['username', 'email', 'password_hash'],
          rows: [
            ['jogadora', 'jogadora@example.invalid', storedHash],
          ],
        ),
      ]);
      Map<String, Object?> attempt(String guess) => {
        'confirmation': 'EXCLUIR MINHA CONTA',
        'password': guess,
      };

      final first = await me_route.onRequest(
        _context(
          'DELETE',
          '/users/me',
          pool: pool,
          body: attempt('Palpite!Um-2026'),
        ),
      );
      final second = await me_route.onRequest(
        _context(
          'DELETE',
          '/users/me',
          pool: pool,
          body: attempt('Palpite!Dois-2026'),
        ),
      );
      final json = jsonDecode(await second.body()) as Map<String, dynamic>;

      expect(first.statusCode, HttpStatus.unauthorized);
      expect(second.statusCode, HttpStatus.tooManyRequests);
      expect(json['rate_limit_bucket'], accountReverificationRateLimitBucket);
      expect(pool.executedCount, 1, reason: 'o 429 vem antes do banco');
    });
  });

  group('bucket de credenciais por IP', () {
    test('exclusão e exportação são tentativas de credencial', () {
      for (final request in const [
        'DELETE /users/me',
        'POST /users/me/export',
        'POST /users/me/export/',
      ]) {
        expect(
          isAuthCredentialAttempt(_request(request)),
          isTrue,
          reason: request,
        );
      }
      for (final request in const [
        'GET /users/me',
        'PATCH /users/me',
        'GET /users/me/export',
        'GET /users/me/plan',
        'DELETE /users/me/fcm-token',
        'DELETE /users/other/follow',
      ]) {
        expect(
          isAuthCredentialAttempt(_request(request)),
          isFalse,
          reason: request,
        );
      }
    });

    test('o middleware de /users conta DELETE /users/me no bucket', () async {
      // Limitador real de desenvolvimento (200 por minuto por cliente). Sem
      // token o handler nem roda: o bucket conta a tentativa antes da
      // autenticação, e a 201ª é barrada.
      var handlerCalls = 0;
      final handler = users_middleware.middleware((_) {
        handlerCalls++;
        return Response.json(body: const {'unexpected': true});
      });
      Response? last;
      for (var i = 0; i < 201; i++) {
        last = await handler(
          _context(
            'DELETE',
            '/users/me',
            headers: const {'user-agent': 'oraculo-de-senha'},
          ),
        );
        if (i < 200) expect(last.statusCode, HttpStatus.unauthorized);
      }
      final json = jsonDecode(await last!.body()) as Map<String, dynamic>;

      expect(last.statusCode, HttpStatus.tooManyRequests);
      expect(json['rate_limit_bucket'], 'auth');
      expect(handlerCalls, 0);

      final profileRead = await handler(
        _context(
          'GET',
          '/users/me',
          headers: const {'user-agent': 'oraculo-de-senha'},
        ),
      );
      expect(profileRead.statusCode, HttpStatus.unauthorized);
    });
  });

  group('troca de e-mail', () {
    test('não existe rota: PATCH /users/me não grava e-mail', () async {
      final onlyEmail = ScriptedPool(const []);
      final rejected = await me_route.onRequest(
        _context(
          'PATCH',
          '/users/me',
          pool: onlyEmail,
          body: {'email': 'nova@example.invalid'},
        ),
      );
      expect(rejected.statusCode, HttpStatus.badRequest);
      expect(onlyEmail.executedCount, 0);

      final mixed = ScriptedPool([_profileRow()]);
      final updated = await me_route.onRequest(
        _context(
          'PATCH',
          '/users/me',
          pool: mixed,
          body: {'email': 'nova@example.invalid', 'display_name': 'Jogadora'},
        ),
      );
      expect(updated.statusCode, HttpStatus.ok);
      final setClause = mixed.queries.single.split('WHERE').first;
      expect(
        setClause,
        isNot(contains('email =')),
        reason:
            'trocar e-mail exige reverificação de senha (D-20); use o mesmo '
            'caminho da exportação e da exclusão',
      );
      expect((mixed.parameters.single! as Map).containsKey('email'), isFalse);
    });
  });
}

Request _request(String line) {
  final separator = line.indexOf(' ');
  return Request(
    line.substring(0, separator),
    Uri.parse('http://localhost${line.substring(separator + 1)}'),
  );
}

RequestContext _context(
  String method,
  String path, {
  Pool? pool,
  Object? body,
  Map<String, String> headers = const {},
}) => ScriptedRequestContext(
  Request(
    method,
    Uri.parse('http://localhost$path'),
    headers: {'content-type': 'application/json', ...headers},
    body: body == null ? null : jsonEncode(body),
  ),
  providers: {String: _userId, if (pool != null) Pool: pool},
);

Result _profileRow() {
  const columns = [
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
  ];
  return scriptedResult(
    columns: columns,
    rows: [
      [
        _userId,
        'jogadora',
        'jogadora@example.invalid',
        'Jogadora',
        null,
        null,
        null,
        null,
        'public',
        'public',
        'private',
        'everyone',
        'everyone',
        'private',
        DateTime.utc(2026, 9, 1),
        DateTime.utc(2026, 9, 23),
        DateTime.utc(2026, 9, 2),
      ],
    ],
  );
}
