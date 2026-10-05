import 'dart:convert';
import 'dart:io';

import 'package:server/sql_statement_splitter.dart';
import 'package:test/test.dart';

import '../bin/migrate.dart' as migrate;
import 'support/migration_sql.dart';
import 'support/schema_adoption.dart';

/// BT-DB-005 (D-48): a 075 cria as tabelas que o código usa e só a produção
/// tinha, com a forma de lá, e adota nos dois bancos as formas de coluna,
/// índice e CHECK da produção; a 076 alinha três chaves para users com
/// RESTRICT, como a 059 fez com trade_items (D-66). O esperado vem da
/// auditoria BT-DB-001 e da lista fechada da deriva, não de uma cópia no teste.
void main() {
  final audit = loadSchemaAudit();
  final differences = audit['diferencas'] as Map;
  final allowlist =
      jsonDecode(File('config/schema_drift_allowlist.json').readAsStringSync())
          as Map<String, dynamic>;
  final reconciled075 =
      ((allowlist['reconciliado_pelas_migrations'] as Map)['075'] as List)
          .cast<String>();
  final reconciled076 =
      ((allowlist['reconciliado_pelas_migrations'] as Map)['076'] as List)
          .cast<String>();
  final extraTables = {
    for (final item in (differences['tabelas'] as Map)['sobrando'] as List)
      item as String,
  };
  final adoptedTables = [
    for (final name in reconciled075)
      if (extraTables.contains(name)) name.split('.').last,
  ];
  final up075 = migrationUp('075');
  final statements075 = splitPostgresStatements(up075);
  final migration076 = migrate.migrations.singleWhere(
    (migration) => migration.version == '076',
  );

  Map<String, Object?> auditedColumn(String name) {
    final columns = differences['colunas'] as Map;
    for (final kind in const ['sobrando', 'divergente', 'faltando']) {
      for (final item in (columns[kind] as List).cast<Map>()) {
        if (item['objeto'] == name) return {'tipo': kind, ...item};
      }
    }
    throw StateError('$name não está na auditoria');
  }

  group('075 (D-48)', () {
    test('cria as seis tabelas que o código usa, com os índices e as chaves '
        'da produção', () {
      expect(adoptedTables, [
        'optimization_analysis_logs',
        'synergy_packages',
        'archetype_patterns',
        'ml_learning_state',
        'theme_contextual_rules',
        'analysis_sources',
      ]);
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
      expect(tableIndexes(statements075, adoptedTables), production);
      // Só o CHECK que a produção tem (theme_contextual_rules.priority, pela
      // leitura autorizada da definição); o do script antigo em
      // synergy_packages.package_type ela não tem.
      final checks = [
        for (final statement in statements075.map(normalized))
          if (statement.startsWith('CREATE TABLE IF NOT EXISTS '))
            for (final match in RegExp(
              r'(\w+) \w+ CHECK',
            ).allMatches(statement))
              '${statement.split(' ')[5]}.${match.group(1)}',
      ];
      expect(checks, ['theme_contextual_rules.priority']);
    });

    test('as tabelas saem do grupo "só da produção" do inventário e da lista '
        'fechada', () {
      final inventory =
          jsonDecode(
                File(
                  '../docs/privacy/data_retention_inventory.json',
                ).readAsStringSync(),
              )
              as Map<String, dynamic>;
      final items = [
        for (final entry in (allowlist['itens'] as List).cast<Map>())
          entry['objeto'],
      ];
      for (final table in adoptedTables) {
        expect(
          (inventory['production_only_tables'] as Map).containsKey(table),
          isFalse,
          reason: table,
        );
        expect((inventory['tables'] as Map)[table], isNotNull, reason: table);
        expect(items, isNot(contains('public.$table')), reason: table);
      }
    });

    test('adota nos dois bancos a forma de coluna da produção', () {
      // Coluna -> (o que a auditoria viu na produção, o comando da 075).
      final expected = <String, (Map<String, Object?>, String)>{
        'public.card_meta_insights.id': (
          {'tipo': 'uuid', 'not_null': true, 'default': 'gen_random_uuid()'},
          'ALTER TABLE card_meta_insights ADD COLUMN IF NOT EXISTS id UUID '
              'NOT NULL DEFAULT gen_random_uuid()',
        ),
        'public.cards.edhrec_rank': (
          {'tipo': 'integer', 'not_null': false, 'default': null},
          'ALTER TABLE cards ADD COLUMN IF NOT EXISTS edhrec_rank INTEGER',
        ),
      };
      for (final MapEntry(key: name, value: (shape, command))
          in expected.entries) {
        final item = auditedColumn(name);
        expect(item['tipo'], 'sobrando', reason: name);
        expect(item['alvo'], shape, reason: name);
        expect(normalizedStatements(statements075), contains(command));
        expect(reconciled075, contains(name));
      }
      // Tipo: a produção é mais estrita, e o banco novo adota (só onde o tipo
      // ainda é o antigo, para a produção não mexer).
      for (final (name, production, command) in const [
        (
          'public.users.location_city',
          'character varying(100)',
          'ALTER TABLE users ALTER COLUMN location_city TYPE VARCHAR(100)',
        ),
        (
          'public.users.location_state',
          'character varying(2)',
          'ALTER TABLE users ALTER COLUMN location_state TYPE VARCHAR(2)',
        ),
        (
          'public.user_binder_items.list_type',
          'character varying(4)',
          'ALTER TABLE user_binder_items ALTER COLUMN list_type TYPE VARCHAR(4)',
        ),
      ]) {
        expect((auditedColumn(name)['tipo'] as List).last, production);
        expect(normalized(up075), contains(command), reason: name);
        expect(
          normalized(up075),
          contains(
            "WHERE attrelid = 'public.${name.split('.')[1]}'::regclass AND "
            "attname = '${name.split('.').last}' ) <> '$production' THEN",
          ),
          reason: name,
        );
      }
      // NOT NULL e default de commander_learned_decks: a produção é mais estrita.
      for (final column in const ['created_at', 'updated_at']) {
        final item = auditedColumn('public.commander_learned_decks.$column');
        expect(item['not_null'], [false, true]);
        expect(item['default'], ['CURRENT_TIMESTAMP', 'now()']);
        expect(
          normalizedStatements(statements075),
          containsAll([
            'ALTER TABLE commander_learned_decks ALTER COLUMN $column SET '
                'DEFAULT now()',
            'ALTER TABLE commander_learned_decks ALTER COLUMN $column SET NOT '
                'NULL',
          ]),
        );
      }
    });

    test('só metadado vai para a produção: dois defaults da migration e os '
        'índices de ml_prompt_feedback', () {
      expect(auditedColumn('public.battle_simulations.simulation_type'), {
        'tipo': 'divergente',
        'objeto': 'public.battle_simulations.simulation_type',
        'default': ["'legacy'::text", null],
      });
      expect(
        normalizedStatements(statements075),
        containsAll([
          "ALTER TABLE battle_simulations ALTER COLUMN simulation_type SET "
              "DEFAULT 'legacy'",
          "ALTER TABLE ml_prompt_feedback ALTER COLUMN prompt_version SET "
              "DEFAULT 'v1.1-hybrid'",
        ]),
      );
      final missing = [
        for (final item
            in ((differences['indices'] as Map)['faltando'] as List)
                .cast<Map>())
          if ((item['objeto'] as String).contains('ml_prompt_feedback'))
            (item['objeto'] as String).split('.').last,
      ];
      expect(missing, hasLength(3));
      for (final index in missing) {
        expect(up075, contains('CREATE INDEX IF NOT EXISTS $index'));
      }
      // Nenhum NOT NULL afrouxado: a D-67 aperta a produção depois de contar os
      // nulos, e o banco novo fica como está.
      expect(up075, isNot(contains('DROP NOT NULL')));
    });

    test('as views do fichário voltam com o texto da 045, só onde list_type '
        'ainda é text', () {
      final views045 = [
        for (final statement in splitPostgresStatements(migrationUp('045')))
          normalized(
            statement.replaceFirst('CREATE OR REPLACE VIEW', 'CREATE VIEW'),
          ),
      ];
      expect(views045, hasLength(2));
      final shapes = normalized(
        statements075.singleWhere(
          (statement) =>
              normalized(statement).startsWith(r'DO $adopt_production_shapes$'),
        ),
      );
      for (final view in views045) {
        expect(shapes, contains(view));
      }
      expect(
        shapes,
        contains(
          'DROP VIEW IF EXISTS binder_item_availability; DROP VIEW IF EXISTS '
          'collection_availability_snapshot; ALTER TABLE user_binder_items '
          'ALTER COLUMN list_type TYPE VARCHAR(4);',
        ),
      );
    });

    test('CHECK e índices com o nome e a forma da produção', () {
      final shapes = normalized(up075);
      expect(
        shapes,
        contains(
          'RENAME CONSTRAINT account_deletion_receipts_deletion_mode_check TO '
          'chk_account_deletion_mode;',
        ),
      );
      // chk_list_type com o texto da produção (leitura autorizada da definição):
      // refeito sobre o varchar(4) só onde o texto ainda é outro.
      expect(
        shapes,
        contains(
          "), '') <> 'CHECK (list_type::text = ANY (ARRAY[''have''::character "
          "varying::text, ''want''::character varying::text]))' THEN",
        ),
      );
      expect(
        shapes,
        contains(
          'ADD CONSTRAINT chk_list_type CHECK (list_type::text = ANY '
          "(ARRAY['have'::character varying::text, 'want'::character "
          'varying::text]));',
        ),
      );
      expect(
        shapes,
        contains(
          'ALTER TABLE post_game_notes DROP CONSTRAINT IF EXISTS '
          'post_game_notes_revision_check',
        ),
      );
      final divergent = {
        for (final item
            in ((differences['indices'] as Map)['divergente'] as List)
                .cast<Map>())
          (item['objeto'] as String).split('.').last:
              (item['definicao'] as List).last as String,
      };
      for (final index in const [
        'idx_trade_history_offer',
        'idx_trade_messages_offer',
      ]) {
        final production = divergent[index]!;
        final table = RegExp(r'ON public\.(\w+) ').firstMatch(production)!;
        expect(
          shapes,
          contains(
            "'${production.replaceFirst('INDEX ON', 'INDEX $index ON')}'",
          ),
        );
        expect(
          shapes,
          contains(
            'CREATE INDEX $index ON ${table.group(1)} '
            '${production.split(' USING btree ').last.replaceFirst('(', '(')}',
          ),
        );
      }
      expect(
        divergent['card_meta_insights_pkey'],
        'CREATE UNIQUE INDEX ON public.card_meta_insights USING btree (id)',
      );
      expect(
        shapes,
        contains('ADD CONSTRAINT card_meta_insights_pkey PRIMARY KEY (id)'),
      );
    });

    test('rollback só por plano manual', () {
      for (final version in const ['075', '076']) {
        expect(
          migrate.migrationRollbackPolicy(version),
          migrate.MigrationRollbackPolicy.manualOnly,
        );
      }
      expect(
        migrate.migrations.singleWhere((m) => m.version == '075').down,
        'SELECT 1;',
      );
    });
  });

  group('076', () {
    final divergentKeys = {
      for (final item
          in ((differences['chaves_estrangeiras'] as Map)['divergente'] as List)
              .cast<Map>())
        item['objeto'] as String: item,
    };

    test('as três chaves ficam RESTRICT, só onde ainda estão sem ação', () {
      expect(reconciled076, hasLength(3));
      final statements = splitPostgresStatements(migration076.up);
      final align = normalized(statements.first);
      for (final key in reconciled076) {
        final item = divergentKeys[key]!;
        expect(item['definicao'], [
          '${(item['definicao'] as List).last} ON DELETE RESTRICT',
          (item['definicao'] as List).last,
        ]);
        final table = key.split(': ').first.split('.').last;
        final column = RegExp(r'\((\w+)\)').firstMatch(key)!.group(1);
        expect(
          align,
          contains("('$table', '$column', '${(item['nome'] as List).last}')"),
        );
      }
      expect(align, contains("AND confdeltype <> 'r'"));
      expect(
        align,
        contains("'FOREIGN KEY (%I) REFERENCES users(id) ON DELETE RESTRICT'"),
      );
    });

    test('o gatilho do OID antigo sai e o laço canônico fecha o up', () {
      final statements = splitPostgresStatements(migration076.up);
      expect(statements, hasLength(3));
      expect(
        statements[1].trimLeft(),
        contains(r'DO $drop_stale_active_user_triggers$'),
      );
      final loop074 = splitPostgresStatements(migrationUp('074')).single;
      expect(normalized(statements.last), normalized(loop074));
    });

    test('o down volta à produção sem ação, com o mesmo cuidado', () {
      final statements = splitPostgresStatements(migration076.down!);
      expect(statements, hasLength(3));
      expect(normalized(statements.first), contains("AND confdeltype <> 'a'"));
      expect(
        normalized(statements.first),
        contains("'FOREIGN KEY (%I) REFERENCES users(id)',"),
      );
      final loop074 = splitPostgresStatements(migrationUp('074')).single;
      expect(normalized(statements.last), normalized(loop074));
    });
  });

  group('consulta de violações de CHECK (só leitura)', () {
    final sql =
        File('sql/readonly/bt_db_005_check_violations.sql').readAsStringSync();
    final statements = d67Statements(sql);

    test('é só leitura: transação READ ONLY que termina em ROLLBACK', () {
      expect(statements.first, 'BEGIN TRANSACTION READ ONLY');
      expect(statements.last, 'ROLLBACK');
      for (final statement in statements.skip(1).take(statements.length - 2)) {
        expect(statement, startsWith('SELECT '));
        expect(
          statement,
          isNot(
            matches(
              RegExp(r'\b(INSERT|UPDATE|DELETE|ALTER|CREATE|DROP|TRUNCATE)\b'),
            ),
          ),
        );
      }
    });

    test('conta as três travas que só o banco novo tem, com a regra dele', () {
      final setup = normalized(File('database_setup.sql').readAsStringSync());
      final pending = [
        for (final entry in (allowlist['itens'] as List).cast<Map>())
          if (entry['categoria'] == 'restricoes' && entry['tipo'] == 'faltando')
            (entry['objeto'] as String).replaceFirst('public.', ''),
      ];
      expect(pending, hasLength(3));
      for (final name in pending) {
        expect(sql, contains("'$name' AS restricao"));
      }
      for (final rule in const [
        "type IN ( 'new_follower', 'trade_offer_received', 'trade_accepted', "
            "'trade_declined', 'trade_shipped', 'trade_delivered', "
            "'trade_completed', 'trade_message', 'direct_message' )",
        "currency IN ('BRL', 'USD')",
        'effectiveness_score IS NULL OR (effectiveness_score >= 1 AND '
            'effectiveness_score <= 10)',
      ]) {
        expect(setup, contains(rule));
        expect(normalized(sql), contains(rule));
      }
    });
  });
}

String normalized(String sql) => sql
    .split('\n')
    .where((line) => !line.trimLeft().startsWith('--'))
    .join(' ')
    .split(RegExp(r'\s+'))
    .where((part) => part.isNotEmpty)
    .join(' ');

List<String> normalizedStatements(List<String> statements) => [
  for (final statement in statements) normalized(statement),
];

/// Índices que a 075 cria nas tabelas [tables], no formato da auditoria:
/// chave primária, UNIQUE declarado na tabela e `CREATE INDEX`.
Map<String, String> tableIndexes(List<String> statements, List<String> tables) {
  final result = <String, String>{};
  for (final statement in statements.map(normalized)) {
    final create = RegExp(
      r'^CREATE TABLE IF NOT EXISTS (\w+) \((.*)\)$',
    ).firstMatch(statement);
    if (create != null && tables.contains(create.group(1))) {
      final table = create.group(1)!;
      final body = create.group(2)!;
      final primary = RegExp(r'(\w+) UUID PRIMARY KEY').firstMatch(body);
      result['${table}_pkey'] =
          'CREATE UNIQUE INDEX ON public.$table USING btree '
          '(${primary!.group(1)})';
      for (final unique in RegExp(
        r'CONSTRAINT (\w+) UNIQUE \(([^)]*)\)',
      ).allMatches(body)) {
        result[unique.group(1)!] =
            'CREATE UNIQUE INDEX ON public.$table USING btree '
            '(${unique.group(2)})';
      }
    }
    final index = RegExp(
      r'^CREATE INDEX IF NOT EXISTS (\w+) ON (\w+) USING btree \(([^)]*)\)$',
    ).firstMatch(statement);
    if (index != null && tables.contains(index.group(2))) {
      result[index.group(1)!] =
          'CREATE INDEX ON public.${index.group(2)} USING btree '
          '(${index.group(3)})';
    }
  }
  return result;
}
