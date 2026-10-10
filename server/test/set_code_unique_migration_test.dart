import 'dart:io';

import 'package:server/sql_statement_splitter.dart';
import 'package:test/test.dart';

import '../bin/migrate.dart' as migrate;

/// BT-CAT-01 / D-74 (decisão do dono de 2026-10-10, item 22), sem banco: a
/// migration 077 cria o índice único em LOWER(code) de `sets` e falha fechada com
/// duplicata, apontando o script do lote que funde antes; o banco novo nasce com o
/// mesmo índice; e nenhuma leitura de `sets` compara o código com caixa. O
/// comportamento contra um PostgreSQL descartável está em
/// `lote_sets_dedupe_077_db_live_test.dart`.
void main() {
  final migration = migrate.migrations.singleWhere(
    (item) => item.version == '077',
  );
  final statements = splitPostgresStatements(migration.up);
  final setupSql = File('database_setup.sql').readAsStringSync();
  const dedupeScript = 'sql/lote/d74_dedupe_sets_lower_code.sql';
  const createIndex =
      'CREATE UNIQUE INDEX IF NOT EXISTS uq_sets_code_lower ON sets (LOWER(code))';

  test('a 077 é a última e se chama enforce_unique_lower_set_code', () {
    expect(migrate.migrations.last, same(migration));
    expect(migration.name, 'enforce_unique_lower_set_code');
  });

  test('trava sets, recusa duplicata apontando o script do lote e só depois '
      'cria o índice único', () {
    expect(statements.first.trim(), 'LOCK TABLE sets IN SHARE MODE');
    final refusal = statements.indexWhere(
      (statement) => statement.contains('migration 077 recusada'),
    );
    final index = statements.indexWhere(
      (statement) => statement.trim() == createIndex,
    );
    expect(refusal, greaterThan(0));
    expect(index, greaterThan(refusal));
    expect(statements[refusal], contains('GROUP BY LOWER(code)'));
    expect(statements[refusal], contains('HAVING COUNT(*) > 1'));
    expect(statements[refusal], contains('server/$dedupeScript'));
    expect(File(dedupeScript).existsSync(), isTrue);
    // O IF NOT EXISTS não basta: um índice velho com o nome passaria.
    expect(statements.last, contains('index_row.indisunique'));
    expect(statements.last, contains("LIKE '% (lower(code))'"));
  });

  test('o banco novo nasce com o mesmo índice', () {
    expect(setupSql, contains('$createIndex;'));
  });

  test('rollback padrão: o down só tira o índice', () {
    expect(migration.down, 'DROP INDEX IF EXISTS uq_sets_code_lower;');
    expect(
      migrate.migrationRollbackPolicy('077'),
      migrate.MigrationRollbackPolicy.standard,
    );
  });

  test('a 077 não cria chave para users (a regra da 070 não se aplica)', () {
    expect(migration.up, isNot(contains('REFERENCES')));
  });

  test('nenhuma leitura de sets compara o código com caixa', () {
    final exactJoin = RegExp(
      r'\bsets\s+(?:AS\s+)?(\w+)\s+ON\s+\1\.code\s*=\s*\w+\.set_code',
      caseSensitive: false,
    );
    final offenders = <String>[];
    for (final root in const ['routes', 'lib', 'bin']) {
      for (final entity in Directory(root).listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        if (exactJoin.hasMatch(entity.readAsStringSync())) {
          offenders.add(entity.path);
        }
      }
    }
    expect(offenders, isEmpty);
    expect(
      File('routes/cards/resolve/index.dart').readAsStringSync(),
      contains('LEFT JOIN sets s ON LOWER(s.code) = LOWER(c.set_code)'),
    );
  });
}
