@Tags(['live', 'live_db_write'])
library;

import 'dart:convert';

import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import '../lib/auth_service.dart';
import '../lib/privacy/account_deletion_outbox.dart';
import '../lib/user_data_privacy_service.dart';
import 'support/privacy_db_fixture.dart';

/// D-68 (BT-PRIV-002) em PostgreSQL descartável.
///
/// A exclusão grava uma linha do outbox por consumidor na mesma transação do
/// recibo, e uma falha no outbox desfaz a exclusão inteira. O job conclui o
/// que sabe concluir (`sentry` na hora, `endpoint_cache` depois do teto de
/// 24 h), marca os consumidores bloqueados com o motivo sem gastar tentativa,
/// respeita o lease de outro dono, agenda nova tentativa depois de falha e
/// deixa um recibo por execução sem identificador.
///
/// O banco descartável guarda linhas de outros arquivos de teste: cada teste
/// começa com o outbox vazio.
///
/// Requer `RUN_PRIVACY_DB_TESTS=1` e as variáveis `DB_*` de um banco
/// descartável já migrado.
void main() {
  final enabled = privacyDbTestsEnabled();
  final skipReason = enabled ? null : privacyDbSkipReason;
  const password = 'Senha!Outbox-2026';
  late Pool pool;

  setUpAll(() async {
    if (!enabled) return;
    AuthService.resetForTesting();
    pool = openPrivacyTestPool();
  });

  tearDownAll(() async {
    if (enabled) await pool.close();
  });

  setUp(() async {
    if (!enabled) return;
    await pool.execute('DELETE FROM account_deletion_outbox');
  });

  Future<PrivacyDbFixture> seed() => PrivacyDbFixture.seed(
    pool,
    passwordHash: AuthService().hashPassword(password),
  );

  Future<void> delete(String userId) => UserDataPrivacyService(
    pool,
  ).deleteAndAnonymizeAccount(userId: userId, password: password);

  Future<String> latestReceipt() async {
    final result = await pool.execute('''
      SELECT id::text FROM account_deletion_receipts
      ORDER BY completed_at DESC LIMIT 1
    ''');
    return result.single.single! as String;
  }

  Future<Map<String, Map<String, dynamic>>> rowsOf(String receiptId) async {
    final result = await pool.execute(
      Sql.named('''
        SELECT consumer, status, attempts, key_version, deck_tokens,
               last_error_code, lease_owner,
               completed_at IS NOT NULL AS completed,
               EXTRACT(EPOCH FROM (next_attempt_at - created_at))::int
                 AS delay_seconds
        FROM account_deletion_outbox
        WHERE receipt_id = CAST(@receipt AS uuid)
      '''),
      parameters: {'receipt': receiptId},
    );
    return {
      for (final row in result)
        row.toColumnMap()['consumer'] as String: row.toColumnMap(),
    };
  }

  Future<List<String>> deckTokens(List<String> deckIds) async {
    final result = await pool.execute(
      Sql.named('''
        SELECT encode(
          hmac(convert_to(deck.id::text, 'UTF8'), key.hmac_key, 'sha256'),
          'hex'
        )
        FROM unnest(CAST(@decks AS uuid[])) AS deck(id)
        CROSS JOIN privacy_keyring key
        WHERE key.is_active
        ORDER BY 1
      '''),
      parameters: {'decks': deckIds},
    );
    return [for (final row in result) row.single! as String];
  }

  Future<Map<String, dynamic>> runWorker({
    Map<String, AccountDeletionOutboxHandler>? handlers,
  }) => AccountDeletionOutboxWorker(
    pool,
    handlers: handlers,
  ).runOnce(runId: 'teste_${DateTime.now().microsecondsSinceEpoch}');

  test('a exclusão grava uma linha por consumidor, na transação do recibo, '
      'com os decks só como HMAC e só para quem precisa deles', () async {
    final fixture = await seed();
    await delete(fixture.userA);
    final receipt = await latestReceipt();
    final rows = await rowsOf(receipt);

    expect(rows.keys.toSet(), {
      for (final consumer in accountDeletionOutboxConsumers) consumer.name,
    });
    final expectedTokens = await deckTokens([
      fixture.deckA1,
      fixture.deckA2Public,
    ]);
    expect(expectedTokens, hasLength(2));
    for (final consumer in accountDeletionOutboxConsumers) {
      final row = rows[consumer.name]!;
      expect(row['status'], 'pending', reason: consumer.name);
      expect(row['attempts'], 0, reason: consumer.name);
      expect(
        row['delay_seconds'],
        consumer.firstAttemptDelay.inSeconds,
        reason: consumer.name,
      );
      final tokens = [...(row['deck_tokens'] as List).cast<String>()]..sort();
      expect(
        tokens,
        consumer.carriesDeckTokens ? expectedTokens : isEmpty,
        reason: consumer.name,
      );
    }

    final tombstones = await pool.execute(
      Sql.named('''
        SELECT COUNT(*)::int FROM privacy_deleted_deck_tombstones
        WHERE deck_token = ANY(CAST(@tokens AS text[]))
      '''),
      parameters: {'tokens': expectedTokens},
    );
    expect(tombstones.single.single, 2, reason: 'mesmo HMAC dos tombstones');

    final raw = jsonEncode(
      rows.values.map((row) => row.map((k, v) => MapEntry(k, '$v'))).toList(),
    );
    for (final id in [fixture.userA, fixture.deckA1, fixture.deckA2Public]) {
      expect(raw, isNot(contains(id)));
    }
  }, skip: skipReason);

  test('conta sem deck: o outbox entra igual, sem tokens', () async {
    final fixture = await seed();
    await delete(fixture.userC);
    final rows = await rowsOf(await latestReceipt());
    expect(rows, hasLength(accountDeletionOutboxConsumers.length));
    for (final row in rows.values) {
      expect(row['deck_tokens'], isEmpty);
    }
  }, skip: skipReason);

  test('se o outbox falha, a exclusão inteira volta', () async {
    final fixture = await seed();
    final receiptsBefore = await pool.execute(
      'SELECT COUNT(*)::int FROM account_deletion_receipts',
    );
    await pool.execute('''
      CREATE OR REPLACE FUNCTION manaloom_test_fail_outbox_insert()
      RETURNS trigger LANGUAGE plpgsql AS \$fail_outbox\$
      BEGIN
        RAISE EXCEPTION 'outbox indisponivel no teste';
      END;
      \$fail_outbox\$
    ''');
    await pool.execute('''
      CREATE TRIGGER manaloom_test_fail_outbox_insert
      BEFORE INSERT ON account_deletion_outbox
      FOR EACH ROW EXECUTE FUNCTION manaloom_test_fail_outbox_insert()
    ''');
    try {
      await expectLater(delete(fixture.userA), throwsA(isA<ServerException>()));
    } finally {
      await pool.execute(
        'DROP TRIGGER IF EXISTS manaloom_test_fail_outbox_insert '
        'ON account_deletion_outbox',
      );
      await pool.execute(
        'DROP FUNCTION IF EXISTS manaloom_test_fail_outbox_insert()',
      );
    }

    final user = await pool.execute(
      Sql.named('''
        SELECT deleted_at IS NULL, username FROM users
        WHERE id = CAST(@id AS uuid)
      '''),
      parameters: {'id': fixture.userA},
    );
    expect(user.single[0], isTrue);
    expect(user.single[1], 'privacy_A_${fixture.suffix}');
    final decks = await pool.execute(
      Sql.named(
        'SELECT COUNT(*)::int FROM decks WHERE user_id = CAST(@id AS uuid)',
      ),
      parameters: {'id': fixture.userA},
    );
    expect(decks.single.single, 2);
    final receiptsAfter = await pool.execute(
      'SELECT COUNT(*)::int FROM account_deletion_receipts',
    );
    expect(receiptsAfter.single.single, receiptsBefore.single.single);
    final outbox = await pool.execute(
      'SELECT COUNT(*)::int FROM account_deletion_outbox',
    );
    expect(outbox.single.single, 0);
  }, skip: skipReason);

  test('o job conclui sentry na hora, deixa endpoint_cache para depois do '
      'teto de 24 h e marca os bloqueados com o motivo', () async {
    final fixture = await seed();
    await delete(fixture.userA);
    final receipt = await latestReceipt();

    final first = await runWorker();
    var rows = await rowsOf(receipt);
    expect(rows['sentry']!['status'], 'done');
    expect(rows['sentry']!['completed'], isTrue);
    expect(rows['sentry']!['attempts'], 1);
    expect(rows['sentry']!['lease_owner'], isNull);
    expect(rows['endpoint_cache']!['status'], 'pending');
    expect(rows['endpoint_cache']!['attempts'], 0);
    for (final consumer in accountDeletionOutboxConsumers.where(
      (consumer) => consumer.handling == AccountDeletionOutboxHandling.blocked,
    )) {
      final row = rows[consumer.name]!;
      expect(row['status'], 'pending', reason: consumer.name);
      expect(row['attempts'], 0, reason: consumer.name);
      expect(row['last_error_code'], consumer.code, reason: consumer.name);
    }
    expect(rows['hermes_learning_sqlite']!['deck_tokens'], hasLength(2));
    final consumers = first['consumers'] as Map;
    expect((consumers['sentry'] as Map)['done'], 1);
    expect((consumers['backups'] as Map)['marked_blocked'], 1);

    // Um dia depois: o teto do EndpointCache passou.
    await pool.execute(
      Sql.named('''
        UPDATE account_deletion_outbox
        SET created_at = created_at - INTERVAL '25 hours',
            next_attempt_at = next_attempt_at - INTERVAL '25 hours'
        WHERE receipt_id = CAST(@receipt AS uuid)
          AND consumer = 'endpoint_cache'
      '''),
      parameters: {'receipt': receipt},
    );
    await runWorker();
    rows = await rowsOf(receipt);
    expect(rows['endpoint_cache']!['status'], 'done');
    expect(rows['backups']!['status'], 'pending');
    expect(rows['backups']!['attempts'], 0);
  }, skip: skipReason);

  test('linha vencida antes do prazo volta para a fila sem gastar '
      'tentativa', () async {
    final fixture = await seed();
    await delete(fixture.userA);
    final receipt = await latestReceipt();
    await pool.execute(
      Sql.named('''
        UPDATE account_deletion_outbox
        SET next_attempt_at = CURRENT_TIMESTAMP - INTERVAL '1 minute'
        WHERE receipt_id = CAST(@receipt AS uuid)
          AND consumer = 'endpoint_cache'
      '''),
      parameters: {'receipt': receipt},
    );
    await runWorker();
    final row = (await rowsOf(receipt))['endpoint_cache']!;
    expect(row['status'], 'pending');
    expect(row['attempts'], 0);
    expect(row['delay_seconds'], endpointCacheOutboxDelay.inSeconds);
  }, skip: skipReason);

  test('lease de outro dono é respeitado; lease vencido é retomado', () async {
    final fixture = await seed();
    await delete(fixture.userA);
    final receipt = await latestReceipt();
    Future<void> lease(String until) => pool.execute(
      Sql.named('''
        UPDATE account_deletion_outbox
        SET status = 'processing',
            lease_owner = 'outro-worker',
            lease_expires_at = CURRENT_TIMESTAMP + CAST(@until AS interval),
            attempts = 1
        WHERE receipt_id = CAST(@receipt AS uuid) AND consumer = 'sentry'
      '''),
      parameters: {'receipt': receipt, 'until': until},
    );

    await lease('5 minutes');
    await runWorker();
    var row = (await rowsOf(receipt))['sentry']!;
    expect(row['status'], 'processing');
    expect(row['lease_owner'], 'outro-worker');
    expect(row['attempts'], 1);

    await lease('-1 second');
    await runWorker();
    row = (await rowsOf(receipt))['sentry']!;
    expect(row['status'], 'done');
    expect(row['lease_owner'], isNull);
    expect(row['attempts'], 2);
  }, skip: skipReason);

  test('falha agenda nova tentativa com intervalo e para no teto de '
      'tentativas', () async {
    final fixture = await seed();
    await delete(fixture.userA);
    final receipt = await latestReceipt();
    Future<Map<String, dynamic>> failingRun() => runWorker(
      handlers: {
        'sentry': (session, row) async => throw StateError('consumidor fora'),
      },
    );

    await failingRun();
    var row = (await rowsOf(receipt))['sentry']!;
    expect(row['status'], 'failed');
    expect(row['last_error_code'], 'handler_error');
    expect(row['attempts'], 1);
    final retry = await pool.execute(
      Sql.named('''
        SELECT EXTRACT(EPOCH FROM (next_attempt_at - updated_at))::int
        FROM account_deletion_outbox
        WHERE receipt_id = CAST(@receipt AS uuid) AND consumer = 'sentry'
      '''),
      parameters: {'receipt': receipt},
    );
    expect(
      retry.single.single,
      AccountDeletionOutboxWorker.retryDelay(1).inSeconds,
    );

    await failingRun();
    row = (await rowsOf(receipt))['sentry']!;
    expect(row['attempts'], 1, reason: 'antes do intervalo não tenta de novo');

    await pool.execute(
      Sql.named('''
        UPDATE account_deletion_outbox
        SET next_attempt_at = CURRENT_TIMESTAMP - INTERVAL '1 second',
            attempts = 20
        WHERE receipt_id = CAST(@receipt AS uuid) AND consumer = 'sentry'
      '''),
      parameters: {'receipt': receipt},
    );
    final exhausted = await runWorker();
    row = (await rowsOf(receipt))['sentry']!;
    expect(row['status'], 'failed');
    expect(row['attempts'], 20);
    expect(((exhausted['consumers'] as Map)['sentry'] as Map)['exhausted'], 1);
  }, skip: skipReason);

  test('quando um consumidor com tokens conclui, os tokens saem da '
      'linha', () async {
    final fixture = await seed();
    await delete(fixture.userA);
    final receipt = await latestReceipt();
    expect(
      (await rowsOf(receipt))['hermes_learning_sqlite']!['deck_tokens'],
      hasLength(2),
    );
    // Simula o consumidor do Hermes que ainda não existe.
    await runWorker(
      handlers: {
        ...defaultAccountDeletionOutboxHandlers(),
        'hermes_learning_sqlite':
            (session, row) async => const OutboxDone('purged_in_test'),
      },
    );
    final rows = await rowsOf(receipt);
    expect(rows['hermes_learning_sqlite']!['status'], 'done');
    expect(rows['hermes_learning_sqlite']!['deck_tokens'], isEmpty);
  }, skip: skipReason);

  test('o sidecar fecha pelo tempo máximo da sessão, contado da exclusão, e o '
      'recibo diz por quê (D-77)', () async {
    final fixture = await seed();
    await delete(fixture.userA);
    final receipt = await latestReceipt();

    /// Deixa a linha do sidecar com [age] de idade e vencida para o job.
    Future<void> age(String age) => pool.execute(
      Sql.named('''
        UPDATE account_deletion_outbox
        SET created_at = CURRENT_TIMESTAMP - CAST(@age AS interval),
            next_attempt_at = CURRENT_TIMESTAMP - INTERVAL '1 second'
        WHERE receipt_id = CAST(@receipt AS uuid)
          AND consumer = 'interactive_battle_sidecar'
      '''),
      parameters: {'receipt': receipt, 'age': age},
    );

    var row = (await rowsOf(receipt))['interactive_battle_sidecar']!;
    expect(row['status'], 'pending');
    expect(row['deck_tokens'], isEmpty);
    expect(row['delay_seconds'], interactiveBattleSidecarOutboxDelay.inSeconds);

    // Na hora da exclusão, nada: a primeira tentativa é 2 h 10 min depois.
    await runWorker();
    row = (await rowsOf(receipt))['interactive_battle_sidecar']!;
    expect(row['status'], 'pending');
    expect(row['attempts'], 0);
    expect(row['last_error_code'], isNull);

    // 2 h 9 min depois: ainda dentro do tempo máximo da sessão.
    await age('2 hours 9 minutes');
    await runWorker();
    row = (await rowsOf(receipt))['interactive_battle_sidecar']!;
    expect(row['status'], 'pending');
    expect(row['attempts'], 0);
    expect(row['delay_seconds'], interactiveBattleSidecarOutboxDelay.inSeconds);

    // 2 h 11 min depois: passou 7200 s + 10 min.
    await age('2 hours 11 minutes');
    final run = await runWorker();
    row = (await rowsOf(receipt))['interactive_battle_sidecar']!;
    expect(row['status'], 'done');
    expect(row['completed'], isTrue);
    expect(row['last_error_code'], isNull);
    final sidecar =
        (run['consumers'] as Map)['interactive_battle_sidecar'] as Map;
    expect(sidecar['done'], 1);
    expect(sidecar['handling'], 'expiresByTtl');
    expect(sidecar['code'], 'expired_by_max_session_lifetime');
  }, skip: skipReason);

  test('linha que outro job retomou não é fechada por este', () async {
    final fixture = await seed();
    await delete(fixture.userA);
    final receipt = await latestReceipt();
    final run = await runWorker(
      handlers: {
        // Enquanto este job trata a linha, o lease dela vence e outro job a
        // retoma.
        'sentry': (session, row) async {
          await session.execute(
            Sql.named('''
              UPDATE account_deletion_outbox
              SET lease_owner = 'outro-worker',
                  lease_expires_at = CURRENT_TIMESTAMP + INTERVAL '5 minutes'
              WHERE id = CAST(@id AS uuid)
            '''),
            parameters: {'id': row.id},
          );
          return const OutboxDone('server_events_carry_no_user_id');
        },
      },
    );
    final row = (await rowsOf(receipt))['sentry']!;
    expect(row['status'], 'processing');
    expect(row['lease_owner'], 'outro-worker');
    expect(row['completed'], isFalse);
    expect(((run['consumers'] as Map)['sentry'] as Map)['lease_lost'], 1);
  }, skip: skipReason);

  test('o recibo da execução não leva identificador', () async {
    final fixture = await seed();
    await delete(fixture.userA);
    final receipt = await latestReceipt();
    final run = await runWorker();
    final line = accountDeletionOutboxReceiptLine(run);

    expect(line, startsWith('$accountDeletionOutboxReceiptMarker {'));
    expect(run['schema'], accountDeletionOutboxReceiptSchema);
    expect(run['contract'], accountDeletionOutboxContract);
    for (final value in [fixture.userA, fixture.deckA1, receipt]) {
      expect(line, isNot(contains(value)));
    }
    expect(
      RegExp(r'[0-9a-f]{64}').hasMatch(line),
      isFalse,
      reason: 'nenhum token de deck',
    );
  }, skip: skipReason);

  test('sem a tabela, o job para sem tocar em nada', () async {
    await pool.execute(
      'ALTER TABLE account_deletion_outbox RENAME TO account_deletion_outbox_fora',
    );
    try {
      await expectLater(
        runWorker(),
        throwsA(isA<AccountDeletionOutboxMissing>()),
      );
    } finally {
      await pool.execute(
        'ALTER TABLE account_deletion_outbox_fora RENAME TO account_deletion_outbox',
      );
    }
  }, skip: skipReason);
}
