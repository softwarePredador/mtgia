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

/// O script do dono (`server/bin/beta_invites.dart`, BT-AUTH-006, BT-COH-001)
/// de ponta a ponta contra um PostgreSQL descartável em loopback: o processo
/// real, com os argumentos e o ambiente que o dono usa, e a entrega por um
/// webhook de teste em loopback (nenhum e-mail real sai).
///
/// Cobre a simulação (nada gravado nem enviado), o bloqueio sem aprovação e
/// sem entrega pronta, a emissão de um lote com a idempotência da repetição,
/// o convite expirado (listar e reemitir) e o convite usado (o código que
/// chegou pelo webhook cria a conta; depois o script não convida de novo,
/// não reenvia e não revoga).
///
/// Requer `RUN_BETA_INVITE_CLI_DB_TESTS=1` e as variáveis `DB_*` de um banco
/// descartável já migrado (061 ou depois), em loopback.
void main() {
  final enabled = Platform.environment['RUN_BETA_INVITE_CLI_DB_TESTS'] == '1';
  final skipReason =
      enabled ? null : 'Requer PostgreSQL descartavel explicitamente isolado.';
  const approval = 'I_HAVE_EXPLICIT_APPROVAL';
  const appUrl = 'https://app.example.test/app/#/register';

  late Pool pool;
  late Directory scratch;
  late String kernel;
  late HttpServer sink;
  final delivered = <Map<String, dynamic>>[];

  setUpAll(() async {
    if (!enabled) return;
    final env = Platform.environment;
    final host = (env['DB_HOST'] ?? '').trim().toLowerCase();
    // O túnel do wrapper da produção também é 127.0.0.1: o marcador dele e
    // qualquer host fora do loopback recusam o teste antes de conectar.
    if (!{'127.0.0.1', 'localhost', '::1'}.contains(host) ||
        env.containsKey('MANALOOM_PG_WRAPPER_MODE')) {
      fail(
        'beta_invites_cli_db_live_test só roda em banco descartável em '
        'loopback, nunca pelo wrapper da produção',
      );
    }
    AuthService.resetForTesting();
    pool = Pool.withEndpoints(
      [
        Endpoint(
          host: env['DB_HOST']!,
          port: int.parse(env['DB_PORT'] ?? '5432'),
          database: env['DB_NAME']!,
          username: env['DB_USER']!,
          password: env['DB_PASS'] ?? '',
        ),
      ],
      settings: const PoolSettings(
        sslMode: SslMode.disable,
        maxConnectionCount: 4,
      ),
    );
    Database.useConnectionForTesting(pool);
    overrideRegistrationAdmissionForTesting(RegistrationAdmission.invite);

    // O script roda compilado, num diretório vazio: nenhum `.env` do checkout
    // entra no processo, só o ambiente que o teste passa.
    scratch = await Directory.systemTemp.createTemp('beta_invites_cli_');
    kernel = '${scratch.path}/beta_invites.dill';
    final compiled = await Process.run(Platform.resolvedExecutable, [
      'compile',
      'kernel',
      'bin/beta_invites.dart',
      '-o',
      kernel,
    ]);
    if (compiled.exitCode != 0) {
      fail('não compilou bin/beta_invites.dart: ${compiled.stderr}');
    }

    sink = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    sink.listen((request) async {
      final body = await utf8.decoder.bind(request).join();
      delivered.add(jsonDecode(body) as Map<String, dynamic>);
      request.response.statusCode = HttpStatus.accepted;
      await request.response.close();
    });
  });

  tearDownAll(() async {
    if (!enabled) return;
    overrideRegistrationAdmissionForTesting(null);
    Database.resetForTesting();
    await sink.close(force: true);
    await pool.close();
    await scratch.delete(recursive: true);
  });

  String unique(String prefix) =>
      '${prefix}_${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}';

  String batchLabel(String prefix) => unique(prefix).toLowerCase();

  /// Roda o script como o dono, só com o ambiente dado.
  Future<({int code, String out, String err, Map<String, dynamic>? summary})>
  cli(
    List<String> args, {
    bool approvals = true,
    bool webhook = true,
    Map<String, String> extra = const {},
  }) async {
    final env = Platform.environment;
    final result = await Process.run(
      Platform.resolvedExecutable,
      [kernel, ...args],
      workingDirectory: scratch.path,
      includeParentEnvironment: false,
      environment: {
        'PATH': env['PATH'] ?? '/usr/bin:/bin',
        if (env['HOME'] case final String home) 'HOME': home,
        'ENVIRONMENT': 'development',
        'DB_HOST': env['DB_HOST']!,
        'DB_PORT': env['DB_PORT'] ?? '5432',
        'DB_NAME': env['DB_NAME']!,
        'DB_USER': env['DB_USER']!,
        'DB_PASS': env['DB_PASS'] ?? '',
        'DB_SSL_MODE': 'disable',
        'BETA_INVITE_APP_URL': appUrl,
        if (webhook)
          'BETA_INVITE_WEBHOOK_URL': 'http://127.0.0.1:${sink.port}/convites',
        if (approvals) ...{
          'MANALOOM_CONFIRM_POSTGRES_WRITES': approval,
          'MANALOOM_CONFIRM_LIVE_MUTATIONS': approval,
        },
        ...extra,
      },
    );
    final out = result.stdout as String;
    Map<String, dynamic>? summary;
    for (final line in const LineSplitter().convert(out).reversed) {
      if (line.startsWith('{')) {
        summary = jsonDecode(line) as Map<String, dynamic>;
        break;
      }
    }
    return (
      code: result.exitCode,
      out: out,
      err: result.stderr as String,
      summary: summary,
    );
  }

  Future<File> emailList(String name, List<String> lines) async {
    final file = File('${scratch.path}/$name.txt');
    await file.writeAsString('${lines.join('\n')}\n');
    return file;
  }

  Future<int> invitesInBatch(String batch) async =>
      (await pool.execute(
            Sql.named(
              'SELECT COUNT(*)::int FROM beta_invites WHERE batch_label = @b',
            ),
            parameters: {'b': batch},
          )).single[0]!
          as int;

  List<Map<String, dynamic>> deliveredTo(String email) => [
    for (final body in delivered)
      if (body['recipient'] == email) body,
  ];

  Future<(int, Map<String, dynamic>)> register(
    String email,
    String code,
  ) async {
    final response = await register_route.onRequest(
      ScriptedRequestContext(
        Request.post(
          Uri.parse('http://localhost/auth/register'),
          headers: const {'content-type': 'application/json'},
          body: jsonEncode({
            'username': unique('coorte'),
            'email': email,
            'password': 'Convite!Beta-2026',
            'legal_accepted': true,
            'terms_version': currentTermsVersion,
            'privacy_version': currentPrivacyVersion,
            'invite_code': code,
          }),
        ),
        providers: {RequestTrace: RequestTrace(requestId: unique('req'))},
      ),
    );
    return (
      response.statusCode,
      jsonDecode(await response.body()) as Map<String, dynamic>,
    );
  }

  test(
    'simulação: prévia e ensaio da entrega, nada gravado nem enviado',
    () async {
      final batch = batchLabel('sim');
      final a = '${unique('sim_a')}@example.invalid';
      final b = '${unique('sim_b')}@example.invalid';
      final list = await emailList(batch, [
        '# lote de teste',
        a,
        b.toUpperCase(),
        '',
        'nao-e-email',
        a,
      ]);
      final before = delivered.length;

      final run = await cli(['emitir', '--lote', batch, '--emails', list.path]);

      expect(run.code, 0, reason: run.err);
      expect(run.out, contains('Simulação: nada foi gravado nem enviado.'));
      expect(
        run.out,
        contains('Entrega (ensaio, nada saiu da máquina): pronta'),
      );
      expect(run.out, contains('?invite_code=XXXX-XXXX-XXXX-XXXX'));
      expect(run.summary!['modo'], 'simulacao');
      expect(run.summary!['resumo'], containsPair('novo', 2));
      expect(run.summary!['resumo'], containsPair('email_invalido', 1));
      expect(run.summary!['resumo'], containsPair('repetido', 1));
      expect(run.summary!['entrega'], containsPair('pronta', true));
      expect(run.summary!['entrega'], containsPair('destino', '127.0.0.1'));
      expect(run.summary!['entrega'], containsPair('aplicar', 'liberado'));
      expect(await invitesInBatch(batch), 0, reason: 'a simulação só lê');
      expect(delivered.length, before, reason: 'o ensaio não sai da máquina');
    },
    skip: skipReason,
  );

  test('aplicar sem as aprovações: BLOCKED (3) e nada gravado', () async {
    final batch = batchLabel('semaprov');
    final email = '${unique('semaprov')}@example.invalid';

    final run = await cli([
      'emitir',
      '--lote',
      batch,
      '--email',
      email,
      '--aplicar',
    ], approvals: false);

    expect(run.code, 3);
    expect(run.err, contains('BLOCKED'));
    expect(await invitesInBatch(batch), 0);
  }, skip: skipReason);

  test('aplicar sem entrega pronta: BLOCKED (3) antes de gravar', () async {
    final batch = batchLabel('sementrega');
    final email = '${unique('sementrega')}@example.invalid';
    final before = delivered.length;

    final simulated = await cli([
      'emitir',
      '--lote',
      batch,
      '--email',
      email,
    ], webhook: false);
    expect(simulated.code, 0, reason: simulated.err);
    expect(
      simulated.out,
      contains('NÃO pronta (email_delivery_not_configured)'),
    );
    expect(simulated.summary!['entrega'], containsPair('aplicar', 'bloqueado'));

    final run = await cli([
      'emitir',
      '--lote',
      batch,
      '--email',
      email,
      '--aplicar',
    ], webhook: false);

    expect(run.code, 3, reason: run.out);
    expect(run.err, contains('BLOCKED'));
    expect(run.err, contains('email_delivery_not_configured'));
    expect(await invitesInBatch(batch), 0, reason: 'nenhum convite sem e-mail');
    expect(delivered.length, before);
  }, skip: skipReason);

  test(
    'emitir o lote grava e entrega; repetir não duplica nem reenvia',
    () async {
      final batch = batchLabel('lote');
      final emails = [
        for (var i = 0; i < 3; i++) '${unique('lote$i')}@example.invalid',
      ];
      final list = await emailList(batch, [...emails, 'nao-e-email']);

      final first = await cli([
        'emitir',
        '--lote',
        batch,
        '--emails',
        list.path,
        '--aplicar',
      ]);

      expect(first.code, 0, reason: first.err);
      expect(first.summary!['modo'], 'aplicado');
      expect(first.summary!['resumo'], {
        'novo': 3,
        'envio_enviado': 3,
        'email_invalido': 1,
      });
      expect(await invitesInBatch(batch), 3);
      final codes = <String>{};
      for (final email in emails) {
        final mail = deliveredTo(email);
        expect(mail, hasLength(1), reason: email);
        expect(mail.single['template'], 'beta_invite');
        final code = mail.single['code'] as String;
        expect(code, matches(RegExp(r'^[0-9A-Z]{4}(-[0-9A-Z]{4}){3}$')));
        expect(
          mail.single['invite_url'],
          '$appUrl?invite_code=${Uri.encodeQueryComponent(code)}',
        );
        codes.add(code);
      }
      expect(codes, hasLength(3), reason: 'um código por convite');
      final stored = await pool.execute(
        Sql.named('''
        SELECT bool_and(delivered_at IS NOT NULL),
               bool_and(email_hint LIKE '%***@example.invalid'),
               string_agg(row_to_json(beta_invites)::text, ' ')
        FROM beta_invites WHERE batch_label = @b
      '''),
        parameters: {'b': batch},
      );
      expect(stored.single[0], isTrue);
      expect(stored.single[1], isTrue);
      final rowsText = stored.single[2]! as String;
      for (final code in codes) {
        expect(
          rowsText,
          isNot(contains(code)),
          reason:
              'o banco não guarda o '
              'código',
        );
      }
      for (final email in emails) {
        expect(rowsText, isNot(contains(email)), reason: 'nem o e-mail');
      }

      final mailsBefore = delivered.length;
      final again = await cli([
        'emitir',
        '--lote',
        batch,
        '--emails',
        list.path,
        '--aplicar',
      ]);

      expect(again.code, 0, reason: again.err);
      expect(again.summary!['resumo'], {
        'ja_convidado': 3,
        'email_invalido': 1,
      });
      expect(await invitesInBatch(batch), 3);
      expect(delivered.length, mailsBefore, reason: 'nenhum e-mail novo');
    },
    skip: skipReason,
  );

  test('convite expirado: listar mostra expirado e emitir reemite', () async {
    final batch = batchLabel('expira');
    final email = '${unique('expira')}@example.invalid';
    final first = await cli([
      'emitir',
      '--lote',
      batch,
      '--email',
      email,
      '--aplicar',
    ]);
    expect(first.code, 0, reason: first.err);
    final oldCode = deliveredTo(email).single['code'] as String;
    await pool.execute(
      Sql.named('''
        UPDATE beta_invites
        SET issued_at = issued_at - INTERVAL '30 days',
            expires_at = CURRENT_TIMESTAMP - INTERVAL '1 second'
        WHERE batch_label = @b
      '''),
      parameters: {'b': batch},
    );

    final listed = await cli(['listar', '--lote', batch]);
    expect(listed.code, 0, reason: listed.err);
    expect(listed.summary!['modo'], 'leitura');
    expect(listed.summary!['resumo'], {'expirado': 1});
    expect(listed.out, isNot(contains(email)), reason: 'só a pista mascarada');

    final again = await cli([
      'emitir',
      '--lote',
      batch,
      '--email',
      email,
      '--aplicar',
    ]);
    expect(again.code, 0, reason: again.err);
    expect(again.summary!['resumo'], {'reemitir': 1, 'envio_enviado': 1});
    final mails = deliveredTo(email);
    expect(mails, hasLength(2));
    final newCode = mails.last['code'] as String;
    expect(newCode, isNot(oldCode));

    final relisted = await cli(['listar', '--lote', batch]);
    expect(relisted.summary!['resumo'], {'revogado': 1, 'aberto': 1});

    final (oldStatus, oldBody) = await register(email, oldCode);
    expect(oldStatus, 403, reason: '$oldBody');
    expect(oldBody['error'], 'invite_revoked');
    final (newStatus, newBody) = await register(email, newCode);
    expect(newStatus, 201, reason: '$newBody');
  }, skip: skipReason);

  test('convite usado: o código do e-mail cria a conta; depois o script não '
      'convida, não reenvia nem revoga', () async {
    final batch = batchLabel('usado');
    final email = '${unique('usado')}@example.invalid';
    final issued = await cli([
      'emitir',
      '--lote',
      batch,
      '--email',
      email,
      '--aplicar',
    ]);
    expect(issued.code, 0, reason: issued.err);
    final code = deliveredTo(email).single['code'] as String;

    final (status, body) = await register(email, code.toLowerCase());
    expect(status, 201, reason: '$body');
    expect((body['user'] as Map<String, dynamic>)['email_verified'], isTrue);

    final mailsBefore = delivered.length;
    final reinvite = await cli([
      'emitir',
      '--lote',
      batch,
      '--email',
      email,
      '--aplicar',
    ]);
    expect(reinvite.code, 0, reason: reinvite.err);
    expect(reinvite.summary!['resumo'], {'ja_tem_conta': 1});

    final resent = await cli(['reenviar', '--email', email, '--aplicar']);
    expect(resent.code, 0, reason: resent.err);
    expect(resent.summary!['resumo'], {'ja_tem_conta': 1});

    final revoked = await cli([
      'revogar',
      '--email',
      email,
      '--motivo',
      'teste do convite usado',
      '--aplicar',
    ]);
    expect(revoked.code, 0, reason: revoked.err);
    expect(revoked.summary!['resumo'], {'sem_convite_aberto': 1});
    expect(delivered.length, mailsBefore, reason: 'nenhum e-mail novo');

    final listed = await cli(['listar', '--lote', batch]);
    expect(listed.summary!['resumo'], {'aceito': 1});

    final (replay, replayBody) = await register(email, code);
    expect(replay, 403);
    expect(replayBody['error'], 'invite_already_used');
    final accounts = await pool.execute(
      Sql.named('SELECT COUNT(*)::int FROM users WHERE email = @e'),
      parameters: {'e': email},
    );
    expect(accounts.single[0], 1);
    expect(await invitesInBatch(batch), 1, reason: 'nenhum convite a mais');
  }, skip: skipReason);
}
