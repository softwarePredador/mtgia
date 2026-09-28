@Tags(['live', 'live_db_write'])
library;

import 'dart:io';

import 'package:postgres/postgres.dart';
import 'package:server/ai/candidate_quality_data_support.dart';
import 'package:server/ai/commander_reference_card_stats_support.dart';
import 'package:server/ai/commander_reference_deck_corpus_support.dart';
import 'package:server/ai/commander_reference_profile_support.dart';
import 'package:server/import_card_lookup_service.dart';
import 'package:server/schema_audit/schema_audit.dart';
import 'package:server/schema_requirements.dart';
import 'package:server/sql_statement_splitter.dart';
import 'package:test/test.dart';

import '../bin/sync_cards.dart' as sync_cards;
import '../bin/sync_rules.dart' as sync_rules;
import 'support/migration_sql.dart';
import 'support/schema_adoption.dart';

/// BT-DB-004 num PostgreSQL descartável migrado do zero
/// (`database_setup.sql` + `bin/migrate.dart`), comparado com a auditoria de
/// schema BT-DB-001. Tudo o que muda o banco roda numa transação desfeita.
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
  Future<T> rolledBack<T>(
    Future<T> Function(Connection connection) body, {
    bool readOnly = false,
  }) => pool.withConnection((connection) async {
    await connection.execute(
      readOnly ? 'BEGIN TRANSACTION READ ONLY' : 'BEGIN',
    );
    try {
      return await body(connection);
    } finally {
      await connection.execute('ROLLBACK');
    }
  });

  test(
    'os índices da 064 e da 065 saem com a definição da produção',
    () async {
      final production = productionOnlyIndexes(audit);
      final adopted = {...adoptedIndexes('064'), ...adoptedIndexes('065')};
      expect(adopted, hasLength(26));
      final result = await pool.execute(
        Sql.named('''
          SELECT index_class.relname, pg_get_indexdef(index_class.oid)
          FROM pg_class index_class
          JOIN pg_namespace namespace ON namespace.oid = index_class.relnamespace
          WHERE namespace.nspname = 'public'
            AND index_class.relkind IN ('i', 'I')
            AND index_class.relname = ANY(CAST(@names AS text[]))
        '''),
        parameters: {'names': adopted.keys.toList()},
      );
      expect(
        {
          for (final row in result)
            row[0]! as String: normalizeIndexDefinition(row[1]! as String),
        },
        {for (final name in adopted.keys) name: production[name]},
      );
    },
    skip: skipReason,
  );

  group('índice UNIQUE do fichário pendente de decisão', () {
    // O INSERT da rota POST /binder, lido do código da rota.
    final routeSource = File('routes/binder/index.dart').readAsStringSync();
    final insertStart = routeSource.indexOf('INSERT INTO user_binder_items');
    final routeInsert = routeSource.substring(
      insertStart,
      routeSource.indexOf("'''", insertStart),
    );

    Future<({String user, String card})> seed(Connection connection) async {
      final run = DateTime.now().microsecondsSinceEpoch;
      final user = await connection.execute(
        Sql.named('''
          INSERT INTO users (username, email, password_hash)
          VALUES (@username, @email, 'x')
          RETURNING id::text
        '''),
        parameters: {
          'username': 'schema_binder_$run',
          'email': 'schema_binder_$run@example.invalid',
        },
      );
      final card = await connection.execute(
        Sql.named('''
          INSERT INTO cards (scryfall_id, oracle_id, name, set_code, collector_number)
          VALUES (gen_random_uuid(), gen_random_uuid(), @name, 'tst', '1')
          RETURNING id::text
        '''),
        parameters: {'name': 'Carta de teste de schema $run'},
      );
      return (
        user: user.single.single! as String,
        card: card.single.single! as String,
      );
    }

    Future<int> addCopy(
      Connection connection,
      ({String user, String card}) owner,
      String language,
    ) async {
      final result = await connection.execute(
        Sql.named(routeInsert),
        parameters: {
          'userId': owner.user,
          'cardId': owner.card,
          'quantity': 1,
          'condition': 'NM',
          'isFoil': false,
          'forTrade': false,
          'forSale': false,
          'price': null,
          'notes': null,
          'language': language,
          'listType': 'have',
        },
      );
      return result.length;
    }

    test('a rota trata a identidade física da 049 pelo ON CONFLICT', () {
      expect(insertStart, greaterThan(0));
      expect(
        routeInsert.replaceAll(RegExp(r'\s+'), ' '),
        contains(
          'ON CONFLICT ( user_id, card_id, condition, is_foil, language, '
          'list_type ) DO NOTHING',
        ),
      );
    });

    test('o banco novo guarda a mesma carta em outro idioma (049)', () async {
      await rolledBack((connection) async {
        final owner = await seed(connection);
        expect(await addCopy(connection, owner, 'en'), 1);
        expect(await addCopy(connection, owner, 'pt-br'), 1);
        // A mesma cópia física cai no ON CONFLICT da rota.
        expect(await addCopy(connection, owner, 'pt-br'), 0);
      });
    }, skip: skipReason);

    test(
      'com o índice da produção, outro idioma falha fora do ON CONFLICT',
      () async {
        // A produção tem este índice além do da 049. O 23505 não é o alvo do
        // ON CONFLICT, então a rota devolve 500 em vez de guardar a cópia.
        final definition =
            productionOnlyIndexes(audit)[pendingBinderUniqueIndex]!;
        await rolledBack((connection) async {
          await connection.execute(
            definition.replaceFirst(
              'CREATE UNIQUE INDEX ON ',
              'CREATE UNIQUE INDEX $pendingBinderUniqueIndex ON ',
            ),
          );
          final owner = await seed(connection);
          expect(await addCopy(connection, owner, 'en'), 1);
          await expectLater(
            addCopy(connection, owner, 'pt-br'),
            throwsA(
              isA<ServerException>()
                  .having((error) => error.code, 'code', '23505')
                  .having(
                    (error) => error.constraintName,
                    'constraintName',
                    pendingBinderUniqueIndex,
                  ),
            ),
          );
        });
      },
      skip: skipReason,
    );
  });

  test(
    'a 063 transforma a view da produção na do banco novo (D-65)',
    () async {
      const view = 'commander_learning_snapshot';
      final base = auditedView(audit, view, 'base');
      final production = auditedView(audit, view, 'alvo');

      Future<String> current(Session session) async {
        final result = await session.execute(
          "SELECT pg_get_viewdef('public.$view'::regclass, true)",
        );
        return 'VIEW: ${result.single.single}';
      }

      expect(await current(pool), base);
      await rolledBack((connection) async {
        final body = production.substring('VIEW: '.length);
        await connection.execute(
          'CREATE OR REPLACE VIEW $view AS '
          '${body.substring(0, body.lastIndexOf(';'))}',
        );
        expect(await current(connection), production);
        for (final statement in splitPostgresStatements(migrationUp('063'))) {
          await connection.execute(statement);
        }
        expect(await current(connection), base);
      });
    },
    skip: skipReason,
  );

  test('a consulta D-67 roda só leitura e devolve as 26 colunas', () async {
    final rows = <List<Object?>>[];
    await pool.withConnection((connection) async {
      for (final statement in d67Statements(
        File(d67NullCountsPath).readAsStringSync(),
      )) {
        final result = await connection.execute(statement);
        rows.addAll(result.map((row) => row.toList()));
      }
    });
    expect(rows.first, ['transaction_read_only', 'on', null, null]);
    final columns = rows.skip(1).toList();
    expect(columns, hasLength(26));
    for (final [table, column, nulls, total] in columns) {
      // No banco novo as 26 colunas são NOT NULL.
      expect(nulls, 0, reason: '$table.$column');
      expect(total, isA<int>(), reason: '$table.$column');
    }
  }, skip: skipReason);

  group('requireSchemaObjects', () {
    List<String> pythonTuple(String path, String name) {
      final body =
          RegExp(
            '$name = \\((.*?)\\)',
            dotAll: true,
          ).firstMatch(File(path).readAsStringSync())!.group(1)!;
      return [
        for (final match in RegExp(r'"(\w+)"').allMatches(body))
          match.group(1)!,
      ];
    }

    const hermes =
        '../docs/hermes-analysis/manaloom-knowledge/scripts/'
        'sync_battle_card_rules_pg.py';

    test(
      'o schema das migrations atende cada CLI, só lendo o catálogo',
      () async {
        final requirements = <String, SchemaRequirements>{
          'sync_cards': sync_cards.syncCardsSchemaRequirements,
          'sync_rules': sync_rules.syncRulesSchemaRequirements,
          'commander_reference_card_stats':
              commanderReferenceCardStatsSchemaRequirements,
          'commander_reference_deck_corpus':
              commanderReferenceDeckCorpusSchemaRequirements,
          'commander_reference_profile':
              commanderReferenceProfileSchemaRequirements,
          'sync_localized_card_names': cardLocalizedNamesSchemaRequirements,
          'candidate_quality': candidateQualitySchemaRequirements,
          'sync_cards_full_fast.py': SchemaRequirements(
            columns: {
              'cards': {
                ...pythonTuple(
                  'bin/sync_cards_full_fast.py',
                  'REQUIRED_CARD_COLUMNS',
                ),
              },
            },
            indexes: {
              ...pythonTuple(
                'bin/sync_cards_full_fast.py',
                'REQUIRED_CARD_INDEXES',
              ),
            },
          ),
          'backfill_card_combat_metadata.py': SchemaRequirements(
            columns: {
              'cards': {
                ...pythonTuple(
                  'bin/backfill_card_combat_metadata.py',
                  'REQUIRED_CARD_COLUMNS',
                ),
              },
            },
            indexes: {
              ...pythonTuple(
                'bin/backfill_card_combat_metadata.py',
                'REQUIRED_CARD_INDEXES',
              ),
            },
          ),
          'sync_battle_card_rules_pg.py': SchemaRequirements(
            columns: {
              'card_battle_rules': {
                ...pythonTuple(hermes, 'PG_REQUIRED_COLUMNS'),
              },
            },
            indexes: {...pythonTuple(hermes, 'PG_REQUIRED_INDEXES')},
          ),
        };
        for (final MapEntry(key: caller, value: wanted)
            in requirements.entries) {
          final objects =
              wanted.tables.length +
              wanted.columns.values.fold(0, (sum, set) => sum + set.length) +
              wanted.indexes.length +
              wanted.views.length;
          expect(objects, greaterThan(0), reason: caller);
          await rolledBack(
            (connection) => requireSchemaObjects(
              connection,
              caller: caller,
              requirements: wanted,
            ),
            readOnly: true,
          );
        }
      },
      skip: skipReason,
    );

    test('aponta o que falta, pelo tipo de objeto', () async {
      await rolledBack((connection) async {
        await connection.execute('DROP VIEW card_identity_bridge CASCADE');
        await connection.execute('DROP INDEX idx_cards_keywords');
        await connection.execute(
          'ALTER TABLE cards DROP COLUMN is_reserved CASCADE',
        );
        await connection.execute('DROP TABLE sync_state CASCADE');
        await expectLater(
          requireSchemaObjects(
            connection,
            caller: 'teste',
            requirements: const SchemaRequirements(
              // Uma view não vale como tabela, nem uma tabela como índice
              // ou view.
              tables: {
                'cards',
                'sync_state',
                'collection_availability_snapshot',
              },
              columns: {
                'cards': {'name', 'is_reserved'},
              },
              indexes: {
                'idx_cards_color_identity',
                'idx_cards_keywords',
                'cards',
              },
              views: {'card_identity_bridge', 'cards'},
            ),
          ),
          throwsA(
            isA<MissingSchemaObjects>()
                .having((error) => error.missing, 'missing', [
                  'tabela sync_state',
                  'tabela collection_availability_snapshot',
                  'coluna cards.is_reserved',
                  'índice idx_cards_keywords',
                  'índice cards',
                  'view card_identity_bridge',
                  'view cards',
                ])
                .having(
                  (error) => error.toString(),
                  'toString',
                  allOf(
                    startsWith('Schema incompleto para teste: falta '),
                    contains('O schema só muda por migration'),
                  ),
                ),
          ),
        );
      });
    }, skip: skipReason);
  });
}
