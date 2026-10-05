@Tags(['live', 'live_db_write'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:postgres/postgres.dart';
import 'package:server/commercial_metrics_service.dart';
import 'package:test/test.dart';

/// BT-KPI-001 (decisão D-47) em PostgreSQL descartável: as métricas de
/// ativação do `GET /health/commercial` contam usuários de uma coorte de
/// cadastro, não eventos.
///
/// A coorte do teste fica numa semana de 9 semanas atrás, com cadastros
/// semeados; o teste compara a linha dessa semana antes e depois de semear,
/// então dados de outros testes no mesmo banco não mudam o resultado.
///
/// Requer `RUN_KPI_DB_TESTS=1` e as variáveis `DB_*` de um banco descartável
/// já migrado.
void main() {
  final enabled = Platform.environment['RUN_KPI_DB_TESTS'] == '1';
  final skipReason =
      enabled ? null : 'Requer PostgreSQL descartavel explicitamente isolado.';
  final suffix = DateTime.now().microsecondsSinceEpoch;
  final marker = 'UGC-$suffix';
  late Pool pool;
  late CommercialMetricsService service;
  late DateTime signupBase;
  late String cohortWeek;
  final seededUsers = <String>[];
  final seededDecks = <String>[];
  final seededAiLogs = <String>[];

  setUpAll(() async {
    if (!enabled) return;
    pool = Pool.withEndpoints([
      Endpoint(
        host: Platform.environment['DB_HOST'] ?? '127.0.0.1',
        port: int.parse(Platform.environment['DB_PORT'] ?? '5432'),
        database: Platform.environment['DB_NAME']!,
        username: Platform.environment['DB_USER']!,
        password: Platform.environment['DB_PASS'] ?? '',
      ),
    ], settings: const PoolSettings(sslMode: SslMode.disable));
    service = CommercialMetricsService(pool);
    final base = await pool.execute('''
      SELECT date_trunc('week', (NOW() - INTERVAL '63 days') AT TIME ZONE 'UTC')
               AT TIME ZONE 'UTC' + INTERVAL '1 day 10 hours',
             date_trunc('week', (NOW() - INTERVAL '63 days') AT TIME ZONE 'UTC')
               ::date::text
    ''');
    signupBase = (base.single[0]! as DateTime).toUtc();
    cohortWeek = base.single[1]! as String;
  });

  tearDownAll(() async {
    if (!enabled) return;
    if (seededAiLogs.isNotEmpty) {
      await pool.execute(
        Sql.named('DELETE FROM ai_logs WHERE id::text = ANY(@ids)'),
        parameters: {'ids': TypedValue(Type.textArray, seededAiLogs)},
      );
    }
    await pool.execute(
      Sql.named('DELETE FROM users WHERE username LIKE @pattern'),
      parameters: {'pattern': 'kpi_cohort_${suffix}_%'},
    );
    await pool.close();
  });

  Future<Map<String, dynamic>?> cohortRow() async {
    final kpi = await service.activationKpi(days: 90);
    expect(kpi['status'], 'ok');
    for (final cohort in (kpi['cohorts'] as List).cast<Map>()) {
      if (cohort['cohort_week'] == cohortWeek) {
        return cohort.cast<String, dynamic>();
      }
    }
    return null;
  }

  int counter(Map<String, dynamic>? row, List<String> path) {
    Object? value = row;
    for (final key in path) {
      if (value is! Map) return 0;
      value = value[key];
    }
    return (value as int?) ?? 0;
  }

  int funnelUsers(Map<String, dynamic>? row, String event) {
    for (final step in ((row?['funnel'] as List?) ?? const []).cast<Map>()) {
      if (step['event_name'] == event) return step['users'] as int;
    }
    return 0;
  }

  Future<String> user(int index, {Duration offset = Duration.zero}) async {
    final name = 'kpi_cohort_${suffix}_$index';
    final result = await pool.execute(
      Sql.named('''
        INSERT INTO users (username, email, password_hash, created_at)
        VALUES (@name, @email, 'x', @createdAt)
        RETURNING id::text
      '''),
      parameters: {
        'name': name,
        'email': '$name@example.invalid',
        'createdAt': signupBase.add(offset),
      },
    );
    final id = result.single.single! as String;
    seededUsers.add(id);
    return id;
  }

  Future<String> deck(
    String userId,
    DateTime createdAt, {
    bool trashed = false,
  }) async {
    final result = await pool.execute(
      Sql.named('''
        INSERT INTO decks (
          user_id, name, format, description, created_at, deleted_at
        ) VALUES (
          CAST(@userId AS uuid), @name, 'commander', @description,
          CAST(@createdAt AS timestamptz),
          CASE WHEN @trashed THEN CAST(@createdAt AS timestamptz) END
        )
        RETURNING id::text
      '''),
      parameters: {
        'userId': userId,
        'name': '$marker deck',
        'description': '$marker descricao',
        'createdAt': createdAt,
        'trashed': trashed,
      },
    );
    final id = result.single.single! as String;
    seededDecks.add(id);
    return id;
  }

  Future<void> event(
    String userId,
    String name,
    DateTime createdAt, {
    Map<String, Object?> metadata = const {},
  }) => pool.execute(
    Sql.named('''
      INSERT INTO activation_funnel_events (
        user_id, event_name, source, metadata, created_at
      ) VALUES (
        CAST(@userId AS uuid), @name, 'onboarding', CAST(@metadata AS jsonb),
        @createdAt
      )
    '''),
    parameters: {
      'userId': userId,
      'name': name,
      'metadata': jsonEncode(metadata),
      'createdAt': createdAt,
    },
  );

  Future<void> ledger(
    String userId,
    String deckId,
    String operation,
    DateTime createdAt,
  ) => pool.execute(
    Sql.named('''
      INSERT INTO deck_change_events (
        deck_id, user_id, revision_before, revision_after, operation,
        created_at
      ) VALUES (
        CAST(@deckId AS uuid), CAST(@userId AS uuid), 1, 2, @operation,
        @createdAt
      )
    '''),
    parameters: {
      'deckId': deckId,
      'userId': userId,
      'operation': operation,
      'createdAt': createdAt,
    },
  );

  Future<void> aiAction(
    String userId,
    DateTime createdAt, {
    String endpoint = 'plan:post:/ai/optimize',
    bool success = true,
  }) async {
    final result = await pool.execute(
      Sql.named('''
        INSERT INTO ai_logs (
          user_id, endpoint, model, success, latency_ms, created_at,
          prompt_summary
        ) VALUES (
          CAST(@userId AS uuid), @endpoint, 'gpt-test', @success, 10,
          @createdAt, @summary
        )
        RETURNING id::text
      '''),
      parameters: {
        'userId': userId,
        'endpoint': endpoint,
        'success': success,
        'createdAt': createdAt,
        'summary': '$marker prompt',
      },
    );
    seededAiLogs.add(result.single.single! as String);
  }

  test('coorte: ativação em 24 h, volta na segunda semana, loops e funil '
      'contam usuários', () async {
    final before = await cohortRow();

    // u1: deck em 2 h (ativa), nota no 8º dia (volta), três eventos iguais.
    final u1 = await user(1);
    final u1Signup = signupBase;
    final u1Deck = await deck(u1, u1Signup.add(const Duration(hours: 2)));
    await pool.execute(
      Sql.named('''
        INSERT INTO post_game_notes (id, user_id, deck_id, notes, created_at)
        VALUES (@id, CAST(@userId AS uuid), CAST(@deckId AS uuid), @notes,
                @createdAt)
      '''),
      parameters: {
        'id': 'kpi-note-$suffix',
        'userId': u1,
        'deckId': u1Deck,
        'notes': '$marker nota do pos-jogo',
        'createdAt': u1Signup.add(const Duration(days: 8)),
      },
    );
    for (var i = 0; i < 3; i++) {
      await event(
        u1,
        'core_flow_started',
        u1Signup.add(Duration(minutes: i)),
        metadata: {'deck_name': '$marker metadado antigo'},
      );
    }
    await event(u1, 'deck_created', u1Signup.add(const Duration(hours: 2)));

    // u2: deck em 30 h (não ativa); ajuste no 6º dia e ação no 14º dia
    // exato (fora da segunda semana): não volta.
    final u2 = await user(2, offset: const Duration(minutes: 1));
    final u2Signup = signupBase.add(const Duration(minutes: 1));
    final u2Deck = await deck(u2, u2Signup.add(const Duration(hours: 30)));
    await ledger(u2, u2Deck, 'card_add', u2Signup.add(const Duration(days: 6)));
    await event(u2, 'deck_created', u2Signup.add(const Duration(days: 14)));

    // u3: sem deck; evento no fim do 14º dia (ainda na segunda semana).
    final u3 = await user(3, offset: const Duration(minutes: 2));
    final u3Signup = signupBase.add(const Duration(minutes: 2));
    await event(u3, 'core_flow_started', u3Signup);
    await event(
      u3,
      'onboarding_completed',
      u3Signup.add(const Duration(days: 13, hours: 23, minutes: 59)),
    );

    // u4: conta excluída: fora das contagens, mesmo com deck e evento.
    final u4 = await user(4, offset: const Duration(minutes: 3));
    final u4Signup = signupBase.add(const Duration(minutes: 3));
    await deck(u4, u4Signup.add(const Duration(hours: 1)));
    await event(u4, 'core_flow_started', u4Signup);
    await pool.execute(
      Sql.named(
        'UPDATE users SET deleted_at = NOW() WHERE id = CAST(@id AS uuid)',
      ),
      parameters: {'id': u4},
    );

    // u5: deck em 23h59 que foi para a lixeira no 9º dia: ainda ativa e
    // volta (ir para a lixeira é uma ação), mas não é ajuste de deck.
    final u5 = await user(5, offset: const Duration(minutes: 4));
    final u5Signup = signupBase.add(const Duration(minutes: 4));
    final u5Deck = await deck(
      u5,
      u5Signup.add(const Duration(hours: 23, minutes: 59)),
      trashed: true,
    );
    await ledger(
      u5,
      u5Deck,
      'deck_delete',
      u5Signup.add(const Duration(days: 9)),
    );

    // u6: sem deck; ação de IA concluída no 10º dia (volta e usou IA); a
    // reserva que falhou não conta.
    final u6 = await user(6, offset: const Duration(minutes: 5));
    final u6Signup = signupBase.add(const Duration(minutes: 5));
    await aiAction(u6, u6Signup.add(const Duration(days: 10)));
    await aiAction(
      u6,
      u6Signup.add(const Duration(days: 3)),
      endpoint: 'plan-reservation:post:/ai/optimize',
      success: false,
    );

    // u7: só uma reserva de IA que falhou no 9º dia: não é ação, não volta.
    final u7 = await user(7, offset: const Duration(minutes: 6));
    final u7Signup = signupBase.add(const Duration(minutes: 6));
    await aiAction(
      u7,
      u7Signup.add(const Duration(days: 9)),
      endpoint: 'plan-reservation:post:/ai/optimize',
      success: false,
    );

    final after = await cohortRow();
    int delta(List<String> path) =>
        counter(after, path) - counter(before, path);

    expect(delta(['signups']), 6);
    expect(delta(['deleted_accounts']), 1);
    expect(delta(['activation', 'matured']), 6);
    expect(delta(['activation', 'activated_24h']), 2);
    expect(delta(['week2_return', 'matured']), 6);
    expect(delta(['week2_return', 'returned']), 4);
    expect(delta(['loops', 'deck_built', 'users']), 3);
    expect(delta(['loops', 'game_noted', 'users']), 1);
    expect(delta(['loops', 'deck_improved', 'users']), 1);
    expect(delta(['loops', 'ai_used', 'users']), 1);
    expect(
      funnelUsers(after, 'core_flow_started') -
          funnelUsers(before, 'core_flow_started'),
      2,
    );
    expect(
      funnelUsers(after, 'deck_created') - funnelUsers(before, 'deck_created'),
      2,
    );
    expect(
      funnelUsers(after, 'onboarding_completed') -
          funnelUsers(before, 'onboarding_completed'),
      1,
    );

    // Taxas por usuário nunca passam de 1.
    if (before == null) {
      expect((after!['activation'] as Map)['rate'], 0.3333);
      expect((after['week2_return'] as Map)['rate'], 0.6667);
      expect(
        (after['funnel'] as List).cast<Map>().firstWhere(
          (step) => step['event_name'] == 'core_flow_started',
        )['share'],
        0.3333,
      );
    }
    for (final step in (after!['funnel'] as List).cast<Map>()) {
      final share = step['share'] as double?;
      expect(share == null || share <= 1, isTrue, reason: '$step');
    }
  }, skip: skipReason);

  test(
    'coorte recente ainda não entra na taxa de ativação nem na volta',
    () async {
      final kpi = await service.activationKpi(days: 90);
      final totalsBefore = kpi['totals'] as Map;
      final name = 'kpi_cohort_${suffix}_recent';
      final created = await pool.execute(
        Sql.named('''
        INSERT INTO users (username, email, password_hash)
        VALUES (@name, @email, 'x')
        RETURNING id::text
      '''),
        parameters: {'name': name, 'email': '$name@example.invalid'},
      );
      await deck(created.single.single! as String, DateTime.now().toUtc());
      final totalsAfter =
          (await service.activationKpi(days: 90))['totals'] as Map;

      int at(Map totals, String group, String key) =>
          (totals[group] as Map)[key] as int;
      expect(
        (totalsAfter['signups'] as int) - (totalsBefore['signups'] as int),
        1,
      );
      expect(
        at(totalsAfter, 'activation', 'matured') -
            at(totalsBefore, 'activation', 'matured'),
        0,
      );
      expect(
        at(totalsAfter, 'activation', 'activated_24h') -
            at(totalsBefore, 'activation', 'activated_24h'),
        0,
      );
      expect(
        at(totalsAfter, 'week2_return', 'matured') -
            at(totalsBefore, 'week2_return', 'matured'),
        0,
      );
    },
    skip: skipReason,
  );

  test('guardrails de custo e erro de IA e do Generate somam o que foi '
      'semeado', () async {
    Future<Map<String, Map<String, Object?>>> items() async {
      final guardrails = await service.activationGuardrails(days: 30);
      expect(guardrails['version'], 1);
      return {
        for (final item in (guardrails['items'] as List).cast<Map>())
          item['id'] as String: item.cast<String, Object?>(),
      };
    }

    final before = await items();
    final name = 'kpi_cohort_${suffix}_ai';
    final created = await pool.execute(
      Sql.named('''
        INSERT INTO users (username, email, password_hash)
        VALUES (@name, @email, 'x')
        RETURNING id::text
      '''),
      parameters: {'name': name, 'email': '$name@example.invalid'},
    );
    final aiUser = created.single.single! as String;
    final now = DateTime.now().toUtc();
    for (var i = 0; i < 4; i++) {
      await aiAction(
        aiUser,
        now,
        endpoint: 'provider:optimize',
        success: i != 0,
      );
    }
    for (var i = 0; i < 6; i++) {
      await aiAction(aiUser, now);
    }
    await aiAction(aiUser, now, success: false);
    for (final status in ['completed', 'failed', 'failed', 'pending']) {
      await pool.execute(
        Sql.named('''
          INSERT INTO ai_generate_requests (
            user_id, request_key, format, status, prompt
          ) VALUES (
            CAST(@userId AS uuid), @key, 'commander', @status, @prompt
          )
        '''),
        parameters: {
          'userId': aiUser,
          'key': 'kpi-$suffix-$status-${DateTime.now().microsecondsSinceEpoch}',
          'status': status,
          'prompt': '$marker prompt do Generate',
        },
      );
    }
    final after = await items();

    int delta(String id, String key) =>
        ((after[id]![key] as int?) ?? 0) - ((before[id]?[key] as int?) ?? 0);
    expect(delta('ai_provider_error_rate', 'sample'), 4);
    expect(delta('ai_provider_error_rate', 'errors'), 1);
    expect(delta('ai_actions_per_ai_user_30d', 'actions'), 6);
    expect(delta('ai_actions_per_ai_user_30d', 'sample'), 1);
    expect(after['ai_actions_per_ai_user_30d']!['monthly_cap'], 120);
    expect(delta('generate_failure_rate', 'sample'), 3);
    expect(delta('generate_failure_rate', 'failed'), 2);
    for (final item in after.values) {
      expect([
        'ok',
        'warning',
        'critical',
        'insufficient_data',
      ], contains(item['status']));
    }
  }, skip: skipReason);

  test('nenhum conteúdo do usuário nem ID sai no painel comercial', () async {
    final snapshot = await service.snapshot(days: 90);
    final text = jsonEncode(snapshot);
    expect(snapshot['activation'], isA<Map>());
    expect(snapshot['guardrails'], isA<Map>());
    expect(snapshot.containsKey('activation_funnel'), isFalse);
    expect(text, isNot(contains(marker)));
    expect(text, isNot(contains('kpi_cohort_$suffix')));
    for (final id in [...seededUsers, ...seededDecks]) {
      expect(text, isNot(contains(id)), reason: id);
    }
  }, skip: skipReason);
}
