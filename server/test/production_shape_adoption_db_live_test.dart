@Tags(['live', 'live_db_write'])
library;

import 'dart:io';

import 'package:postgres/postgres.dart';
import 'package:server/sql_statement_splitter.dart';
import 'package:test/test.dart';

import '../bin/migrate.dart' as migrate;
import 'support/schema_adoption.dart';

/// BT-DB-005 num PostgreSQL descartável migrado do zero
/// (`database_setup.sql` + `bin/migrate.dart`): as tabelas, as formas e as
/// chaves que a 075 e a 076 adotam da produção, comparadas com a auditoria
/// BT-DB-001. O que muda o banco roda numa transação desfeita.
///
/// Requer `RUN_SCHEMA_DB_TESTS=1` e as variáveis `DB_*` de um banco
/// descartável em loopback.
void main() {
  final enabled = Platform.environment['RUN_SCHEMA_DB_TESTS'] == '1';
  final skipReason =
      enabled
          ? null
          : 'Requer RUN_SCHEMA_DB_TESTS=1 e PostgreSQL descartavel isolado.';
  final audit = loadSchemaAudit();
  final differences = audit['diferencas'] as Map;
  const adoptedTables = [
    'optimization_analysis_logs',
    'synergy_packages',
    'archetype_patterns',
    'ml_learning_state',
    'theme_contextual_rules',
    'analysis_sources',
  ];
  const alignedKeys = {
    'direct_messages': 'direct_messages_sender_id_fkey',
    'trade_messages': 'trade_messages_sender_id_fkey',
    'trade_status_history': 'trade_status_history_changed_by_fkey',
  };
  late Pool pool;

  setUpAll(() {
    if (!enabled) return;
    final host = Platform.environment['DB_HOST'] ?? '127.0.0.1';
    if (!const {'127.0.0.1', 'localhost', '::1'}.contains(host)) {
      throw StateError('RUN_SCHEMA_DB_TESTS só roda em banco loopback: $host');
    }
    pool = Pool.withEndpoints(
      [
        Endpoint(
          host: host,
          port: int.parse(Platform.environment['DB_PORT'] ?? '5432'),
          database: Platform.environment['DB_NAME']!,
          username: Platform.environment['DB_USER']!,
          password: Platform.environment['DB_PASS'] ?? '',
        ),
      ],
      settings: const PoolSettings(
        sslMode: SslMode.disable,
        maxConnectionCount: 1,
      ),
    );
  });

  tearDownAll(() async {
    if (enabled) await pool.close();
  });

  /// Roda [body] numa transação que sempre termina em ROLLBACK.
  Future<T> rolledBack<T>(Future<T> Function(Connection connection) body) =>
      pool.withConnection((connection) async {
        await connection.execute('BEGIN');
        try {
          return await body(connection);
        } finally {
          await connection.execute('ROLLBACK');
        }
      });

  Future<void> apply(Session session, String version) async {
    final migration = migrate.migrations.singleWhere(
      (item) => item.version == version,
    );
    for (final statement in splitPostgresStatements(migration.up)) {
      await session.execute(statement);
    }
  }

  Future<Map<String, Object?>> column(
    Session session,
    String table,
    String name,
  ) async {
    final result = await session.execute(
      Sql.named('''
        SELECT format_type(a.atttypid, a.atttypmod), a.attnotnull,
               pg_get_expr(d.adbin, d.adrelid)
        FROM pg_attribute a
        LEFT JOIN pg_attrdef d ON d.adrelid = a.attrelid AND d.adnum = a.attnum
        WHERE a.attrelid = ('public.' || @table)::regclass
          AND a.attname = @name AND NOT a.attisdropped
      '''),
      parameters: {'table': table, 'name': name},
    );
    final row = result.single;
    return {'tipo': row[0], 'not_null': row[1], 'default': row[2]};
  }

  /// Índices das [tables] no formato da auditoria (sem o nome na definição).
  Future<Map<String, String>> indexes(
    Session session,
    List<String> tables,
  ) async {
    final result = await session.execute(
      Sql.named('''
        SELECT indexname, indexdef FROM pg_indexes
        WHERE schemaname = 'public' AND tablename::text = ANY (@tables)
      '''),
      parameters: {'tables': TypedValue(Type.textArray, tables)},
    );
    return {
      for (final row in result)
        row[0] as String: (row[1] as String).replaceFirst(
          RegExp(r'INDEX \S+ ON'),
          'INDEX ON',
        ),
    };
  }

  /// Chaves, ações e gatilhos de conta ativa das tabelas da 076, com o
  /// resto do catálogo que a 075 toca: a foto que tem de ficar igual.
  Future<List<String>> snapshot(Session session) async {
    final result = await session.execute('''
      SELECT 'chave ' || conrelid::regclass || ' ' || conname || ' ' ||
             pg_get_constraintdef(oid)
      FROM pg_constraint
      WHERE connamespace = 'public'::regnamespace
      UNION ALL
      SELECT 'gatilho ' || tgrelid::regclass || ' ' || tgname
      FROM pg_trigger
      WHERE NOT tgisinternal
      UNION ALL
      SELECT 'indice ' || indexname || ' ' || indexdef
      FROM pg_indexes WHERE schemaname = 'public'
      UNION ALL
      SELECT 'coluna ' || attrelid::regclass || '.' || attname || ' ' ||
             format_type(atttypid, atttypmod) || ' ' || attnotnull
      FROM pg_attribute
      WHERE attrelid IN (
        SELECT oid FROM pg_class
        WHERE relnamespace = 'public'::regnamespace AND relkind IN ('r', 'v')
      )
        AND attnum > 0 AND NOT attisdropped
      UNION ALL
      SELECT 'view ' || viewname || ' ' || definition
      FROM pg_views WHERE schemaname = 'public'
      ORDER BY 1
    ''');
    return [for (final row in result) row[0] as String];
  }

  test(
    'as tabelas da 075 existem com os índices e as chaves da produção',
    () async {
      final production = {
        for (final item
            in ((differences['indices'] as Map)['sobrando'] as List)
                .cast<Map>())
          if (adoptedTables.contains(
            (item['alvo']['tabela'] as String).split('.').last,
          ))
            (item['objeto'] as String).split('.').last:
                item['alvo']['definicao'] as String,
      };
      expect(production, hasLength(20));
      expect(await indexes(pool, adoptedTables), production);
      // Os tipos que a leitura autorizada da definição na produção trouxe.
      expect(await column(pool, 'optimization_analysis_logs', 'test_run_id'), {
        'tipo': 'text',
        'not_null': true,
        'default': null,
      });
      expect(await column(pool, 'archetype_patterns', 'last_analyzed_at'), {
        'tipo': 'timestamp without time zone',
        'not_null': false,
        'default': 'CURRENT_TIMESTAMP',
      });
      final listType = await pool.execute('''
        SELECT pg_get_constraintdef(oid, true) FROM pg_constraint
        WHERE conrelid = 'public.user_binder_items'::regclass
          AND conname = 'chk_list_type'
      ''');
      expect(
        listType.single.single,
        "CHECK (list_type::text = ANY (ARRAY['have'::character varying::text, "
        "'want'::character varying::text]))",
      );
    },
    skip: skipReason,
  );

  test('as colunas adotadas têm a forma da produção, e os dois defaults da '
      'migration ficam', () async {
    final columns = differences['colunas'] as Map;
    Map<String, Object?> productionShape(String name) {
      for (final item in (columns['sobrando'] as List).cast<Map>()) {
        if (item['objeto'] == name) return (item['alvo'] as Map).cast();
      }
      throw StateError(name);
    }

    expect(
      await column(pool, 'card_meta_insights', 'id'),
      productionShape('public.card_meta_insights.id'),
    );
    expect(
      await column(pool, 'cards', 'edhrec_rank'),
      productionShape('public.cards.edhrec_rank'),
    );
    for (final (table, name, type) in const [
      ('users', 'location_city', 'character varying(100)'),
      ('users', 'location_state', 'character varying(2)'),
      ('user_binder_items', 'list_type', 'character varying(4)'),
      ('card_meta_insights', 'versatility_score', 'double precision'),
    ]) {
      expect(
        (await column(pool, table, name))['tipo'],
        type,
        reason: '$table.$name',
      );
    }
    expect(
      (await column(pool, 'user_binder_items', 'list_type'))['default'],
      "'have'::character varying",
    );
    expect(
      (await column(
        pool,
        'card_meta_insights',
        'versatility_score',
      ))['default'],
      '0.0',
    );
    for (final name in const ['created_at', 'updated_at']) {
      expect(await column(pool, 'commander_learned_decks', name), {
        'tipo': 'timestamp with time zone',
        'not_null': true,
        'default': 'now()',
      });
    }
    expect(
      (await column(pool, 'battle_simulations', 'simulation_type'))['default'],
      "'legacy'::text",
    );
    expect(
      (await column(pool, 'ml_prompt_feedback', 'prompt_version'))['default'],
      "'v1.1-hybrid'::text",
    );
    final primary = await pool.execute('''
        SELECT pg_get_constraintdef(oid) FROM pg_constraint
        WHERE conrelid = 'public.card_meta_insights'::regclass AND contype = 'p'
      ''');
    expect(primary.single.single, 'PRIMARY KEY (id)');
    final checks = await pool.execute('''
        SELECT conrelid::regclass::text || '.' || conname FROM pg_constraint
        WHERE conname IN (
          'chk_account_deletion_mode',
          'account_deletion_receipts_deletion_mode_check',
          'chk_list_type',
          'user_binder_items_list_type_check',
          'post_game_notes_revision_check',
          'chk_post_game_notes_revision'
        )
        ORDER BY 1
      ''');
    expect(
      [for (final row in checks) row[0]],
      [
        'account_deletion_receipts.chk_account_deletion_mode',
        'post_game_notes.chk_post_game_notes_revision',
        'user_binder_items.chk_list_type',
      ],
    );
    final trade = await indexes(pool, const [
      'trade_status_history',
      'trade_messages',
      'ml_prompt_feedback',
    ]);
    final divergent = {
      for (final item
          in ((differences['indices'] as Map)['divergente'] as List)
              .cast<Map>())
        (item['objeto'] as String).split('.').last:
            (item['definicao'] as List).last as String,
    };
    for (final name in const [
      'idx_trade_history_offer',
      'idx_trade_messages_offer',
    ]) {
      expect(trade[name], divergent[name], reason: name);
    }
    for (final item
        in ((differences['indices'] as Map)['faltando'] as List).cast<Map>()) {
      final name = (item['objeto'] as String).split('.').last;
      if (!name.startsWith('idx_ml_prompt_feedback_')) continue;
      expect(trade[name], item['base']['definicao'], reason: name);
    }
  }, skip: skipReason);

  test('as três chaves da 076 são RESTRICT, cada uma com só o gatilho de conta '
      'ativa do OID dela', () async {
    for (final MapEntry(key: table, value: name) in alignedKeys.entries) {
      final key = await pool.execute(
        Sql.named('''
            SELECT oid::text, confdeltype::text FROM pg_constraint
            WHERE conrelid = ('public.' || @table)::regclass AND conname = @name
          '''),
        parameters: {'table': table, 'name': name},
      );
      expect(key.single[1], 'r', reason: table);
      final triggers = await pool.execute(
        Sql.named('''
            SELECT tgname FROM pg_trigger
            WHERE tgrelid = ('public.' || @table)::regclass
              AND NOT tgisinternal
              AND left(tgname, 21) = 'manaloom_active_user_'
          '''),
        parameters: {'table': table},
      );
      final expected = await pool.execute(
        Sql.named('''
            SELECT 'manaloom_active_user_' || oid FROM pg_constraint
            WHERE conrelid = ('public.' || @table)::regclass
              AND contype = 'f'
              AND confrelid = 'public.users'::regclass
            ORDER BY 1
          '''),
        parameters: {'table': table},
      );
      expect([for (final row in triggers) row[0]]..sort(), [
        for (final row in expected) row[0],
      ], reason: table);
    }
  }, skip: skipReason);

  test('a 075 e a 076 aplicadas de novo não mudam nada', () async {
    await rolledBack((connection) async {
      final before = await snapshot(connection);
      await apply(connection, '075');
      await apply(connection, '076');
      expect(await snapshot(connection), before);
    });
  }, skip: skipReason);

  test('na forma da produção (chave sem ação), a 076 põe RESTRICT e tira o '
      'gatilho do OID antigo', () async {
    await rolledBack((connection) async {
      await connection.execute(
        'ALTER TABLE direct_messages '
        'DROP CONSTRAINT direct_messages_sender_id_fkey',
      );
      await connection.execute(
        'ALTER TABLE direct_messages ADD CONSTRAINT '
        'direct_messages_sender_id_fkey FOREIGN KEY (sender_id) '
        'REFERENCES users(id)',
      );
      Future<(String, String, List<String>)> state() async {
        final key = await connection.execute('''
            SELECT oid::text, confdeltype::text FROM pg_constraint
            WHERE conrelid = 'public.direct_messages'::regclass
              AND conname = 'direct_messages_sender_id_fkey'
          ''');
        final triggers = await connection.execute('''
            SELECT tgname FROM pg_trigger
            WHERE tgrelid = 'public.direct_messages'::regclass
              AND NOT tgisinternal
              AND left(tgname, 21) = 'manaloom_active_user_'
          ''');
        return (
          key.single[0] as String,
          key.single[1] as String,
          [for (final row in triggers) row[0] as String],
        );
      }

      final (oldOid, action, stale) = await state();
      expect(action, 'a');
      expect(stale, isNot(contains('manaloom_active_user_$oldOid')));
      expect(stale, isNotEmpty);

      await apply(connection, '076');
      final (newOid, restrict, triggers) = await state();
      expect(restrict, 'r');
      expect(triggers, ['manaloom_active_user_$newOid']);
    });
  }, skip: skipReason);
}
