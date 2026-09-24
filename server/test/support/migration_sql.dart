import 'package:server/sql_statement_splitter.dart';

import '../../bin/migrate.dart' as migrate;

/// BT-DB-004: o SQL de schema vive só nas migrations (e no baseline). Os
/// testes que conferem o texto de uma view ou tabela leem da migration.
///
/// Devolve o último statement, na ordem das migrations, cujo texto começa com
/// [prefix] (sem diferença de maiúsculas e espaços do começo).
String latestMigrationStatement(String prefix) {
  final wanted = prefix.toLowerCase();
  String? found;
  for (final migration in migrate.migrations) {
    for (final statement in splitPostgresStatements(migration.up)) {
      if (statement.trimLeft().toLowerCase().startsWith(wanted)) {
        found = statement;
      }
    }
  }
  if (found == null) {
    throw StateError(
      'Nenhuma migration tem um statement que comece com $prefix',
    );
  }
  return found;
}

/// O `up` da migration [version].
String migrationUp(String version) =>
    migrate.migrations.singleWhere((m) => m.version == version).up;
