import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('hosted GitHub Actions is replaced by versioned local gates', () {
    final localCi = File('../scripts/manaloom_local_ci.sh').readAsStringSync();
    final installer =
        File('../scripts/manaloom_install_local_hooks.sh').readAsStringSync();
    final preCommit = File('../.githooks/pre-commit').readAsStringSync();
    final prePush = File('../.githooks/pre-push').readAsStringSync();
    final stagedUiScope =
        File('../scripts/manaloom_staged_ui_scope.py').readAsStringSync();
    final stagedDispatcher =
        File(
          '../server/test/local_ci_staged_scope_dispatcher_test.py',
        ).readAsStringSync();

    expect(
      File('../.github/workflows/manaloom-guardrails.yml').existsSync(),
      isFalse,
    );
    expect(localCi, contains('quick [--staged-scope]|schema|full|e2e|release'));
    expect(localCi, contains('manaloom_secret_scan.sh'));
    expect(localCi, contains('manaloom_release_ops_contract_test.sh'));
    expect(localCi, contains('manaloom_tbls_local_gate.sh'));
    expect(localCi, contains('manaloom_build_android_release.sh'));
    expect(localCi, contains('sync_game_changers_to_dart.py'));
    expect(localCi, contains('run_commander_game_changer_source'));
    expect(localCi, contains('--check'));
    expect(preCommit, contains('manaloom_local_ci.sh" quick --staged-scope'));
    expect(prePush, contains('manaloom_local_ci.sh" full'));
    expect(localCi, contains('N/A_UI_SOURCE_UNCHANGED_STAGED_SCOPE'));
    expect(localCi, contains('BOOTSTRAP_STAGED_UI_SCOPE_CONTROL_PLANE'));
    expect(localCi, contains('ACCEPTED_STAGED_NON_UI_SCOPE'));
    expect(localCi, contains('"commit_gate_only":true'));
    expect(localCi, contains('"ui_pass_claimed":false'));
    expect(localCi, contains('"local_completion_credit":false'));
    expect(localCi, contains('"release_credit":false'));
    expect(localCi, contains(r'if [[ "$STAGED_SCOPE" != "1" ]]'));
    expect(localCi, contains('final_scope_record'));
    expect(localCi, contains('initial_scope_record'));
    expect(localCi, contains(r'final_scope_record" != "$initial_scope_record'));
    expect(stagedUiScope, contains('old_roots | new_roots'));
    expect(stagedUiScope, contains('"--no-renames"'));
    expect(stagedUiScope, contains('"--cached"'));
    expect(stagedUiScope, contains('"-z"'));
    expect(stagedUiScope, contains('"write-tree"'));
    expect(stagedUiScope, contains('_verify_worktree_index_binding(root)'));
    expect(stagedUiScope, contains('BOOTSTRAP_PATHS - path_texts'));
    expect(stagedDispatcher, contains('test_manual_quick_runs_ui_once'));
    expect(stagedDispatcher, contains('test_staged_non_ui_runs_ui_zero_times'));
    expect(stagedDispatcher, contains('test_index_change_during_gate_fails'));
    expect(stagedDispatcher, contains('test_worktree_index_divergence_fails'));
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
