import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:postgres/postgres.dart';

import 'auth_service.dart';
import 'privacy/privacy_export_allowlist.dart';
import 'privacy/privacy_export_pseudonymizer.dart';
import 'rate_limit_middleware.dart' show credentialEmailRateLimitIdentifier;

const accountDeletionConfirmation = 'EXCLUIR MINHA CONTA';
const accountDeletionPolicyVersion = 'manaloom-beta-privacy-v1';

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
        'battle_jobs',
        'DELETE FROM battle_jobs WHERE user_id = CAST(@userId AS uuid)',
        userId,
      );
      await _deleteIfPresent(
        session,
        'interactive_battle_sessions',
        'DELETE FROM interactive_battle_sessions '
            'WHERE user_id = CAST(@userId AS uuid)',
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
      await _deleteIfPresent(
        session,
        'battle_replay_annotations',
        'DELETE FROM battle_replay_annotations '
            'WHERE user_id = CAST(@userId AS uuid)',
        userId,
      );
      await _executeIfAllPresent(
        session,
        const ['battle_simulation_attempts', 'decks'],
        '''
          DELETE FROM battle_simulation_attempts attempt
          WHERE attempt.user_id = CAST(@userId AS uuid)
             OR EXISTS (
               SELECT 1
               FROM decks deck
               WHERE deck.user_id = CAST(@userId AS uuid)
                 AND deck.id IN (attempt.deck_a_id, attempt.deck_b_id)
             )
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
