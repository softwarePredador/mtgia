@Tags(['live', 'live_db_write'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import '../bin/migrate.dart' as migrate;
import '../lib/auth_service.dart';
import '../lib/beta_invites/beta_invite_admission_gate.dart';
import '../lib/beta_invites/beta_invite_policy.dart';
import '../lib/database.dart';
import '../lib/legal_acceptance_middleware.dart';
import '../lib/legal_acceptance_service.dart';
import '../lib/legal_policy.dart';
import '../lib/request_trace.dart';
import '../lib/sql_statement_splitter.dart';
import '../routes/auth/register.dart' as register_route;
import '../routes/decks/_middleware.dart' as decks_middleware;
import 'support/scripted_pool.dart';

/// BT-LEGAL-ACCEPT-001 contra PostgreSQL (migration 062): histórico de
/// aceites (retrato inicial, cadastro e reaceite), aceite idempotente e sob
/// concorrência, e a trava do reaceite pelo middleware real de `/decks`.
///
/// Requer `RUN_LEGAL_ACCEPTANCE_DB_TESTS=1` e as variáveis `DB_*` de um banco
/// descartável já migrado (062).
void main() {
  final enabled = Platform.environment['RUN_LEGAL_ACCEPTANCE_DB_TESTS'] == '1';
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
      settings: const PoolSettings(
        sslMode: SslMode.disable,
        maxConnectionCount: 10,
      ),
    );
    Database.useConnectionForTesting(pool);
    overrideRegistrationAdmissionForTesting(RegistrationAdmission.open);
  });

  tearDownAll(() async {
    if (!enabled) return;
    overrideRegistrationAdmissionForTesting(null);
    overrideLegalReacceptanceForTesting(null);
    Database.resetForTesting();
    await pool.close();
  });

  tearDown(() => overrideLegalReacceptanceForTesting(null));

  String unique(String prefix) =>
      '${prefix}_${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}';

  Future<String> insertUser({String? terms, String? privacy}) async {
    final rows = await pool.execute(
      Sql.named('''
        INSERT INTO users (
          username, email, password_hash,
          terms_version, terms_accepted_at, privacy_version, privacy_accepted_at
        ) VALUES (
          @username, @email, 'x',
          CAST(@terms AS text),
          CASE WHEN CAST(@terms AS text) IS NULL THEN NULL
            ELSE CURRENT_TIMESTAMP END,
          CAST(@privacy AS text),
          CASE WHEN CAST(@privacy AS text) IS NULL THEN NULL
            ELSE CURRENT_TIMESTAMP END
        )
        RETURNING id::text
      '''),
      parameters: {
        'username': unique('legal'),
        'email': '${unique('legal')}@example.invalid',
        'terms': terms,
        'privacy': privacy,
      },
    );
    return rows.single[0]! as String;
  }

  Future<List<List<Object?>>> history(String userId) async {
    final rows = await pool.execute(
      Sql.named('''
        SELECT terms_version, privacy_version, source, request_id
        FROM user_legal_acceptances
        WHERE user_id = CAST(@userId AS uuid)
        ORDER BY id
      '''),
      parameters: {'userId': userId},
    );
    return [for (final row in rows) row.toList()];
  }

  test(
    'retrato inicial da 062: uma linha por conta com aceite, idempotente',
    () async {
      final accepted = await insertUser(
        terms: '2026-01-01',
        privacy: '2026-01-02',
      );
      final never = await insertUser();
      // Conta excluída não entra no retrato (e a trava de conta ativa
      // recusaria a linha).
      final deleted = await insertUser(
        terms: '2026-01-01',
        privacy: '2026-01-02',
      );
      await pool.execute(
        Sql.named(
          'UPDATE users SET deleted_at = CURRENT_TIMESTAMP '
          'WHERE id = CAST(@id AS uuid)',
        ),
        parameters: {'id': deleted},
      );
      final migration = migrate.migrations.singleWhere(
        (m) => m.version == '062',
      );

      // Duas vezes, como o migrate.dart roda (comando a comando): o up é
      // idempotente e o retrato não duplica.
      for (var round = 0; round < 2; round++) {
        for (final statement in splitPostgresStatements(migration.up)) {
          await pool.execute(statement);
        }
      }

      expect(await history(accepted), [
        ['2026-01-01', '2026-01-02', 'backfill', null],
      ]);
      expect(await history(never), isEmpty);
      expect(await history(deleted), isEmpty);
    },
    skip: skipReason,
  );

  test('a 062 devolve a trava de conta ativa à chave de beta_invites (061) e a '
      'tabela nova recusa conta excluída', () async {
    // Chaves de uma coluna para users sem o trigger de conta ativa
    // (manaloom_active_user_<oid da chave>, migration 038).
    Future<List<String>> keysWithoutTrigger() async {
      final rows = await pool.execute('''
          SELECT constraint_row.conrelid::regclass::text
          FROM pg_constraint constraint_row
          WHERE constraint_row.contype = 'f'
            AND constraint_row.confrelid = 'users'::regclass
            AND array_length(constraint_row.conkey, 1) = 1
            AND NOT EXISTS (
              SELECT 1
              FROM pg_trigger trigger_row
              WHERE trigger_row.tgrelid = constraint_row.conrelid
                AND NOT trigger_row.tgisinternal
                AND trigger_row.tgname =
                  'manaloom_active_user_' || constraint_row.oid
            )
          ORDER BY 1
        ''');
      return [for (final row in rows) row[0]! as String];
    }

    final migration = migrate.migrations.singleWhere((m) => m.version == '062');
    Future<void> runUp() async {
      for (final statement in splitPostgresStatements(migration.up)) {
        await pool.execute(statement);
      }
    }

    // Se o teste cair no meio, o laço da 062 devolve o trigger.
    addTearDown(runUp);

    // Banco migrado até a 061: a chave de beta_invites nasceu sem a trava
    // (a 061 não refez o laço da 038).
    final inviteTrigger = await pool.execute('''
        SELECT tgname
        FROM pg_trigger
        WHERE tgrelid = 'public.beta_invites'::regclass
          AND NOT tgisinternal
          AND left(tgname, 21) = 'manaloom_active_user_'
      ''');
    expect(inviteTrigger, hasLength(1));
    await pool.execute(
      'DROP TRIGGER "${inviteTrigger.single[0]}" ON public.beta_invites',
    );
    expect(await keysWithoutTrigger(), ['beta_invites']);

    await runUp();
    expect(await keysWithoutTrigger(), isEmpty);

    // E a trava funciona nas duas tabelas: conta excluída não entra.
    final deleted = await insertUser(
      terms: currentTermsVersion,
      privacy: currentPrivacyVersion,
    );
    await pool.execute(
      Sql.named(
        'UPDATE users SET deleted_at = CURRENT_TIMESTAMP '
        'WHERE id = CAST(@id AS uuid)',
      ),
      parameters: {'id': deleted},
    );
    Future<void> expectInactiveRefusal(Future<Object?> write) async {
      await expectLater(
        write,
        throwsA(
          isA<ServerException>()
              .having((error) => error.code, 'code', '23503')
              .having(
                (error) => error.message,
                'message',
                contains('inactive_user_reference'),
              ),
        ),
      );
    }

    await expectInactiveRefusal(
      pool.execute(
        Sql.named('''
            INSERT INTO beta_invites (
              batch_label, email_digest, email_hint, token_hash, issued_by,
              expires_at, accepted_at, accepted_user_id
            ) VALUES (
              'teste-legal',
              encode(sha256(convert_to(gen_random_uuid()::text, 'UTF8')), 'hex'),
              'e***@example.invalid',
              encode(sha256(convert_to(gen_random_uuid()::text, 'UTF8')), 'hex'),
              'teste',
              CURRENT_TIMESTAMP + INTERVAL '1 day',
              CURRENT_TIMESTAMP,
              CAST(@userId AS uuid)
            )
          '''),
        parameters: {'userId': deleted},
      ),
    );
    await expectInactiveRefusal(
      pool.execute(
        Sql.named('''
            INSERT INTO user_legal_acceptances (
              user_id, terms_version, privacy_version, source
            ) VALUES (CAST(@userId AS uuid), 'a', 'b', 'reaccept')
          '''),
        parameters: {'userId': deleted},
      ),
    );
  }, skip: skipReason);

  test('cadastro grava o aceite no histórico, com o request-id', () async {
    final email = '${unique('cadastro')}@example.invalid';
    final response = await register_route.onRequest(
      ScriptedRequestContext(
        Request.post(
          Uri.parse('http://localhost/auth/register'),
          headers: const {'content-type': 'application/json'},
          body: jsonEncode({
            'username': unique('cadastro'),
            'email': email,
            'password': 'Convite!Beta-2026',
            'legal_accepted': true,
            'terms_version': currentTermsVersion,
            'privacy_version': currentPrivacyVersion,
          }),
        ),
        providers: {RequestTrace: RequestTrace(requestId: 'req-cadastro')},
      ),
    );
    expect(response.statusCode, 201, reason: await response.body());
    final user = await pool.execute(
      Sql.named('SELECT id::text FROM users WHERE email = @email'),
      parameters: {'email': email},
    );
    expect(await history(user.single[0]! as String), [
      [currentTermsVersion, currentPrivacyVersion, 'register', 'req-cadastro'],
    ]);
  }, skip: skipReason);

  test('reaceite grava uma linha; aceitar de novo não duplica', () async {
    final userId = await insertUser(
      terms: '2026-01-01',
      privacy: currentPrivacyVersion,
    );
    final service = LegalAcceptanceService(pool);
    expect((await service.status(userId))!.upToDate, isFalse);

    const acceptance = LegalAcceptance(
      termsVersion: currentTermsVersion,
      privacyVersion: currentPrivacyVersion,
    );
    final first = await service.accept(userId, acceptance, requestId: 'r1');
    final again = await service.accept(userId, acceptance, requestId: 'r2');

    expect(first!.upToDate, isTrue);
    expect(again!.upToDate, isTrue);
    expect((await service.status(userId))!.upToDate, isTrue);
    expect(await history(userId), [
      [currentTermsVersion, currentPrivacyVersion, 'reaccept', 'r1'],
    ]);
  }, skip: skipReason);

  test('dez aceites simultâneos: uma linha só no histórico', () async {
    final userId = await insertUser();
    const acceptance = LegalAcceptance(
      termsVersion: currentTermsVersion,
      privacyVersion: currentPrivacyVersion,
    );
    await Future.wait([
      for (var i = 0; i < 10; i++)
        LegalAcceptanceService(pool).accept(userId, acceptance),
    ]);
    expect(await history(userId), hasLength(1));
  }, skip: skipReason);

  test('conta excluída não aceita nem aparece', () async {
    final userId = await insertUser(terms: '2026-01-01', privacy: '2026-01-01');
    await pool.execute(
      Sql.named(
        'UPDATE users SET deleted_at = CURRENT_TIMESTAMP '
        'WHERE id = CAST(@id AS uuid)',
      ),
      parameters: {'id': userId},
    );
    final service = LegalAcceptanceService(pool);
    expect(await service.status(userId), isNull);
    expect(
      await service.accept(
        userId,
        const LegalAcceptance(
          termsVersion: currentTermsVersion,
          privacyVersion: currentPrivacyVersion,
        ),
      ),
      isNull,
    );
    expect(await history(userId), isEmpty);
  }, skip: skipReason);

  test(
    'middleware real de /decks: bloqueia versão antiga até o reaceite',
    () async {
      overrideLegalReacceptanceForTesting(true);
      final userId = await insertUser(
        terms: '2026-01-01',
        privacy: currentPrivacyVersion,
      );
      final username =
          (await pool.execute(
                Sql.named(
                  'SELECT username FROM users WHERE id = CAST(@id AS uuid)',
                ),
                parameters: {'id': userId},
              )).single[0]!
              as String;
      final token = AuthService().generateToken(userId, username);
      var created = 0;
      // O Cascade cria um RequestContext de verdade: o id da conta que o
      // authMiddleware põe no contexto chega à trava do reaceite.
      final handler =
          Cascade()
              .add(
                decks_middleware
                    .middleware((_) {
                      created++;
                      return Response.json(
                        statusCode: 201,
                        body: const {'ok': true},
                      );
                    })
                    .use(provider<Pool>((_) => pool)),
              )
              .handler;

      Future<Response> post(String path) async => handler(
        ScriptedRequestContext(
          Request.post(
            Uri.parse('http://localhost$path'),
            headers: {'Authorization': 'Bearer $token'},
            body: '{}',
          ),
        ),
      );

      final blocked = await post('/decks');
      expect(blocked.statusCode, 403);
      final body = jsonDecode(await blocked.body()) as Map<String, dynamic>;
      expect(body['error'], 'legal_acceptance_required');
      expect(created, 0);

      // Editar o que já existe segue livre.
      final edit = await handler(
        ScriptedRequestContext(
          Request.put(
            Uri.parse('http://localhost/decks/d1'),
            headers: {'Authorization': 'Bearer $token'},
            body: '{}',
          ),
        ),
      );
      expect(edit.statusCode, 201);

      await LegalAcceptanceService(pool).accept(
        userId,
        const LegalAcceptance(
          termsVersion: currentTermsVersion,
          privacyVersion: currentPrivacyVersion,
        ),
      );
      final allowed = await post('/decks');
      expect(allowed.statusCode, 201);
      expect(created, 2);
    },
    skip: skipReason,
  );
}
