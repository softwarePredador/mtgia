import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('deep AI alignment keeps every PostgreSQL operation read-only', () {
    final source =
        File(
          '../scripts/manaloom_deep_ai_alignment_tester.sh',
        ).readAsStringSync();

    expect(source, isNot(contains('manaloom_mutation_guard.sh')));
    expect(source, isNot(contains('require_live_mutation_approval')));
    expect(source, isNot(contains('require_postgres_write_approval')));
    expect(source, isNot(contains('--write-approved')));

    expect(
      RegExp(
        r'with_new_server_pg\.sh\\?" --read-only',
      ).allMatches(source).length,
      greaterThanOrEqualTo(3),
    );
    expect(
      source,
      contains('dart run \\"\$ROOT_DIR/server/bin/migrate.dart\\" --status'),
    );
    expect(source, contains('pg_hermes_sqlite_contract_audit.py'));
  });

  test(
    'deterministic E2E does not require mutation tokens for read-only gates',
    () {
      final source =
          File('../scripts/manaloom_e2e_suite.sh').readAsStringSync();

      expect(source, contains('has_read_only_postgres_runner_prerequisites'));
      expect(
        source,
        contains(
          'run_read_only_postgres_step "PostgreSQL Hermes SQLite contract"',
        ),
      );
      expect(
        source,
        contains(
          'run_read_only_postgres_step "Deep AI alignment with deckbuilder battle logs"',
        ),
      );
      expect(source, contains('nenhuma autorizacao de mutacao e necessaria'));
    },
  );
}
