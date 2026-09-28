import 'dart:io';

import 'package:server/sql_statement_splitter.dart';
import 'package:test/test.dart';

import '../bin/migrate.dart' as migrate;
import 'support/migration_sql.dart';
import 'support/schema_adoption.dart';

/// BT-DB-004: as migrations 063 a 065 adotam o que a auditoria de schema
/// (BT-DB-001, 2026-09-23) achou só na produção. O esperado vem da saída da
/// auditoria, não de uma cópia no teste:
/// - 063 (D-65): a view `commander_learning_snapshot` com o texto de hoje,
///   escrito por extenso;
/// - 064 (D-67): os índices `UNIQUE` que só a produção tinha, menos o do
///   fichário, pendente de decisão;
/// - 065 (D-48): os índices do `database_indexes.sql` aposentado que a
///   produção tem.
void main() {
  final audit = loadSchemaAudit();
  final productionOnly = productionOnlyIndexes(audit);

  group('064 (D-67)', () {
    final productionUnique = {
      for (final MapEntry(key: name, value: definition)
          in productionOnly.entries)
        if (definition.startsWith('CREATE UNIQUE INDEX ')) name: definition,
    };

    test('cria os UNIQUE que só a produção tinha, com a definição de lá', () {
      expect(productionUnique, hasLength(6));
      expect(
        adoptedIndexes('064'),
        Map.of(productionUnique)..remove(pendingBinderUniqueIndex),
      );
    });

    test('o UNIQUE do fichário sem idioma fica fora, pendente de decisão', () {
      // Um dos seis da D-67; contradiz a identidade física da 049.
      expect(
        productionUnique[pendingBinderUniqueIndex],
        'CREATE UNIQUE INDEX ON public.user_binder_items USING btree '
        '(user_id, card_id, condition, is_foil, list_type)',
      );
      final physicalIdentity = migrationUp('049');
      expect(
        physicalIdentity,
        contains('uq_user_binder_items_physical_identity'),
      );
      expect(physicalIdentity, contains('language, list_type'));
      for (final migration in migrate.migrations) {
        expect(
          migration.up,
          isNot(contains(pendingBinderUniqueIndex)),
          reason: migration.version,
        );
      }
      expect(
        File('database_setup.sql').readAsStringSync(),
        isNot(contains('INDEX IF NOT EXISTS $pendingBinderUniqueIndex')),
      );
    });

    test('o down derruba o que o up cria, na ordem inversa', () {
      expect(
        droppedIndexes('064'),
        adoptedIndexes('064').keys.toList().reversed.toList(),
      );
    });
  });

  group('065 (D-48)', () {
    test('cria os índices do database_indexes.sql que a produção tem', () {
      final expected = {
        for (final MapEntry(key: name, value: definition)
            in productionOnly.entries)
          if (retiredDatabaseIndexesSql.contains(name)) name: definition,
      };
      expect(expected, hasLength(21));
      expect(adoptedIndexes('065'), expected);
    });

    test('nenhum índice do arquivo aposentado diverge na produção', () {
      // Os 15 que ficaram fora da 065 estão iguais nos dois bancos ou não
      // existem em nenhum dos dois; a auditoria não os lista.
      final indexes = (audit['diferencas'] as Map)['indices'] as Map;
      final listed = <String>{
        for (final kind in const ['faltando', 'sobrando', 'divergente'])
          for (final item in indexes[kind] as List)
            ((item as Map)['objeto'] as String).split('.').last,
      };
      final outside065 = retiredDatabaseIndexesSql.difference(
        adoptedIndexes('065').keys.toSet(),
      );
      expect(outside065, hasLength(15));
      expect(outside065.intersection(listed), isEmpty);
    });

    test('o down derruba o que o up cria, na ordem inversa', () {
      expect(
        droppedIndexes('065'),
        adoptedIndexes('065').keys.toList().reversed.toList(),
      );
    });
  });

  test('database_setup.sql cria os mesmos índices, com o mesmo texto', () {
    final setup = File('database_setup.sql').readAsStringSync();
    final setupTables = {
      for (final match in RegExp(
        r'CREATE TABLE (?:IF NOT EXISTS )?(\w+)',
      ).allMatches(setup))
        match.group(1)!,
    };
    final setupLines = setup.split('\n').toSet();
    for (final version in const ['064', '065']) {
      for (final statement in splitPostgresStatements(migrationUp(version))) {
        final table = RegExp(r' ON (\w+) USING ').firstMatch(statement)!;
        final name = RegExp(r'EXISTS (\w+) ON ').firstMatch(statement)!;
        if (setupTables.contains(table.group(1))) {
          expect(setupLines, contains('$statement;'), reason: version);
        } else {
          // card_meta_insights e card_rulings nascem de migration: o índice
          // fica só na 064.
          expect(setup, isNot(contains(name.group(1)!)), reason: version);
        }
      }
    }
  });

  group('063 (D-65)', () {
    const viewPrefix = 'CREATE OR REPLACE VIEW commander_learning_snapshot';

    test('é a última migration que define a view', () {
      expect(splitPostgresStatements(migrationUp('063')), [
        latestMigrationStatement(viewPrefix),
      ]);
    });

    test('tem os filtros que faltam na view da produção', () {
      const filters = [
        'commander_learned_decks.card_count = 100',
        "commander_learned_decks.card_list ~~* (('%'::text || "
            "commander_learned_decks.commander_name) || '%'::text)",
      ];
      for (final filter in filters) {
        expect(
          auditedView(audit, 'commander_learning_snapshot', 'base'),
          contains(filter),
        );
        expect(
          auditedView(audit, 'commander_learning_snapshot', 'alvo'),
          isNot(contains(filter)),
        );
      }

      final up = migrationUp('063');
      expect(up, contains('AND card_count = 100'));
      expect(up, contains("AND card_list ILIKE '%' || commander_name || '%'"));
    });
  });

  test('063, 064 e 065 só voltam por plano manual', () {
    for (final version in const ['063', '064', '065']) {
      expect(
        migrate.migrationRollbackPolicy(version),
        migrate.MigrationRollbackPolicy.manualOnly,
        reason: version,
      );
    }
  });

  group('consulta D-67 das 26 colunas', () {
    final sql = File(d67NullCountsPath).readAsStringSync();
    final statements = d67Statements(sql);

    test('é uma transação só de leitura, desfeita no fim', () {
      expect(statements.first, 'BEGIN TRANSACTION READ ONLY');
      expect(statements.last, 'ROLLBACK');
      for (final statement in statements.sublist(1, statements.length - 1)) {
        expect(statement, startsWith('SELECT '));
        expect(
          statement,
          isNot(
            matches(
              RegExp(
                r'\b(INSERT|UPDATE|DELETE|CREATE|ALTER|DROP|TRUNCATE|'
                r'GRANT|COPY|SET)\b',
              ),
            ),
          ),
        );
      }
    });

    test('conta nulos em cada coluna NOT NULL só na migration', () {
      final expected = <String>{
        for (final item
            in ((audit['diferencas'] as Map)['colunas'] as Map)['divergente']
                as List)
          if ((item as Map)['not_null'] case [true, false])
            (item['objeto'] as String).substring('public.'.length),
      };
      expect(expected, hasLength(26));
      final counted = <String>{};
      for (final statement in statements.sublist(2, statements.length - 1)) {
        final table =
            RegExp(
              r"^SELECT '(\w+)' AS tabela",
            ).firstMatch(statement)!.group(1)!;
        // Cada bloco lê só a própria tabela e conta, de cada coluna que
        // devolve, os nulos dela mesma.
        expect(statement, contains('FROM public.$table\n'));
        expect(RegExp(r'FROM public\.').allMatches(statement), hasLength(1));
        for (final match in RegExp(
          r"\('(\w+)', s\.\1\)",
        ).allMatches(statement)) {
          final column = match.group(1)!;
          expect(
            statement,
            contains('COUNT(*) FILTER (WHERE $column IS NULL) AS $column'),
          );
          counted.add('$table.$column');
        }
      }
      expect(counted, expected);
    });
  });
}
