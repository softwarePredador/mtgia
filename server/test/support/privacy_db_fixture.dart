import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:postgres/postgres.dart';

/// Banco descartável dos testes de privacidade (BT-PRIV-001 e BT-PRIV-002).
///
/// Só abre conexão com `RUN_PRIVACY_DB_TESTS=1` e as variáveis `DB_*` de um
/// PostgreSQL descartável já migrado (`server/database_setup.sql` +
/// `server/bin/migrate.dart`).
bool privacyDbTestsEnabled() =>
    Platform.environment['RUN_PRIVACY_DB_TESTS'] == '1';

const privacyDbSkipReason =
    'Requer RUN_PRIVACY_DB_TESTS=1 e PostgreSQL descartavel isolado.';

Pool openPrivacyTestPool() => Pool.withEndpoints([
  Endpoint(
    host: Platform.environment['DB_HOST'] ?? '127.0.0.1',
    port: int.parse(Platform.environment['DB_PORT'] ?? '5432'),
    database: Platform.environment['DB_NAME']!,
    username: Platform.environment['DB_USER']!,
    password: Platform.environment['DB_PASS'] ?? '',
  ),
], settings: const PoolSettings(sslMode: SslMode.disable));

/// Três contas com dado em todas as tabelas que a exportação e a exclusão
/// tocam: A é o titular; B e C são outras pessoas. B tem deck público contra
/// o qual A simula, e B simula contra o deck público de A.
class PrivacyDbFixture {
  PrivacyDbFixture._(this.suffix, this.passwordHash);

  final String suffix;

  /// Hash gravado em `users.password_hash` das três contas.
  final String passwordHash;
  late final String userA;
  late final String userB;
  late final String userC;
  late final String cardId;
  late final String deckA1;
  late final String deckA2Public;
  late final String deckB1Public;
  late final String deckB2Private;
  late final String simulationByA;
  late final String simulationByB;
  late final String attemptByA;
  late final String attemptByB;
  late final String jobByA;
  late final String jobByBAgainstA;
  late final String sessionByA;
  late final String binderItemA;
  late final String tradeFromA;
  late final String tradeFromB;
  late final String tradeCompletedAB;
  late final String itemOfAInOpenOfferFromA;
  late final String itemOfBInOpenOfferFromA;
  late final String itemOfAInOpenOfferFromB;
  late final String itemOfBInOpenOfferFromB;
  late final String itemOfAInCompletedTrade;
  late final String itemOfBInCompletedTrade;
  late final String conversationAB;
  late final String reportByA;
  late final String reportByB;
  late final String appealByA;

  String get blockRequestOfA => 'req-bloqueio-a-$suffix';
  String get blockRequestOfC => 'req-bloqueio-c-$suffix';
  String get deckB2PrivateName => 'Deck privado de B $suffix';
  String get deckA2PublicName => 'Deck publico de A $suffix';
  String get deckB1PublicName => 'Deck publico de B $suffix';

  /// Textos escritos por B (ou sobre B) que nunca podem sair na exportação
  /// de A.
  List<String> get textsOfB => [
    'mensagem da proposta de B $suffix',
    'mensagem de troca de B $suffix',
    'oi de B $suffix',
    'comentario de B no deck de A $suffix',
    'detalhe da denuncia de B $suffix',
    'nota de status de B $suffix',
    deckB2PrivateName,
    'B $suffix começou a seguir você',
  ];

  static Future<PrivacyDbFixture> seed(
    Pool pool, {
    String passwordHash = 'hash-que-nao-sai',
  }) async {
    final fixture = PrivacyDbFixture._(
      '${DateTime.now().microsecondsSinceEpoch}${Random().nextInt(1000)}',
      passwordHash,
    );
    await fixture._seed(pool);
    return fixture;
  }

  static String hex64(String seed) {
    final bytes = utf8.encode(seed);
    final buffer = StringBuffer();
    var index = 0;
    while (buffer.length < 64) {
      buffer.write(
        ((bytes[index % bytes.length] + index) % 16).toRadixString(16),
      );
      index++;
    }
    return buffer.toString();
  }

