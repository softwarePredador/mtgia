@Tags(['live'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

/// BT-PRIV-003 contra as tabelas reais: o inventário
/// (`docs/privacy/data_retention_inventory.json`) confere com o
/// `information_schema` e com as FKs de um PostgreSQL descartável criado por
/// `server/database_setup.sql` + `server/bin/migrate.dart`.
///
/// Somente leitura. Requer `RUN_PRIVACY_DB_TESTS=1` e as variáveis `DB_*` de
/// um banco descartável já migrado.
void main() {
  final enabled = Platform.environment['RUN_PRIVACY_DB_TESTS'] == '1';
  final skipReason =
      enabled ? null : 'Requer PostgreSQL descartavel explicitamente isolado.';
  final inventory =
      jsonDecode(
            File(
              '../docs/privacy/data_retention_inventory.json',
            ).readAsStringSync(),
          )
          as Map<String, dynamic>;
  final tables = (inventory['tables'] as Map).cast<String, Map>();
  late Pool pool;

  setUpAll(() async {
    if (!enabled) return;
    pool = Pool.withEndpoints([
      Endpoint(
        host: Platform.environment['DB_HOST'] ?? '127.0.0.1',
        port: int.parse(Platform.environment['DB_PORT'] ?? '5432'),
        database: Platform.environment['DB_NAME']!,
        username: Platform.environment['DB_USER']!,
        password: Platform.environment['DB_PASS'] ?? '',
      ),
    ], settings: const PoolSettings(sslMode: SslMode.disable));
  });

  tearDownAll(() async {
    if (enabled) await pool.close();
  });

  Future<Map<String, Set<String>>> liveColumns() async {
    final rows = await pool.execute('''
      SELECT c.table_name, c.column_name
      FROM information_schema.columns c
      JOIN information_schema.tables t
        ON t.table_schema = c.table_schema AND t.table_name = c.table_name
      WHERE c.table_schema = 'public' AND t.table_type = 'BASE TABLE'
    ''');
    final result = <String, Set<String>>{};
    for (final row in rows) {
      result
          .putIfAbsent(row[0]! as String, () => <String>{})
          .add(row[1]! as String);
    }
    return result;
  }

  test(
    'toda tabela real está no inventário e toda entrada existe no banco',
    () async {
      final live = await liveColumns();
      expect(live.keys.toSet(), tables.keys.toSet());
    },
    skip: skipReason,
  );

  test('tabela exportada classifica exatamente as colunas reais', () async {
    final live = await liveColumns();
    for (final MapEntry(key: name, value: entry) in tables.entries) {
      final columns = (entry['columns'] as Map?)?.cast<String, String>();
      if (columns == null) continue;
      expect(columns.keys.toSet(), live[name], reason: name);
    }
  }, skip: skipReason);

  test('views reais são as do inventário', () async {
    final rows = await pool.execute('''
        SELECT table_name
        FROM information_schema.views
        WHERE table_schema = 'public'
      ''');
    expect({
      for (final row in rows) row[0]! as String,
    }, (inventory['views'] as Map).keys.toSet());
  }, skip: skipReason);

  test('toda tabela declarada em cascata tem FK ON DELETE CASCADE para um pai '
      'que a exclusão apaga', () async {
    final rows = await pool.execute('''
        SELECT child.relname, parent.relname
        FROM pg_constraint constraint_row
        JOIN pg_class child ON child.oid = constraint_row.conrelid
        JOIN pg_class parent ON parent.oid = constraint_row.confrelid
        JOIN pg_namespace ns ON ns.oid = child.relnamespace
        WHERE constraint_row.contype = 'f'
          AND constraint_row.confdeltype = 'c'
          AND ns.nspname = 'public'
      ''');
    final cascadeParents = <String, Set<String>>{};
    for (final row in rows) {
      cascadeParents
          .putIfAbsent(row[0]! as String, () => <String>{})
          .add(row[1]! as String);
    }
    for (final MapEntry(key: name, value: entry) in tables.entries) {
      if ((entry['deletion'] as Map)['mode'] != 'cascade') continue;
      final parents = cascadeParents[name] ?? const <String>{};
      final deleted = parents.where(
        (parent) => const {
          'delete',
          'cascade',
        }.contains((tables[parent]!['deletion'] as Map)['mode']),
      );
      expect(deleted, isNotEmpty, reason: name);
    }
  }, skip: skipReason);
}
