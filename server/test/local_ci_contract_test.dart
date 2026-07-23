import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('hosted GitHub Actions is replaced by versioned local gates', () {
    final localCi = File('../scripts/manaloom_local_ci.sh').readAsStringSync();
    final installer =
        File('../scripts/manaloom_install_local_hooks.sh').readAsStringSync();
    final preCommit = File('../.githooks/pre-commit').readAsStringSync();
    final prePush = File('../.githooks/pre-push').readAsStringSync();

    expect(
      File('../.github/workflows/manaloom-guardrails.yml').existsSync(),
      isFalse,
    );
    expect(localCi, contains('quick|schema|full|e2e|release'));
    expect(localCi, contains('manaloom_secret_scan.sh'));
    expect(localCi, contains('manaloom_release_ops_contract_test.sh'));
    expect(localCi, contains('manaloom_tbls_local_gate.sh'));
    expect(localCi, contains('manaloom_build_android_release.sh'));
    expect(preCommit, contains('manaloom_local_ci.sh" quick'));
    expect(prePush, contains('manaloom_local_ci.sh" full'));
    expect(installer, contains('core.hooksPath .githooks'));
    expect(installer, contains('manaloom.localGates.disposablePostgres true'));
  });

  test('tbls gate owns and removes a loopback disposable PostgreSQL', () {
    final gate =
        File('../scripts/manaloom_tbls_local_gate.sh').readAsStringSync();

    expect(gate, contains('mktemp -d'));
    expect(gate, contains('-h 127.0.0.1'));
    expect(gate, contains(r'pg_ctl -D "$DATA_DIR" -m fast stop'));
    expect(gate, contains(r'rm -rf "$RUN_DIR"'));
    expect(gate, contains('database_setup.sql'));
    expect(gate, contains('run bin/migrate.dart'));
    expect(gate, contains('tbls out'));
    expect(gate, contains('tbls doc'));
    expect(gate, contains('tbls lint'));
    expect(gate, contains('table inventory drift'));
    expect(gate, contains('column drift'));
    expect(gate, contains('foreign-key drift'));
    expect(gate, isNot(contains('TBLS_DSN')));
  });
}
