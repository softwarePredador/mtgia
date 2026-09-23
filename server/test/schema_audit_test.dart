import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

import '../lib/schema_audit/schema_audit.dart';

/// BT-DB-001: o auditor classifica as diferenças entre um banco-alvo e a base
/// criada pelas migrations em faltando, sobrando e divergente, sem apagar
/// nada. Aqui a comparação roda sobre inventários sintéticos; a leitura do
/// catálogo está em `bin/schema_audit.dart`.
void main() {
  SchemaInventory inventory({
    String label = 'base',
    Set<String> schemas = const {'public'},
    Set<String> tables = const {'public.users', 'public.decks'},
    Map<String, String> views = const {
      'public.deck_summary': 'VIEW: SELECT id FROM decks',
    },
    Map<String, ColumnShape> columns = const {
      'public.users.id': ColumnShape(
        type: 'uuid',
        notNull: true,
        defaultExpression: 'gen_random_uuid()',
      ),
      'public.users.email': ColumnShape(
        type: 'text',
        notNull: true,
        defaultExpression: null,
      ),
      'public.decks.id': ColumnShape(
        type: 'uuid',
        notNull: true,
        defaultExpression: 'gen_random_uuid()',
      ),
      'public.decks.user_id': ColumnShape(
        type: 'uuid',
        notNull: false,
        defaultExpression: null,
      ),
    },
    Map<String, ForeignKeyShape>? foreignKeys,
    Map<String, IndexShape> indexes = const {
      'public.idx_decks_user_id': IndexShape(
        table: 'public.decks',
        definition: 'CREATE INDEX ON public.decks USING btree (user_id)',
      ),
    },
    Map<String, String>? migrations = const {'001': 'a', '002': 'b'},
  }) {
    const fk = 'FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE';
    return SchemaInventory(
      label: label,
      database: label,
      serverVersion: '17.9',
      schemas: schemas,
      tables: tables,
      views: views,
      columns: columns,
      foreignKeys:
          foreignKeys ??
          {
            foreignKeySignature('public.decks', fk): const ForeignKeyShape(
              name: 'decks_user_id_fkey',
              definition: fk,
            ),
          },
      indexes: indexes,
      migrations: migrations,
    );
  }

  final generatedAt = DateTime.utc(2026, 9, 23, 12);

  test('bancos iguais não têm diferença', () {
    final report = compareSchemaInventories(
      inventory(),
      inventory(label: 'alvo'),
      generatedAt: generatedAt,
    );

    expect(report.hasDifferences, isFalse);
  });

  test('tabela, coluna e ledger: faltando, sobrando e divergente', () {
    final base = inventory();
    final alvo = inventory(
      label: 'alvo',
      tables: const {'public.users', 'public.decks', 'public.posts'},
      columns: const {
        'public.users.id': ColumnShape(
          type: 'uuid',
          notNull: true,
          defaultExpression: 'gen_random_uuid()',
        ),
        'public.users.email': ColumnShape(
          type: 'character varying(255)',
          notNull: false,
          defaultExpression: "''::character varying",
        ),
        'public.decks.id': ColumnShape(
          type: 'uuid',
          notNull: true,
          defaultExpression: 'gen_random_uuid()',
        ),
        'public.decks.edhrec_rank': ColumnShape(
          type: 'integer',
          notNull: false,
          defaultExpression: null,
        ),
        'public.posts.id': ColumnShape(
          type: 'integer',
          notNull: true,
          defaultExpression: null,
        ),
      },
      migrations: const {'001': 'a', '002': 'outro_nome', '003': 'c'},
    );
    final report = compareSchemaInventories(
      base,
      alvo,
      generatedAt: generatedAt,
    );

    expect(report.tables.sobrando, ['public.posts']);
    expect(report.tables.faltando, isEmpty);
    // Coluna de tabela que sobra inteira não é contada de novo.
    expect(report.columns.sobrando.map((item) => (item! as Map)['objeto']), [
      'public.decks.edhrec_rank',
    ]);
    expect(report.columns.faltando.map((item) => (item! as Map)['objeto']), [
      'public.decks.user_id',
    ]);
    final email = report.columns.divergente.single! as Map;
    expect(email['objeto'], 'public.users.email');
    expect(email['tipo'], ['text', 'character varying(255)']);
    expect(email['not_null'], [true, false]);
    expect(email['default'], [null, "''::character varying"]);
    expect(report.migrations.sobrando.map((item) => (item! as Map)['objeto']), [
      '003',
    ]);
    expect((report.migrations.divergente.single! as Map)['nome'], [
      'b',
      'outro_nome',
    ]);
  });

  test('ledger atrás da base aparece como migration faltando', () {
    final report = compareSchemaInventories(
      inventory(migrations: const {'057': 'x', '058': 'y'}),
      inventory(label: 'alvo', migrations: const {'057': 'x'}),
      generatedAt: generatedAt,
    );

    expect(report.migrations.faltando.map((item) => (item! as Map)['objeto']), [
      '058',
    ]);
    expect(report.toJson()['alvo'], containsPair('ultima_migration', '057'));
  });

  test('chave estrangeira: faltando, sobrando e ação divergente', () {
    const cascade =
        'FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE';
    const setNull =
        'FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL';
    const extra = 'FOREIGN KEY (deck_id) REFERENCES decks(id)';
    final report = compareSchemaInventories(
      inventory(),
      inventory(
        label: 'alvo',
        foreignKeys: {
          foreignKeySignature('public.decks', setNull): const ForeignKeyShape(
            name: 'fk_decks_user',
            definition: setNull,
          ),
          foreignKeySignature('public.users', extra): const ForeignKeyShape(
            name: 'users_deck_id_fkey',
            definition: extra,
          ),
        },
      ),
      generatedAt: generatedAt,
    );

    final divergent = report.foreignKeys.divergente.single! as Map;
    expect(divergent['definicao'], [cascade, setNull]);
    expect(report.foreignKeys.faltando, isEmpty);
    expect(report.foreignKeys.sobrando, hasLength(1));
  });

  test('índice com outro nome e mesma definição é divergente só no nome', () {
    final report = compareSchemaInventories(
      inventory(),
      inventory(
        label: 'alvo',
        indexes: const {
          'public.decks_user_idx': IndexShape(
            table: 'public.decks',
            definition: 'CREATE INDEX ON public.decks USING btree (user_id)',
          ),
          'public.idx_extra': IndexShape(
            table: 'public.users',
            definition: 'CREATE INDEX ON public.users USING btree (email)',
          ),
        },
      ),
      generatedAt: generatedAt,
    );

    final renamed = report.indexes.divergente.single! as Map;
    expect(renamed['nome'], [
      'public.idx_decks_user_id',
      'public.decks_user_idx',
    ]);
    expect(report.indexes.faltando, isEmpty);
    expect(report.indexes.sobrando.map((item) => (item! as Map)['objeto']), [
      'public.idx_extra',
    ]);
  });

  test('schema só do alvo é resumido, sem espalhar seus objetos', () {
    const backupFk = 'FOREIGN KEY (deck_id) REFERENCES decks(id)';
    final base = inventory();
    final report = compareSchemaInventories(
      base,
      inventory(
        label: 'alvo',
        schemas: const {'public', 'manaloom_deploy_audit'},
        tables: const {
          'public.users',
          'public.decks',
          'manaloom_deploy_audit.pg007_backup',
        },
        views: const {
          'public.deck_summary': 'VIEW: SELECT id FROM decks',
          'manaloom_deploy_audit.pg007_view': 'VIEW: SELECT 1',
        },
        foreignKeys: {
          ...base.foreignKeys,
          foreignKeySignature(
            'manaloom_deploy_audit.pg007_backup',
            backupFk,
          ): const ForeignKeyShape(
            name: 'pg007_backup_deck_id_fkey',
            definition: backupFk,
          ),
        },
        indexes: const {
          'public.idx_decks_user_id': IndexShape(
            table: 'public.decks',
            definition: 'CREATE INDEX ON public.decks USING btree (user_id)',
          ),
          'manaloom_deploy_audit.pg007_backup_pkey': IndexShape(
            table: 'manaloom_deploy_audit.pg007_backup',
            definition:
                'CREATE UNIQUE INDEX ON manaloom_deploy_audit.pg007_backup '
                'USING btree (id)',
          ),
        },
      ),
      generatedAt: generatedAt,
      targetSchemaObjectCounts: const {
        'manaloom_deploy_audit': {
          'tabelas': 1,
          'views': 1,
          'chaves_estrangeiras': 1,
          'indices': 1,
        },
      },
    );

    expect(report.schemas.sobrando, ['manaloom_deploy_audit']);
    expect(report.tables.sobrando, isEmpty);
    expect(report.views.sobrando, isEmpty);
    expect(report.foreignKeys.sobrando, isEmpty);
    expect(report.indexes.sobrando, isEmpty);
    expect(report.extraSchemaSummaries['manaloom_deploy_audit'], {
      'tabelas': 1,
      'views': 1,
      'chaves_estrangeiras': 1,
      'indices': 1,
    });
  });

  test('alvo sem ledger aparece como ledger faltando', () {
    final report = compareSchemaInventories(
      inventory(),
      inventory(label: 'alvo', migrations: null),
      generatedAt: generatedAt,
    );

    expect(report.migrations.faltando.map((item) => (item! as Map)['objeto']), [
      'public.schema_migrations',
    ]);
  });

  test('URL do banco: sem senha e, fora do loopback, só com opt-in', () {
    final local = parseAuditTarget(
      'postgres://postgres@127.0.0.1:55439/base',
      passwordEnvironment: 'BASELINE_PGPASSWORD',
      allowRemote: false,
    );
    expect(local.loopback, isTrue);
    expect(local.host, '127.0.0.1');
    expect(local.port, 55439);
    expect(local.database, 'base');
    expect(local.username, 'postgres');

    expect(
      () => parseAuditTarget(
        'postgres://postgres:segredo@127.0.0.1/base',
        passwordEnvironment: 'BASELINE_PGPASSWORD',
        allowRemote: false,
      ),
      throwsA(
        isA<AuditUsageException>().having(
          (error) => error.message,
          'message',
          allOf(contains('BASELINE_PGPASSWORD'), isNot(contains('segredo'))),
        ),
      ),
    );
    expect(
      () => parseAuditTarget(
        'postgres://leitor@db.exemplo.com/producao',
        passwordEnvironment: 'TARGET_PGPASSWORD',
        allowRemote: false,
      ),
      throwsA(isA<AuditUsageException>()),
    );
    final remote = parseAuditTarget(
      'postgres://leitor@db.exemplo.com/producao',
      passwordEnvironment: 'TARGET_PGPASSWORD',
      allowRemote: true,
    );
    expect(remote.loopback, isFalse);
    expect(remote.port, 5432);
    for (final invalid in const [
      'mysql://leitor@127.0.0.1/base',
      'postgres://127.0.0.1/base',
      'postgres://leitor@127.0.0.1/',
    ]) {
      expect(
        () => parseAuditTarget(
          invalid,
          passwordEnvironment: 'TARGET_PGPASSWORD',
          allowRemote: false,
        ),
        throwsA(isA<AuditUsageException>()),
        reason: invalid,
      );
    }
  });

  test('view com definição diferente é divergente', () {
    final report = compareSchemaInventories(
      inventory(),
      inventory(
        label: 'alvo',
        views: const {
          'public.deck_summary': 'VIEW: SELECT id, user_id FROM decks',
        },
      ),
      generatedAt: generatedAt,
    );

    expect(
      (report.views.divergente.single! as Map)['objeto'],
      'public.deck_summary',
    );
  });

  test('relatório em JSON e Markdown declara que não apaga nada', () {
    final report = compareSchemaInventories(
      inventory(),
      inventory(label: 'alvo', migrations: const {'001': 'a'}),
      generatedAt: generatedAt,
    );
    final json = jsonDecode(report.toJsonText()) as Map<String, dynamic>;
    final markdown = report.toMarkdown();

    expect(json['politica'], containsPair('apaga_extras', false));
    expect(json['politica'], containsPair('somente_leitura', true));
    expect((json['resumo'] as Map)['ledger_schema_migrations'], {
      'faltando': 1,
      'sobrando': 0,
      'divergente': 0,
    });
    expect(markdown, contains('## Resumo das diferenças'));
    expect(markdown, contains('### faltando (1)'));
    expect(markdown, contains('`002`'));
  });

  test('normaliza o nome do índice e a assinatura da chave estrangeira', () {
    expect(
      normalizeIndexDefinition(
        'CREATE UNIQUE INDEX users_pkey ON public.users USING btree (id)',
      ),
      'CREATE UNIQUE INDEX ON public.users USING btree (id)',
    );
    expect(
      foreignKeySignature(
        'public.decks',
        'FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE',
      ),
      'public.decks: FOREIGN KEY (user_id) REFERENCES users(id)',
    );
  });

  test('o auditor só lê: a CLI abre transação READ ONLY', () {
    final cli = File('bin/schema_audit.dart').readAsStringSync();

    expect(cli, contains('AccessMode.readOnly'));
    expect(cli, isNot(contains('AccessMode.readWrite')));
    // Host remoto só com TLS; o loopback do PostgreSQL descartável não tem.
    expect(
      cli,
      contains('target.loopback ? SslMode.disable : SslMode.require'),
    );
    for (final statement in const [
      'INSERT ',
      'UPDATE ',
      'DELETE ',
      'DROP ',
      'ALTER ',
      'TRUNCATE ',
      'CREATE ',
    ]) {
      expect(cli, isNot(contains("'$statement")), reason: statement);
      expect(cli, isNot(contains("'''\n    $statement")), reason: statement);
    }
  });
}
