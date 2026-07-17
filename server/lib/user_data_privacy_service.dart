import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:postgres/postgres.dart';

import 'auth_service.dart';

const accountDeletionConfirmation = 'EXCLUIR MINHA CONTA';
const accountDeletionPolicyVersion = 'manaloom-beta-privacy-v1';

class UserDataNotFoundException implements Exception {}

class InvalidAccountPasswordException implements Exception {}

class UserDataPrivacyService {
  UserDataPrivacyService(this.pool, {AuthService? authService})
    : _authService = authService ?? AuthService();

  final Pool pool;
  final AuthService _authService;

  Future<Map<String, dynamic>> exportUserData(String userId) {
    return pool.runTx(
      (session) async {
        final accountResult = await session.execute(
          Sql.named('''
          SELECT jsonb_build_object(
            'id', id,
            'username', username,
            'email', email,
            'display_name', display_name,
            'avatar_url', avatar_url,
            'location_state', location_state,
            'location_city', location_city,
            'trade_notes', trade_notes,
            'created_at', created_at,
            'updated_at', updated_at
          )
          FROM users
          WHERE id = CAST(@userId AS uuid)
            AND deleted_at IS NULL
          LIMIT 1
        '''),
          parameters: {'userId': userId},
        );
        if (accountResult.isEmpty) throw UserDataNotFoundException();

        final plan = await _optionalJsonRows(
          session,
          relation: 'user_plans',
          query:
              'SELECT to_jsonb(p) FROM user_plans p '
              'WHERE p.user_id = CAST(@userId AS uuid)',
          userId: userId,
        );
        final decks = await _optionalJsonRows(
          session,
          relation: 'decks',
          query:
              'SELECT to_jsonb(d) FROM decks d '
              'WHERE d.user_id = CAST(@userId AS uuid) '
              'ORDER BY d.created_at, d.id',
          userId: userId,
        );
        final deckCards = await _optionalJsonRows(
          session,
          relation: 'deck_cards',
          query: '''
          SELECT jsonb_build_object(
            'deck_card', to_jsonb(dc),
            'card_identity', jsonb_build_object(
              'name', c.name,
              'scryfall_id', c.scryfall_id,
              'oracle_id', c.oracle_id,
              'set_code', c.set_code,
              'collector_number', c.collector_number
            )
          )
          FROM deck_cards dc
          JOIN decks d ON d.id = dc.deck_id
          JOIN cards c ON c.id = dc.card_id
          WHERE d.user_id = CAST(@userId AS uuid)
          ORDER BY dc.deck_id, dc.id
        ''',
          userId: userId,
        );
        final deckLearningEvents = await _optionalJsonRows(
          session,
          relation: 'deck_learning_events',
          query: '''
          SELECT to_jsonb(learning_event)
          FROM deck_learning_events learning_event
          WHERE learning_event.deck_id IN (
            SELECT deck.id
            FROM decks deck
            WHERE deck.user_id = CAST(@userId AS uuid)
          )
          ORDER BY learning_event.created_at, learning_event.id
        ''',
          userId: userId,
        );
        final battleSimulations = await _optionalJsonRows(
          session,
          relation: 'battle_simulations',
          query: '''
          SELECT to_jsonb(simulation)
          FROM battle_simulations simulation
          WHERE EXISTS (
            SELECT 1
            FROM decks deck
            WHERE deck.user_id = CAST(@userId AS uuid)
              AND deck.id IN (
                simulation.deck_a_id,
                simulation.deck_b_id,
                simulation.winner_deck_id
              )
          )
          ORDER BY simulation.created_at, simulation.id
        ''',
          userId: userId,
        );
        final binderItems = await _optionalJsonRows(
          session,
          relation: 'user_binder_items',
          query: '''
          SELECT jsonb_build_object(
            'binder_item', to_jsonb(bi),
            'card_identity', jsonb_build_object(
              'name', c.name,
              'scryfall_id', c.scryfall_id,
              'oracle_id', c.oracle_id,
              'set_code', c.set_code,
              'collector_number', c.collector_number
            )
          )
          FROM user_binder_items bi
          JOIN cards c ON c.id = bi.card_id
          WHERE bi.user_id = CAST(@userId AS uuid)
          ORDER BY bi.created_at, bi.id
        ''',
          userId: userId,
        );
        final postGameNotes = await _optionalJsonRows(
          session,
          relation: 'post_game_notes',
          query:
              'SELECT to_jsonb(n) FROM post_game_notes n '
              'WHERE n.user_id = CAST(@userId AS uuid) '
              'ORDER BY n.created_at, n.id',
          userId: userId,
        );
        final sharedDeckReports = await _optionalJsonRows(
          session,
          relation: 'shared_deck_reports',
          query:
              'SELECT to_jsonb(r) FROM shared_deck_reports r '
              'WHERE r.user_id = CAST(@userId AS uuid) '
              'ORDER BY r.created_at, r.id',
          userId: userId,
        );
        final comments = await _optionalJsonRows(
          session,
          relation: 'deck_comments',
          query:
              'SELECT to_jsonb(c) FROM deck_comments c '
              'WHERE c.user_id = CAST(@userId AS uuid) '
              'ORDER BY c.created_at, c.id',
          userId: userId,
        );
        final follows = await _optionalJsonRows(
          session,
          relation: 'user_follows',
          query:
              'SELECT to_jsonb(f) FROM user_follows f '
              'WHERE f.follower_id = CAST(@userId AS uuid) '
              'OR f.following_id = CAST(@userId AS uuid) '
              'ORDER BY f.created_at, f.id',
          userId: userId,
        );
        final activationEvents = await _optionalJsonRows(
          session,
          relation: 'activation_funnel_events',
          query:
              'SELECT to_jsonb(e) FROM activation_funnel_events e '
              'WHERE e.user_id = CAST(@userId AS uuid) '
              'ORDER BY e.created_at, e.id',
          userId: userId,
        );
        final optimizationEvents = await _optionalJsonRows(
          session,
          relation: 'deck_optimization_events',
          query:
              'SELECT to_jsonb(e) FROM deck_optimization_events e '
              'WHERE e.user_id = CAST(@userId AS uuid) '
              'ORDER BY e.created_at, e.id',
          userId: userId,
        );
        final aiPreferences = await _optionalJsonRows(
          session,
          relation: 'ai_user_preferences',
          query:
              'SELECT to_jsonb(p) FROM ai_user_preferences p '
              'WHERE p.user_id = CAST(@userId AS uuid)',
          userId: userId,
        );
        final aiLogs = await _optionalJsonRows(
          session,
          relation: 'ai_logs',
          query:
              'SELECT to_jsonb(l) FROM ai_logs l '
              'WHERE l.user_id = CAST(@userId AS uuid) '
              'ORDER BY l.created_at, l.id',
          userId: userId,
        );
        final aiFeedback = await _optionalJsonRows(
          session,
          relation: 'ml_prompt_feedback',
          query:
              'SELECT to_jsonb(f) FROM ml_prompt_feedback f '
              'WHERE f.user_id = CAST(@userId AS uuid) '
              'ORDER BY f.created_at, f.id',
          userId: userId,
        );
        final aiFallbackTelemetry = await _optionalJsonRows(
          session,
          relation: 'ai_optimize_fallback_telemetry',
          query:
              'SELECT to_jsonb(t) FROM ai_optimize_fallback_telemetry t '
              'WHERE t.user_id = CAST(@userId AS uuid) '
              'ORDER BY t.created_at, t.id',
          userId: userId,
        );
        final aiOptimizeCache = await _optionalJsonRows(
          session,
          relation: 'ai_optimize_cache',
          query:
              'SELECT to_jsonb(c) FROM ai_optimize_cache c '
              'WHERE c.user_id = CAST(@userId AS uuid) '
              'ORDER BY c.created_at, c.id',
          userId: userId,
        );
        final aiGenerateJobs = await _optionalJsonRows(
          session,
          relation: 'ai_generate_jobs',
          query:
              'SELECT to_jsonb(j) FROM ai_generate_jobs j '
              'WHERE j.user_id = CAST(@userId AS uuid) '
              'ORDER BY j.created_at, j.id',
          userId: userId,
        );
        final aiOptimizeJobs = await _optionalJsonRows(
          session,
          relation: 'ai_optimize_jobs',
          query:
              'SELECT to_jsonb(j) FROM ai_optimize_jobs j '
              'WHERE j.user_id = CAST(@userId AS uuid) '
              'ORDER BY j.created_at, j.id',
          userId: userId,
        );
        final trades = await _optionalJsonRows(
          session,
          relation: 'trade_offers',
          query: '''
          SELECT jsonb_build_object(
            'id', t.id,
            'sender_id', t.sender_id,
            'receiver_id', t.receiver_id,
            'status', t.status,
            'type', t.type,
            'message', CASE
              WHEN t.sender_id = CAST(@userId AS uuid) THEN t.message
              ELSE NULL
            END,
            'payment_amount', t.payment_amount,
            'payment_currency', t.payment_currency,
            'payment_method', t.payment_method,
            'delivery_method', t.delivery_method,
            'tracking_code', t.tracking_code,
            'created_at', t.created_at,
            'updated_at', t.updated_at
          )
          FROM trade_offers t
          WHERE t.sender_id = CAST(@userId AS uuid)
             OR t.receiver_id = CAST(@userId AS uuid)
          ORDER BY t.created_at, t.id
        ''',
          userId: userId,
        );
        final tradeItems = await _optionalJsonRows(
          session,
          relation: 'trade_items',
          query:
              'SELECT to_jsonb(i) FROM trade_items i '
              'WHERE i.owner_id = CAST(@userId AS uuid) '
              'ORDER BY i.id',
          userId: userId,
        );
        final tradeMessages = await _optionalJsonRows(
          session,
          relation: 'trade_messages',
          query:
              'SELECT to_jsonb(m) FROM trade_messages m '
              'WHERE m.sender_id = CAST(@userId AS uuid) '
              'ORDER BY m.created_at, m.id',
          userId: userId,
        );
        final tradeStatusHistory = await _optionalJsonRows(
          session,
          relation: 'trade_status_history',
          query:
              'SELECT to_jsonb(h) FROM trade_status_history h '
              'WHERE h.changed_by = CAST(@userId AS uuid) '
              'ORDER BY h.created_at, h.id',
          userId: userId,
        );
        final directMessagesSent = await _optionalJsonRows(
          session,
          relation: 'direct_messages',
          query:
              'SELECT to_jsonb(m) FROM direct_messages m '
              'WHERE m.sender_id = CAST(@userId AS uuid) '
              'ORDER BY m.created_at, m.id',
          userId: userId,
        );
        final conversations = await _optionalJsonRows(
          session,
          relation: 'conversations',
          query:
              'SELECT to_jsonb(c) FROM conversations c '
              'WHERE c.user_a_id = CAST(@userId AS uuid) '
              'OR c.user_b_id = CAST(@userId AS uuid) '
              'ORDER BY c.created_at, c.id',
          userId: userId,
        );
        final notifications = await _optionalJsonRows(
          session,
          relation: 'notifications',
          query: '''
            SELECT jsonb_build_object(
              'id', n.id,
              'type', n.type,
              'reference_id', n.reference_id,
              'title', n.title,
              'body', NULL,
              'read_at', n.read_at,
              'created_at', n.created_at
            )
            FROM notifications n
            WHERE n.user_id = CAST(@userId AS uuid)
            ORDER BY n.created_at, n.id
          ''',
          userId: userId,
        );
        final contentReports = await _optionalJsonRows(
          session,
          relation: 'content_reports',
          query:
              'SELECT to_jsonb(r) FROM content_reports r '
              'WHERE r.reporter_user_id = CAST(@userId AS uuid) '
              'ORDER BY r.created_at, r.id',
          userId: userId,
        );

        return <String, dynamic>{
          'schema_version': 1,
          'exported_at': DateTime.now().toUtc().toIso8601String(),
          'account': _jsonObject(accountResult.first[0]),
          'data': {
            'plan': plan.isEmpty ? null : plan.first,
            'decks': decks,
            'deck_cards': deckCards,
            'deck_learning_events': deckLearningEvents,
            'battle_simulations': battleSimulations,
            'binder_items': binderItems,
            'post_game_notes': postGameNotes,
            'shared_deck_reports': sharedDeckReports,
            'comments': comments,
            'follows': follows,
            'activation_events': activationEvents,
            'optimization_events': optimizationEvents,
            'ai_preferences':
                aiPreferences.isEmpty ? null : aiPreferences.first,
            'ai_activity': {
              'logs': aiLogs,
              'feedback': aiFeedback,
              'fallback_telemetry': aiFallbackTelemetry,
              'optimize_cache': aiOptimizeCache,
              'generate_jobs': aiGenerateJobs,
              'optimize_jobs': aiOptimizeJobs,
            },
            'trades': trades,
            'trade_items': tradeItems,
            'trade_messages': tradeMessages,
            'trade_status_history': tradeStatusHistory,
            'conversations': conversations,
            'direct_messages_sent': directMessagesSent,
            'notifications': notifications,
            'content_reports': contentReports,
          },
          'portability': {
            'format': 'application/json',
            'scope': 'data supplied by or directly associated with the account',
            'omitted_secrets': const [
              'password_hash',
              'jwt',
              'fcm_token',
              'server_credentials',
              'messages_authored_by_other_users',
              'notification_message_bodies',
            ],
          },
        };
      },
      settings: TransactionSettings(
        isolationLevel: IsolationLevel.repeatableRead,
        accessMode: AccessMode.readOnly,
      ),
    );
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
      var passwordMatches = false;
      try {
        passwordMatches = _authService.verifyPassword(password, passwordHash);
      } catch (_) {
        passwordMatches = false;
      }
      if (!passwordMatches) throw InvalidAccountPasswordException();

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

      await _deleteIfPresent(
        session,
        'ai_logs',
        'DELETE FROM ai_logs WHERE user_id = CAST(@userId AS uuid)',
        userId,
      );
      await _deleteIfPresent(
        session,
        'ai_optimize_fallback_telemetry',
        'DELETE FROM ai_optimize_fallback_telemetry '
            'WHERE user_id = CAST(@userId AS uuid)',
        userId,
      );
      await _deleteIfPresent(
        session,
        'ai_optimize_cache',
        'DELETE FROM ai_optimize_cache WHERE user_id = CAST(@userId AS uuid)',
        userId,
      );
      await _deleteIfPresent(
        session,
        'ai_optimize_jobs',
        'DELETE FROM ai_optimize_jobs WHERE user_id = CAST(@userId AS uuid)',
        userId,
      );
      await _deleteIfPresent(
        session,
        'ai_generate_jobs',
        'DELETE FROM ai_generate_jobs WHERE user_id = CAST(@userId AS uuid)',
        userId,
      );
      await _deleteIfPresent(
        session,
        'ml_prompt_feedback',
        'DELETE FROM ml_prompt_feedback WHERE user_id = CAST(@userId AS uuid)',
        userId,
      );
      await _deleteIfPresent(
        session,
        'activation_funnel_events',
        'DELETE FROM activation_funnel_events '
            'WHERE user_id = CAST(@userId AS uuid)',
        userId,
      );
      await _deleteIfPresent(
        session,
        'deck_optimization_events',
        'DELETE FROM deck_optimization_events '
            'WHERE user_id = CAST(@userId AS uuid)',
        userId,
      );
      await _deleteIfPresent(
        session,
        'shared_deck_reports',
        'DELETE FROM shared_deck_reports '
            'WHERE user_id = CAST(@userId AS uuid)',
        userId,
      );
      await _deleteIfPresent(
        session,
        'post_game_notes',
        'DELETE FROM post_game_notes WHERE user_id = CAST(@userId AS uuid)',
        userId,
      );
      await _deleteIfPresent(
        session,
        'deck_comments',
        'DELETE FROM deck_comments WHERE user_id = CAST(@userId AS uuid)',
        userId,
      );
      await _deleteIfPresent(
        session,
        'user_follows',
        'DELETE FROM user_follows '
            'WHERE follower_id = CAST(@userId AS uuid) '
            'OR following_id = CAST(@userId AS uuid)',
        userId,
      );
      await _executeIfPresent(session, 'notifications', '''
          DELETE FROM notifications
          WHERE type = 'new_follower'
            AND reference_id::text = @userId
        ''', userId);
      await _executeIfAllPresent(
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
      await _executeIfAllPresent(
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
      await _deleteIfPresent(
        session,
        'notifications',
        'DELETE FROM notifications WHERE user_id = CAST(@userId AS uuid)',
        userId,
      );
      await _executeIfPresent(session, 'content_reports', '''
          UPDATE content_reports
          SET reporter_user_id = NULL, details = ''
          WHERE reporter_user_id = CAST(@userId AS uuid)
        ''', userId);
      await _executeIfPresent(
        session,
        'content_reports',
        'UPDATE content_reports SET reviewed_by = NULL '
            'WHERE reviewed_by = CAST(@userId AS uuid)',
        userId,
      );
      await _executeIfPresent(session, 'direct_messages', '''
          UPDATE direct_messages
          SET message = '[mensagem removida pelo titular]'
          WHERE sender_id = CAST(@userId AS uuid)
        ''', userId);
      await _executeIfPresent(session, 'trade_messages', '''
          UPDATE trade_messages
          SET message = '[mensagem removida pelo titular]',
              attachment_url = NULL,
              attachment_type = NULL
          WHERE sender_id = CAST(@userId AS uuid)
        ''', userId);
      await _executeIfPresent(session, 'trade_status_history', '''
          UPDATE trade_status_history
          SET notes = '[detalhe removido pelo titular]'
          WHERE changed_by = CAST(@userId AS uuid)
        ''', userId);
      await _executeIfPresent(session, 'trade_offers', '''
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
      await _deleteIfPresent(
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
            RETURNING 1
          )
          SELECT
            (SELECT COUNT(*)::int FROM owned_decks) AS owned_deck_count,
            (SELECT COUNT(*)::int FROM upserted) AS tombstone_count
        '''),
        parameters: {'userId': userId, 'deletedAt': deletedAt},
      );
      final tombstoneCounts = deckTombstoneResult.first.toColumnMap();
      if (tombstoneCounts['owned_deck_count'] !=
          tombstoneCounts['tombstone_count']) {
        throw StateError('privacy_keyring ativa ausente; exclusão abortada.');
      }
      await _executeIfAllPresent(
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
      await _executeIfAllPresent(
        session,
        const ['battle_simulations', 'decks'],
        '''
          DELETE FROM battle_simulations simulation
          USING decks deck
          WHERE deck.user_id = CAST(@userId AS uuid)
            AND (
              simulation.deck_a_id = deck.id
              OR simulation.deck_b_id = deck.id
              OR simulation.winner_deck_id = deck.id
            )
        ''',
        userId,
      );
      await _deleteIfPresent(
        session,
        'decks',
        'DELETE FROM decks WHERE user_id = CAST(@userId AS uuid)',
        userId,
      );
      await _deleteIfPresent(
        session,
        'ai_user_preferences',
        'DELETE FROM ai_user_preferences '
            'WHERE user_id = CAST(@userId AS uuid)',
        userId,
      );
      await _deleteIfPresent(
        session,
        'user_plans',
        'DELETE FROM user_plans WHERE user_id = CAST(@userId AS uuid)',
        userId,
      );
      await _executeIfPresent(
        session,
        'rate_limit_events',
        '''
          DELETE FROM rate_limit_events
          WHERE identifier IN (@userId, @email)
        ''',
        userId,
        extraParameters: {'email': originalEmail.toLowerCase()},
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

      const retention = <String, String>{
        'trades_and_disputes': 'anonymized',
        'moderation_records': 'anonymized',
        'operational_aggregates': 'deidentified',
        'deck_learning_and_battle_rows': 'deleted',
        'deleted_deck_anti_resurrection_keys': 'opaque_identifier_only',
      };
      await session.execute(
        Sql.named('''
          INSERT INTO account_deletion_receipts (
            policy_version, deletion_mode, retention_summary, completed_at
          )
          VALUES (
            @policyVersion, 'anonymized', @retention::jsonb, @completedAt
          )
        '''),
        parameters: {
          'policyVersion': accountDeletionPolicyVersion,
          'retention': jsonEncode(retention),
          'completedAt': deletedAt,
        },
      );

      return <String, dynamic>{
        'account_deleted': true,
        'deletion_mode': 'anonymized',
        'deleted_at': deletedAt.toIso8601String(),
        'retention': retention,
      };
    });
  }

  Future<List<Map<String, dynamic>>> _optionalJsonRows(
    Session session, {
    required String relation,
    required String query,
    required String userId,
  }) async {
    if (!await _relationExists(session, relation)) return const [];
    final result = await session.execute(
      Sql.named(query),
      parameters: {'userId': userId},
    );
    return result.map((row) => _jsonObject(row[0])).toList(growable: false);
  }

  Future<void> _deleteIfPresent(
    Session session,
    String relation,
    String query,
    String userId,
  ) => _executeIfPresent(session, relation, query, userId);

  Future<void> _executeIfPresent(
    Session session,
    String relation,
    String query,
    String userId, {
    Map<String, dynamic> extraParameters = const {},
  }) async {
    if (!await _relationExists(session, relation)) return;
    await session.execute(
      Sql.named(query),
      parameters: {'userId': userId, ...extraParameters},
    );
  }

  Future<void> _executeIfAllPresent(
    Session session,
    List<String> relations,
    String query,
    String userId,
  ) async {
    for (final relation in relations) {
      if (!await _relationExists(session, relation)) return;
    }
    await session.execute(Sql.named(query), parameters: {'userId': userId});
  }

  Future<bool> _relationExists(Session session, String relation) async {
    final result = await session.execute(
      Sql.named('SELECT to_regclass(@relation)'),
      parameters: {'relation': 'public.$relation'},
    );
    return result.isNotEmpty && result.first[0] != null;
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
