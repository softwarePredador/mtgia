import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:test/test.dart';

// Imports relativos, como os das rotas: `package:server/...` criaria uma
// segunda cópia dos singletons (AuthService, Database) que a rota não vê.
import '../lib/auth_service.dart';
import '../lib/database.dart';
import '../lib/rate_limit_middleware.dart';
import '../routes/auth/forgot-password.dart' as forgot_password_route;
import '../routes/auth/login.dart' as login_route;
import 'support/scripted_pool.dart';

/// BT-AUTH-003, buraco 3 da D-19, com a D-21: o login não pode denunciar pelo
/// tempo nem pelo corpo da resposta quais e-mails têm conta, e as tentativas
/// são limitadas por e-mail além de por IP.
void main() {
  const loginColumns = [
    'id',
    'username',
    'email',
    'password_hash',
    'auth_version',
    'email_verified_at',
  ];
  const userId = '11111111-1111-4111-8111-111111111111';
  const email = 'jogadora@example.invalid';
  const password = 'Senha!Correta-2026';

  late String storedHash;

  setUpAll(() {
    AuthService.resetForTesting();
    storedHash = AuthService().hashPassword(password);
  });

  tearDown(() {
    overrideCredentialEmailRateLimiterForTesting(null);
    AuthService.resetForTesting();
    Database.resetForTesting();
  });

  List<Object?> accountRow() => [
    userId,
    'jogadora',
    email,
    storedHash,
    0,
    null,
  ];

  group('verificação de senha no login', () {
    test('roda também quando o e-mail não tem conta', () async {
      final verifications = <String>[];
      AuthService.resetForTesting(
        loginPasswordVerifier: (candidate, hash) {
          verifications.add(hash);
          return false;
        },
      );
      Database.useConnectionForTesting(
        ScriptedPool([scriptedResult(columns: loginColumns)]),
      );

      await expectLater(
        AuthService().login(email: 'ninguem@example.invalid', password: 'x'),
        throwsA(isA<InvalidCredentialsException>()),
      );

      expect(verifications, [
        AuthService().missingAccountPasswordHashForTesting,
      ]);
    });

    test(
      'conta existente com senha errada falha igual, uma verificação',
      () async {
        final verifications = <String>[];
        AuthService.resetForTesting(
          loginPasswordVerifier: (candidate, hash) {
            verifications.add(hash);
            return false;
          },
        );
        Database.useConnectionForTesting(
          ScriptedPool([
            scriptedResult(columns: loginColumns, rows: [accountRow()]),
          ]),
        );

        await expectLater(
          AuthService().login(email: email, password: 'Senha!Errada-2026'),
          throwsA(
            isA<InvalidCredentialsException>().having(
              (error) => error.toString(),
              'mensagem',
              InvalidCredentialsException.message,
            ),
          ),
        );
        expect(verifications, [storedHash]);
      },
    );

    test(
      'conta inexistente nunca autentica, nem se o hash fictício bater',
      () async {
        AuthService.resetForTesting(loginPasswordVerifier: (_, __) => true);
        Database.useConnectionForTesting(
          ScriptedPool([scriptedResult(columns: loginColumns)]),
        );

        await expectLater(
          AuthService().login(email: 'ninguem@example.invalid', password: 'x'),
          throwsA(isA<InvalidCredentialsException>()),
        );
      },
    );

    test('o hash fictício tem o custo bcrypt dos hashes guardados', () {
      final service = AuthService();
      final dummy = service.missingAccountPasswordHashForTesting;
      final real = service.hashPassword('Outra!Senha-2026');

      expect(dummy, matches(RegExp(r'^\$2[aby]\$\d\d\$.{53}$')));
      expect(dummy.substring(0, 7), real.substring(0, 7));
    });

    test('sem conta e com senha errada pagam o mesmo bcrypt', () async {
      // bcrypt de verdade: sem a verificação no caminho da conta inexistente,
      // esse caminho leva microssegundos contra dezenas de milissegundos.
      const rounds = 7;
      final missingSteps = <Object>[];
      final existingSteps = <Object>[];
      for (var i = 0; i < rounds; i++) {
        missingSteps.add(scriptedResult(columns: loginColumns));
        existingSteps.add(
          scriptedResult(columns: loginColumns, rows: [accountRow()]),
        );
      }
      final missingPool = ScriptedPool(missingSteps);
      final existingPool = ScriptedPool(existingSteps);
      // Primeiro uso do hash fictício fora da medição.
      expect(AuthService().missingAccountPasswordHashForTesting, isNotEmpty);

      Future<int> timedFailure(ScriptedPool pool, String target) async {
        Database.useConnectionForTesting(pool);
        final watch = Stopwatch()..start();
        await expectLater(
          AuthService().login(email: target, password: 'Senha!Errada-2026'),
          throwsA(isA<InvalidCredentialsException>()),
        );
        return watch.elapsedMicroseconds;
      }

      final missing = <int>[];
      final existing = <int>[];
      for (var i = 0; i < rounds; i++) {
        missing.add(await timedFailure(missingPool, 'ninguem@example.invalid'));
        existing.add(await timedFailure(existingPool, email));
      }

      final missingMedian = _median(missing);
      final existingMedian = _median(existing);
      expect(
        missingMedian,
        greaterThanOrEqualTo(existingMedian * 0.5),
        reason:
            'mediana sem conta ${missingMedian}us contra com conta '
            '${existingMedian}us',
      );
    });
  });

  group('rota POST /auth/login', () {
    test('401 idêntico para conta inexistente e senha errada', () async {
      Database.useConnectionForTesting(
        ScriptedPool([
          scriptedResult(columns: loginColumns),
          scriptedResult(columns: loginColumns, rows: [accountRow()]),
        ]),
      );

      final missing = await login_route.onRequest(
        _loginContext({'email': 'ninguem@example.invalid', 'password': 'x'}),
      );
      final wrong = await login_route.onRequest(
        _loginContext({'email': email, 'password': 'Senha!Errada-2026'}),
      );

      expect(missing.statusCode, HttpStatus.unauthorized);
      expect(wrong.statusCode, HttpStatus.unauthorized);
      final missingBody = await missing.body();
      expect(missingBody, await wrong.body());
      expect(jsonDecode(missingBody), {'message': 'Credenciais inválidas'});
    });

    test('senha certa continua entrando', () async {
      Database.useConnectionForTesting(
        ScriptedPool([
          scriptedResult(columns: loginColumns, rows: [accountRow()]),
        ]),
      );

      final response = await login_route.onRequest(
        _loginContext({'email': email, 'password': password}),
      );
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;

      expect(response.statusCode, HttpStatus.ok);
      expect(body['token'], isA<String>());
      expect((body['user'] as Map)['id'], userId);
    });

    test('falha interna não devolve o texto da exceção', () async {
      const secret = 'connection to 10.0.0.9:5432 refused for user postgres';
      Database.useConnectionForTesting(ScriptedPool([Exception(secret)]));

      final response = await login_route.onRequest(
        _loginContext({'email': email, 'password': password}),
      );
      final text = await response.body();

      expect(response.statusCode, HttpStatus.internalServerError);
      expect(text, isNot(contains('10.0.0.9')));
      expect(text, isNot(contains('Exception')));
      expect(jsonDecode(text), {'message': 'Erro ao fazer login'});
    });

    test('corpo inválido não devolve o texto do parser', () async {
      final response = await login_route.onRequest(
        ScriptedRequestContext(
          Request.post(
            Uri.parse('http://localhost/auth/login'),
            headers: const {'content-type': 'application/json'},
            body: '{"email": ',
          ),
        ),
      );
      final text = await response.body();

      expect(response.statusCode, HttpStatus.badRequest);
      expect(text, isNot(contains('FormatException')));
      expect(jsonDecode(text), {'message': 'Dados inválidos.'});
    });
  });

  group('limite por e-mail', () {
    test('bloqueia o mesmo e-mail vindo de qualquer cliente', () async {
      overrideCredentialEmailRateLimiterForTesting(
        RateLimiter(maxRequests: 2, windowSeconds: 900),
      );
      final pool = ScriptedPool([
        scriptedResult(columns: loginColumns),
        scriptedResult(columns: loginColumns),
        scriptedResult(columns: loginColumns),
      ]);
      Database.useConnectionForTesting(pool);

      for (final variant in const [
        'alvo@example.invalid',
        ' ALVO@example.invalid ',
      ]) {
        final response = await login_route.onRequest(
          _loginContext({'email': variant, 'password': 'x'}, client: variant),
        );
        expect(response.statusCode, HttpStatus.unauthorized, reason: variant);
      }

      final blocked = await login_route.onRequest(
        _loginContext({
          'email': 'Alvo@Example.invalid',
          'password': 'x',
        }, client: 'outro-cliente'),
      );
      final body = jsonDecode(await blocked.body()) as Map<String, dynamic>;

      expect(blocked.statusCode, HttpStatus.tooManyRequests);
      expect(body['rate_limit_bucket'], 'auth_login_email');
      expect(body['rate_limit_scope'], 'account');
      expect(pool.executedCount, 2, reason: 'o bloqueio vem antes do banco');

      final otherEmail = await login_route.onRequest(
        _loginContext({'email': 'outra@example.invalid', 'password': 'x'}),
      );
      expect(otherEmail.statusCode, HttpStatus.unauthorized);
    });

    test('o identificador guarda só o digest do e-mail normalizado', () {
      final identifier = credentialEmailRateLimitIdentifier(
        ' Alvo@Example.invalid ',
      );

      expect(
        identifier,
        credentialEmailRateLimitIdentifier('alvo@example.invalid'),
      );
      expect(identifier, matches(RegExp(r'^email:[0-9a-f]{64}$')));
      expect(identifier.toLowerCase(), isNot(contains('alvo')));
    });

    test('recuperação de senha tem bucket próprio por e-mail', () async {
      overrideCredentialEmailRateLimiterForTesting(
        RateLimiter(maxRequests: 1, windowSeconds: 900),
      );
      Database.useConnectionForTesting(
        ScriptedPool([
          scriptedResult(columns: const ['id', 'email']),
        ]),
      );

      final first = await forgot_password_route.onRequest(
        _forgotContext('alvo@example.invalid'),
      );
      final second = await forgot_password_route.onRequest(
        _forgotContext('ALVO@example.invalid'),
      );
      final body = jsonDecode(await second.body()) as Map<String, dynamic>;

      expect(first.statusCode, HttpStatus.accepted);
      expect(second.statusCode, HttpStatus.tooManyRequests);
      expect(body['rate_limit_bucket'], 'auth_recovery_email');
    });
  });
}

int _median(List<int> values) {
  final sorted = [...values]..sort();
  return sorted[sorted.length ~/ 2];
}

RequestContext _loginContext(
  Map<String, Object?> body, {
  String client = 'cliente-teste',
}) => ScriptedRequestContext(
  Request.post(
    Uri.parse('http://localhost/auth/login'),
    headers: {'content-type': 'application/json', 'user-agent': client},
    body: jsonEncode(body),
  ),
);

RequestContext _forgotContext(String email) => ScriptedRequestContext(
  Request.post(
    Uri.parse('http://localhost/auth/forgot-password'),
    headers: const {'content-type': 'application/json'},
    body: jsonEncode({'email': email}),
  ),
);
