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
import '../lib/beta_invites/beta_invite_issuance.dart';
import '../lib/beta_invites/beta_invite_policy.dart';
import '../lib/beta_invites/beta_invite_store.dart';
import '../lib/database.dart';
import '../lib/legal_policy.dart';
import '../lib/request_trace.dart';
import '../routes/auth/register.dart' as register_route;
import 'support/scripted_pool.dart';

/// BT-AUTH-006 contra PostgreSQL: emissão idempotente e cadastro por convite
/// com convite válido, inválido, expirado, revogado, replay e concorrência.
/// A negativa acontece antes de criar a conta; o aceite verifica o e-mail.
///
/// Requer `RUN_BETA_INVITE_DB_TESTS=1` e as variáveis `DB_*` de um banco
/// descartável já migrado (061).
void main() {
  final enabled = Platform.environment['RUN_BETA_INVITE_DB_TESTS'] == '1';
  final skipReason =
      enabled ? null : 'Requer PostgreSQL descartavel explicitamente isolado.';
  late Pool pool;
  final sent = <String, String>{};
  late BetaInviteIssuer issuer;

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
      // Várias conexões, como o pool da API: com uma só, as transações nunca
      // se sobrepõem e a corrida não aparece.
      settings: const PoolSettings(
        sslMode: SslMode.disable,
        maxConnectionCount: 10,
      ),
    );
    Database.useConnectionForTesting(pool);
    overrideRegistrationAdmissionForTesting(RegistrationAdmission.invite);
    issuer = BetaInviteIssuer(
      pool,
      deliver: ({
        required String email,
        required String code,
        required DateTime expiresAt,
      }) async {
        sent[email] = code;
        return true;
      },
    );
  });

  tearDownAll(() async {
    if (!enabled) return;
    overrideRegistrationAdmissionForTesting(null);
    Database.resetForTesting();
    await pool.close();
  });

  String unique(String prefix) =>
      '${prefix}_${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}';

  Future<String> invite(String email, {String batch = 'teste-db'}) async {
    final outcomes = await issuer.issue(
      await issuer.plan([email]),
      batchLabel: batch,
      validity: const Duration(days: 14),
      issuedBy: 'teste',
    );
    expect(outcomes.single.status, 'novo');
    return sent[email]!;
  }

  Future<(int, Map<String, dynamic>)> register(
    String email,
    Object? code, {
    String? username,
    String requestId = 'req-teste',
  }) async {
    final response = await register_route.onRequest(
      ScriptedRequestContext(
        Request.post(
          Uri.parse('http://localhost/auth/register'),
          headers: const {'content-type': 'application/json'},
          body: jsonEncode({
            'username': username ?? unique('conv'),
            'email': email,
            'password': 'Convite!Beta-2026',
            'legal_accepted': true,
            'terms_version': currentTermsVersion,
            'privacy_version': currentPrivacyVersion,
            if (code != null) 'invite_code': code,
          }),
        ),
        providers: {RequestTrace: RequestTrace(requestId: requestId)},
      ),
    );
    return (
      response.statusCode,
      jsonDecode(await response.body()) as Map<String, dynamic>,
    );
  }

  Future<int> accounts(String email) async =>
      (await pool.execute(
            Sql.named('SELECT COUNT(*)::int FROM users WHERE email = @email'),
            parameters: {'email': email},
          )).single[0]!
          as int;

  Future<List<String>> events(String email) async => [
    for (final row in await pool.execute(
      Sql.named('''
        SELECT e.event
        FROM beta_invite_events e
        JOIN beta_invites i ON i.id = e.invite_id
        WHERE i.email_digest = @digest
        ORDER BY e.id
      '''),
      parameters: {'digest': betaInviteEmailDigest(email)},
    ))
      row[0]! as String,
  ];

  group('emissão', () {
    test('simulação não grava; aplicar grava; repetir não duplica', () async {
      final email = '${unique('lote')}@example.invalid';
      final plan = await issuer.plan([email, email.toUpperCase(), 'invalido']);
      expect(plan.map((entry) => entry.action), [
        BetaInvitePlanAction.issue,
        BetaInvitePlanAction.duplicate,
        BetaInvitePlanAction.invalidEmail,
      ]);
      final before = await pool.execute(
        Sql.named(
          'SELECT COUNT(*)::int FROM beta_invites WHERE email_digest = @d',
        ),
        parameters: {'d': betaInviteEmailDigest(email)},
      );
      expect(before.single[0], 0, reason: 'o plano é só leitura');

      final first = await issuer.issue(
        plan,
        batchLabel: 'teste-db',
        validity: const Duration(days: 14),
        issuedBy: 'teste',
      );
      expect(first.first.status, 'novo');
      expect(first.first.delivery, BetaInviteDeliveryState.delivered);
      expect(sent[email], matches(RegExp(r'^[0-9A-Z]{4}(-[0-9A-Z]{4}){3}$')));
      final firstCode = sent[email];

      final again = await issuer.issue(
        await issuer.plan([email]),
        batchLabel: 'teste-db',
        validity: const Duration(days: 14),
        issuedBy: 'teste',
      );
      expect(again.single.status, 'ja_convidado');
      expect(sent[email], firstCode, reason: 'nenhum e-mail novo');
      final rows = await pool.execute(
        Sql.named('''
          SELECT COUNT(*)::int, bool_and(delivered_at IS NOT NULL),
                 bool_and(email_hint LIKE '%***@example.invalid')
          FROM beta_invites WHERE email_digest = @d
        '''),
        parameters: {'d': betaInviteEmailDigest(email)},
      );
      expect(rows.single, [1, true, true]);
      expect(await events(email), ['issued', 'delivered']);
    }, skip: skipReason);

    test('e-mail com conta ativa não recebe convite', () async {
      final email = '${unique('conta')}@example.invalid';
      await pool.execute(
        Sql.named('''
          INSERT INTO users (username, email, password_hash)
          VALUES (@u, @e, 'x')
        '''),
        parameters: {'u': unique('conta'), 'e': email},
      );
      final plan = await issuer.plan([email]);
      expect(plan.single.action, BetaInvitePlanAction.hasAccount);
    }, skip: skipReason);

    test('convite aberto expirado é substituído por um novo', () async {
      final email = '${unique('reemite')}@example.invalid';
      await invite(email);
      await pool.execute(
        Sql.named('''
          UPDATE beta_invites
          SET issued_at = issued_at - INTERVAL '30 days',
              expires_at = CURRENT_TIMESTAMP - INTERVAL '1 second'
          WHERE email_digest = @d
        '''),
        parameters: {'d': betaInviteEmailDigest(email)},
      );
      final plan = await issuer.plan([email]);
      expect(plan.single.action, BetaInvitePlanAction.reissue);
      final outcome = await issuer.issue(
        plan,
        batchLabel: 'teste-db',
        validity: const Duration(days: 14),
        issuedBy: 'teste',
      );
      expect(outcome.single.status, 'reemitir');
      final states = await pool.execute(
        Sql.named('''
          SELECT revoked_reason FROM beta_invites
          WHERE email_digest = @d ORDER BY issued_at
        '''),
        parameters: {'d': betaInviteEmailDigest(email)},
      );
      expect(states.map((row) => row[0]), [
        'substituido por novo convite',
        null,
      ]);
    }, skip: skipReason);
  });

  group('cadastro', () {
    test(
      'convite válido: conta criada, e-mail verificado, convite consumido',
      () async {
        final email = '${unique('valido')}@example.invalid';
        final code = await invite(email);

        final (status, body) = await register(
          email,
          code,
          requestId: 'req-valido',
        );

        expect(status, 201, reason: '$body');
        expect(body['admission'], 'invite');
        expect(body['verification_sent'], isFalse);
        final user = body['user'] as Map<String, dynamic>;
        expect(user['email_verified'], isTrue);
        final row = await pool.execute(
          Sql.named('''
          SELECT u.email_verified_at IS NOT NULL,
                 i.accepted_at IS NOT NULL,
                 i.accepted_user_id = u.id,
                 (SELECT COUNT(*)::int FROM email_verification_tokens t
                   WHERE t.user_id = u.id)
          FROM users u
          JOIN beta_invites i ON i.email_digest = @d
          WHERE u.id = CAST(@id AS uuid)
        '''),
          parameters: {'d': betaInviteEmailDigest(email), 'id': user['id']},
        );
        expect(row.single, [true, true, true, 0]);
        expect(await events(email), ['issued', 'delivered', 'accepted']);
        final audit = await pool.execute(
          Sql.named('''
          SELECT e.request_id, e.actor FROM beta_invite_events e
          JOIN beta_invites i ON i.id = e.invite_id
          WHERE i.email_digest = @d AND e.event = 'accepted'
        '''),
          parameters: {'d': betaInviteEmailDigest(email)},
        );
        expect(audit.single, ['req-valido', 'auth_register']);
      },
      skip: skipReason,
    );

    test('replay: o mesmo convite não cria segunda conta', () async {
      final email = '${unique('replay')}@example.invalid';
      final code = await invite(email);
      final (first, _) = await register(email, code);
      expect(first, 201);

      final (status, body) = await register(email, code);

      expect(status, 403);
      expect(body['error'], 'invite_already_used');
      expect(await accounts(email), 1);
      expect(await events(email), [
        'issued',
        'delivered',
        'accepted',
        'denied_used',
      ]);
    }, skip: skipReason);

    test('inválido: código inexistente e convite de outro e-mail', () async {
      final email = '${unique('invalido')}@example.invalid';
      final code = await invite(email);
      final other = '${unique('outro')}@example.invalid';

      final (unknown, unknownBody) = await register(email, newBetaInviteCode());
      final (mismatch, mismatchBody) = await register(other, code);

      expect(unknown, 403);
      expect(unknownBody['error'], 'invite_invalid');
      expect(mismatch, 403);
      expect(mismatchBody['error'], 'invite_invalid');
      expect(await accounts(email), 0);
      expect(await accounts(other), 0);
      expect(await events(email), [
        'issued',
        'delivered',
        'denied_email_mismatch',
      ]);
      // O convite continua valendo para o e-mail certo.
      final (status, _) = await register(email, code);
      expect(status, 201);
    }, skip: skipReason);

    test('expirado: negado, sem conta', () async {
      final email = '${unique('expirado')}@example.invalid';
      final code = await invite(email);
      await pool.execute(
        Sql.named('''
          UPDATE beta_invites
          SET issued_at = issued_at - INTERVAL '30 days',
              expires_at = CURRENT_TIMESTAMP - INTERVAL '1 second'
          WHERE email_digest = @d
        '''),
        parameters: {'d': betaInviteEmailDigest(email)},
      );

      final (status, body) = await register(email, code);

      expect(status, 403);
      expect(body['error'], 'invite_expired');
      expect(await accounts(email), 0);
      expect(await events(email), ['issued', 'delivered', 'denied_expired']);
    }, skip: skipReason);

    test(
      'revogado: negado, sem conta; revogar de novo não muda nada',
      () async {
        final email = '${unique('revogado')}@example.invalid';
        final code = await invite(email);
        final revoked = await issuer.revoke(
          email: email,
          reason: 'pedido do dono',
          actor: 'teste',
        );
        expect(revoked.status, 'revogado');
        final again = await issuer.revoke(
          email: email,
          reason: 'pedido do dono',
          actor: 'teste',
        );
        expect(again.status, 'sem_convite_aberto');

        final (status, body) = await register(email, code);

        expect(status, 403);
        expect(body['error'], 'invite_revoked');
        expect(await accounts(email), 0);
        expect(await events(email), [
          'issued',
          'delivered',
          'revoked',
          'denied_revoked',
        ]);
      },
      skip: skipReason,
    );

    test('concorrência: 10 cadastros ao mesmo tempo, uma conta só', () async {
      final email = '${unique('corrida')}@example.invalid';
      final code = await invite(email);

      final results = await Future.wait([
        for (var i = 0; i < 10; i++)
          register(email, code, username: unique('corrida$i')),
      ]);

      final statuses = results.map((result) => result.$1).toList();
      expect(statuses.where((status) => status == 201), hasLength(1));
      expect(
        results
            .where((result) => result.$1 != 201)
            .map((result) => result.$2['error'])
            .toSet(),
        {'invite_already_used'},
      );
      expect(await accounts(email), 1);
      final accepted = (await events(email)).where((e) => e == 'accepted');
      expect(accepted, hasLength(1));
    }, skip: skipReason);

    test(
      'trava: o segundo aceite espera o primeiro e encontra o convite usado',
      () async {
        // A corrida acima prova o resultado; esta prova o mecanismo, com as duas
        // transações abertas ao mesmo tempo, na ordem que o teste escolhe.
        final email = '${unique('trava')}@example.invalid';
        final code = normalizeBetaInviteCode(await invite(email))!;
        final user = await pool.execute(
          Sql.named('''
          INSERT INTO users (username, email, password_hash)
          VALUES (@u, @e, 'x') RETURNING id::text
        '''),
          parameters: {'u': unique('trava'), 'e': email},
        );
        final userId = user.single[0]! as String;
        final firstLocked = Completer<void>();
        final release = Completer<void>();
        // Se uma expectativa falhar no meio, a primeira transação ainda precisa
        // terminar; senão o pool nunca fecha.
        addTearDown(() {
          if (!release.isCompleted) release.complete();
        });

        final first = pool.runTx((tx) async {
          final inviteId = await BetaInviteAdmission.lockForAcceptance(
            tx,
            code: code,
            email: email,
          );
          firstLocked.complete();
          await release.future;
          await BetaInviteAdmission.markAccepted(
            tx,
            inviteId: inviteId,
            userId: userId,
          );
        });
        await firstLocked.future;
        var secondFinished = false;
        final second = pool
            .runTx(
              (tx) => BetaInviteAdmission.lockForAcceptance(
                tx,
                code: code,
                email: email,
              ),
            )
            .whenComplete(() => secondFinished = true);
        await Future<void>.delayed(const Duration(milliseconds: 400));
        expect(secondFinished, isFalse, reason: 'a segunda espera a trava');

        release.complete();
        await first;
        await expectLater(
          second,
          throwsA(
            isA<BetaInviteDeniedException>().having(
              (error) => error.denial,
              'denial',
              BetaInviteDenial.alreadyUsed,
            ),
          ),
        );
      },
      skip: skipReason,
    );

    test('marcar aceito de novo falha, mesmo sem a trava', () async {
      final email = '${unique('duplo')}@example.invalid';
      final code = await invite(email);
      final (status, body) = await register(email, code);
      expect(status, 201);
      final userId = (body['user'] as Map<String, dynamic>)['id'] as String;
      final inviteId =
          (await pool.execute(
                Sql.named(
                  'SELECT id::text FROM beta_invites WHERE email_digest = @d',
                ),
                parameters: {'d': betaInviteEmailDigest(email)},
              )).single[0]!
              as String;

      await expectLater(
        pool.runTx(
          (tx) => BetaInviteAdmission.markAccepted(
            tx,
            inviteId: inviteId,
            userId: userId,
          ),
        ),
        throwsA(isA<BetaInviteDeniedException>()),
      );
    }, skip: skipReason);

    test('reenviar troca o código: o antigo deixa de valer', () async {
      final email = '${unique('reenvio')}@example.invalid';
      final oldCode = await invite(email);
      final resent = await issuer.resend(
        email,
        validity: const Duration(days: 7),
        issuedBy: 'teste',
      );
      expect(resent.status, 'reenviado');
      final newCode = sent[email]!;
      expect(newCode, isNot(oldCode));

      final (old, oldBody) = await register(email, oldCode);
      expect(old, 403);
      expect(oldBody['error'], 'invite_invalid');
      final (status, _) = await register(email, newCode);
      expect(status, 201);
    }, skip: skipReason);

    test(
      'modo invite sem convite: negado antes de qualquer escrita',
      () async {
        final email = '${unique('semconvite')}@example.invalid';
        final usersBefore = await pool.execute(
          'SELECT COUNT(*)::int FROM users',
        );

        final (status, body) = await register(email, null);

        expect(status, 403);
        expect(body['error'], 'invite_required');
        final usersAfter = await pool.execute(
          'SELECT COUNT(*)::int FROM users',
        );
        expect(usersAfter.single[0], usersBefore.single[0]);
      },
      skip: skipReason,
    );
  });
}
