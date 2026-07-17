import 'dart:io';

import '../bin/migrate.dart' as migrate;
import 'package:server/sql_statement_splitter.dart';
import 'package:test/test.dart';

void main() {
  final migration038 = migrate.migrations.singleWhere(
    (migration) => migration.version == '038',
  );
  final setupSql = File('database_setup.sql').readAsStringSync();

  group('privacy migration SQL regression', () {
    test('PL/pgSQL function statements have one language clause each', () {
      for (final source
          in {
            'migration_038': migration038.up,
            'database_setup': setupSql,
          }.entries) {
        for (final functionName in const [
          'manaloom_require_active_user',
          'manaloom_guard_deck_learning_event',
          'manaloom_guard_battle_simulation',
        ]) {
          final statement = _functionStatement(source.value, functionName);
          expect(
            _occurrences(
              statement,
              RegExp(r'LANGUAGE\s+plpgsql', caseSensitive: false),
            ),
            equals(1),
            reason: '${source.key}: $functionName',
          );
          expect(
            _occurrences(
              statement,
              RegExp(r'RETURNS\s+trigger', caseSensitive: false),
            ),
            equals(1),
            reason: '${source.key}: $functionName',
          );
        }
      }
    });

    test('deck-learning owner lookup predicate is not duplicated', () {
      for (final source
          in {
            'migration_038': migration038.up,
            'database_setup': setupSql,
          }.entries) {
        final statement = _functionStatement(
          source.value,
          'manaloom_guard_deck_learning_event',
        );
        expect(
          _occurrences(
            statement,
            RegExp(r'WHERE\s+id\s*=\s*NEW\.deck_id\s*;', caseSensitive: false),
          ),
          equals(1),
          reason: source.key,
        );
      }
    });

    test('migration and fresh bootstrap keep equivalent guard functions', () {
      for (final functionName in const [
        'manaloom_require_active_user',
        'manaloom_guard_deck_learning_event',
        'manaloom_guard_battle_simulation',
      ]) {
        expect(
          _normalizeSql(_functionStatement(migration038.up, functionName)),
          equals(_normalizeSql(_functionStatement(setupSql, functionName))),
          reason: functionName,
        );
      }
    });

    test(
      'specific duplicate regressions remain absent in complete sources',
      () {
        final duplicateLanguage = RegExp(
          r'LANGUAGE\s+plpgsql\s+LANGUAGE\s+plpgsql',
          caseSensitive: false,
        );
        final duplicateOwnerWhere = RegExp(
          r'WHERE\s+id\s*=\s*NEW\.deck_id\s*;\s*'
          r'WHERE\s+id\s*=\s*NEW\.deck_id\s*;',
          caseSensitive: false,
        );

        expect(migration038.up, isNot(matches(duplicateLanguage)));
        expect(setupSql, isNot(matches(duplicateLanguage)));
        expect(migration038.up, isNot(matches(duplicateOwnerWhere)));
        expect(setupSql, isNot(matches(duplicateOwnerWhere)));
      },
    );
  });
}

String _functionStatement(String source, String functionName) {
  final declaration = RegExp(
    'CREATE\\s+OR\\s+REPLACE\\s+FUNCTION\\s+$functionName\\s*\\(',
    caseSensitive: false,
  );
  final matches = splitPostgresStatements(
    source,
  ).where((statement) => statement.contains(declaration));
  expect(matches, hasLength(1), reason: functionName);
  final statement = matches.single;
  return statement.substring(declaration.firstMatch(statement)!.start);
}

int _occurrences(String source, RegExp pattern) =>
    pattern.allMatches(source).length;

String _normalizeSql(String source) =>
    source.replaceAll(RegExp(r'\s+'), ' ').trim().toLowerCase();
