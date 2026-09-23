import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:postgres/postgres.dart';

import 'auth_service.dart';
import 'privacy/account_deletion_outbox.dart';
import 'privacy/deleted_deck_anonymizer.dart';
import 'privacy/privacy_export_allowlist.dart';
import 'privacy/privacy_export_pseudonymizer.dart';
import 'rate_limit_middleware.dart' show credentialEmailRateLimitIdentifier;

const accountDeletionConfirmation = 'EXCLUIR MINHA CONTA';

/// Versão da política gravada em cada recibo. A v2 anonimiza as simulações
/// de outras pessoas contra o deck público de quem saiu (D-23), fecha as
/// lacunas do inventário (BT-PRIV-003) e para quando falta uma relação. A v3
/// cancela as ofertas de troca abertas e trata os itens de troca (D-66). A v4
/// grava o outbox da exclusão para os lugares fora do PostgreSQL (D-68).
const accountDeletionPolicyVersion = 'brewtact-beta-privacy-v4';

/// Nota gravada no histórico da oferta aberta que a exclusão cancela (D-66).
const openTradeOfferCancelledNote = 'Oferta cancelada: a conta foi excluída.';

/// O que a exclusão faz com cada classe de dado; vai no recibo e na resposta.
const accountDeletionRetentionSummary = <String, String>{
  'trades_and_disputes': 'anonymized',
  'open_trade_offers': 'cancelled',
  'moderation_records': 'anonymized',
  'operational_aggregates': 'deidentified',
  'deck_learning_and_battle_rows': 'deleted',
  'third_party_simulations_against_public_decks': 'anonymized',
  'blocks_and_account_tokens': 'deleted',
  'deleted_deck_anti_resurrection_keys': 'opaque_identifier_only',
  'copies_outside_database': 'queued_for_each_consumer',
};

/// Relações que a exclusão toca. Todas são conferidas antes da primeira
/// escrita: relação ausente para a exclusão em vez de virar sucesso.
const accountDeletionRelations = <String>[
  'account_deletion_outbox',
  'account_deletion_receipts',
  'activation_funnel_events',
  'ai_generate_jobs',
  'ai_logs',
  'ai_optimize_cache',
  'ai_optimize_fallback_telemetry',
  'ai_optimize_jobs',
  'ai_user_preferences',
  'battle_jobs',
  'battle_replay_annotations',
  'battle_simulation_attempts',
  'battle_simulations',
  'content_report_appeals',
  'content_reports',
  'conversations',
  'deck_comments',
  'deck_learning_events',
  'deck_optimization_events',
  'decks',
  'direct_messages',
  'email_verification_tokens',
  'interactive_battle_sessions',
  'ml_prompt_feedback',
  'moderation_actions',
  'notifications',
  'password_reset_tokens',
  'post_game_notes',
  'privacy_deleted_deck_tombstones',
  'privacy_keyring',
  'rate_limit_events',
  'shared_deck_reports',
  'trade_items',
  'trade_messages',
  'trade_offers',
  'trade_status_history',
  'user_binder_items',
  'user_block_events',
  'user_blocks',
  'user_follows',
  'user_plans',
  'users',
];

class UserDataNotFoundException implements Exception {}

class InvalidAccountPasswordException implements Exception {}

class UserDataPrivacyService {
  UserDataPrivacyService(this.pool, {AuthService? authService})
    : _authService = authService ?? AuthService();

  final Pool pool;
  final AuthService _authService;

  /// Reverificação de senha por requisição (D-20), sem migração: compara a
  /// senha enviada com `users.password_hash`. A exportação chama antes de
  /// montar o arquivo; a exclusão confere dentro da própria transação.
  Future<void> verifyCurrentPassword({
    required String userId,
    required String password,
  }) async {
    final result = await pool.execute(
      Sql.named('''
        SELECT password_hash
        FROM users
        WHERE id = CAST(@userId AS uuid)
          AND deleted_at IS NULL
        LIMIT 1
      '''),
      parameters: {'userId': userId},
    );
    if (result.isEmpty) throw UserDataNotFoundException();
    final passwordHash = result.first.toColumnMap()['password_hash'];
    if (!_passwordMatches(password, passwordHash?.toString() ?? '')) {
      throw InvalidAccountPasswordException();
    }
  }

  bool _passwordMatches(String password, String passwordHash) {
    try {
      return _authService.verifyPassword(password, passwordHash);
    } catch (_) {
      return false;
    }
  }