  Future<String> _one(
    Session pool,
    String sql, [
    Map<String, Object?> parameters = const {},
  ]) async {
    final result = await pool.execute(Sql.named(sql), parameters: parameters);
    return result.single.single!.toString();
  }

  Future<void> _seed(Pool pool) async {
    await pool.runTx((tx) async {
      Future<String> user(String name) => _one(
        tx,
        '''
        INSERT INTO users (
          username, email, password_hash, display_name, fcm_token,
          terms_version, terms_accepted_at, privacy_version, privacy_accepted_at
        )
        VALUES (
          @username, @email, @passwordHash, @display, 'fcm-que-nao-sai',
          'termos-v1', NOW(), 'privacidade-v1', NOW()
        )
        RETURNING id::text
        ''',
        {
          'username': 'privacy_${name}_$suffix',
          'email': 'privacy_${name}_$suffix@example.invalid',
          'passwordHash': passwordHash,
          'display': '$name $suffix',
        },
      );
      userA = await user('A');
      userB = await user('B');
      userC = await user('C');

      cardId = await _one(
        tx,
        '''
        INSERT INTO cards (scryfall_id, oracle_id, name, set_code, collector_number)
        VALUES (gen_random_uuid(), gen_random_uuid(), @name, 'tst', '1')
        RETURNING id::text
      ''',
        {'name': 'Carta de teste de privacidade $suffix'},
      );

      Future<String> deck(String owner, String name, bool isPublic) => _one(
        tx,
        '''
        INSERT INTO decks (user_id, name, format, is_public, description)
        VALUES (CAST(@owner AS uuid), @name, 'commander', @public, @description)
        RETURNING id::text
        ''',
        {
          'owner': owner,
          'name': name,
          'public': isPublic,
          'description': 'descricao de $name',
        },
      );
      deckA1 = await deck(userA, 'Deck de A $suffix', false);
      deckA2Public = await deck(userA, deckA2PublicName, true);
      deckB1Public = await deck(userB, deckB1PublicName, true);
      deckB2Private = await deck(userB, deckB2PrivateName, false);

      for (final deckId in [
        deckA1,
        deckA2Public,
        deckB1Public,
        deckB2Private,
      ]) {
        await tx.execute(
          Sql.named('''
            INSERT INTO deck_cards (deck_id, card_id, quantity, is_commander)
            VALUES (CAST(@deck AS uuid), CAST(@card AS uuid), 1, TRUE)
          '''),
          parameters: {'deck': deckId, 'card': cardId},
        );
      }

      await tx.execute(
        Sql.named('''
          INSERT INTO deck_learning_events (
            deck_id, format, card_count, commander_name, event_data, source
          )
          VALUES (
            CAST(@deck AS uuid), 'commander', 1, 'Comandante',
            '{"cards": ["Carta"]}'::jsonb, 'user_created'
          )
        '''),
        parameters: {'deck': deckA1},
      );
      await tx.execute(
        Sql.named('''
          INSERT INTO deck_matchups (deck_id, opponent_deck_id, win_rate, notes)
          VALUES (CAST(@a AS uuid), CAST(@b AS uuid), 0.5, 'confronto de A')
        '''),
        parameters: {'a': deckA1, 'b': deckB1Public},
      );
      await tx.execute(
        Sql.named('''
          INSERT INTO deck_weakness_reports (
            deck_id, weakness_type, severity, description, recommendations
          )
          VALUES (
            CAST(@deck AS uuid), 'mana', 'low', 'fraqueza de A',
            ARRAY['mais terrenos']
          )
        '''),
        parameters: {'deck': deckA1},
      );

      Future<String> simulation(String deckAId, String deckBId, String label) =>
          _one(
            tx,
            '''
            INSERT INTO battle_simulations (
              deck_a_id, deck_b_id, simulation_type, winner_deck_id,
              turns_played, game_log, metrics
            )
            VALUES (
              CAST(@a AS uuid), CAST(@b AS uuid), 'battle', CAST(@b AS uuid),
              7, CAST(@log AS jsonb), CAST(@metrics AS jsonb)
            )
            RETURNING id::text
            ''',
            {
              'a': deckAId,
              'b': deckBId,
              'log': jsonEncode({
                'label': label,
                'deck_b': {'id': deckBId, 'name': 'deck $deckBId'},
                'events': [
                  {'actor': 'deck_b', 'message': 'vence $deckBId'},
                ],
                'deck_b_hash': hex64('log-$label'),
                'request_fingerprint': hex64('fp-$label'),
              }),
              'metrics': jsonEncode({'winner_deck_id': deckBId}),
            },
          );
      simulationByA = await simulation(deckA1, deckB1Public, 'A');
      simulationByB = await simulation(deckB2Private, deckA2Public, 'B');

      Future<String> attempt(
        String owner,
        String deckAId,
        String deckBId,
        String replay,
        String label,
      ) => _one(
        tx,
        '''
        INSERT INTO battle_simulation_attempts (
          user_id, deck_a_id, deck_b_id, replay_id, simulation_type,
          outcome, request_id, request_schema_version, request_hash,
          deck_hash_schema, deck_a_hash, deck_b_hash, engine, timeout_ms,
          finished_at
        )
        VALUES (
          CAST(@owner AS uuid), CAST(@a AS uuid), CAST(@b AS uuid),
          CAST(@replay AS uuid), 'battle', 'completed', @request,
          'battle_simulation_request_v1', @hash,
          'external_battle_deck_hash_v1', @hashA, @hashB, 'native', 60000,
          NOW()
        )
        RETURNING id::text
        ''',
        {
          'owner': owner,
          'a': deckAId,
          'b': deckBId,
          'replay': replay,
          'request': 'req-$label-$suffix',
          'hash': hex64('request-$label'),
          'hashA': hex64('deck-a-$label'),
          'hashB': hex64('deck-b-$label'),
        },
      );
      attemptByA = await attempt(
        userA,
        deckA1,
        deckB1Public,
        simulationByA,
        'A',
      );
      attemptByB = await attempt(
        userB,
        deckB2Private,
        deckA2Public,
        simulationByB,
        'B',
      );

      Future<String> job(
        String owner,
        String deckAId,
        String deckBId,
        String label,
      ) => _one(
        tx,
        '''
            INSERT INTO battle_jobs (
              user_id, deck_a_id, deck_b_id, deck_hash_schema, deck_a_hash,
              deck_b_hash, request_schema_version, request_hash, request_payload,
              requested_engine, engine_lane, timeout_ms, idempotency_key,
              request_fingerprint, quota_user_limit, quota_global_limit
            )
            VALUES (
              CAST(@owner AS uuid), CAST(@a AS uuid), CAST(@b AS uuid),
              'external_battle_deck_hash_v1', @hashA, @hashB,
              'battle_job_request_v1', @hash, CAST(@payload AS jsonb),
              'auto', 'auto', 60000, @key, @fingerprint, 1, 10
            )
            RETURNING id::text
            ''',
        {
          'owner': owner,
          'a': deckAId,
          'b': deckBId,
          'hashA': hex64('job-a-$label'),
          'hashB': hex64('job-b-$label'),
          'hash': hex64('job-request-$label'),
          'payload': jsonEncode({
            'deck_b': {
              'id': deckBId,
              'cards': ['Carta'],
            },
          }),
          'key': 'privacy-job-$label-$suffix',
          'fingerprint': hex64('job-fp-$label'),
        },
      );
      jobByA = await job(userA, deckA1, deckB1Public, 'A');
      jobByBAgainstA = await job(userB, deckB2Private, deckA2Public, 'B');

      await tx.execute(
        Sql.named('''
          INSERT INTO battle_job_live_records (
            job_id, sequence, record_id, kind, payload, fingerprint,
            source_kind, public_visible
          )
          VALUES (
            CAST(@job AS uuid), 1, @record, 'event', CAST(@payload AS jsonb),
            @fingerprint, 'terminal_replay', TRUE
          )
        '''),
        parameters: {
          'job': jobByA,
          'record': 'blr-${hex64('record-visible').substring(0, 40)}',
          'payload': jsonEncode({'text': 'turno 1', 'deck_b_id': deckB1Public}),
          'fingerprint': hex64('live-fp-1'),
        },
      );
      await tx.execute(
        Sql.named('''
          INSERT INTO battle_job_live_records (
            job_id, sequence, record_id, kind, payload, fingerprint,
            source_kind, public_visible, source_process_id, source_sequence
          )
          VALUES (
            CAST(@job AS uuid), 2, @record, 'event', '{}'::jsonb, @fingerprint,
            'xmage_checkpoint', FALSE, 'processo-interno', 0
          )
        '''),
        parameters: {
          'job': jobByA,
          'record': 'blr-${hex64('record-hidden').substring(0, 40)}',
          'fingerprint': hex64('live-fp-2'),
        },
      );

      sessionByA = await _one(
        tx,
        '''
        INSERT INTO interactive_battle_sessions (
          user_id, deck_a_id, deck_b_id, deck_hash_schema, deck_a_hash,
          deck_b_hash, request_schema_version, request_hash, request_payload,
          idempotency_key, request_fingerprint, ttl_seconds, expires_at,
          private_state
        )
        VALUES (
          CAST(@owner AS uuid), CAST(@a AS uuid), CAST(@b AS uuid),
          'external_battle_deck_hash_v1', @hashA, @hashB,
          'interactive_battle_request_v1', @hash, CAST(@payload AS jsonb),
          @key, @fingerprint, 600, NOW() + INTERVAL '10 minutes',
          '{"hand": ["Carta"]}'::jsonb
        )
        RETURNING id::text
      ''',
        {
          'owner': userA,
          'a': deckA1,
          'b': deckB1Public,
          'hashA': hex64('session-a'),
          'hashB': hex64('session-b'),
          'hash': hex64('session-request'),
          'payload': jsonEncode({
            'deck_b': {'id': deckB1Public},
          }),
          'key': 'privacy-session-$suffix',
          'fingerprint': hex64('session-fp'),
        },
      );
      await tx.execute(
        Sql.named('''
          INSERT INTO interactive_battle_records (
            session_id, sequence, record_kind, visibility, state_version,
            payload, idempotency_key, request_fingerprint
          )
          VALUES
            (CAST(@session AS uuid), 1, 'private_state', 'private_user', 1,
             '{"hand": ["Carta"]}'::jsonb, 'record-1', @fingerprint),
            (CAST(@session AS uuid), 2, 'runtime_started', 'internal', 1,
             '{"internal": true}'::jsonb, NULL, NULL)
        '''),
        parameters: {'session': sessionByA, 'fingerprint': hex64('record-fp')},
      );

      await tx.execute(
        Sql.named('''
          INSERT INTO battle_replay_annotations (
            user_id, replay_id, attempt_id, subject_deck_id, subject_deck_key,
            deck_hash_schema, subject_deck_hash, subject_deck_revision, kind,
            payload, idempotency_key, request_fingerprint
          )
          VALUES (
            CAST(@owner AS uuid), CAST(@replay AS uuid), CAST(@attempt AS uuid),
            CAST(@deck AS uuid), 'deck_a', 'external_battle_deck_hash_v1',
            @hash, @revision, 'note', '{"text": "anotacao de A"}'::jsonb,
            'annotation-1', @fingerprint
          )
        '''),
        parameters: {
          'owner': userA,
          'replay': simulationByA,
          'attempt': attemptByA,
          'deck': deckA1,
          'hash': hex64('annotation-hash'),
          'revision':
              'external_battle_deck_hash_v1:${hex64('annotation-hash')}',
          'fingerprint': hex64('annotation-fp'),
        },
      );

      binderItemA = await _one(
        tx,
        '''
          INSERT INTO user_binder_items (user_id, card_id, quantity, notes)
          VALUES (CAST(@owner AS uuid), CAST(@card AS uuid), 2, 'nota do fichario de A')
          RETURNING id::text
        ''',
        {'owner': userA, 'card': cardId},
      );
      await tx.execute(
        Sql.named('''
          INSERT INTO post_game_notes (
            id, user_id, deck_id, notes, deck_snapshot_hash, play_session_id
          )
          VALUES (
            @id, CAST(@owner AS uuid), CAST(@deck AS uuid), 'nota pos-jogo de A',
            @hash, 'sessao-de-jogo'
          )
        '''),
        parameters: {
          'id': 'privacy-note-$suffix',
          'owner': userA,
          'deck': deckA1,
          'hash': hex64('note-hash'),
        },
      );
      await tx.execute(
        Sql.named('''
          INSERT INTO shared_deck_reports (id, user_id, deck_id, title, payload)
          VALUES (@id, CAST(@owner AS uuid), CAST(@deck AS uuid), 'Relatorio de A', '{}'::jsonb)
        '''),
        parameters: {
          'id': 'privacy-report-$suffix',
          'owner': userA,
          'deck': deckA1,
        },
      );
      await tx.execute(
        Sql.named('''
          INSERT INTO deck_comments (deck_id, user_id, body)
          VALUES
            (CAST(@deckB AS uuid), CAST(@a AS uuid), @bodyA),
            (CAST(@deckA AS uuid), CAST(@b AS uuid), @bodyB)
        '''),
        parameters: {
          'deckB': deckB1Public,
          'deckA': deckA2Public,
          'a': userA,
          'b': userB,
          'bodyA': 'comentario de A no deck de B $suffix',
          'bodyB': 'comentario de B no deck de A $suffix',
        },
      );
      await tx.execute(
        Sql.named('''
          INSERT INTO user_follows (follower_id, following_id)
          VALUES (CAST(@a AS uuid), CAST(@b AS uuid)), (CAST(@b AS uuid), CAST(@a AS uuid))
        '''),
        parameters: {'a': userA, 'b': userB},
      );
      await tx.execute(
        Sql.named('''
          INSERT INTO user_blocks (blocker_id, blocked_id, reason)
          VALUES
            (CAST(@a AS uuid), CAST(@c AS uuid), 'motivo do bloqueio de A'),
            (CAST(@c AS uuid), CAST(@a AS uuid), 'motivo do bloqueio de C')
        '''),
        parameters: {'a': userA, 'c': userC},
      );
      await tx.execute(
        Sql.named('''
          INSERT INTO user_block_events (actor_user_id, target_user_id, action, reason, request_id)
          VALUES
            (CAST(@a AS uuid), CAST(@c AS uuid), 'blocked', 'motivo do bloqueio de A', @requestA),
            (CAST(@c AS uuid), CAST(@a AS uuid), 'blocked', 'motivo do bloqueio de C', @requestC)
        '''),
        parameters: {
          'a': userA,
          'c': userC,
          'requestA': blockRequestOfA,
          'requestC': blockRequestOfC,
        },
      );
      await tx.execute(
        Sql.named('''
          INSERT INTO activation_funnel_events (user_id, event_name, deck_id, metadata)
          VALUES (CAST(@a AS uuid), 'deck_created', CAST(@deck AS uuid),
                  CAST(@metadata AS jsonb))
        '''),
        parameters: {
          'a': userA,
          'deck': deckA1,
          'metadata': jsonEncode({'idempotency_key': 'activation-$userA'}),
        },
      );
      await tx.execute(
        Sql.named('''
          INSERT INTO deck_optimization_events (user_id, deck_id, archetype)
          VALUES (CAST(@a AS uuid), CAST(@deck AS uuid), 'aggro')
        '''),
        parameters: {'a': userA, 'deck': deckA1},
      );
      await tx.execute(
        Sql.named('''
          INSERT INTO ai_user_preferences (user_id, preferred_colors)
          VALUES (CAST(@a AS uuid), ARRAY['R'])
        '''),
        parameters: {'a': userA},
      );
      await tx.execute(
        Sql.named('INSERT INTO user_plans (user_id) VALUES (CAST(@a AS uuid))'),
        parameters: {'a': userA},
      );
      await tx.execute(
        Sql.named('''
          INSERT INTO ai_logs (
            user_id, deck_id, endpoint, model, latency_ms, prompt_summary,
            response_summary, error_message
          )
          VALUES (
            CAST(@a AS uuid), CAST(@deck AS uuid), 'optimize', 'gpt-4o-mini',
            10, 'resumo do prompt de A', 'resumo da resposta', 'erro interno'
          )
        '''),
        parameters: {'a': userA, 'deck': deckA1},
      );
      await tx.execute(
        Sql.named('''
          INSERT INTO ml_prompt_feedback (user_id, deck_id, archetype, user_comment)
          VALUES (CAST(@a AS uuid), CAST(@deck AS uuid), 'aggro', 'comentario de A sobre a IA')
        '''),
        parameters: {'a': userA, 'deck': deckA1},
      );
      await tx.execute(
        Sql.named('''
          INSERT INTO ai_optimize_fallback_telemetry (user_id, deck_id, triggered)
          VALUES (CAST(@a AS uuid), CAST(@deck AS uuid), TRUE)
        '''),
        parameters: {'a': userA, 'deck': deckA1},
      );
      await tx.execute(
        Sql.named('''
          INSERT INTO ai_optimize_cache (
            user_id, deck_id, cache_key, deck_signature, payload, expires_at
          )
          VALUES (
            CAST(@a AS uuid), CAST(@deck AS uuid), @key, @signature,
            CAST(@payload AS jsonb), NOW() + INTERVAL '1 hour'
          )
        '''),
        parameters: {
          'a': userA,
          'deck': deckA1,
          'key': 'cache-key-$suffix',
          'signature': hex64('signature'),
          'payload': jsonEncode({
            'cache_key': 'cache-key-$suffix',
            'suggestions': ['Carta'],
          }),
        },
      );
      await tx.execute(
        Sql.named('''
          INSERT INTO ai_generate_jobs (
            id, user_id, cache_key, format, request_key, request_fingerprint,
            result, status
          )
          VALUES (
            @id, CAST(@a AS uuid), @key, 'commander', @requestKey, @fingerprint,
            CAST(@result AS jsonb), 'completed'
          )
        '''),
        parameters: {
          'id': 'privacy-generate-$suffix',
          'a': userA,
          'key': 'generate-cache-key-$suffix',
          'requestKey': 'generate-request-key-$suffix',
          'fingerprint': hex64('generate-fp'),
          'result': jsonEncode({
            'prompt': 'prompt bruto de A',
            'cache': {'hit': false, 'cache_key': 'generate-cache-key-$suffix'},
          }),
        },
      );
      await tx.execute(
        Sql.named('''
          INSERT INTO ai_optimize_jobs (
            id, user_id, deck_id, archetype, request_key, request_fingerprint,
            result, status
          )
          VALUES (
            @id, CAST(@a AS uuid), CAST(@deck AS uuid), 'aggro', @requestKey,
            @fingerprint, '{"suggestions": ["Carta"]}'::jsonb, 'completed'
          )
        '''),
        parameters: {
          'id': 'privacy-optimize-$suffix',
          'a': userA,
          'deck': deckA1,
          'requestKey': 'optimize-request-key-$suffix',
          'fingerprint': hex64('optimize-fp'),
        },
      );

      Future<String> trade(
        String sender,
        String receiver,
        String message, {
        String status = 'pending',
      }) => _one(
        tx,
        '''
            INSERT INTO trade_offers (sender_id, receiver_id, message, tracking_code, status)
            VALUES (CAST(@sender AS uuid), CAST(@receiver AS uuid), @message, 'BR123', @status)
            RETURNING id::text
            ''',
        {
          'sender': sender,
          'receiver': receiver,
          'message': message,
          'status': status,
        },
      );
      tradeFromA = await trade(
        userA,
        userB,
        'mensagem da proposta de A $suffix',
      );
      tradeFromB = await trade(
        userB,
        userA,
        'mensagem da proposta de B $suffix',
      );
      tradeCompletedAB = await trade(
        userA,
        userB,
        'mensagem da troca concluida de A $suffix',
        status: 'completed',
      );

      Future<String> item(
        String trade,
        String owner,
        String direction,
        String cardName, {
        String? binderItem,
      }) => _one(
        tx,
        '''
          INSERT INTO trade_items (
            trade_offer_id, owner_id, direction, binder_item_id,
            snapshot_status, item_snapshot, snapshot_captured_at
          )
          VALUES (
            CAST(@trade AS uuid), CAST(@owner AS uuid), @direction,
            CAST(@binder AS uuid), 'captured', CAST(@snapshot AS jsonb), NOW()
          )
          RETURNING id::text
        ''',
        {
          'trade': trade,
          'owner': owner,
          'direction': direction,
          'binder': binderItem,
          'snapshot': jsonEncode({
            'schema_version': 'trade_item_snapshot_v1',
            'card': {'name': cardName},
            'physical': {'condition': 'NM'},
          }),
        },
      );
      // Oferta aberta de A para B: um item de cada lado.
      itemOfAInOpenOfferFromA = await item(
        tradeFromA,
        userA,
        'offering',
        'Carta de A',
      );
      itemOfBInOpenOfferFromA = await item(
        tradeFromA,
        userB,
        'requesting',
        'Carta de B',
      );
      // Oferta aberta de B para A: A é quem recebe e tem o item pedido.
      itemOfAInOpenOfferFromB = await item(
        tradeFromB,
        userA,
        'requesting',
        'Carta pedida de A',
      );
      itemOfBInOpenOfferFromB = await item(
        tradeFromB,
        userB,
        'offering',
        'Carta oferecida por B',
      );
      // Troca concluída de A com B: o item de A vem do fichário dele.
      itemOfAInCompletedTrade = await item(
        tradeCompletedAB,
        userA,
        'offering',
        'Carta trocada por A',
        binderItem: binderItemA,
      );
      itemOfBInCompletedTrade = await item(
        tradeCompletedAB,
        userB,
        'requesting',
        'Carta trocada por B',
      );
      await tx.execute(
        Sql.named('''
          INSERT INTO trade_messages (trade_offer_id, sender_id, message, attachment_url, attachment_type)
          VALUES
            (CAST(@trade AS uuid), CAST(@a AS uuid), @messageA, 'https://example.invalid/a.png', 'photo'),
            (CAST(@trade AS uuid), CAST(@b AS uuid), @messageB, NULL, NULL)
        '''),
        parameters: {
          'trade': tradeFromA,
          'a': userA,
          'b': userB,
          'messageA': 'mensagem de troca de A $suffix',
          'messageB': 'mensagem de troca de B $suffix',
        },
      );
      await tx.execute(
        Sql.named('''
          INSERT INTO trade_status_history (trade_offer_id, old_status, new_status, changed_by, notes)
          VALUES
            (CAST(@tradeA AS uuid), 'pending', 'accepted', CAST(@a AS uuid), @notesA),
            (CAST(@tradeB AS uuid), 'pending', 'declined', CAST(@b AS uuid), @notesB)
        '''),
        parameters: {
          'tradeA': tradeFromA,
          'tradeB': tradeFromB,
          'a': userA,
          'b': userB,
          'notesA': 'nota de status de A $suffix',
          'notesB': 'nota de status de B $suffix',
        },
      );
      conversationAB = await _one(
        tx,
        '''
        INSERT INTO conversations (user_a_id, user_b_id)
        VALUES (CAST(@a AS uuid), CAST(@b AS uuid))
        RETURNING id::text
      ''',
        {'a': userA, 'b': userB},
      );
      await tx.execute(
        Sql.named('''
          INSERT INTO direct_messages (conversation_id, sender_id, message)
          VALUES
            (CAST(@conversation AS uuid), CAST(@a AS uuid), @messageA),
            (CAST(@conversation AS uuid), CAST(@b AS uuid), @messageB)
        '''),
        parameters: {
          'conversation': conversationAB,
          'a': userA,
          'b': userB,
          'messageA': 'oi de A $suffix',
          'messageB': 'oi de B $suffix',
        },
      );
      await tx.execute(
        Sql.named('''
          INSERT INTO notifications (user_id, type, reference_id, title, body)
          VALUES
            (CAST(@a AS uuid), 'new_follower', CAST(@b AS uuid), @followTitle, 'corpo'),
            (CAST(@a AS uuid), 'trade_offer_received', CAST(@trade AS uuid), 'Nova proposta', 'corpo'),
            (CAST(@b AS uuid), 'new_follower', CAST(@a AS uuid), 'A começou a seguir você', 'corpo')
        '''),
        parameters: {
          'a': userA,
          'b': userB,
          'trade': tradeFromB,
          'followTitle': 'B $suffix começou a seguir você',
        },
      );
      reportByA = await _one(
        tx,
        '''
        INSERT INTO content_reports (
          reporter_user_id, target_type, target_id, reason, details, evidence
        )
        VALUES (
          CAST(@a AS uuid), 'deck', @target, 'spam', 'detalhe da denuncia de A',
          '{"nota": "evidencia de A"}'::jsonb
        )
        RETURNING id::text
      ''',
        {'a': userA, 'target': deckB1Public},
      );
      reportByB = await _one(
        tx,
        '''
        INSERT INTO content_reports (
          reporter_user_id, target_type, target_id, reason, details
        )
        VALUES (
          CAST(@b AS uuid), 'deck', @target, 'abuse', @details
        )
        RETURNING id::text
      ''',
        {
          'b': userB,
          'target': deckA2Public,
          'details': 'detalhe da denuncia de B $suffix',
        },
      );
      appealByA = await _one(
        tx,
        '''
        INSERT INTO content_report_appeals (report_id, appellant_user_id, reason)
        VALUES (CAST(@report AS uuid), CAST(@a AS uuid), 'recurso de A contra a denuncia')
        RETURNING id::text
      ''',
        {'report': reportByB, 'a': userA},
      );
      await tx.execute(
        Sql.named('''
          INSERT INTO moderation_actions (report_id, moderator_user_id, action, rationale)
          VALUES
            (CAST(@reportA AS uuid), CAST(@c AS uuid), 'start_review', 'revisao de C'),
            (CAST(@reportB AS uuid), CAST(@a AS uuid), 'dismiss', 'revisao de A')
        '''),
        parameters: {
          'reportA': reportByA,
          'reportB': reportByB,
          'a': userA,
          'c': userC,
        },
      );
      await tx.execute(
        Sql.named('''
          INSERT INTO password_reset_tokens (user_id, token_hash, expires_at)
          VALUES (CAST(@a AS uuid), @hash, NOW() + INTERVAL '20 minutes')
        '''),
        parameters: {'a': userA, 'hash': hex64('reset-$suffix')},
      );
      await tx.execute(
        Sql.named('''
          INSERT INTO email_verification_tokens (user_id, token_hash, expires_at)
          VALUES (CAST(@a AS uuid), @hash, NOW() + INTERVAL '24 hours')
        '''),
        parameters: {'a': userA, 'hash': hex64('verify-$suffix')},
      );
      await tx.execute(
        Sql.named('''
          INSERT INTO rate_limit_events (bucket, identifier)
          VALUES ('account_reverification', @identifier)
        '''),
        parameters: {'identifier': 'user:$userA'},
      );
    });
  }

  /// Contagem de linhas de cada tabela, para provar que a exportação não
  /// grava nada.
  static Future<Map<String, int>> rowCounts(
    Pool pool,
    Iterable<String> tables,
  ) async {
    final counts = <String, int>{};
    for (final table in tables) {
      final result = await pool.execute('SELECT COUNT(*)::int FROM $table');
      counts[table] = result.single.single! as int;
    }
    return counts;
  }
}
