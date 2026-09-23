@Tags(['live', 'live_db_write'])
library;

import 'dart:convert';

import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import '../lib/auth_service.dart';
import '../lib/privacy/deleted_deck_anonymizer.dart';
import '../lib/user_data_privacy_service.dart';
import 'support/privacy_db_fixture.dart';

/// BT-PRIV-002 (D-23) em PostgreSQL descartável: A exclui a conta com dado
/// de A, B e C em todas as tabelas. O que é de A some ou fica anonimizado, as
/// lacunas do inventário ficam fechadas, a simulação que B rodou contra o
/// deck público de A continua com B sem apontar para A, e nada de B muda.
///
/// Requer `RUN_PRIVACY_DB_TESTS=1` e as variáveis `DB_*` de um banco
/// descartável já migrado.
void main() {
  final enabled = privacyDbTestsEnabled();
  final skipReason = enabled ? null : privacyDbSkipReason;
  const password = 'Senha!Titular-2026';

  late Pool pool;
  late PrivacyDbFixture fixture;
  late Map<String, dynamic> response;

  setUpAll(() async {
    if (!enabled) return;
    AuthService.resetForTesting();
    pool = openPrivacyTestPool();
    fixture = await PrivacyDbFixture.seed(
      pool,
      passwordHash: AuthService().hashPassword(password),
    );
    response = await UserDataPrivacyService(
      pool,
    ).deleteAndAnonymizeAccount(userId: fixture.userA, password: password);
  });

  tearDownAll(() async {
    if (enabled) await pool.close();
  });

  Future<int> count(
    String sql, [
    Map<String, Object?> parameters = const {},
  ]) async {
    final result = await pool.execute(Sql.named(sql), parameters: parameters);
    return result.single.single! as int;
  }

  Future<Map<String, dynamic>> row(
    String sql, [
    Map<String, Object?> parameters = const {},
  ]) async {
    final result = await pool.execute(Sql.named(sql), parameters: parameters);
    return result.single.toColumnMap();
  }

  test('a conta fica pseudonimizada e sem segredo', () async {
    expect(response['account_deleted'], isTrue);
    final user = await row(
      'SELECT username, email, display_name, fcm_token, deleted_at '
      'FROM users WHERE id = CAST(@id AS uuid)',
      {'id': fixture.userA},
    );
    expect(user['username'], startsWith('deleted_'));
    expect(user['email'], endsWith('@deleted.invalid'));
    expect(user['display_name'], 'Usuário excluído');
    expect(user['fcm_token'], isNull);
    expect(user['deleted_at'], isNotNull);
  }, skip: skipReason);

  test('conteúdo e atividade de A foram apagados', () async {
    for (final table in [
      'decks',
      'user_binder_items',
      'post_game_notes',
      'shared_deck_reports',
      'deck_comments',
      'activation_funnel_events',
      'deck_optimization_events',
      'ai_logs',
      'ml_prompt_feedback',
      'ai_optimize_fallback_telemetry',
      'ai_optimize_cache',
      'ai_generate_jobs',
      'ai_optimize_jobs',
      'battle_jobs',
      'interactive_battle_sessions',
      'battle_simulation_attempts',
      'battle_replay_annotations',
      'ai_user_preferences',
      'user_plans',
    ]) {
      expect(
        await count(
          'SELECT COUNT(*)::int FROM $table WHERE user_id = CAST(@id AS uuid)',
          {'id': fixture.userA},
        ),
        0,
        reason: table,
      );
    }
  }, skip: skipReason);

  test('lacunas do inventário: bloqueios e tokens de A somem', () async {
    expect(
      await count(
        'SELECT COUNT(*)::int FROM user_blocks '
        'WHERE blocker_id = CAST(@id AS uuid) OR blocked_id = CAST(@id AS uuid)',
        {'id': fixture.userA},
      ),
      0,
    );
    for (final table in [
      'password_reset_tokens',
      'email_verification_tokens',
    ]) {
      expect(
        await count(
          'SELECT COUNT(*)::int FROM $table WHERE user_id = CAST(@id AS uuid)',
          {'id': fixture.userA},
        ),
        0,
        reason: table,
      );
    }
  }, skip: skipReason);

  test('lacunas do inventário: eventos de bloqueio, recurso, moderação e '
      'evidência ficam sem A', () async {
    expect(
      await count(
        'SELECT COUNT(*)::int FROM user_block_events '
        'WHERE actor_user_id = CAST(@id AS uuid) '
        'OR target_user_id = CAST(@id AS uuid)',
        {'id': fixture.userA},
      ),
      0,
    );
    final eventByC = await row(
      'SELECT actor_user_id::text AS actor, target_user_id FROM user_block_events '
      'WHERE request_id = @request',
      {'request': fixture.blockRequestOfC},
    );
    expect(eventByC['actor'], fixture.userC);
    expect(eventByC['target_user_id'], isNull);
    final eventByA = await row(
      'SELECT actor_user_id, target_user_id::text AS target, reason '
      'FROM user_block_events WHERE request_id = @request',
      {'request': fixture.blockRequestOfA},
    );
    expect(eventByA['actor_user_id'], isNull);
    expect(eventByA['target'], fixture.userC);
    expect(eventByA['reason'], isNull);

    final appeal = await row(
      'SELECT reason FROM content_report_appeals WHERE id = CAST(@id AS uuid)',
      {'id': fixture.appealByA},
    );
    expect(appeal['reason'], '[recurso removido pelo titular]');
    expect(
      await count(
        'SELECT COUNT(*)::int FROM moderation_actions '
        'WHERE moderator_user_id = CAST(@id AS uuid)',
        {'id': fixture.userA},
      ),
      0,
    );
    final report = await row(
      'SELECT reporter_user_id, details, evidence FROM content_reports '
      'WHERE id = CAST(@id AS uuid)',
      {'id': fixture.reportByA},
    );
    expect(report['reporter_user_id'], isNull);
    expect(report['details'], '');
    expect(report['evidence'], <String, dynamic>{});
  }, skip: skipReason);

  test('a simulação que B rodou contra o deck público de A fica com B, sem '
      'apontar para A (D-23)', () async {
    final simulation = await row(
      'SELECT deck_a_id::text AS deck_a, deck_b_id, winner_deck_id, game_log, '
      'metrics FROM battle_simulations WHERE id = CAST(@id AS uuid)',
      {'id': fixture.simulationByB},
    );
    expect(simulation['deck_a'], fixture.deckB2Private);
    expect(simulation['deck_b_id'], isNull);
    expect(simulation['winner_deck_id'], isNull);
    final replay = jsonEncode([simulation['game_log'], simulation['metrics']]);
    expect(replay, isNot(contains(fixture.deckA2Public)));
    expect(replay, contains(deletedDeckPlaceholderId));
    expect(replay, contains(deletedDeckPlaceholderName));

    final attempt = await row(
      'SELECT user_id::text AS owner, deck_b_id, deck_a_hash, deck_b_hash '
      'FROM battle_simulation_attempts WHERE id = CAST(@id AS uuid)',
      {'id': fixture.attemptByB},
    );
    expect(attempt['owner'], fixture.userB);
    expect(attempt['deck_b_id'], isNull);
    expect(attempt['deck_a_hash'], isNotNull, reason: 'o lado de B fica');
    expect(attempt['deck_b_hash'], isNull, reason: 'o lado de A some');

    final job = await row(
      'SELECT user_id::text AS owner, deck_b_id FROM battle_jobs '
      'WHERE id = CAST(@id AS uuid)',
      {'id': fixture.jobByBAgainstA},
    );
    expect(job['owner'], fixture.userB);
    expect(job['deck_b_id'], isNull);
  }, skip: skipReason);

  test('a simulação que A rodou sai junto com A', () async {
    expect(
      await count(
        'SELECT COUNT(*)::int FROM battle_simulations WHERE id = CAST(@id AS uuid)',
        {'id': fixture.simulationByA},
      ),
      0,
    );
    expect(
      await count(
        'SELECT COUNT(*)::int FROM battle_simulation_attempts '
        'WHERE id = CAST(@id AS uuid)',
        {'id': fixture.attemptByA},
      ),
      0,
    );
  }, skip: skipReason);

  test('nada de B muda: decks, mensagens e troca continuam', () async {
    expect(
      await count(
        'SELECT COUNT(*)::int FROM decks WHERE user_id = CAST(@id AS uuid)',
        {'id': fixture.userB},
      ),
      2,
    );
    expect(
      await count(
        'SELECT COUNT(*)::int FROM direct_messages WHERE message = @text',
        {'text': 'oi de B ${fixture.suffix}'},
      ),
      1,
    );
    expect(
      await count(
        'SELECT COUNT(*)::int FROM trade_messages WHERE message = @text',
        {'text': 'mensagem de troca de B ${fixture.suffix}'},
      ),
      1,
    );
    final trade = await row(
      'SELECT message, tracking_code FROM trade_offers WHERE id = CAST(@id AS uuid)',
      {'id': fixture.tradeFromB},
    );
    expect(trade['message'], 'mensagem da proposta de B ${fixture.suffix}');
    expect(trade['tracking_code'], isNull);
  }, skip: skipReason);

  test('o recibo diz o que foi feito e não identifica A', () async {
    final receipt = await row(
      'SELECT policy_version, retention_summary FROM account_deletion_receipts '
      'ORDER BY completed_at DESC LIMIT 1',
    );
    expect(receipt['policy_version'], accountDeletionPolicyVersion);
    expect(receipt['retention_summary'], accountDeletionRetentionSummary);
    final text = jsonEncode(receipt);
    expect(text, isNot(contains(fixture.userA)));
    expect(text, isNot(contains('privacy_A_${fixture.suffix}')));
  }, skip: skipReason);

  test('pedir de novo não reabre a conta', () async {
    await expectLater(
      UserDataPrivacyService(
        pool,
      ).deleteAndAnonymizeAccount(userId: fixture.userA, password: password),
      throwsA(isA<UserDataNotFoundException>()),
    );
  }, skip: skipReason);
}