  /// Exportação dos dados da conta (BT-PRIV-001, D-22).
  ///
  /// Gerada sob demanda numa transação somente leitura e devolvida ao
  /// cliente; o servidor não guarda cópia. Cada seção sai só com as colunas da
  /// allowlist (`lib/privacy/privacy_export_allowlist.dart`, espelho do
  /// inventário do BT-PRIV-003). IDs de outras pessoas viram pseudônimos que
  /// só valem neste arquivo, e hashes, fingerprints e chaves internas saem de
  /// qualquer profundidade do JSON. Relação ausente derruba a exportação em
  /// vez de devolver uma seção vazia.
  Future<Map<String, dynamic>> exportUserData(String userId) {
    return pool.runTx(
      (session) async {
        final rows = <String, List<Map<String, dynamic>>>{};
        for (final section in privacyExportSections) {
          final result = await session.execute(
            Sql.named(privacyExportSectionSql(section)),
            parameters: {'userId': userId},
          );
          final sectionRows = result
              .map((row) => _jsonObject(row[0]))
              .toList(growable: false);
          if (section.path == privacyExportAccountPath && sectionRows.isEmpty) {
            throw UserDataNotFoundException();
          }
          rows[section.path] = sectionRows;
        }
        return _assembleExport(userId, rows);
      },
      settings: TransactionSettings(
        isolationLevel: IsolationLevel.repeatableRead,
        accessMode: AccessMode.readOnly,
      ),
    );
  }

  Map<String, dynamic> _assembleExport(
    String userId,
    Map<String, List<Map<String, dynamic>>> rows,
  ) {
    final pseudonymizer = PrivacyExportPseudonymizer(
      subjectUserId: userId,
      ownDeckIds: [for (final deck in rows['data.decks']!) '${deck['id']}'],
      sharedEntityIds: [
        for (final trade in rows['data.trades']!) '${trade['id']}',
        for (final conversation in rows['data.conversations']!)
          '${conversation['id']}',
      ],
    );
    Object? account;
    final data = <String, dynamic>{};
    for (final section in privacyExportSections) {
      final sectionRows = [
        for (final row in rows[section.path]!)
          _pseudonymizeRow(section, row, pseudonymizer),
      ];
      final Object? value =
          section.single
              ? (sectionRows.isEmpty ? null : sectionRows.first)
              : sectionRows;
      if (section.path == privacyExportAccountPath) {
        account = value;
      } else {
        _putExportPath(data, section.path, value);
      }
    }
    final export = <String, dynamic>{
      'schema_version': privacyExportSchemaVersion,
      'exported_at': DateTime.now().toUtc().toIso8601String(),
      'account': account,
      'data': data,
      'portability': privacyExportPortability,
    };
    return pseudonymizer.scrub(export)! as Map<String, dynamic>;
  }

  static Map<String, dynamic> _pseudonymizeRow(
    PrivacyExportSection section,
    Map<String, dynamic> row,
    PrivacyExportPseudonymizer pseudonymizer,
  ) => {
    for (final MapEntry(key: column, value: value) in row.entries)
      column: switch (section.fields[column]) {
        PrivacyExportField.personRef => pseudonymizer.person(value),
        PrivacyExportField.deckRef => pseudonymizer.deck(value),
        PrivacyExportField.entityRef => pseudonymizer.entity(value),
        _ => value,
      },
  };

  static void _putExportPath(
    Map<String, dynamic> data,
    String path,
    Object? value,
  ) {
    final parts = path.split('.');
    if (parts.length < 2 || parts.first != 'data') {
      throw StateError('Seção de exportação fora de data: $path');
    }
    var node = data;
    for (final part in parts.sublist(1, parts.length - 1)) {
      node =
          node.putIfAbsent(part, () => <String, dynamic>{})
              as Map<String, dynamic>;
    }
    node[parts.last] = value;
  }

