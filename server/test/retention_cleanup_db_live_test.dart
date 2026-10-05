@Tags(['live', 'live_db_write'])
library;

import 'dart:async';
import 'dart:convert';

import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import '../lib/privacy/retention_cleanup.dart';
import 'support/privacy_db_fixture.dart';

/// D-70 (BT-PRIV-002) em PostgreSQL descartável.
///
/// A limpeza por prazo está desligada por padrão: o agendado e o dry-run só
/// contam. Ativar exige a aprovação explícita; ativada, apaga só o que venceu
/// nas regras do inventário e nada mais; pausada, volta a só contar. Com
/// outra execução em andamento, não apaga.
///
/// Requer `RUN_PRIVACY_DB_TESTS=1` e as variáveis `DB_*` de um banco
/// descartável já migrado.
void main() {
  final enabled = privacyDbTestsEnabled();
  final skipReason = enabled ? null : privacyDbSkipReason;
  late Pool pool;
  const approved = {
    retentionCleanupWriteApprovalEnvironment:
        retentionCleanupWriteApprovalValue,
  };

  setUpAll(() async {
    if (!enabled) return;
    pool = openPrivacyTestPool();
  });

  tearDownAll(() async {
    if (!enabled) return;
    await pool.execute(
      Sql.named('DELETE FROM sync_state WHERE key = @key'),
      parameters: {'key': retentionCleanupStateKey},
    );
    await pool.close();
  });

  setUp(() async {
    if (!enabled) return;
    await pool.execute(
      Sql.named('DELETE FROM sync_state WHERE key = @key'),
      parameters: {'key': retentionCleanupStateKey},
    );
  });

  Future<Map<String, dynamic>> run(
    RetentionCleanupMode mode, {
    Map<String, String> environment = const {},
  }) => RetentionCleanupRunner(pool).run(
    mode: mode,
    runId: 'teste_${DateTime.now().microsecondsSinceEpoch}',
    environment: environment,
  );

  /// Uma linha vencida e uma dentro do prazo em cada regra, mais linhas que
  /// nenhuma regra alcança: notificação antiga e reserva de cota confirmada
  /// antiga.
  Future<({Map<String, (String, String)> byRule, List<(String, String)> kept})>
  seed() async {
    final suffix = '${DateTime.now().microsecondsSinceEpoch}';
    Future<String> one(
      String sql, [
      Map<String, Object?> parameters = const {},
    ]) async {
      final result = await pool.execute(Sql.named(sql), parameters: parameters);
      return result.single.single!.toString();
    }

    final user = await one(
      '''
      INSERT INTO users (username, email, password_hash)
      VALUES (@username, @email, 'x') RETURNING id::text
      ''',
      {
        'username': 'retencao_$suffix',
        'email': 'retencao_$suffix@example.invalid',
      },
    );
    final deck = await one(
      '''
      INSERT INTO decks (user_id, name, format)
      VALUES (CAST(@user AS uuid), @name, 'commander') RETURNING id::text
      ''',
      {'user': user, 'name': 'Deck de retencao $suffix'},
    );

    var ledgerRevision = 0;
    var trashCount = 0;

    /// D-30: deck na lixeira há [age] (o prazo conta de deleted_at).
    Future<String> trashedDeck(Duration age) => one(
      '''
      INSERT INTO decks (user_id, name, format, created_at, deleted_at)
      VALUES (CAST(@user AS uuid), @name, 'commander',
              CAST(@at AS timestamptz) - INTERVAL '1 day',
              CAST(@at AS timestamptz))
      RETURNING id::text
      ''',
      {
        'user': user,
        'name': 'Lixeira $suffix ${++trashCount}',
        'at': DateTime.now().toUtc().subtract(age),
      },
    );

    Future<String> row(
      String table,
      Duration age, {
      String? endpoint,
      bool success = true,
    }) {
      final at = DateTime.now().toUtc().subtract(age);
      return switch (table) {
        'ai_optimize_fallback_telemetry' => one(
          '''
          INSERT INTO ai_optimize_fallback_telemetry (created_at)
          VALUES (@at) RETURNING id::text
          ''',
          {'at': at},
        ),
        'ai_logs' => one(
          '''
          INSERT INTO ai_logs (endpoint, model, success, latency_ms, created_at)
          VALUES (@endpoint, 'modelo-teste', @success, 1, @at)
          RETURNING id::text
          ''',
          {'endpoint': endpoint ?? 'optimize', 'success': success, 'at': at},
        ),
        'rate_limit_events' => one(
          '''
          INSERT INTO rate_limit_events (bucket, identifier, created_at)
          VALUES ('teste-retencao', @identifier, @at) RETURNING id::text
          ''',
          {'identifier': 'id-$suffix', 'at': at},
        ),
        'ai_generate_jobs' => one(
          '''
          INSERT INTO ai_generate_jobs (id, cache_key, format, created_at)
          VALUES (@id, @id, 'commander', @at) RETURNING id
          ''',
          {'id': 'gen-$suffix-${at.microsecondsSinceEpoch}', 'at': at},
        ),
        'ai_optimize_jobs' => one(
          '''
          INSERT INTO ai_optimize_jobs (id, deck_id, archetype, created_at)
          VALUES (@id, CAST(@deck AS uuid), 'teste', @at) RETURNING id
          ''',
          {
            'id': 'opt-$suffix-${at.microsecondsSinceEpoch}',
            'deck': deck,
            'at': at,
          },
        ),
        // D-29: pedido do Generate com prompt e mudança do ledger com
        // descrição (a redação apaga o texto e deixa a linha).
        'ai_generate_requests' => one(
          '''
          INSERT INTO ai_generate_requests (
            user_id, request_key, request_fingerprint, format, prompt,
            created_at
          ) VALUES (
            CAST(@user AS uuid), @key, 'impressao', 'commander',
            'prompt bruto', @at
          ) RETURNING id::text
          ''',
          {'user': user, 'key': 'req-${at.microsecondsSinceEpoch}', 'at': at},
        ),
        'deck_change_events' => one(
          '''
          INSERT INTO deck_change_events (
            deck_id, user_id, revision_before, revision_after, operation,
            metadata_before, metadata_after, created_at
          ) VALUES (
            CAST(@deck AS uuid), CAST(@user AS uuid), @before, @after,
            'deck_patch', '{"description": "prompt bruto"}'::jsonb,
            '{"description": "outra"}'::jsonb, @at
          ) RETURNING id::text
          ''',
          {
            'deck': deck,
            'user': user,
            'before': ++ledgerRevision,
            'after': ledgerRevision + 1,
            'at': at,
          },
        ),
        // D-30: o deck, o relatório e o evento de aprendizado de um deck na
        // lixeira há [age]; a cópia nasceu antes de o deck ir para lá.
        'decks' => trashedDeck(age),
        'shared_deck_reports' => trashedDeck(age).then(
          (trashed) => one(
            '''
            INSERT INTO shared_deck_reports (
              id, user_id, deck_id, title, payload, is_public, created_at,
              updated_at
            ) VALUES (
              @id, CAST(@user AS uuid), CAST(@deck AS uuid), 'relatório',
              '{}'::jsonb, FALSE, @at, @at
            ) RETURNING id
            ''',
            {
              'id': 'rpt_retencao_${suffix}_$trashCount',
              'user': user,
              'deck': trashed,
              'at': at.subtract(const Duration(days: 2)),
            },
          ),
        ),
        'deck_learning_events' => trashedDeck(age).then(
          (trashed) => one(
            '''
            INSERT INTO deck_learning_events (deck_id, format, created_at)
            VALUES (CAST(@deck AS uuid), 'commander', @at)
            RETURNING id::text
            ''',
            {'deck': trashed, 'at': at.subtract(const Duration(days: 2))},
          ),
        ),
        _ => throw ArgumentError(table),
      };
    }

    final byRule = <String, (String, String)>{};
    for (final rule in retentionCleanupRules) {
      final reservation =
          rule.id == 'ai_logs_unconfirmed_plan_reservation_10min';
      final endpoint = reservation ? 'plan-reservation:teste' : null;
      final expired = await row(
        rule.table,
        rule.maxAge + const Duration(minutes: 5),
        endpoint: endpoint,
        success: !reservation,
      );
      final fresh = await row(
        rule.table,
        rule.maxAge - const Duration(minutes: 5),
        endpoint: endpoint,
        success: !reservation,
      );
      byRule[rule.id] = (expired, fresh);
    }
    final kept = <(String, String)>[
      (
        'ai_logs',
        await row(
          'ai_logs',
          const Duration(days: 400),
          endpoint: 'plan-reservation:confirmada',
        ),
      ),
      (
        'notifications',
        await one(
          '''
          INSERT INTO notifications (user_id, type, title, created_at)
          VALUES (CAST(@user AS uuid), 'new_follower', 'antiga',
                  CURRENT_TIMESTAMP - INTERVAL '400 days')
          RETURNING id::text
          ''',
          {'user': user},
        ),
      ),
    ];
    // D-30: deck vivo antigo, com relatório e evento antigos, fica.
    final oldAlive = await one(
      '''
      INSERT INTO decks (user_id, name, format, created_at)
      VALUES (CAST(@user AS uuid), @name, 'commander',
              CURRENT_TIMESTAMP - INTERVAL '400 days')
      RETURNING id::text
      ''',
      {'user': user, 'name': 'Vivo antigo $suffix'},
    );
    kept
      ..add(('decks', oldAlive))
      ..add((
        'shared_deck_reports',
        await one(
          '''
          INSERT INTO shared_deck_reports (
            id, user_id, deck_id, title, payload, is_public, created_at,
            updated_at
          ) VALUES (
            @id, CAST(@user AS uuid), CAST(@deck AS uuid), 'vivo',
            '{}'::jsonb, TRUE, CURRENT_TIMESTAMP - INTERVAL '400 days',
            CURRENT_TIMESTAMP - INTERVAL '400 days'
          ) RETURNING id
          ''',
          {'id': 'rpt_vivo_$suffix', 'user': user, 'deck': oldAlive},
        ),
      ))
      ..add((
        'deck_learning_events',
        await one(
          '''
          INSERT INTO deck_learning_events (deck_id, format, created_at)
          VALUES (CAST(@deck AS uuid), 'commander',
                  CURRENT_TIMESTAMP - INTERVAL '400 days')
          RETURNING id::text
          ''',
          {'deck': oldAlive},
        ),
      ));
    return (byRule: byRule, kept: kept);
  }

  Future<bool> exists(String table, String id) async {
    final idColumn =
        table == 'ai_generate_jobs' || table == 'ai_optimize_jobs'
            ? 'id'
            : 'id::text';
    final result = await pool.execute(
      Sql.named('SELECT EXISTS (SELECT 1 FROM $table WHERE $idColumn = @id)'),
      parameters: {'id': id},
    );
    return result.single.single == true;
  }

  /// A linha segue como estava: para a regra que apaga, existe; para a
  /// redação da D-29, o texto ainda está lá.
  Future<bool> intact(RetentionCleanupRule rule, String id) async {
    if (!rule.isRedaction) return exists(rule.table, id);
    final column = switch (rule.table) {
      'ai_generate_requests' => 'prompt IS NOT NULL',
      _ => 'description_redacted_at IS NULL',
    };
    final result = await pool.execute(
      Sql.named(
        'SELECT $column FROM ${rule.table} WHERE id = CAST(@id AS uuid)',
      ),
      parameters: {'id': id},
    );
    return result.single.single == true;
  }

  Future<String?> state() async {
    final result = await pool.execute(
      Sql.named('SELECT value FROM sync_state WHERE key = @key'),
      parameters: {'key': retentionCleanupStateKey},
    );
    return result.isEmpty ? null : result.single.single as String?;
  }

  Future<void> expectAllKept(
    ({Map<String, (String, String)> byRule, List<(String, String)> kept})
    seeded,
  ) async {
    for (final rule in retentionCleanupRules) {
      final (expired, fresh) = seeded.byRule[rule.id]!;
      expect(await intact(rule, expired), isTrue, reason: rule.id);
      expect(await intact(rule, fresh), isTrue, reason: rule.id);
    }
    for (final (table, id) in seeded.kept) {
      expect(await exists(table, id), isTrue, reason: table);
    }
  }

  test('desligada por padrão: o agendado e o dry-run só contam', () async {
    final seeded = await seed();
    for (final mode in [
      RetentionCleanupMode.scheduled,
      RetentionCleanupMode.dryRun,
    ]) {
      final receipt = await run(mode);
      expect(receipt['applied'], isFalse, reason: mode.wireName);
      expect(receipt['activation'], retentionCleanupInactive);
      for (final rule in (receipt['rules'] as List).cast<Map>()) {
        expect(rule['eligible'], greaterThanOrEqualTo(1), reason: rule['id']);
        expect(rule['deleted'], 0, reason: rule['id']);
      }
    }
    await expectAllKept(seeded);
    expect(await state(), isNull);
  }, skip: skipReason);

  test('ativar sem a aprovação é recusado e não muda nada', () async {
    final seeded = await seed();
    await expectLater(
      run(RetentionCleanupMode.activate),
      throwsA(isA<RetentionCleanupRefused>()),
    );
    await expectAllKept(seeded);
    expect(await state(), isNull);
  }, skip: skipReason);

  test('ativar apaga só o que venceu nas regras do inventário e registra a '
      'ativação', () async {
    final seeded = await seed();
    final receipt = await run(
      RetentionCleanupMode.activate,
      environment: approved,
    );
    expect(receipt['status'], 'ok');
    expect(receipt['applied'], isTrue);
    for (final rule in retentionCleanupRules) {
      final (expired, fresh) = seeded.byRule[rule.id]!;
      expect(await intact(rule, expired), isFalse, reason: rule.id);
      expect(await intact(rule, fresh), isTrue, reason: rule.id);
    }
    for (final (table, id) in seeded.kept) {
      expect(await exists(table, id), isTrue, reason: table);
    }
    expect(await state(), retentionCleanupContract);
  }, skip: skipReason);

  test('ativada, o agendado apaga; pausada, volta a só contar', () async {
    await run(RetentionCleanupMode.activate, environment: approved);
    var seeded = await seed();
    final applied = await run(RetentionCleanupMode.scheduled);
    expect(applied['applied'], isTrue);
    for (final rule in retentionCleanupRules) {
      final (expired, fresh) = seeded.byRule[rule.id]!;
      expect(await intact(rule, expired), isFalse, reason: rule.id);
      expect(await intact(rule, fresh), isTrue, reason: rule.id);
    }

    await expectLater(
      run(RetentionCleanupMode.deactivate),
      throwsA(isA<RetentionCleanupRefused>()),
    );
    expect(await state(), retentionCleanupContract);
    await run(RetentionCleanupMode.deactivate, environment: approved);
    expect(await state(), retentionCleanupInactive);
    seeded = await seed();
    final paused = await run(RetentionCleanupMode.scheduled);
    expect(paused['applied'], isFalse);
    await expectAllKept(seeded);
  }, skip: skipReason);

  test('com outra execução em andamento, não apaga', () async {
    await run(RetentionCleanupMode.activate, environment: approved);
    final seeded = await seed();
    final locked = Completer<void>();
    final release = Completer<void>();
    // Outra conexão faz o papel da outra execução.
    final other = openPrivacyTestPool();
    addTearDown(other.close);
    final holder = other.runTx((tx) async {
      await tx.execute(
        "SELECT pg_advisory_xact_lock(hashtext('$retentionCleanupContract'))",
      );
      locked.complete();
      await release.future;
    });
    await locked.future;
    try {
      final receipt = await run(RetentionCleanupMode.scheduled);
      expect(receipt['status'], 'busy');
      expect(receipt['applied'], isFalse);
    } finally {
      release.complete();
      await holder;
    }
    await expectAllKept(seeded);
  }, skip: skipReason);

  test('o recibo não leva identificador', () async {
    final seeded = await seed();
    final receipt = await run(
      RetentionCleanupMode.activate,
      environment: approved,
    );
    final line = retentionCleanupReceiptLine(receipt);
    expect(line, startsWith('$retentionCleanupReceiptMarker {'));
    for (final (expired, fresh) in seeded.byRule.values) {
      expect(line, isNot(contains(expired)));
      expect(line, isNot(contains(fresh)));
    }
    expect(
      RegExp(
        r'[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}',
      ).hasMatch(line),
      isFalse,
    );
    expect(jsonDecode(line.substring(line.indexOf('{'))), isA<Map>());
  }, skip: skipReason);
}
