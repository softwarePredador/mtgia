import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

void main() {
  final repoRoot = Directory.current.parent.absolute.path;
  final e2eSuite = '$repoRoot/scripts/manaloom_e2e_suite.sh';

  Future<ProcessResult> evaluateStatus(String status, String policy) {
    final quotedSuite = e2eSuite.replaceAll("'", "'\\''");
    return Process.run('bash', [
      '-c',
      "source '$quotedSuite'; "
          'e2e_exit_code_for_status "\$1" "\$2"',
      'e2e-status-contract',
      status,
      policy,
    ]);
  }

  test('strict E2E maps every non-PASS result to a non-zero exit', () async {
    final expected = <String, String>{
      'PASS': '0',
      'FAIL': '1',
      'BLOCKED': '2',
      'PARTIAL': '3',
    };

    for (final entry in expected.entries) {
      final result = await evaluateStatus(entry.key, 'strict-gate');
      expect(result.exitCode, 0, reason: entry.key);
      expect('${result.stdout}'.trim(), entry.value, reason: entry.key);
    }
  });

  test(
    'strict E2E makes omitted Flutter, server runtime and PG explicit',
    () async {
      final runDir = Directory.systemTemp.createTempSync(
        'manaloom-e2e-omitted-contract-',
      );
      try {
        final quotedSuite = e2eSuite.replaceAll("'", "'\\''");
        final fixture = await Process.run(
          'bash',
          [
            '-c',
            "source '$quotedSuite'; "
                'E2E_EXECUTION_POLICY=strict-gate; '
                'initialize_run_dir; write_summary_header; '
                'run_optional_flutter_runtime_e2e; '
                'run_optional_server_live_e2e; '
                'run_read_only_postgres_step "PostgreSQL fixture" "true"; '
                'write_final_summary; write_summary_json; '
                'exit "\$(e2e_exit_code_for_status "\$FINAL_STATUS" '
                '"\$E2E_EXECUTION_POLICY")"',
          ],
          environment: {
            ...Platform.environment,
            'MANALOOM_E2E_RUN_DIR': runDir.path,
            'MANALOOM_RUN_FLUTTER_RUNTIME_E2E': '0',
            'MANALOOM_RUN_SERVER_LIVE_E2E': '0',
            'MANALOOM_NEW_SERVER_ENV': '${runDir.path}/missing.env',
            'MANALOOM_EXPECTED_SSH_HOST_KEY_SHA256': '',
          },
        );
        expect(fixture.exitCode, 3, reason: '${fixture.stderr}');

        final summary =
            jsonDecode(File('${runDir.path}/summary.json').readAsStringSync())
                as Map<String, dynamic>;
        expect(summary['result'], 'partial');
        expect(summary['gate_eligible'], isFalse);
        final steps =
            (summary['steps'] as List<dynamic>).cast<Map<String, dynamic>>();
        expect(
          steps.map((step) => step['label']),
          containsAll(<String>[
            'Flutter live runtime integration E2E',
            'Server live API E2E',
            'PostgreSQL fixture',
          ]),
        );
        expect(steps.every((step) => step['status'] == 'skip'), isTrue);
      } finally {
        runDir.deleteSync(recursive: true);
      }
    },
  );

  test('requested Flutter layer without approval is BLOCKED', () async {
    final runDir = Directory.systemTemp.createTempSync(
      'manaloom-e2e-blocked-contract-',
    );
    try {
      final quotedSuite = e2eSuite.replaceAll("'", "'\\''");
      final fixture = await Process.run(
        'bash',
        [
          '-c',
          "source '$quotedSuite'; "
              'E2E_EXECUTION_POLICY=strict-gate; '
              'initialize_run_dir; write_summary_header; '
              'run_optional_flutter_runtime_e2e; '
              'write_final_summary; write_summary_json; '
              'exit "\$(e2e_exit_code_for_status "\$FINAL_STATUS" '
              '"\$E2E_EXECUTION_POLICY")"',
        ],
        environment: {
          ...Platform.environment,
          'MANALOOM_E2E_RUN_DIR': runDir.path,
          'MANALOOM_RUN_FLUTTER_RUNTIME_E2E': '1',
          'MANALOOM_CONFIRM_LIVE_MUTATIONS': '',
        },
      );
      expect(fixture.exitCode, 2, reason: '${fixture.stderr}');
      final summary =
          jsonDecode(File('${runDir.path}/summary.json').readAsStringSync())
              as Map<String, dynamic>;
      expect(summary['result'], 'blocked');
      expect((summary['steps'] as List<dynamic>).single['status'], 'blocked');
    } finally {
      runDir.deleteSync(recursive: true);
    }
  });

  test(
    'allow-partial is explicit diagnostic evidence, never gate evidence',
    () async {
      final result = await evaluateStatus(
        'PARTIAL',
        'diagnostic-allow-partial',
      );
      expect(result.exitCode, 0);
      expect('${result.stdout}'.trim(), '0');

      final source = File(e2eSuite).readAsStringSync();
      expect(source, contains('--allow-partial'));
      expect(source, contains('"gate_eligible"'));
      expect(source, contains('diagnostic-allow-partial'));
      expect(source, contains('PARTIAL_DIAGNOSTIC:'));

      final runDir = Directory.systemTemp.createTempSync(
        'manaloom-e2e-status-contract-',
      );
      try {
        final quotedSuite = e2eSuite.replaceAll("'", "'\\''");
        final fixture = await Process.run(
          'bash',
          [
            '-c',
            "source '$quotedSuite'; "
                'E2E_EXECUTION_POLICY=diagnostic-allow-partial; '
                'initialize_run_dir; write_summary_header; '
                'skip_step "fixture optional layer" "fixture prerequisite"; '
                'write_final_summary; write_summary_json',
          ],
          environment: {
            ...Platform.environment,
            'MANALOOM_E2E_RUN_DIR': runDir.path,
          },
        );
        expect(fixture.exitCode, 0, reason: '${fixture.stderr}');

        final summary =
            jsonDecode(File('${runDir.path}/summary.json').readAsStringSync())
                as Map<String, dynamic>;
        expect(summary['result'], 'partial');
        expect(summary['execution_policy'], 'diagnostic-allow-partial');
        expect(summary['gate_eligible'], isFalse);
        expect((summary['summary'] as Map<String, dynamic>)['skipped'], 1);
      } finally {
        runDir.deleteSync(recursive: true);
      }
    },
  );

  test('all gate wrappers select strict and PowerShell checks native exit', () {
    final qualityGate =
        File('$repoRoot/scripts/quality_gate.sh').readAsStringSync();
    final localCi =
        File('$repoRoot/scripts/manaloom_local_ci.sh').readAsStringSync();
    final powershell =
        File('$repoRoot/scripts/quality_gate.ps1').readAsStringSync();

    expect(
      qualityGate,
      contains(r'"$ROOT_DIR/scripts/manaloom_e2e_suite.sh" --strict'),
    );
    expect(
      qualityGate,
      isNot(contains('manaloom_e2e_suite.sh" --allow-partial')),
    );
    expect(localCi, contains('run_strict_e2e_gate'));
    expect(localCi, isNot(contains('manaloom_e2e_suite.sh" --allow-partial')));
    expect(powershell, contains('manaloom_e2e_suite.sh") --strict'));
    expect(powershell, contains(r'$LASTEXITCODE'));
    expect(powershell, contains(r'if ($e2eExitCode -ne 0)'));
    expect(powershell, contains(r'exit $e2eExitCode'));
  });
}
