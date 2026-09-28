import 'dart:io';

import 'package:test/test.dart';

import '../bin/migrate.dart' as migrate;
import '../lib/decks/deck_revision_support.dart';

/// DCK-P0-06 (decisão D-30 do dono), sem banco: a migration 072 abre a
/// lixeira de decks no ledger e no índice, o baseline acompanha, e o
/// rollback automático só roda sem deck na lixeira nem evento de lixeira.
void main() {
  final migration072 = migrate.migrations.singleWhere(
    (migration) => migration.version == '072',
  );
  final bootstrap = File('database_setup.sql').readAsStringSync();
  String normalized(String sql) => sql.replaceAll(RegExp(r'\s+'), ' ');

  Set<String> checkedOperations(String sql) {
    final match = RegExp(
      r'ADD CONSTRAINT chk_deck_change_events_operation CHECK \(operation IN \(([^)]*)\)\)',
    ).firstMatch(normalized(sql));
    expect(match, isNotNull, reason: 'CHECK de operation');
    return RegExp(
      r"'([a-z_]+)'",
    ).allMatches(match!.group(1)!).map((value) => value.group(1)!).toSet();
  }

  test('072 abre a lixeira no ledger e cria o índice da lixeira', () {
    expect(migration072.name, 'deck_trash_lifecycle');
    expect(checkedOperations(migration072.up), deckChangeOperations);
    expect(checkedOperations(bootstrap), deckChangeOperations);
    const index =
        'CREATE INDEX IF NOT EXISTS idx_decks_user_trash ON decks '
        '(user_id, deleted_at DESC) WHERE deleted_at IS NOT NULL;';
    expect(normalized(migration072.up), contains(index));
    expect(normalized(bootstrap), contains(index));
  });

  test('o down volta o CHECK de antes e só roda com a lixeira vazia', () {
    final down = migration072.down!;
    expect(down, contains('DROP INDEX IF EXISTS idx_decks_user_trash;'));
    expect(checkedOperations(down), deckContentOperations);
    expect(
      migrate.migrationRollbackPolicy('072'),
      migrate.MigrationRollbackPolicy.emptyOnly,
    );
    final source = File('bin/migrate.dart').readAsStringSync();
    final guard = source.substring(source.indexOf("    '072' =>\n"));
    expect(
      normalized(guard.substring(0, guard.indexOf('true,'))),
      allOf(
        contains('EXISTS (SELECT 1 FROM decks WHERE deleted_at IS NOT NULL)'),
        contains("WHERE operation IN ('deck_delete', 'deck_restore')"),
      ),
    );
  });
}
