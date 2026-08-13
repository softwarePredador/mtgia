import 'dart:io';

import 'package:server/sql_statement_splitter.dart';
import 'package:test/test.dart';

void main() {
  group('splitPostgresStatements', () {
    test('keeps PL/pgSQL function and DO bodies intact', () {
      final statements = splitPostgresStatements(r'''
        CREATE FUNCTION demo() RETURNS trigger AS $fn$
        BEGIN
          IF NEW.value = ';' THEN
            RETURN NEW;
          END IF;
          RETURN NEW;
        END;
        $fn$ LANGUAGE plpgsql;
        DO $$
        BEGIN
          PERFORM 1;
        END;
        $$;
        SELECT 2;
      ''');

      expect(statements, hasLength(3));
      expect(statements[0], contains('END;'));
      expect(statements[0], contains(r'$fn$ LANGUAGE plpgsql'));
      expect(statements[1], contains('PERFORM 1;'));
      expect(statements[2], equals('SELECT 2'));
    });

    test('ignores terminators in strings, identifiers and comments', () {
      final statements = splitPostgresStatements(r'''
        -- comentario ; permanece no statement
        SELECT 'a;''b', "column;name";
        /* bloco ; /* aninhado ; */ concluido */
        SELECT E'c\';d';
      ''');

      expect(statements, hasLength(2));
      expect(statements.first, contains("'a;''b'"));
      expect(statements.last, contains('bloco ;'));
    });

    test('all schema executors use the PostgreSQL-aware splitter', () {
      for (final path in const [
        'bin/migrate.dart',
        'bin/setup_database.dart',
      ]) {
        final source = File(path).readAsStringSync();
        expect(source, contains('splitPostgresStatements('), reason: path);
        expect(source, isNot(contains(".split(';')")), reason: path);
      }
    });

    test('retired update_schema entrypoint is a fail-closed tombstone', () {
      final source = File('bin/update_schema.dart').readAsStringSync();

      expect(source, contains('BLOCKED:'));
      expect(source, contains('retired destructive schema'));
      expect(source, contains('reset entrypoint'));
      expect(source, contains('bin/migrate.dart'));
      expect(source, contains('exitCode = 2'));
      expect(source, isNot(contains('Database()')));
      expect(source, isNot(contains('DROP TABLE')));
      expect(source, isNot(contains('database_setup.sql')));
      expect(source, isNot(contains('execute(')));
    });
  });
}
