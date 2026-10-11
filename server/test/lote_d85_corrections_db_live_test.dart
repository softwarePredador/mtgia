@Tags(['live', 'live_db_write'])
library;

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:server/sql_statement_splitter.dart';
import 'package:test/test.dart';

import 'support/lote_database.dart';

/// D-85: as cinco correções de dados do lote (`server/sql/lote/d85_*.sql`) num
/// PostgreSQL descartável, migrado do zero e copiado para cada cenário, com
/// linhas que a correção pega e linhas que ela não pode tocar. Cada script roda
/// pelo `psql`, como no lote: primeiro a prévia (o padrão), que imprime antes,
/// ação e depois e não grava nada; depois a gravação (`-v aplicar=1`) com as
/// contagens da prévia (`-v esperado_<objeto>=<n>`), duas vezes: a segunda não
/// muda nada. Sem as contagens, ou com uma errada, a gravação recusa sem gravar.
///
/// Requer `RUN_LOTE_DB_TESTS=1` e as variáveis `DB_*` de um banco descartável
/// em loopback.
void main() {
  final enabled = LoteDatabase.enabled;
  late LoteDatabase database;

  setUpAll(() {
    if (enabled) database = LoteDatabase.open();
  });

  Future<void> run(LoteCopy copy, String sql) async {
    for (final statement in splitPostgresStatements(sql)) {
      await copy.sql(statement);
    }
  }

  Future<T> withCopy<T>(
    String label,
    Future<T> Function(LoteCopy copy) body,
  ) async {
    final copy = await database.copy(label);
    try {
      return await body(copy);
    } finally {
      await copy.drop();
    }
  }

  group('d85_1: prompt do Generate na descrição do deck', () {
    const script = 'd85_1_deck_description_generate_prompt.sql';

    Future<Map<String, String?>> descriptions(LoteCopy copy) async => {
      for (final row in await copy.sql(
        'SELECT name, description FROM decks ORDER BY name',
      ))
        row[0] as String: row[1] as String?,
    };

    Future<void> seed(LoteCopy copy) async {
      final ana = await insertLoteUser(copy, 'lote_ana');
      final bia = await insertLoteUser(copy, 'lote_bia');
      await copy.sql(
        '''
        INSERT INTO ai_generate_jobs (id, user_id, cache_key, format, status, result)
        VALUES
          ('job-ana', @ana, 'k1', 'commander', 'completed',
           '{"prompt": "Deck de goblins agressivo", "format": "commander"}'),
          ('job-ana-sem-prompt', @ana, 'k2', 'commander', 'failed', NULL)
        ''',
        {'ana': ana},
      );
      await copy.sql(
        '''
        INSERT INTO ai_generate_requests (user_id, request_key, format, prompt)
        VALUES (@bia, 'r1', 'commander', 'Mono azul controle')
        ''',
        {'bia': bia},
      );
      await copy.sql(
        '''
        INSERT INTO ai_generate_requests
          (user_id, request_key, format, prompt, prompt_purged_at)
        VALUES (@ana, 'r2', 'commander', NULL, now())
        ''',
        {'ana': ana},
      );
      await copy.sql(
        '''
        INSERT INTO decks (user_id, name, format, description) VALUES
          (@ana, 'a1_prompt_com_espacos', 'commander', '  Deck de goblins agressivo '),
          (@ana, 'a2_descricao_propria', 'commander', 'Minha lista de goblins'),
          (@ana, 'a3_sem_descricao', 'commander', NULL),
          (@ana, 'a4_descricao_vazia', 'commander', ''),
          (@bia, 'b1_prompt_de_outra_conta', 'commander', 'Deck de goblins agressivo'),
          (@bia, 'b2_prompt_do_pedido', 'commander', 'Mono azul controle')
        ''',
        {'ana': ana, 'bia': bia},
      );
    }

    test(
      'limpa só a descrição igual a um prompt salvo do mesmo dono, sem mexer '
      'na revisão nem no ledger, e a segunda rodada não muda nada',
      () => withCopy('d85_1', (copy) async {
        await seed(copy);
        final revisions = await copy.count(
          'SELECT COALESCE(SUM(revision), 0)::bigint FROM decks',
        );

        final untouched = await copy.fingerprint();
        final preview = await copy.runScript(script);
        expect(preview.exitCode, 0, reason: '$preview');
        expect(preview.previewRolledBack, isTrue, reason: '$preview');
        expect(preview.value('antes', 'descricao_igual_a_prompt_salvo'), '2');
        expect(preview.value('acao', 'descricoes_limpas'), '2');
        expect(preview.value('depois', 'decks_com_descricao'), '2');
        expect(preview.value('depois', 'descricao_igual_a_prompt_salvo'), '0');
        expect(await copy.fingerprint(), untouched);

        final first = await copy.applyScript(
          script,
          expected: preview.actionCounts,
        );
        expect(first.exitCode, 0, reason: '$first');
        expect(first.appliedCommitted, isTrue, reason: '$first');
        expect(first.value('antes', 'decks_com_descricao'), '4');
        expect(first.value('antes', 'descricao_igual_a_prompt_salvo'), '2');
        expect(first.value('acao', 'descricoes_limpas'), '2');
        expect(first.value('depois', 'decks_com_descricao'), '2');
        expect(first.value('depois', 'descricao_igual_a_prompt_salvo'), '0');
        expect(await descriptions(copy), {
          'a1_prompt_com_espacos': null,
          'a2_descricao_propria': 'Minha lista de goblins',
          'a3_sem_descricao': null,
          'a4_descricao_vazia': '',
          'b1_prompt_de_outra_conta': 'Deck de goblins agressivo',
          'b2_prompt_do_pedido': null,
        });
        expect(
          await copy.count('SELECT COALESCE(SUM(revision), 0)::bigint FROM decks'),
          revisions,
        );
        expect(await copy.count('SELECT COUNT(*) FROM deck_change_events'), 0);

        final before = await descriptions(copy);
        final second = await copy.applyScript(
          script,
          expected: {'descricoes_limpas': '0'},
        );
        expect(second.exitCode, 0, reason: '$second');
        expect(second.value('antes', 'descricao_igual_a_prompt_salvo'), '0');
        expect(second.value('acao', 'descricoes_limpas'), '0');
        expect(await descriptions(copy), before);
      }),
      skip: enabled ? false : LoteDatabase.skipReason,
    );

    test(
      'a gravação sem a contagem esperada, ou com ela errada, recusa e não '
      'grava nada',
      () => withCopy('d85_1_esperado', (copy) async {
        await seed(copy);
        await expectApplyRefusals(
          copy,
          script,
          expected: {'descricoes_limpas': '2'},
          refusal: 'd85_1 recusado',
        );
      }),
      skip: enabled ? false : LoteDatabase.skipReason,
    );

    test(
      'D-118: a contagem só de leitura acha os decks do Generate pela marca de '
      'origem e diz quando não há marca',
      () => withCopy('d85_1_origem', (copy) async {
        const origin = 'd85_1_generate_origin_count.sql';
        Future<PsqlRun> count() async {
          final run = await copy.runScript(
            origin,
            directory: 'readonly',
            tabular: false,
            readOnly: true,
          );
          expect(run.exitCode, 0, reason: '$run');
          return run;
        }

        final ana = await insertLoteUser(copy, 'lote_ana');
        final ids = <String, String>{};
        for (final (name, description) in const [
          ('g1_materializado', null),
          ('g2_materializado_com_descricao', 'Goblins'),
          ('g3_evento_deck_generated', 'Mono azul'),
          ('m1_manual_com_descricao', 'Minha lista'),
          ('m2_manual', null),
        ]) {
          ids[name] = (await copy.sql(
            '''
            INSERT INTO decks (user_id, name, format, description)
            VALUES (@ana, @name, 'commander', @description) RETURNING id::text
            ''',
            {'ana': ana, 'name': name, 'description': description},
          )).single[0] as String;
        }
        for (final (key, deck) in [
          ('r1', ids['g1_materializado']!),
          ('r2', ids['g2_materializado_com_descricao']!),
        ]) {
          await copy.sql(
            '''
            INSERT INTO ai_generate_requests
              (user_id, request_key, format, materialized_deck_id)
            VALUES (@ana, @key, 'commander', CAST(@deck AS uuid))
            ''',
            {'ana': ana, 'key': key, 'deck': deck},
          );
        }
        await copy.sql(
          '''
          INSERT INTO activation_funnel_events (user_id, event_name, deck_id)
          VALUES (@ana, 'deck_generated', CAST(@g3 AS uuid)),
                 (@ana, 'deck_created', CAST(@m1 AS uuid))
          ''',
          {
            'ana': ana,
            'g3': ids['g3_evento_deck_generated']!,
            'm1': ids['m1_manual_com_descricao']!,
          },
        );
        final untouched = await copy.fingerprint();

        final marked = await count();
        expect(
          marked.value('marca', 'ai_generate_requests.materialized_deck_id'),
          'presente',
        );
        expect(
          marked.value('marca', 'activation_funnel_events.deck_id:deck_generated'),
          'presente',
        );
        expect(marked.value('marca', 'decks.coluna_de_origem'), 'ausente');
        expect(
          marked.value('marca', 'deck_do_app_antigo'),
          startsWith('sem_marca'),
        );
        expect(marked.value('contagem', 'decks_por_materialized_deck_id'), '2');
        expect(marked.value('contagem', 'decks_por_evento_deck_generated'), '1');
        expect(marked.value('contagem', 'decks'), '5');
        expect(marked.value('contagem', 'decks_do_generate'), '3');
        expect(marked.value('contagem', 'decks_do_generate_com_descricao'), '2');
        expect(marked.value('contagem', 'decks_com_descricao_sem_marca'), '1');
        expect(
          marked.value('resultado', 'd85_1'),
          startsWith('com_marca: 3 deck(s) vieram do Generate (2 com descrição)'),
        );
        expect(await copy.fingerprint(), untouched);

        // A marca existe, mas nenhum deck veio do Generate por ela.
        await copy.sql('DELETE FROM ai_generate_requests');
        await copy.sql('DELETE FROM activation_funnel_events');
        final unmarked = await count();
        expect(unmarked.value('contagem', 'decks_do_generate'), '0');
        expect(unmarked.value('contagem', 'decks_com_descricao_sem_marca'), '3');
        expect(
          unmarked.value('resultado', 'd85_1'),
          startsWith('com_marca_sem_deck'),
        );

        // Sem marca nenhuma: o script diz isso, e a correção 1 é no-op.
        await copy.sql('DROP TABLE ai_generate_requests CASCADE');
        await copy.sql('ALTER TABLE activation_funnel_events DROP COLUMN deck_id');
        final none = await count();
        expect(
          none.value('marca', 'ai_generate_requests.materialized_deck_id'),
          'ausente',
        );
        expect(
          none.value('marca', 'activation_funnel_events.deck_id:deck_generated'),
          'ausente',
        );
        expect(none.value('contagem', 'decks_do_generate'), '0');
        expect(
          none.value('resultado', 'd85_1'),
          allOf(startsWith('sem_marca'), contains('no-op documentado (D-118)')),
        );

        // Uma coluna de origem em decks é avisada, sem interpretar os valores.
        await copy.sql('ALTER TABLE decks ADD COLUMN origin TEXT');
        final column = await count();
        expect(column.value('marca', 'decks.coluna_de_origem'), 'origin');
        expect(
          column.value('resultado', 'd85_1'),
          startsWith('coluna_de_origem_em_decks: origin'),
        );
      }),
      skip: enabled ? false : LoteDatabase.skipReason,
    );

    test(
      'recusa sem a 069 e não muda nada',
      () => withCopy('d85_1_sem_069', (copy) async {
        await seed(copy);
        await copy.sql("DELETE FROM schema_migrations WHERE version = '069'");
        final before = await descriptions(copy);

        final refused = await copy.runScript(script);
        expect(refused.exitCode, isNot(0), reason: '$refused');
        expect(refused.stderr, contains('d85_1 recusado'));
        expect(await descriptions(copy), before);
      }),
      skip: enabled ? false : LoteDatabase.skipReason,
    );
  });

  group('d85_2: relatórios públicos órfãos', () {
    const script = 'd85_2_orphan_public_deck_reports.sql';

    test(
      'apaga só o órfão público, conta o privado sem tocar, e a segunda rodada '
      'não muda nada',
      () => withCopy('d85_2', (copy) async {
        final ana = await insertLoteUser(copy, 'lote_ana');
        final deck = (await copy.sql(
          '''
          INSERT INTO decks (user_id, name, format)
          VALUES (@ana, 'vivo', 'commander') RETURNING id::text
          ''',
          {'ana': ana},
        )).single[0] as String;
        await copy.sql(
          '''
          INSERT INTO shared_deck_reports (id, user_id, deck_id, title, payload, is_public)
          VALUES
            ('orfao_publico_1', @ana, NULL, 't', '{}', TRUE),
            ('orfao_publico_2', @ana, NULL, 't', '{}', TRUE),
            ('orfao_privado', @ana, NULL, 't', '{}', FALSE),
            ('deck_vivo_publico', @ana, CAST(@deck AS uuid), 't', '{}', TRUE),
            ('deck_vivo_privado', @ana, CAST(@deck AS uuid), 't', '{}', FALSE)
          ''',
          {'ana': ana, 'deck': deck},
        );
        Future<List<String>> reports() async => [
          for (final row in await copy.sql(
            'SELECT id FROM shared_deck_reports ORDER BY id',
          ))
            row[0] as String,
        ];

        final untouched = await copy.fingerprint();
        final preview = await copy.runScript(script);
        expect(preview.exitCode, 0, reason: '$preview');
        expect(preview.previewRolledBack, isTrue, reason: '$preview');
        expect(preview.actionCounts, {'orfaos_publicos_apagados': '2'});
        expect(preview.value('depois', 'relatorios'), '3');
        expect(await copy.fingerprint(), untouched);
        await expectApplyRefusals(
          copy,
          script,
          expected: preview.actionCounts,
          refusal: 'd85_2 recusado',
        );

        final first = await copy.applyScript(
          script,
          expected: preview.actionCounts,
        );
        expect(first.exitCode, 0, reason: '$first');
        expect(first.appliedCommitted, isTrue, reason: '$first');
        expect(first.value('antes', 'relatorios'), '5');
        expect(first.value('antes', 'orfaos_publicos'), '2');
        expect(first.value('antes', 'orfaos_privados_fora_do_escopo'), '1');
        expect(first.value('acao', 'orfaos_publicos_apagados'), '2');
        expect(first.value('depois', 'relatorios'), '3');
        expect(first.value('depois', 'orfaos_publicos'), '0');
        expect(first.value('depois', 'orfaos_privados_fora_do_escopo'), '1');
        expect(await reports(), [
          'deck_vivo_privado',
          'deck_vivo_publico',
          'orfao_privado',
        ]);

        final second = await copy.applyScript(
          script,
          expected: {'orfaos_publicos_apagados': '0'},
        );
        expect(second.exitCode, 0, reason: '$second');
        expect(second.value('acao', 'orfaos_publicos_apagados'), '0');
        expect(second.value('depois', 'relatorios'), '3');
        expect(await reports(), hasLength(3));
      }),
      skip: enabled ? false : LoteDatabase.skipReason,
    );
  });

  group('d85_3: metadado antigo dos eventos de ativação', () {
    const script = 'd85_3_activation_event_legacy_metadata.sql';

    Future<Map<String, Object?>> metadata(LoteCopy copy) async => {
      for (final row in await copy.sql(
        'SELECT event_name, metadata::text FROM activation_funnel_events',
      ))
        row[0] as String: jsonDecode(row[1] as String),
    };

    Future<void> seed(LoteCopy copy) async {
      final ana = await insertLoteUser(copy, 'lote_ana');
      final rows = <String, String>{
        'e1_idempotencia':
            '{"idempotency_key": "core_flow_started:$ana", "goal": "buildDeck"}',
        'e2_arquetipo_e_nota':
            '{"archetype": "Goblins do meu jeito", "intensity": "focused", '
            '"recommendation_context": {"post_game_note_id": "nota-1", '
            '"prefer_collection": true}}',
        'e3_deck_de_origem':
            '{"source_deck_id": "11111111-1111-4111-8111-111111111111", '
            '"save_mode": "draft_clone"}',
        'e4_nota_no_topo': '{"post_game_note_id": "nota-2"}',
        'e5_limpo': '{"goal": "play"}',
        'e6_lista': '["archetype"]',
        'e7_contexto_texto':
            '{"recommendation_context": "post_game_note_id"}',
      };
      for (final entry in rows.entries) {
        await copy.sql(
          '''
          INSERT INTO activation_funnel_events (user_id, event_name, metadata)
          VALUES (@ana, @name, CAST(@metadata AS jsonb))
          ''',
          {'ana': ana, 'name': entry.key, 'metadata': entry.value},
        );
      }
    }

    test(
      'tira as quatro chaves antigas, inclusive a nota dentro do contexto, '
      'mantém o resto e a segunda rodada não muda nada',
      () => withCopy('d85_3', (copy) async {
        await seed(copy);

        final untouched = await copy.fingerprint();
        final preview = await copy.runScript(script);
        expect(preview.exitCode, 0, reason: '$preview');
        expect(preview.previewRolledBack, isTrue, reason: '$preview');
        expect(preview.actionCounts, {'eventos_limpos': '4'});
        expect(preview.value('depois', 'eventos_com_chave_antiga'), '0');
        expect(await copy.fingerprint(), untouched);
        await expectApplyRefusals(
          copy,
          script,
          expected: preview.actionCounts,
          refusal: 'd85_3 recusado',
        );

        final first = await copy.applyScript(
          script,
          expected: preview.actionCounts,
        );
        expect(first.exitCode, 0, reason: '$first');
        expect(first.appliedCommitted, isTrue, reason: '$first');
        expect(first.value('antes', 'eventos'), '7');
        expect(first.value('antes', 'eventos_com_chave_antiga'), '4');
        expect(first.value('antes', 'metadata.idempotency_key'), '1');
        expect(first.value('antes', 'metadata.archetype'), '1');
        expect(first.value('antes', 'metadata.source_deck_id'), '1');
        expect(first.value('antes', 'metadata.post_game_note_id'), '1');
        expect(
          first.value(
            'antes',
            'metadata.recommendation_context.post_game_note_id',
          ),
          '1',
        );
        expect(first.value('acao', 'eventos_limpos'), '4');
        expect(first.value('depois', 'eventos'), '7');
        expect(first.value('depois', 'eventos_com_chave_antiga'), '0');
        for (final key in const [
          'metadata.idempotency_key',
          'metadata.archetype',
          'metadata.source_deck_id',
          'metadata.post_game_note_id',
          'metadata.recommendation_context.post_game_note_id',
        ]) {
          expect(first.value('depois', key), '0', reason: key);
        }
        expect(await metadata(copy), {
          'e1_idempotencia': {'goal': 'buildDeck'},
          'e2_arquetipo_e_nota': {
            'intensity': 'focused',
            'recommendation_context': {'prefer_collection': true},
          },
          'e3_deck_de_origem': {'save_mode': 'draft_clone'},
          'e4_nota_no_topo': <String, Object?>{},
          'e5_limpo': {'goal': 'play'},
          'e6_lista': ['archetype'],
          'e7_contexto_texto': {'recommendation_context': 'post_game_note_id'},
        });

        final before = await metadata(copy);
        final second = await copy.applyScript(
          script,
          expected: {'eventos_limpos': '0'},
        );
        expect(second.exitCode, 0, reason: '$second');
        expect(second.value('antes', 'eventos_com_chave_antiga'), '0');
        expect(second.value('acao', 'eventos_limpos'), '0');
        expect(await metadata(copy), before);
      }),
      skip: enabled ? false : LoteDatabase.skipReason,
    );

    test(
      'recusa sem a 073 e não muda nada',
      () => withCopy('d85_3_sem_073', (copy) async {
        await seed(copy);
        await copy.sql("DELETE FROM schema_migrations WHERE version = '073'");
        final before = await metadata(copy);

        final refused = await copy.runScript(script);
        expect(refused.exitCode, isNot(0), reason: '$refused');
        expect(refused.stderr, contains('d85_3 recusado'));
        expect(await metadata(copy), before);
      }),
      skip: enabled ? false : LoteDatabase.skipReason,
    );
  });

  group('d85_4: três CHECK com NOT VALID e depois VALIDATE', () {
    const script = 'd85_4_three_checks_not_valid_validate.sql';
    const checks = {
      'ml_prompt_feedback': 'chk_ml_prompt_feedback_effectiveness_score',
      'notifications': 'notifications_type_check',
      'user_binder_items': 'user_binder_items_currency_check',
    };

    /// Nome do CHECK -> (definição, validado), dos que existem.
    Future<Map<String, (String, bool)>> state(LoteCopy copy) async => {
      for (final row in await copy.sql('''
        SELECT conname, pg_get_constraintdef(oid), convalidated
        FROM pg_constraint
        WHERE contype = 'c'
          AND conname IN (
            'chk_ml_prompt_feedback_effectiveness_score',
            'notifications_type_check',
            'user_binder_items_currency_check'
          )
      '''))
        row[0] as String: (row[1] as String, row[2] as bool),
    };

    /// A produção: sem os três CHECK, com uma linha que viola cada um.
    Future<({String ana, String card})> productionShape(LoteCopy copy) async {
      for (final entry in checks.entries) {
        await copy.sql(
          'ALTER TABLE ${entry.key} DROP CONSTRAINT ${entry.value}',
        );
      }
      final ana = await insertLoteUser(copy, 'lote_ana');
      final card = (await copy.sql('''
        INSERT INTO cards (scryfall_id, name)
        VALUES (gen_random_uuid(), 'Lote Card') RETURNING id::text
      ''')).single[0] as String;
      await copy.sql(
        '''
        INSERT INTO ml_prompt_feedback (user_id, archetype, effectiveness_score)
        VALUES (@ana, 'aggro', 7), (@ana, 'aggro', NULL), (@ana, 'aggro', 11)
        ''',
        {'ana': ana},
      );
      await copy.sql(
        '''
        INSERT INTO notifications (user_id, type, title)
        VALUES (@ana, 'direct_message', 't'), (@ana, 'tipo_aposentado', 't')
        ''',
        {'ana': ana},
      );
      await copy.sql(
        '''
        INSERT INTO user_binder_items (user_id, card_id, currency, language)
        VALUES (@ana, CAST(@card AS uuid), 'BRL', 'en'),
               (@ana, CAST(@card AS uuid), 'EUR', 'pt')
        ''',
        {'ana': ana, 'card': card},
      );
      return (ana: ana, card: card);
    }

    test(
      'no banco novo os três já existem validados e o script não muda nada',
      () => withCopy('d85_4_novo', (copy) async {
        final before = await state(copy);
        expect(before.keys, unorderedEquals(checks.values));
        expect(before.values.every((value) => value.$2), isTrue);

        final preview = await copy.runScript(script);
        expect(preview.exitCode, 0, reason: '$preview');
        expect(preview.previewRolledBack, isTrue, reason: '$preview');
        expect(preview.actionCounts, {
          'checks_criados_not_valid': '0',
          'checks_validados': '0',
        });

        final run = await copy.applyScript(
          script,
          expected: preview.actionCounts,
        );
        expect(run.exitCode, 0, reason: '$run');
        expect(run.appliedCommitted, isTrue, reason: '$run');
        expect(run.value('acao', 'checks_criados_not_valid'), '0');
        expect(run.value('acao', 'checks_validados'), '0');
        expect(await state(copy), before);
      }),
      skip: enabled ? false : LoteDatabase.skipReason,
    );

    test(
      'com violação em qualquer um, recusa os três sem criar nada; com zero, '
      'cria NOT VALID, valida, barra linha nova e a segunda rodada não muda nada',
      () => withCopy('d85_4_producao', (copy) async {
        final fresh = await withCopy(
          'd85_4_referencia',
          (reference) => state(reference),
        );
        final shape = await productionShape(copy);
        expect(await state(copy), isEmpty);

        final refused = await copy.runScript(script);
        expect(refused.exitCode, isNot(0), reason: '$refused');
        expect(refused.stderr, contains('d85_4 recusado'));
        for (final entry in checks.entries) {
          expect(refused.stderr, contains('${entry.key}.${entry.value} (1)'));
          expect(
            refused.value('antes', '${entry.key}.${entry.value}:violacoes'),
            '1',
          );
          expect(
            refused.value('antes', '${entry.key}.${entry.value}:estado'),
            'ausente',
          );
        }
        expect(await state(copy), isEmpty);

        // Uma violação que sobra ainda recusa os três.
        await copy.sql(
          'UPDATE ml_prompt_feedback SET effectiveness_score = 10 '
          'WHERE effectiveness_score = 11',
        );
        await copy.sql(
          "UPDATE notifications SET type = 'trade_message' "
          "WHERE type = 'tipo_aposentado'",
        );
        final stillRefused = await copy.runScript(script);
        expect(stillRefused.exitCode, isNot(0), reason: '$stillRefused');
        expect(
          stillRefused.stderr,
          contains('user_binder_items.user_binder_items_currency_check (1)'),
        );
        expect(await state(copy), isEmpty);

        await copy.sql(
          "UPDATE user_binder_items SET currency = 'USD' WHERE currency = 'EUR'",
        );
        // A prévia faz as duas fases numa transação só e desfaz tudo.
        final untouched = await copy.fingerprint();
        final preview = await copy.runScript(script);
        expect(preview.exitCode, 0, reason: '$preview');
        expect(preview.previewRolledBack, isTrue, reason: '$preview');
        expect(preview.actionCounts, {
          'checks_criados_not_valid': '3',
          'checks_validados': '3',
        });
        for (final entry in checks.entries) {
          expect(
            preview.value('depois', '${entry.key}.${entry.value}:estado'),
            'validado',
          );
        }
        expect(await state(copy), isEmpty);
        expect(await copy.fingerprint(), untouched);
        await expectApplyRefusals(
          copy,
          script,
          expected: preview.actionCounts,
          refusal: 'd85_4 recusado',
        );
        expect(await state(copy), isEmpty);

        final applied = await copy.applyScript(
          script,
          expected: preview.actionCounts,
        );
        expect(applied.exitCode, 0, reason: '$applied');
        expect(applied.appliedCommitted, isTrue, reason: '$applied');
        expect(applied.value('acao', 'checks_criados_not_valid'), '3');
        expect(applied.value('acao', 'checks_validados'), '3');
        for (final entry in checks.entries) {
          final name = '${entry.key}.${entry.value}';
          expect(applied.value('antes', '$name:violacoes'), '0');
          expect(applied.value('antes', '$name:estado'), 'ausente');
          expect(applied.value('depois', '$name:estado'), 'validado');
        }
        // A mesma definição do banco novo, validada.
        expect(await state(copy), fresh);

        // A partir daqui, linha que viola é recusada.
        await expectLater(
          copy.sql(
            '''
            INSERT INTO user_binder_items (user_id, card_id, currency, language)
            VALUES (@ana, CAST(@card AS uuid), 'EUR', 'es')
            ''',
            {'ana': shape.ana, 'card': shape.card},
          ),
          throwsA(isA<Object>()),
        );

        final second = await copy.applyScript(
          script,
          expected: {'checks_criados_not_valid': '0', 'checks_validados': '0'},
        );
        expect(second.exitCode, 0, reason: '$second');
        expect(second.value('acao', 'checks_criados_not_valid'), '0');
        expect(second.value('acao', 'checks_validados'), '0');
        expect(await state(copy), fresh);
      }),
      skip: enabled ? false : LoteDatabase.skipReason,
    );

    test(
      'um CHECK com o nome certo e outra definição recusa os três sem criar '
      'nada',
      () => withCopy('d85_4_outra_definicao', (copy) async {
        await productionShape(copy);
        await copy.sql('DELETE FROM ml_prompt_feedback WHERE effectiveness_score = 11');
        await copy.sql("DELETE FROM notifications WHERE type = 'tipo_aposentado'");
        await copy.sql("DELETE FROM user_binder_items WHERE currency = 'EUR'");
        // O nome da D-85 com uma lista de tipos menor: não é o CHECK do banco novo.
        await copy.sql('''
          ALTER TABLE notifications ADD CONSTRAINT notifications_type_check
          CHECK (type IN ('new_follower', 'direct_message')) NOT VALID
        ''');
        final before = await state(copy);
        expect(before.keys, ['notifications_type_check']);

        final refused = await copy.runScript(script);
        expect(refused.exitCode, isNot(0), reason: '$refused');
        expect(refused.stderr, contains('d85_4 recusado'));
        expect(
          refused.stderr,
          contains('já existe restrição com o nome e outra definição'),
        );
        expect(
          refused.stderr,
          contains('notifications.notifications_type_check (CHECK'),
        );
        expect(
          refused.value('antes', 'notifications.notifications_type_check:estado'),
          'definicao_divergente',
        );
        expect(
          refused.value(
            'antes',
            'user_binder_items.user_binder_items_currency_check:estado',
          ),
          'ausente',
        );
        final applied = await copy.applyScript(
          script,
          expected: {'checks_criados_not_valid': '2', 'checks_validados': '3'},
        );
        expect(applied.exitCode, isNot(0), reason: '$applied');
        expect(applied.stderr, contains('outra definição'));
        expect(await state(copy), before);

        // Outro tipo de restrição com o nome do CHECK também não conta.
        await copy.sql('ALTER TABLE notifications DROP CONSTRAINT notifications_type_check');
        await copy.sql(
          'ALTER TABLE user_binder_items ADD CONSTRAINT '
          'user_binder_items_currency_check UNIQUE (id, currency)',
        );
        final unique = await copy.runScript(script);
        expect(unique.exitCode, isNot(0), reason: '$unique');
        expect(
          unique.value(
            'antes',
            'user_binder_items.user_binder_items_currency_check:estado',
          ),
          'definicao_divergente',
        );
      }),
      skip: enabled ? false : LoteDatabase.skipReason,
    );

    test(
      'um CHECK que ficou NOT VALID numa rodada anterior é só validado',
      () => withCopy('d85_4_retomada', (copy) async {
        await productionShape(copy);
        await copy.sql('DELETE FROM ml_prompt_feedback WHERE effectiveness_score = 11');
        await copy.sql("DELETE FROM notifications WHERE type = 'tipo_aposentado'");
        await copy.sql("DELETE FROM user_binder_items WHERE currency = 'EUR'");
        await copy.sql('''
          ALTER TABLE notifications ADD CONSTRAINT notifications_type_check
          CHECK (type IN ('new_follower', 'trade_offer_received', 'trade_accepted',
            'trade_declined', 'trade_shipped', 'trade_delivered', 'trade_completed',
            'trade_message', 'direct_message')) NOT VALID
        ''');

        final run = await copy.applyScript(
          script,
          expected: {'checks_criados_not_valid': '2', 'checks_validados': '3'},
        );
        expect(run.exitCode, 0, reason: '$run');
        expect(
          run.value('antes', 'notifications.notifications_type_check:estado'),
          'not_valid',
        );
        expect(run.value('acao', 'checks_criados_not_valid'), '2');
        expect(run.value('acao', 'checks_validados'), '3');
        expect(
          (await state(copy)).values.every((value) => value.$2),
          isTrue,
        );
      }),
      skip: enabled ? false : LoteDatabase.skipReason,
    );
  });

  group('d85_5: arquivar e apagar card_rulings_legacy e poststatus', () {
    const archiveScript = 'd85_5a_legacy_ruling_poststatus_archive.sql';
    const dropScript = 'd85_5b_drop_legacy_ruling_poststatus.sql';

    /// A forma da produção: a tabela antiga da 016, o enum e a `posts` que o usa.
    Future<void> productionShape(LoteCopy copy) => run(copy, r'''
      CREATE TYPE public.poststatus AS ENUM ('draft', 'published', 'archived');
      CREATE TABLE public.posts (
        id SERIAL PRIMARY KEY,
        status public.poststatus NOT NULL DEFAULT 'draft'
      );
      CREATE TABLE public.card_rulings_legacy (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        card_name TEXT NOT NULL,
        ruling_date DATE,
        ruling_text TEXT
      );
      CREATE INDEX ON public.card_rulings_legacy (card_name);
      INSERT INTO public.card_rulings_legacy (card_name, ruling_date, ruling_text) VALUES
        ('Æther Vial', '2004-10-04', 'Ação "dupla" com aspas'),
        ('Lightning Bolt', NULL, E'linha 1\nlinha 2\ttab'),
        ('Sol Ring', '2021-03-01', NULL);
    ''');

    Future<({String sha, String lines, List<String> content})> archive(
      LoteCopy copy,
    ) async {
      final result = await copy.runScript(archiveScript, tabular: false);
      expect(result.exitCode, 0, reason: '$result');
      final text = utf8.decode(result.stdoutBytes);
      expect(text.isEmpty || text.endsWith('\n'), isTrue, reason: text);
      final content = const LineSplitter().convert(text);
      return (
        sha: sha256.convert(result.stdoutBytes).toString(),
        lines: '${content.length}',
        content: content,
      );
    }

    Future<bool> exists(LoteCopy copy, String regclassOrType) async =>
        (await copy.sql(
          "SELECT to_regclass(@name) IS NOT NULL OR to_regtype(@name) IS NOT NULL",
          {'name': regclassOrType},
        )).single[0] as bool;

    test(
      'o arquivo traz o enum e cada registro, e o script só apaga com o '
      'arquivo que bate com o banco',
      () => withCopy('d85_5', (copy) async {
        await productionShape(copy);

        final first = await archive(copy);
        expect(first.lines, '4');
        expect(jsonDecode(first.content.first), {
          'objeto': 'public.poststatus',
          'tipo': 'enum',
          'rotulos': ['draft', 'published', 'archived'],
        });
        final rows = [
          for (final line in first.content.skip(1))
            (jsonDecode(line) as Map)['linha'] as Map,
        ];
        expect(
          rows.map((row) => row['card_name']),
          unorderedEquals(['Æther Vial', 'Lightning Bolt', 'Sol Ring']),
        );
        expect(
          rows.map((row) => row['ruling_text']),
          contains('linha 1\nlinha 2\ttab'),
        );

        // A prévia sem o arquivo mostra o sha256 e as linhas que o banco tem, faz
        // tudo e desfaz: nada sai.
        final untouched = await copy.fingerprint();
        final blindPreview = await copy.runScript(dropScript);
        expect(blindPreview.exitCode, 0, reason: '$blindPreview');
        expect(blindPreview.previewRolledBack, isTrue, reason: '$blindPreview');
        expect(blindPreview.value('acao', 'arquivo:conferencia'), 'nao_informado');
        expect(blindPreview.value('acao', 'arquivo:sha256_no_banco'), first.sha);
        expect(blindPreview.value('acao', 'arquivo:linhas_no_banco'), first.lines);
        expect(blindPreview.value('acao', 'linhas_do_arquivo_conferidas'), '0');
        expect(blindPreview.value('acao', 'objetos_apagados'), '1');
        expect(
          blindPreview.value('depois', 'card_rulings_legacy:linhas'),
          'ausente',
        );
        expect(await copy.fingerprint(), untouched);

        // A prévia com o arquivo confere como a gravação.
        final preview = await copy.runScript(
          dropScript,
          variables: {'arquivo_sha256': first.sha, 'arquivo_linhas': first.lines},
        );
        expect(preview.exitCode, 0, reason: '$preview');
        expect(preview.previewRolledBack, isTrue, reason: '$preview');
        expect(preview.value('acao', 'arquivo:conferencia'), 'conferido');
        expect(preview.value('acao', 'linhas_do_arquivo_conferidas'), '4');
        expect(await copy.fingerprint(), untouched);

        // A gravação sem o arquivo: nada sai.
        final withoutArchive = await copy.applyScript(
          dropScript,
          expected: {'objetos_apagados': '1'},
        );
        expect(withoutArchive.exitCode, isNot(0), reason: '$withoutArchive');
        expect(withoutArchive.stderr, contains('d85_5b recusado'));
        expect(withoutArchive.stderr, contains('informe -v arquivo_sha256'));
        expect(await exists(copy, 'public.card_rulings_legacy'), isTrue);

        // Sem a contagem esperada, ou com ela errada: nada sai.
        await expectApplyRefusals(
          copy,
          dropScript,
          expected: {'objetos_apagados': '1'},
          refusal: 'd85_5b recusado',
          variables: {'arquivo_sha256': first.sha, 'arquivo_linhas': first.lines},
        );

        // Arquivo de outro conteúdo: nada sai.
        final wrong = await copy.applyScript(
          dropScript,
          expected: {'objetos_apagados': '1'},
          variables: {'arquivo_sha256': '0' * 64, 'arquivo_linhas': first.lines},
        );
        expect(wrong.exitCode, isNot(0), reason: '$wrong');
        expect(wrong.stderr, contains('não confere'));
        expect(await exists(copy, 'public.card_rulings_legacy'), isTrue);

        // O banco mudou depois do arquivo: o arquivo velho não serve.
        await copy.sql(
          "UPDATE card_rulings_legacy SET ruling_text = 'mudou' "
          "WHERE card_name = 'Sol Ring'",
        );
        final stale = await copy.applyScript(
          dropScript,
          expected: {'objetos_apagados': '1'},
          variables: {'arquivo_sha256': first.sha, 'arquivo_linhas': first.lines},
        );
        expect(stale.exitCode, isNot(0), reason: '$stale');
        expect(stale.stderr, contains('não confere'));
        expect(await exists(copy, 'public.card_rulings_legacy'), isTrue);

        // Algo que depende da tabela: sem CASCADE, a transação inteira volta.
        await copy.sql(
          'CREATE VIEW lote_dependente AS SELECT card_name FROM card_rulings_legacy',
        );
        final current = await archive(copy);
        final dependent = await copy.applyScript(
          dropScript,
          expected: {'objetos_apagados': '1'},
          variables: {
            'arquivo_sha256': current.sha,
            'arquivo_linhas': current.lines,
          },
        );
        expect(dependent.exitCode, isNot(0), reason: '$dependent');
        expect(await exists(copy, 'public.card_rulings_legacy'), isTrue);
        expect(await exists(copy, 'public.lote_dependente'), isTrue);
        expect(await exists(copy, 'public.poststatus'), isTrue);
        await copy.sql('DROP VIEW lote_dependente');

        // Arquivo certo: a tabela sai; o enum fica, porque a posts o usa.
        final partial = await copy.applyScript(
          dropScript,
          expected: {'objetos_apagados': '1'},
          variables: {
            'arquivo_sha256': current.sha,
            'arquivo_linhas': current.lines,
          },
        );
        expect(partial.exitCode, 0, reason: '$partial');
        expect(partial.appliedCommitted, isTrue, reason: '$partial');
        expect(partial.value('acao', 'objetos_apagados'), '1');
        expect(partial.value('antes', 'card_rulings_legacy:linhas'), '3');
        expect(partial.value('antes', 'poststatus:estado'), 'presente');
        expect(
          partial.value('antes', 'poststatus:colunas_que_usam'),
          'posts.status',
        );
        expect(partial.value('acao', 'linhas_do_arquivo_conferidas'), '4');
        expect(partial.value('depois', 'card_rulings_legacy:linhas'), 'ausente');
        expect(partial.value('depois', 'poststatus:estado'), 'presente');
        expect(
          partial.value('resultado', 'd85_5'),
          allOf(startsWith('parcial'), contains('posts.status')),
        );
        expect(await exists(copy, 'public.card_rulings_legacy'), isFalse);
        expect(await exists(copy, 'public.poststatus'), isTrue);
        expect(await copy.count('SELECT COUNT(*) FROM posts'), 0);

        // Quando a posts sair (D-49), o enum sai com um arquivo novo.
        await copy.sql('DROP TABLE posts');
        final typeOnly = await archive(copy);
        expect(typeOnly.lines, '1');
        final complete = await copy.applyScript(
          dropScript,
          expected: {'objetos_apagados': '1'},
          variables: {
            'arquivo_sha256': typeOnly.sha,
            'arquivo_linhas': typeOnly.lines,
          },
        );
        expect(complete.exitCode, 0, reason: '$complete');
        expect(complete.value('resultado', 'd85_5'), 'completo');
        expect(complete.value('depois', 'poststatus:estado'), 'ausente');
        expect(await exists(copy, 'public.poststatus'), isFalse);

        // De novo, sem nada: não faz nada e não pede arquivo.
        final again = await copy.runScript(dropScript);
        expect(again.exitCode, 0, reason: '$again');
        expect(again.value('resultado', 'd85_5'), 'nada_a_fazer');
        final againApplied = await copy.applyScript(
          dropScript,
          expected: {'objetos_apagados': '0'},
        );
        expect(againApplied.exitCode, 0, reason: '$againApplied');
        expect(againApplied.value('resultado', 'd85_5'), 'nada_a_fazer');
        final emptyArchive = await archive(copy);
        expect(emptyArchive.lines, '0');
      }),
      skip: enabled ? false : LoteDatabase.skipReason,
    );
  });
}
