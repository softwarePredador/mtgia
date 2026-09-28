import 'dart:io';

import 'package:test/test.dart';

import '../bin/migrate.dart' as migrate;

/// BT-KPI-001, sem banco: a migration 073 guarda o hash da chave de
/// idempotência do coletor de eventos e deduplica por usuário; o baseline
/// acompanha. O comportamento está em `activation_events_db_live_test.dart`.
void main() {
  final migration073 = migrate.migrations.singleWhere(
    (migration) => migration.version == '073',
  );
  final bootstrap = File('database_setup.sql').readAsStringSync();
  String normalized(String sql) => sql.replaceAll(RegExp(r'\s+'), ' ');

  const column =
      'ALTER TABLE activation_funnel_events '
      'ADD COLUMN IF NOT EXISTS dedupe_key TEXT;';
  const check =
      'ADD CONSTRAINT chk_activation_funnel_events_dedupe_key '
      "CHECK (dedupe_key IS NULL OR dedupe_key ~ '^[0-9a-f]{64}\$');";
  const index =
      'CREATE UNIQUE INDEX IF NOT EXISTS uq_activation_funnel_events_dedupe '
      'ON activation_funnel_events (user_id, dedupe_key) '
      'WHERE dedupe_key IS NOT NULL;';

  test('073 cria a coluna do hash, o CHECK e o índice único parcial', () {
    expect(migration073.name, 'activation_events_dedupe');
    for (final sql in [migration073.up, bootstrap]) {
      expect(normalized(sql), contains(column));
      expect(normalized(sql), contains(check));
      expect(normalized(sql), contains(index));
    }
    // Não cria tabela: o laço dos gatilhos de conta ativa não é preciso.
    expect(migration073.up, isNot(contains('CREATE TABLE')));
    expect(migrate.migrations.last.version, '073');
  });

  test('o down desfaz tudo e o rollback é o padrão', () {
    final down = normalized(migration073.down!);
    expect(
      down,
      contains('DROP INDEX IF EXISTS uq_activation_funnel_events_dedupe;'),
    );
    expect(
      down,
      contains(
        'DROP CONSTRAINT IF EXISTS chk_activation_funnel_events_dedupe_key;',
      ),
    );
    expect(
      down,
      contains(
        'ALTER TABLE activation_funnel_events DROP COLUMN IF EXISTS '
        'dedupe_key;',
      ),
    );
    expect(
      migrate.migrationRollbackPolicy('073'),
      migrate.MigrationRollbackPolicy.standard,
    );
  });
}