  Future<Map<String, dynamic>> deleteAndAnonymizeAccount({
    required String userId,
    required String password,
  }) {
    return pool.runTx((session) async {
      final userResult = await session.execute(
        Sql.named('''
          SELECT username, email, password_hash
          FROM users
          WHERE id = CAST(@userId AS uuid)
            AND deleted_at IS NULL
          FOR UPDATE
        '''),
        parameters: {'userId': userId},
      );
      if (userResult.isEmpty) throw UserDataNotFoundException();

      final user = userResult.first.toColumnMap();
      final passwordHash = user['password_hash']?.toString() ?? '';
      if (!_passwordMatches(password, passwordHash)) {
        throw InvalidAccountPasswordException();
      }
      await _requireRelations(session, accountDeletionRelations);
      final ownDeckIds = await _ownDeckIds(session, userId);

      final originalEmail = user['email']?.toString() ?? '';
      final randomSecret = _secureRandomToken();
      final pseudonym = sha256
          .convert(utf8.encode('$userId|$randomSecret'))
          .toString()
          .substring(0, 24);
      final deletedUsername = 'deleted_$pseudonym';
      final deletedEmail = '$deletedUsername@deleted.invalid';
      final replacementPasswordHash = _authService.hashPassword(randomSecret);
      final deletedAt = DateTime.now().toUtc();

      await _executeOn(
        session,
        'ai_logs',
        'DELETE FROM ai_logs WHERE user_id = CAST(@userId AS uuid)',
        userId,
      );
      await _executeOn(
        session,
        'ai_optimize_fallback_telemetry',
        'DELETE FROM ai_optimize_fallback_telemetry '
            'WHERE user_id = CAST(@userId AS uuid)',
        userId,
      );
      await _executeOn(
        session,
        'ai_optimize_cache',
        'DELETE FROM ai_optimize_cache WHERE user_id = CAST(@userId AS uuid)',
        userId,
      );
      await _executeOn(
        session,
        'ai_optimize_jobs',
        'DELETE FROM ai_optimize_jobs WHERE user_id = CAST(@userId AS uuid)',
        userId,
      );
      await _executeOn(
        session,
        'ai_generate_jobs',
        'DELETE FROM ai_generate_jobs WHERE user_id = CAST(@userId AS uuid)',
        userId,
      );
      await _executeOn(
        session,
        'battle_jobs',
        'DELETE FROM battle_jobs WHERE user_id = CAST(@userId AS uuid)',
        userId,
      );
      await _executeOn(
        session,
        'interactive_battle_sessions',
        'DELETE FROM interactive_battle_sessions '
            'WHERE user_id = CAST(@userId AS uuid)',
        userId,
      );
      await _executeOn(
        session,
        'ml_prompt_feedback',
        'DELETE FROM ml_prompt_feedback WHERE user_id = CAST(@userId AS uuid)',
        userId,
      );
      await _executeOn(
        session,
        'activation_funnel_events',
        'DELETE FROM activation_funnel_events '
            'WHERE user_id = CAST(@userId AS uuid)',
        userId,
      );
      await _executeOn(
        session,
        'deck_optimization_events',
        'DELETE FROM deck_optimization_events '
            'WHERE user_id = CAST(@userId AS uuid)',
        userId,
      );
      await _executeOn(
        session,
        'shared_deck_reports',
        'DELETE FROM shared_deck_reports '
            'WHERE user_id = CAST(@userId AS uuid)',
        userId,
      );
      await _executeOn(
        session,
        'post_game_notes',
        'DELETE FROM post_game_notes WHERE user_id = CAST(@userId AS uuid)',
        userId,
      );
      await _executeOn(
        session,
        'deck_comments',
        'DELETE FROM deck_comments WHERE user_id = CAST(@userId AS uuid)',
        userId,
      );
      await _executeOn(
        session,
        'user_follows',
        'DELETE FROM user_follows '
            'WHERE follower_id = CAST(@userId AS uuid) '
            'OR following_id = CAST(@userId AS uuid)',
        userId,
      );
      await _executeOn(session, 'notifications', '''
          DELETE FROM notifications
          WHERE type = 'new_follower'
            AND reference_id::text = @userId
        ''', userId);
      await _executeOnAll(
        session,
        const ['notifications', 'trade_offers'],
        '''
          DELETE FROM notifications n
          USING trade_offers t
          WHERE n.reference_id::text = t.id::text
            AND (
              t.sender_id = CAST(@userId AS uuid)
              OR t.receiver_id = CAST(@userId AS uuid)
            )
        ''',
        userId,
      );
      await _executeOnAll(
        session,
        const ['notifications', 'conversations'],
        '''
          DELETE FROM notifications n
          USING conversations c
          WHERE n.reference_id::text = c.id::text
            AND (
              c.user_a_id = CAST(@userId AS uuid)
              OR c.user_b_id = CAST(@userId AS uuid)
            )
        ''',
        userId,
      );
      await _executeOn(
        session,
        'notifications',
        'DELETE FROM notifications WHERE user_id = CAST(@userId AS uuid)',
        userId,
      );
      await _executeOn(session, 'content_reports', '''
          UPDATE content_reports
          SET reporter_user_id = NULL, details = '', evidence = '{}'::jsonb
          WHERE reporter_user_id = CAST(@userId AS uuid)
        ''', userId);
      await _executeOn(
        session,
        'content_reports',
        'UPDATE content_reports SET reviewed_by = NULL '
            'WHERE reviewed_by = CAST(@userId AS uuid)',
        userId,
      );
      await _executeOn(session, 'direct_messages', '''
          UPDATE direct_messages
          SET message = '[mensagem removida pelo titular]'
          WHERE sender_id = CAST(@userId AS uuid)
        ''', userId);
      await _executeOn(session, 'trade_messages', '''
          UPDATE trade_messages
          SET message = '[mensagem removida pelo titular]',
              attachment_url = NULL,
              attachment_type = NULL
          WHERE sender_id = CAST(@userId AS uuid)
        ''', userId);
      await _executeOn(session, 'trade_status_history', '''
          UPDATE trade_status_history
          SET notes = '[detalhe removido pelo titular]'
          WHERE changed_by = CAST(@userId AS uuid)
        ''', userId);
      await _executeOn(session, 'trade_offers', '''
          UPDATE trade_offers
          SET message = CASE
                WHEN sender_id = CAST(@userId AS uuid) THEN NULL
                ELSE message
              END,
              tracking_code = NULL,
              updated_at = CURRENT_TIMESTAMP
          WHERE sender_id = CAST(@userId AS uuid)
             OR receiver_id = CAST(@userId AS uuid)
        ''', userId);
      // D-66: os itens de troca são tratados aqui, sem depender da ação da
      // chave trade_items.owner_id. Oferta aberta (pending) é cancelada e
      // perde os itens do titular; nas demais a troca fica para a outra
      // pessoa, e os itens do titular perdem o vínculo com o fichário dele.
      await _executeOn(
        session,
        'trade_offers',
        '''
          WITH open_offers AS (
            SELECT offer.id
            FROM trade_offers offer
            WHERE offer.status = 'pending'
              AND (
                offer.sender_id = CAST(@userId AS uuid)
                OR offer.receiver_id = CAST(@userId AS uuid)
              )
            FOR UPDATE
          ), removed_items AS (
            DELETE FROM trade_items item
            USING open_offers
            WHERE item.trade_offer_id = open_offers.id
              AND item.owner_id = CAST(@userId AS uuid)
            RETURNING item.id
          ), cancelled AS (
            UPDATE trade_offers offer
            SET status = 'cancelled',
                updated_at = CURRENT_TIMESTAMP
            FROM open_offers
            WHERE offer.id = open_offers.id
            RETURNING offer.id
          )
          INSERT INTO trade_status_history (
            trade_offer_id, old_status, new_status, changed_by, notes
          )
          SELECT
            cancelled.id,
            'pending',
            'cancelled',
            CAST(@userId AS uuid),
            @cancelNote
          FROM cancelled
        ''',
        userId,
        extraParameters: {'cancelNote': openTradeOfferCancelledNote},
      );
      await _executeOn(session, 'trade_items', '''
          UPDATE trade_items
          SET binder_item_id = NULL
          WHERE owner_id = CAST(@userId AS uuid)
            AND binder_item_id IS NOT NULL
        ''', userId);
      await _executeOn(
        session,
        'user_binder_items',
        'DELETE FROM user_binder_items WHERE user_id = CAST(@userId AS uuid)',
        userId,
      );
      final deckTombstoneResult = await session.execute(
        Sql.named('''
          WITH owned_decks AS (
            SELECT id
            FROM decks
            WHERE user_id = CAST(@userId AS uuid)
          ), active_key AS (
            SELECT key_version, hmac_key
            FROM privacy_keyring
            WHERE is_active = TRUE
          ), upserted AS (
            INSERT INTO privacy_deleted_deck_tombstones (
              key_version, deck_token, deleted_at
            )
            SELECT
              active_key.key_version,
              encode(
                hmac(
                  convert_to(owned_decks.id::text, 'UTF8'),
                  active_key.hmac_key,
                  'sha256'
                ),
                'hex'
              ),
              @deletedAt
            FROM owned_decks
            CROSS JOIN active_key
            ON CONFLICT (key_version, deck_token) DO UPDATE
            SET deleted_at = LEAST(
              privacy_deleted_deck_tombstones.deleted_at,
              EXCLUDED.deleted_at
            )
            RETURNING deck_token
          )
          SELECT
            (SELECT COUNT(*)::int FROM owned_decks) AS owned_deck_count,
            (SELECT COUNT(*)::int FROM upserted) AS tombstone_count,
            (SELECT key_version::int FROM active_key) AS key_version,
            (
              SELECT COALESCE(
                array_agg(deck_token ORDER BY deck_token),
                ARRAY[]::text[]
              )
              FROM upserted
            ) AS deck_tokens
        '''),
        parameters: {'userId': userId, 'deletedAt': deletedAt},
      );
      final tombstoneCounts = deckTombstoneResult.first.toColumnMap();
      final keyVersion = tombstoneCounts['key_version'];
      if (keyVersion is! int ||
          tombstoneCounts['owned_deck_count'] !=
              tombstoneCounts['tombstone_count']) {
        throw StateError('privacy_keyring ativa ausente; exclusão abortada.');
      }
      // D-68: os mesmos tokens dos tombstones vão para o outbox, para quem
      // precisa achar os decks fora do PostgreSQL.
      final deckTokens = [
        for (final token in tombstoneCounts['deck_tokens'] as List) '$token',
      ];
      await _executeOnAll(
        session,
        const ['deck_learning_events', 'decks'],
        '''
          DELETE FROM deck_learning_events learning_event
          USING decks deck
          WHERE learning_event.deck_id = deck.id
            AND deck.user_id = CAST(@userId AS uuid)
        ''',
        userId,
      );
      await _executeOn(
        session,
        'battle_replay_annotations',
        'DELETE FROM battle_replay_annotations '
            'WHERE user_id = CAST(@userId AS uuid)',
        userId,
      );
      // D-23 (BT-BAT-002): simulação que outra pessoa rodou contra o deck
      // público do titular fica com ela, sem apontar para ele; as que o
      // titular rodou saem.
      await _anonymizeThirdPartySimulations(session, userId, ownDeckIds);
      await _executeOnAll(
        session,
        const ['battle_simulations', 'battle_simulation_attempts', 'decks'],
        '''
          DELETE FROM battle_simulations simulation
          WHERE simulation.deck_a_id IN (
                  SELECT deck.id
                  FROM decks deck
                  WHERE deck.user_id = CAST(@userId AS uuid)
                )
             OR simulation.id IN (
                  SELECT own_attempt.replay_id
                  FROM battle_simulation_attempts own_attempt
                  WHERE own_attempt.user_id = CAST(@userId AS uuid)
                    AND own_attempt.replay_id IS NOT NULL
                )
        ''',
        userId,
      );
      await _executeOn(session, 'battle_simulation_attempts', '''
          DELETE FROM battle_simulation_attempts attempt
          WHERE attempt.user_id = CAST(@userId AS uuid)
        ''', userId);
      await _executeOn(
        session,
        'decks',
        'DELETE FROM decks WHERE user_id = CAST(@userId AS uuid)',
        userId,
      );
      await _executeOn(
        session,
        'ai_user_preferences',
        'DELETE FROM ai_user_preferences '
            'WHERE user_id = CAST(@userId AS uuid)',
        userId,
      );
      await _executeOn(
        session,
        'user_plans',
        'DELETE FROM user_plans WHERE user_id = CAST(@userId AS uuid)',
        userId,
      );
      await _executeOn(
        session,
        'rate_limit_events',
        '''
          DELETE FROM rate_limit_events
          WHERE identifier IN (
            @userId, @email, @userIdentity, @emailIdentity
          )
        ''',
        userId,
        extraParameters: {
          'email': originalEmail.toLowerCase(),
          // Identidades dos limites por conta (D-20, D-21).
          'userIdentity': 'user:$userId',
          'emailIdentity': credentialEmailRateLimitIdentifier(originalEmail),
        },
      );
      // Lacunas do inventário (BT-PRIV-003): bloqueios, tokens, recursos,
      // ações de moderação e trilha de bloqueios.
      await _executeOn(session, 'user_blocks', '''
          DELETE FROM user_blocks
          WHERE blocker_id = CAST(@userId AS uuid)
             OR blocked_id = CAST(@userId AS uuid)
        ''', userId);
      // Um comando por coluna: o trigger de conta ativa roda só na coluna
      // alterada, e a outra ponta pode ser uma conta já excluída.
      await _executeOn(session, 'user_block_events', '''
          UPDATE user_block_events
          SET actor_user_id = NULL, reason = NULL
          WHERE actor_user_id = CAST(@userId AS uuid)
        ''', userId);
      await _executeOn(session, 'user_block_events', '''
          UPDATE user_block_events
          SET target_user_id = NULL
          WHERE target_user_id = CAST(@userId AS uuid)
        ''', userId);
      await _executeOn(session, 'content_report_appeals', '''
          UPDATE content_report_appeals
          SET reason = '[recurso removido pelo titular]'
          WHERE appellant_user_id = CAST(@userId AS uuid)
        ''', userId);
      await _executeOn(session, 'content_report_appeals', '''
          UPDATE content_report_appeals
          SET reviewed_by = NULL
          WHERE reviewed_by = CAST(@userId AS uuid)
        ''', userId);
      await _executeOn(session, 'moderation_actions', '''
          UPDATE moderation_actions
          SET moderator_user_id = NULL
          WHERE moderator_user_id = CAST(@userId AS uuid)
        ''', userId);
      await _executeOn(
        session,
        'password_reset_tokens',
        'DELETE FROM password_reset_tokens '
            'WHERE user_id = CAST(@userId AS uuid)',
        userId,
      );
      await _executeOn(
        session,
        'email_verification_tokens',
        'DELETE FROM email_verification_tokens '
            'WHERE user_id = CAST(@userId AS uuid)',
        userId,
      );

      final anonymized = await session.execute(
        Sql.named('''
          UPDATE users
          SET username = @username,
              email = @email,
              password_hash = @passwordHash,
              display_name = 'Usuário excluído',
              avatar_url = NULL,
              location_state = NULL,
              location_city = NULL,
              trade_notes = NULL,
              fcm_token = NULL,
              deleted_at = @deletedAt,
              updated_at = @deletedAt
          WHERE id = CAST(@userId AS uuid)
            AND deleted_at IS NULL
          RETURNING id
        '''),
        parameters: {
          'userId': userId,
          'username': deletedUsername,
          'email': deletedEmail,
          'passwordHash': replacementPasswordHash,
          'deletedAt': deletedAt,
        },
      );
      if (anonymized.isEmpty) throw UserDataNotFoundException();

      const retention = accountDeletionRetentionSummary;
      final receipt = await session.execute(
        Sql.named('''
          INSERT INTO account_deletion_receipts (
            policy_version, deletion_mode, retention_summary, completed_at
          )
          VALUES (
            @policyVersion, 'anonymized', @retention::jsonb, @completedAt
          )
          RETURNING id::text
        '''),
        parameters: {
          'policyVersion': accountDeletionPolicyVersion,
          'retention': jsonEncode(retention),
          'completedAt': deletedAt,
        },
      );
      // D-68: uma linha por consumidor fora do PostgreSQL, na mesma
      // transação do recibo. Se o outbox falhar, a exclusão inteira volta.
      await enqueueAccountDeletionOutbox(
        session,
        receiptId: receipt.single.single! as String,
        keyVersion: keyVersion,
        deckTokens: deckTokens,
        completedAt: deletedAt,
      );

      return <String, dynamic>{
        'account_deleted': true,
        'deletion_mode': 'anonymized',
        'deleted_at': deletedAt.toIso8601String(),
        'retention': retention,
      };
    });
  }

