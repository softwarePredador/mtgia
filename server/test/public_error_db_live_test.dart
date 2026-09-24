@Tags(['live', 'live_db_write'])
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import '../lib/auth_service.dart';
import '../lib/beta_invites/beta_invite_admission_gate.dart';
import '../lib/beta_invites/beta_invite_policy.dart';
import '../lib/database.dart';
import '../lib/legal_policy.dart';
import '../lib/request_trace.dart';
import '../routes/auth/register.dart' as register_route;
import 'support/scripted_pool.dart';

/// BT-AUTH-001 contra PostgreSQL: dois cadastros ao mesmo tempo com o mesmo
/// e-mail (ou nome). O segundo passa da checagem de leitura, porque o
/// primeiro ainda não commitou, e bate no índice único. A recusa sai como 400
/// com código estável, nunca com o texto do PostgreSQL.
///
/// Requer `RUN_PUBLIC_ERROR_DB_TESTS=1` e as variáveis `DB_*` de um banco
/// descartável já migrado.
void main() {
  final enabled = Platform.environment['RUN_PUBLIC_ERROR_DB_TESTS'] == '1';
  final skipReason =
      enabled ? null : 'Requer PostgreSQL descartavel explicitamente isolado.';
  late Pool pool;

  setUpAll(() {
    if (!enabled) return;
    AuthService.resetForTesting();
    pool = Pool.withEndpoints(
      [
        Endpoint(
          host: Platform.environment['DB_HOST'] ?? '127.0.0.1',
          port: int.parse(Platform.environment['DB_PORT'] ?? '5432'),
          database: Platform.environment['DB_NAME']!,
          username: Platform.environment['DB_USER']!,
          password: Platform.environment['DB_PASS'] ?? '',
        ),
      ],
      // A transação que segura a linha, o cadastro e a consulta que observa
      // a espera precisam de conexões diferentes.
      settings: const PoolSettings(
        sslMode: SslMode.disable,
        maxConnectionCount: 6,
      ),
    );
    Database.useConnectionForTesting(pool);
    overrideRegistrationAdmissionForTesting(RegistrationAdmission.open);
  });

  tearDownAll(() async {
    if (!enabled) return;
    overrideRegistrationAdmissionForTesting(null);
    Database.resetForTesting();
    await pool.close();
  });

  String unique(String prefix) =>
      '${prefix}_${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}';

  Future<(int, String)> register({
    required String username,
    required String email,
  }) async {
    final response = await register_route.onRequest(
      ScriptedRequestContext(
        Request.post(
          Uri.parse('http://localhost/auth/register'),
          headers: const {'content-type': 'application/json'},
          body: jsonEncode({
            'username': username,
            'email': email,
            'password': 'Convite!Beta-2026',
            'legal_accepted': true,
            'terms_version': currentTermsVersion,
            'privacy_version': currentPrivacyVersion,
          }),
        ),
        providers: {RequestTrace: RequestTrace(requestId: 'req-corrida')},
      ),
    );
    return (response.statusCode, await response.body());
  }

  /// Espera o cadastro ficar parado no índice único (esperando a trava da
  /// linha que a outra transação inseriu e ainda não commitou).
  Future<void> waitForBlockedInsert() async {
    final deadline = DateTime.now().add(const Duration(seconds: 15));
    while (DateTime.now().isBefore(deadline)) {
      final waiting = await pool.execute('''
        SELECT COUNT(*)::int
        FROM pg_stat_activity
        WHERE datname = current_database()
          AND wait_event_type = 'Lock'
          AND query ILIKE '%INSERT INTO users%'
      ''');
      if ((waiting.single[0]! as int) > 0) return;
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    fail('o cadastro não chegou a esperar no índice único');
  }

  for (final (label, sameEmail) in [('e-mail', true), ('nome', false)]) {
    test(
      'corrida no mesmo $label: 400 auth_account_taken, sem texto do banco',
      () async {
        final holderUsername = unique('dono');
        final holderEmail = '${unique('dono')}@example.invalid';
        final username = sameEmail ? unique('segundo') : holderUsername;
        final email =
            sameEmail ? holderEmail : '${unique('segundo')}@example.invalid';
        final inserted = Completer<void>();
        final release = Completer<void>();
        // Se uma expectativa falhar no meio, a transação ainda precisa
        // terminar; senão o pool nunca fecha.
        addTearDown(() {
          if (!release.isCompleted) release.complete();
        });

        final holder = pool.runTx((tx) async {
          await tx.execute(
            Sql.named('''
              INSERT INTO users (username, email, password_hash)
              VALUES (@username, @email, 'x')
            '''),
            parameters: {'username': holderUsername, 'email': holderEmail},
          );
          inserted.complete();
          await release.future;
        });
        await inserted.future;

        final registration = register(username: username, email: email);
        await waitForBlockedInsert();
        release.complete();
        await holder;
        final (status, text) = await registration;

        expect(status, HttpStatus.badRequest, reason: text);
        expect(jsonDecode(text), {
          'message': 'Nome de usuário ou email já está em uso',
          'code': 'auth_account_taken',
        });
        for (final fragment in [
          'Severity',
          '23505',
          'duplicate key',
          'constraint',
          'Exception',
        ]) {
          expect(text, isNot(contains(fragment)), reason: fragment);
        }
        final accounts = await pool.execute(
          Sql.named('''
            SELECT COUNT(*)::int FROM users
            WHERE email IN (@holderEmail, @email)
          '''),
          parameters: {'holderEmail': holderEmail, 'email': email},
        );
        expect(accounts.single[0], 1, reason: 'só a conta que commitou');
      },
      skip: skipReason,
    );
  }
}
