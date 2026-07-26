import 'dart:io';

import 'package:test/test.dart';

void main() {
  test(
    'full backend gate batches explicit files without re-expanding preset paths',
    () {
      final source = File('../scripts/quality_gate.sh').readAsStringSync();

      expect(source, contains('BACKEND_TEST_BATCH_SIZE'));
      expect(source, contains("find test -type f -name '*_test.dart'"));
      expect(source, isNot(contains('dart test -P all-local')));
      expect(
        source,
        contains(
          '--exclude-tags "live || live_backend || live_db_write || live_external || historical_external_snapshot"',
        ),
      );
      expect(source, contains(r'"${batch[@]}"'));
    },
  );

  test('battle-lab is a fail-fast composite local gate', () {
    final source = File('../scripts/quality_gate.sh').readAsStringSync();

    expect(source, contains('run_battle_lab_gate()'));
    expect(source, contains('test/battle_*_test.dart'));
    expect(source, contains('test/features/battle'));
    expect(source, contains('run_battle_product_gate'));
    expect(source, contains('run_runtime_performance_contract'));
    expect(source, contains('run_report_retention_audit'));
    expect(source, contains('run_project_logic_docs'));
    expect(source, contains('battle-lab)'));
  });
}