  /// Para a exclusão, antes de qualquer escrita, se alguma relação faltar.
  /// Os nomes vêm de [accountDeletionRelations], constantes do código.
  Future<void> _requireRelations(
    Session session,
    List<String> relations,
  ) async {
    final names = relations.map((relation) {
      if (!RegExp(r'^[a-z_]+$').hasMatch(relation)) {
        throw StateError('Nome de relação inválido: $relation');
      }
      return "'$relation'";
    });
    final result = await session.execute('''
      SELECT relation
      FROM unnest(ARRAY[${names.join(', ')}]::text[]) AS relation
      WHERE to_regclass('public.' || relation) IS NULL
      ORDER BY relation
    ''');
    final missing = [for (final row in result) '${row[0]}'];
    if (missing.isNotEmpty) {
      throw StateError(
        'Relações obrigatórias ausentes na exclusão: ${missing.join(', ')}.',
      );
    }
  }

  Future<List<String>> _ownDeckIds(Session session, String userId) async {
    final result = await session.execute(
      Sql.named('''
        SELECT id::text
        FROM decks
        WHERE user_id = CAST(@userId AS uuid)
      '''),
      parameters: {'userId': userId},
    );
    return [for (final row in result) '${row[0]}'];
  }

  /// D-23: o replay (`game_log`, `metrics`) de uma simulação que outra
  /// pessoa rodou contra o deck público do titular perde o UUID e o nome do
  /// deck dele, e a tentativa perde o hash do lado dele. `deck_b_id` e
  /// `winner_deck_id` viram nulos pela FK quando os decks são apagados.
  Future<void> _anonymizeThirdPartySimulations(
    Session session,
    String userId,
    List<String> ownDeckIds,
  ) async {
    if (ownDeckIds.isEmpty) return;
    const ownDecks = '''
      SELECT deck.id
      FROM decks deck
      WHERE deck.user_id = CAST(@userId AS uuid)
    ''';
    final replays = await session.execute(
      Sql.named('''
        SELECT simulation.id::text, simulation.game_log, simulation.metrics
        FROM battle_simulations simulation
        WHERE (
            simulation.deck_b_id IN ($ownDecks)
            OR simulation.winner_deck_id IN ($ownDecks)
          )
          AND (
            simulation.deck_a_id IS NULL
            OR simulation.deck_a_id NOT IN ($ownDecks)
          )
        FOR UPDATE
      '''),
      parameters: {'userId': userId},
    );
    for (final replay in replays) {
      await session.execute(
        Sql.named('''
          UPDATE battle_simulations
          SET game_log = CAST(@gameLog AS jsonb),
              metrics = CAST(@metrics AS jsonb)
          WHERE id = CAST(@id AS uuid)
        '''),
        parameters: {
          'id': '${replay[0]}',
          'gameLog': _anonymizedReplayJson(replay[1], ownDeckIds),
          'metrics': _anonymizedReplayJson(replay[2], ownDeckIds),
        },
      );
    }
    await session.execute(
      Sql.named('''
        UPDATE battle_simulation_attempts attempt
        SET deck_a_hash = CASE
              WHEN attempt.deck_a_id IN ($ownDecks) THEN NULL
              ELSE attempt.deck_a_hash
            END,
            deck_b_hash = CASE
              WHEN attempt.deck_b_id IN ($ownDecks) THEN NULL
              ELSE attempt.deck_b_hash
            END
        WHERE attempt.user_id <> CAST(@userId AS uuid)
          AND (
            attempt.deck_a_id IN ($ownDecks)
            OR attempt.deck_b_id IN ($ownDecks)
          )
      '''),
      parameters: {'userId': userId},
    );
  }

