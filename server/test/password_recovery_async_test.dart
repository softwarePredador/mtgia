import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:test/test.dart';

import '../lib/auth_service.dart';
import '../lib/database.dart';
import '../lib/password_recovery_dispatcher.dart';
import '../routes/auth/forgot-password.dart' as forgot_password_route;
import 'support/scripted_pool.dart';

const _publicBody = {
  'message':
      'Se o email estiver cadastrado, enviaremos as instruções de recuperação.',
};
const _knownEmail = 'recupera@example.invalid';
const _userId = '77777777-7777-4777-8777-777777777777';

/// BT-AUTH-003, o que faltava depois do login (D-21): `POST
/// /auth/forgot-password` não espera nada que dependa da conta. Achar a
/// conta, criar o token e entregar o e-mail rodam depois da resposta; a
/// falha fica registrada e não chega ao cliente.
void main() {
  setUpAll(AuthService.resetForTesting);

  setUp(() => overridePasswordResetTokenExposureForTesting(false));

  tearDown(() {
    overridePasswordRecoveryDispatcherForTesting(null);
    overridePasswordResetTokenExposureForTesting(null);
    Database.resetForTesting();
  });

  /// Pool do `createPasswordResetRequest` real: a busca da conta e, se ela
  /// existe, a transação que trava a conta e troca o token.
  ScriptedPool accountPool({required bool exists}) => ScriptedPool([
    scriptedResult(
      columns: const ['id', 'email'],
      rows: [
        if (exists) [_userId, _knownEmail],
      ],
    ),
    if (exists)
      scriptedResult(
        columns: const ['id'],
        rows: [
          [_userId],
        ],
      ),
    if (exists) scriptedResult(),
    if (exists) scriptedResult(),
  ]);

  test('com ou sem conta, nada da conta acontece antes da resposta', () async {
    final delivered = <PasswordResetRequest>[];
    final pending = <Future<void> Function()>[];
    overridePasswordRecoveryDispatcherForTesting(
      (_) => PasswordRecoveryDispatcher(
        createRequest:
            (email) => AuthService().createPasswordResetRequest(email: email),
        deliver: (request) async {
          delivered.add(request);
          return true;
        },
        reportFailure: (error, _) async => fail('falha inesperada: $error'),
        scheduler: pending.add,
      ),
    );

    for (final (email, exists) in const [
      (_knownEmail, true),
      ('ninguem@example.invalid', false),
    ]) {
      final pool = accountPool(exists: exists);
      Database.useConnectionForTesting(pool);
      pending.clear();
      delivered.clear();

      final response = await forgot_password_route.onRequest(_context(email));

      expect(response.statusCode, HttpStatus.accepted, reason: email);
      expect(jsonDecode(await response.body()), _publicBody, reason: email);
      expect(pool.executedCount, 0, reason: 'banco antes da resposta: $email');
      expect(pending, hasLength(1), reason: email);

      await pending.single();
      expect(pool.exhausted, isTrue, reason: email);
      expect(delivered, hasLength(exists ? 1 : 0), reason: email);
      if (exists) {
        expect(delivered.single.email, _knownEmail);
        expect(delivered.single.token, isNotEmpty);
      }
    }
  });

  test('a resposta não espera a entrega do e-mail', () async {
    final neverDelivered = Completer<bool>();
    overridePasswordRecoveryDispatcherForTesting(
      (_) => PasswordRecoveryDispatcher(
        createRequest: (email) async => _request(email),
        deliver: (_) => neverDelivered.future,
        reportFailure: (error, _) async => fail('falha inesperada: $error'),
        scheduler: (work) => unawaited(work()),
      ),
    );

    final response = await forgot_password_route
        .onRequest(_context(_knownEmail))
        .timeout(const Duration(seconds: 5));

    expect(response.statusCode, HttpStatus.accepted);
    expect(jsonDecode(await response.body()), _publicBody);
    expect(neverDelivered.isCompleted, isFalse);
  });

  test('falha na entrega fica registrada e não vaza', () async {
    final failures = <Object>[];
    final pending = <Future<void> Function()>[];
    overridePasswordRecoveryDispatcherForTesting(
      (_) => PasswordRecoveryDispatcher(
        createRequest: (email) async => _request(email),
        deliver:
            (_) async =>
                throw Exception('smtp 10.0.0.9 recusou; token=segredo-123'),
        reportFailure: (error, _) async => failures.add(error),
        scheduler: pending.add,
      ),
    );

    final response = await forgot_password_route.onRequest(
      _context(_knownEmail),
    );
    final text = await response.body();
    await pending.single();

    expect(response.statusCode, HttpStatus.accepted);
    expect(jsonDecode(text), _publicBody);
    expect(text, isNot(contains('10.0.0.9')));
    expect(failures, hasLength(1));
    expect(failures.single.toString(), contains('10.0.0.9'));
  });

  test('falha ao criar o token também fica registrada', () async {
    final failures = <Object>[];
    final pending = <Future<void> Function()>[];
    overridePasswordRecoveryDispatcherForTesting(
      (_) => PasswordRecoveryDispatcher(
        createRequest: (_) async => throw StateError('banco fora'),
        deliver: (_) async => fail('não deveria entregar'),
        reportFailure: (error, _) async => failures.add(error),
        scheduler: pending.add,
      ),
    );

    final response = await forgot_password_route.onRequest(
      _context(_knownEmail),
    );
    await pending.single();

    expect(jsonDecode(await response.body()), _publicBody);
    expect(failures.single, isA<StateError>());
  });

  test('o agendador padrão começa depois de a rota devolver', () async {
    final started = <String>[];
    final dispatcher = PasswordRecoveryDispatcher(
      createRequest: (email) async {
        started.add(email);
        return null;
      },
      deliver: (_) async => true,
      reportFailure: (error, _) async => fail('falha inesperada: $error'),
    );

    dispatcher.dispatch(_knownEmail);
    expect(started, isEmpty, reason: 'nada roda dentro da requisição');

    await Future<void>.delayed(Duration.zero);
    expect(started, [_knownEmail]);
  });

  test('a troca de token trava a conta antes de consumir o anterior', () async {
    final pool = accountPool(exists: true);
    Database.useConnectionForTesting(pool);

    final request = await AuthService().createPasswordResetRequest(
      email: _knownEmail,
    );

    expect(request?.email, _knownEmail);
    expect(pool.queries, hasLength(4));
    expect(pool.queries[1], contains('FROM users'));
    expect(
      pool.queries[1],
      matches(RegExp(r'^\s*FOR UPDATE\s*$', multiLine: true)),
    );
    expect(pool.queries[2], contains('UPDATE password_reset_tokens'));
    expect(pool.queries[3], contains('INSERT INTO password_reset_tokens'));
  });

  test('conta apagada entre a busca e a trava não ganha token', () async {
    final pool = ScriptedPool([
      scriptedResult(
        columns: const ['id', 'email'],
        rows: [
          [_userId, _knownEmail],
        ],
      ),
      scriptedResult(columns: const ['id']),
    ]);
    Database.useConnectionForTesting(pool);

    final request = await AuthService().createPasswordResetRequest(
      email: _knownEmail,
    );

    expect(request, isNull);
    expect(pool.exhausted, isTrue, reason: 'nem UPDATE nem INSERT');
  });

  test('modo de teste leva o token e ainda entrega depois', () async {
    overridePasswordResetTokenExposureForTesting(true);
    final delivered = <PasswordResetRequest>[];
    final pending = <Future<void> Function()>[];
    overridePasswordRecoveryDispatcherForTesting(
      (_) => PasswordRecoveryDispatcher(
        createRequest:
            (email) async => email == _knownEmail ? _request(email) : null,
        deliver: (request) async {
          delivered.add(request);
          return true;
        },
        reportFailure: (error, _) async => fail('falha inesperada: $error'),
        scheduler: pending.add,
      ),
    );

    final known = await forgot_password_route.onRequest(_context(_knownEmail));
    final knownBody = jsonDecode(await known.body()) as Map<String, dynamic>;
    expect(knownBody['test_reset_token'], 'token-$_knownEmail');
    expect(delivered, isEmpty);
    expect(pending, hasLength(1));
    await pending.single();
    expect(delivered, hasLength(1));

    pending.clear();
    final unknown = await forgot_password_route.onRequest(
      _context('ninguem@example.invalid'),
    );
    expect(jsonDecode(await unknown.body()), _publicBody);
    expect(pending, isEmpty);
  });
}

PasswordResetRequest _request(String email) => PasswordResetRequest(
  email: email,
  token: 'token-$email',
  expiresAt: DateTime.utc(2026, 9, 23, 12),
);

RequestContext _context(String email) => ScriptedRequestContext(
  Request.post(
    Uri.parse('http://localhost/auth/forgot-password'),
    headers: const {'content-type': 'application/json'},
    body: jsonEncode({'email': email}),
  ),
);