  static String? _anonymizedReplayJson(Object? value, List<String> deckIds) {
    if (value == null) return null;
    final decoded = value is String ? jsonDecode(value) : value;
    return jsonEncode(anonymizeDeletedDeckReferences(decoded, deckIds));
  }

  /// Executa um comando da exclusão sobre [relation], já conferida por
  /// [_requireRelations].
  Future<void> _executeOn(
    Session session,
    String relation,
    String query,
    String userId, {
    Map<String, dynamic> extraParameters = const {},
  }) async {
    assert(accountDeletionRelations.contains(relation));
    await session.execute(
      Sql.named(query),
      parameters: {'userId': userId, ...extraParameters},
    );
  }

  Future<void> _executeOnAll(
    Session session,
    List<String> relations,
    String query,
    String userId,
  ) async {
    assert(relations.every(accountDeletionRelations.contains));
    await session.execute(Sql.named(query), parameters: {'userId': userId});
  }

  static Map<String, dynamic> _jsonObject(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, item) => MapEntry(key.toString(), item));
    }
    if (value is String) {
      final decoded = jsonDecode(value);
      if (decoded is Map) {
        return decoded.map((key, item) => MapEntry(key.toString(), item));
      }
    }
    throw StateError('Expected PostgreSQL JSON object.');
  }

  static String _secureRandomToken() {
    final random = Random.secure();
    final bytes = List<int>.generate(48, (_) => random.nextInt(256));
    return base64Url.encode(bytes);
  }
}
