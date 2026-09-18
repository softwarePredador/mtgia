import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

void main() {
  late String fixtureSource;
  late String serverFixtureSource;

  setUpAll(() {
    final fixture = File(
      '../scripts/manaloom_authenticated_visual_qa_isolated.sh',
    );
    final serverFixture = File(
      '../scripts/manaloom_server_contract_e2e_isolated.sh',
    );
    expect(
      fixture.existsSync(),
      isTrue,
      reason: 'The authenticated visual fixture must remain versioned.',
    );
    expect(
      serverFixture.existsSync(),
      isTrue,
      reason: 'The isolated backend fixture must remain versioned.',
    );
    fixtureSource = fixture.readAsStringSync();
    serverFixtureSource = serverFixture.readAsStringSync();
  });

  group('isolated fixture safety contract', () {
    test('credentials are private before any child and never env argv', () async {
      for (final source in [fixtureSource, serverFixtureSource]) {
        expect(
          source.indexOf('unset DB_PASS PGPASSWORD'),
          lessThan(source.indexOf('ROOT_DIR=')),
        );
        expect(source, isNot(contains(r'export PGPASSWORD="$DB_PASS"')));
        expect(RegExp(r'env \\\n\s+DB_HOST=').hasMatch(source), isFalse);
        expect(
          source.indexOf('trap cleanup EXIT'),
          lessThan(source.indexOf('mkdir -')),
        );
        final capture = source.substring(
          source.indexOf('FIXTURE_DB_PASSWORD='),
          source.indexOf('ROOT_DIR='),
        );
        final functionName =
            source == fixtureSource ? 'run_visual_pg' : 'run_pg';
        final result = await Process.run(
          '/bin/bash',
          [
            '-c',
            'set -euo pipefail\n$capture\n'
                    'EGRESS_GUARD=(/usr/bin/env)\n'
                    '${shellFunction(source, functionName)}\n'
                    r'''/bin/bash -c '[[ -z "${DB_PASS+x}" && -z "${PGPASSWORD+x}" && -z "${FIXTURE_DB_PASSWORD+x}" ]]'
''' +
                '$functionName /bin/bash -c ' +
                r"""'[[ -n "$PGPASSWORD" && -z "${DB_PASS+x}" && -z "${FIXTURE_DB_PASSWORD+x}" && -z "${PGHOSTADDR+x}" && -z "${PGSERVICE+x}" && -z "${PGSERVICEFILE+x}" && -z "${PGSYSCONFDIR+x}" && -z "${PGPASSFILE+x}" ]] && printf "%s\n" "$BASH_EXECUTION_STRING" "$0" "$@"'""",
          ],
          environment: {
            'DB_PASS': 'fixture-sentinel-not-a-real-secret',
            'PGPASSWORD': 'must-not-be-inherited',
            'PGHOSTADDR': '192.0.2.123',
            'PGSERVICE': 'forbidden-service-sentinel',
            'PGSERVICEFILE': '/nonexistent/service-sentinel',
            'PGSYSCONFDIR': '/nonexistent/config-sentinel',
            'PGPASSFILE': '/nonexistent/password-sentinel',
          },
        );
        expect(result.exitCode, 0, reason: '${result.stderr}');
        expect(result.stdout, isNot(contains('fixture-sentinel')));
      }
    });

    test('rejects nonliteral hosts and invalid ports before PG use', () async {
      for (final source in [fixtureSource, serverFixtureSource]) {
        final start = source.indexOf(r'case "$DB_HOST" in');
        final end =
            source.indexOf(
              '\nfi',
              source.indexOf(r'if [[ ! "$DB_ADMIN"', start),
            ) +
            3;
        final validation = source.substring(start, end);
        for (final entry in <(String, String, bool)>[
          ('127.0.0.1', '1', true),
          ('127.0.0.1', '65535', true),
          ('127.0.0.1', '05432', true),
          ('localhost', '5432', false),
          ('::1', '5432', false),
          ('192.0.2.1', '5432', false),
          ('127.0.0.1', '0', false),
          ('127.0.0.1', '65536', false),
          ('127.0.0.1', '123x', false),
          ('127.0.0.1', '-1', false),
        ]) {
          final result = await Process.run(
            '/bin/bash',
            ['-c', 'set -euo pipefail\n$validation'],
            environment: {
              'DB_HOST': entry.$1,
              'DB_PORT': entry.$2,
              'DB_ADMIN': 'postgres',
            },
          );
          expect(
            result.exitCode == 0,
            entry.$3,
            reason: '${entry.$1}:${entry.$2} ${result.stderr}',
          );
        }
      }
    });

    test('bootstrap uses locked CLI before starting database or email', () {
      final build = serverFixtureSource.indexOf(
        r'"$DART_BIN" run dart_frog_cli:dart_frog build',
      );
      expect(build, greaterThan(0));
      expect(
        build,
        lessThan(serverFixtureSource.indexOf('DATABASE_ATTEMPTED=1')),
      );
      expect(
        build,
        lessThan(serverFixtureSource.indexOf(r'EMAIL_FIXTURE_PID=$!')),
      );
      expect(
        serverFixtureSource,
        contains(
          r'"$DART_BIN" pub get --offline --enforce-lockfile --no-precompile',
        ),
      );
      expect(serverFixtureSource, isNot(contains('run_no_egress dart_frog')));
      expect(serverFixtureSource, contains('run_pg createdb'));
      expect(serverFixtureSource, contains('run_pg dropdb'));
    });

    for (final scenario in [
      'ok',
      'query_fail',
      'dropdb_fail',
      'db_residual',
      'listener_residual',
      'kill_fail',
      'restore_fail',
    ]) {
      test('backend cleanup is fail-closed: $scenario', () async {
        final root = Directory.systemTemp.createTempSync(
          'manaloom-fixture-contract.',
        );
        addTearDown(() => root.deleteSync(recursive: true));
        final script = [
          'set -euo pipefail',
          'RUN_DIR="${root.path}"',
          'RUN_ID=contract_fixture',
          'RUN_OWNED=1; DATABASE_ATTEMPTED=1; FORCED_CLEANUP_USED=0',
          'SERVER_PID=""; EMAIL_FIXTURE_PID=""',
          'DB_HOST=127.0.0.1; DB_PORT=23456; DB_USER=fixture; DB_ADMIN=postgres',
          'DATABASE=manaloom_s1_api_contract_fixture; PORT=12345; EMAIL_FIXTURE_PORT=12346',
          r'SUMMARY="$RUN_DIR/summary.txt"; CLEANUP_SUMMARY="$RUN_DIR/cleanup.txt"',
          'RECEIPT_SUMMARY=""; RECEIPT_CLEANUP=""',
          'SCENARIO=$scenario',
          r'''terminate_bootstrap_group() { return 0; }
terminate_fixture_pid() { [[ "$SCENARIO" != kill_fail ]]; }
restore_build_outputs() { [[ "$SCENARIO" != restore_fail ]]; }
backend_listener_count() { [[ "$SCENARIO" == listener_residual ]] && echo 1 || echo 0; }
run_pg() {
  if [[ "$1" == dropdb ]]; then
    [[ "$SCENARIO" != dropdb_fail ]]; return
  fi
  [[ "$SCENARIO" != query_fail ]] || return 2
  [[ "$SCENARIO" == db_residual ]] && echo 1 || echo 0
}''',
          shellFunction(serverFixtureSource, 'cleanup'),
          'trap cleanup EXIT',
          'exit 0',
        ].join('\n');
        final result = await Process.run('/bin/bash', ['-c', script]);
        final receipt = File('${root.path}/cleanup.txt').readAsStringSync();
        expect(
          result.exitCode,
          scenario == 'ok' ? 0 : 1,
          reason: '${result.stderr}\n$receipt',
        );
        expect(
          receipt,
          contains('result=${scenario == 'ok' ? 'pass' : 'fail'}\n'),
        );
        if (scenario == 'query_fail') {
          expect(receipt, contains('database_remaining=unknown'));
        }
      });
    }

    test('ignored build PRE is restored instead of inherited or deleted', () async {
      final root = Directory.systemTemp.createTempSync(
        'manaloom-build-restore.',
      );
      addTearDown(() => root.deleteSync(recursive: true));
      final server = Directory('${root.path}/server')..createSync();
      final run = Directory('${root.path}/run')..createSync();
      for (final output in ['build', '.dart_frog']) {
        Directory('${server.path}/$output').createSync();
        File(
          '${server.path}/$output/new.txt',
        ).writeAsStringSync('owned output');
        Directory('${run.path}/pre-$output').createSync();
        File(
          '${run.path}/pre-$output/pre.txt',
        ).writeAsStringSync('preserved $output');
      }
      final result = await Process.run('/bin/bash', [
        '-c',
        'set -euo pipefail\n'
            'SERVER_DIR="${server.path}"; RUN_DIR="${run.path}"; ROOT_DIR="${root.path}"\n'
            'BUILD_MANAGED=(build .dart_frog); BUILD_SAVED=(build .dart_frog)\n'
            'git() { return 0; }\n'
            '${shellFunction(serverFixtureSource, 'restore_build_outputs')}\n'
            'restore_build_outputs\nrestore_build_outputs',
      ]);
      expect(result.exitCode, 0, reason: '${result.stderr}');
      for (final output in ['build', '.dart_frog']) {
        expect(
          File('${server.path}/$output/pre.txt').readAsStringSync(),
          'preserved $output',
        );
        expect(File('${server.path}/$output/new.txt').existsSync(), isFalse);
      }
    });

    for (final scenario in [
      'ok',
      'missing',
      'malformed',
      'cross_run',
      'duplicate',
      'query_fail',
      'db_residual',
      'listener_residual',
    ]) {
      test('visual cleanup rejects invalid proof: $scenario', () async {
        final root = Directory.systemTemp.createTempSync(
          'manaloom-visual-cleanup.',
        );
        addTearDown(() => root.deleteSync(recursive: true));
        final receipts = Directory('${root.path}/receipts')..createSync();
        const childRunId = '20260909T010203Z_765432';
        const database = 'manaloom_s1_api_$childRunId';
        var receipt =
            'result=pass\nrun_id=$childRunId\ndatabase=$database\n'
            'database_remaining=0\napi_listeners=0\nemail_fixture_listeners=0\n'
            'forced_kill_used=0\nbuild_baseline_restored=true\n';
        if (scenario == 'cross_run') {
          receipt = receipt.replaceAll('765432', '765433');
        } else if (scenario == 'malformed') {
          receipt = '{"result":"pass"}';
        } else if (scenario == 'duplicate') {
          receipt += 'result=fail\n';
        }
        if (scenario != 'missing') {
          File('${receipts.path}/cleanup.txt').writeAsStringSync(receipt);
        }
        final script = [
          'set -euo pipefail',
          'RUN_DIR="${root.path}"; RUN_ID=visual_contract; RUN_OWNED=1',
          'VISUAL_READY=0; BACKEND_PID=765432; WEB_PID=""',
          'BACKEND_RECEIPT_DIR="${receipts.path}"',
          'DATABASE=$database; DB_HOST=127.0.0.1; DB_PORT=23456; DB_USER=fixture; DB_ADMIN=postgres',
          'API_BASE_URL=http://127.0.0.1:12345; WEB_PORT=12346',
          r'CREDENTIALS_FILE="$RUN_DIR/credentials"; ISOLATED_CAPABILITIES_FILE="$RUN_DIR/policy"',
          r'WEB_BUILD_DIR="$RUN_DIR/web-build"; SUMMARY_FILE="$RUN_DIR/summary.json"',
          'SCENARIO=$scenario',
          r'''stop_visual_child() { return 0; }
listener_count() { [[ "$SCENARIO" == listener_residual ]] && echo 1 || echo 0; }
run_visual_pg() {
  [[ "$SCENARIO" != query_fail ]] || return 2
  [[ "$SCENARIO" == db_residual ]] && echo 1 || echo 0
}''',
          shellFunction(fixtureSource, 'cleanup'),
          'trap cleanup EXIT',
          'exit 0',
        ].join('\n');
        final result = await Process.run('/bin/bash', ['-c', script]);
        final summary =
            jsonDecode(File('${root.path}/summary.json').readAsStringSync())
                as Map<String, dynamic>;
        expect(
          result.exitCode,
          scenario == 'ok' ? 0 : 1,
          reason: '${result.stderr}\n$summary',
        );
        expect(summary['result'], scenario == 'ok' ? 'pass' : 'fail');
        if (scenario == 'query_fail') {
          expect(summary['database_remaining'], 'unknown');
        }
      });
    }

    test(
      'owned child termination checks wait status without leaking process',
      () async {
        for (final earlyFailure in [false, true]) {
          final source = shellFunction(
            serverFixtureSource,
            'terminate_fixture_pid',
          );
          final result = await Process.run('/bin/bash', [
            '-c',
            'set -euo pipefail\nFORCED_CLEANUP_USED=0\n$source\n'
                    r'''child=""
trap 'if [[ -n "$child" ]]; then kill -KILL "$child" 2>/dev/null || true; wait "$child" 2>/dev/null || true; fi' EXIT
''' +
                (earlyFailure
                    ? '/bin/bash -c "exit 42" &\n'
                    : '/bin/sleep 30 &\n') +
                'child=\$!\n/bin/sleep 0.1\nterminate_fixture_pid "\$child"\n',
          ]);
          expect(
            result.exitCode,
            earlyFailure ? 1 : 0,
            reason: '${result.stderr}',
          );
        }
      },
    );

    test('cancel before READY stops bootstrap group and restores PRE', () async {
      final root = Directory.systemTemp.createTempSync(
        'manaloom-bootstrap-cancel.',
      );
      addTearDown(() => root.deleteSync(recursive: true));
      final server = Directory('${root.path}/server')..createSync();
      final run = Directory('${root.path}/run')..createSync();
      Directory('${server.path}/build').createSync();
      File('${server.path}/build/pre.txt').writeAsStringSync('PRE preserved');
      final script = File('${root.path}/child.sh');
      script.writeAsStringSync(
        [
          'set -euo pipefail',
          'ROOT_DIR="${root.path}"; SERVER_DIR="${server.path}"; RUN_DIR="${run.path}"',
          'RUN_ID=cancel_contract; RUN_OWNED=1; DATABASE_ATTEMPTED=0',
          'FORCED_CLEANUP_USED=0; BOOTSTRAP_PID=""; SERVER_PID=""; EMAIL_FIXTURE_PID=""',
          'DATABASE=manaloom_s1_api_cancel_contract; PORT=12345; EMAIL_FIXTURE_PORT=12346',
          r'SUMMARY="$RUN_DIR/summary.txt"; CLEANUP_SUMMARY="$RUN_DIR/cleanup.txt"',
          'RECEIPT_SUMMARY=""; RECEIPT_CLEANUP=""; BUILD_MANAGED=(); BUILD_SAVED=()',
          'git() { return 0; }',
          'backend_listener_count() { echo 0; }',
          for (final function in [
            'run_bootstrap_phase',
            'terminate_bootstrap_group',
            'terminate_fixture_pid',
            'restore_build_outputs',
            'cleanup',
          ])
            shellFunction(serverFixtureSource, function),
          'trap cleanup EXIT',
          "trap 'exit 143' TERM",
          r'mv "$SERVER_DIR/build" "$RUN_DIR/pre-build"',
          'BUILD_MANAGED=(build); BUILD_SAVED=(build)',
          // No SDK, PG or network: only a child and its sleeping worker.
          r'''run_bootstrap_phase "$RUN_DIR/bootstrap.log" /bin/bash -c 'echo "$$" > "$1"; /bin/sleep 30 & wait' bootstrap "$RUN_DIR/group.pid"''',
        ].join('\n'),
      );
      final child = await Process.start('/bin/bash', [script.path]);
      final stdoutFuture = child.stdout.transform(utf8.decoder).join();
      final stderrFuture = child.stderr.transform(utf8.decoder).join();
      final groupFile = File('${run.path}/group.pid');
      var reached = false;
      try {
        for (var attempt = 0; attempt < 100; attempt++) {
          if (groupFile.existsSync() &&
              groupFile.readAsStringSync().trim().isNotEmpty) {
            reached = true;
            break;
          }
          await Future<void>.delayed(const Duration(milliseconds: 20));
        }
        expect(reached, isTrue, reason: 'Owned bootstrap never started');
        final group = int.parse(groupFile.readAsStringSync().trim());
        expect(child.kill(ProcessSignal.sigterm), isTrue);
        final exit = await child.exitCode.timeout(const Duration(seconds: 15));
        final output = await stdoutFuture;
        final error = await stderrFuture;
        expect(exit, 143, reason: '$output\n$error');
        final receipt = File('${run.path}/cleanup.txt').readAsStringSync();
        expect(receipt, contains('result=pass\n'), reason: receipt);
        expect(receipt, contains('build_baseline_restored=true'));
        expect(
          File('${server.path}/build/pre.txt').readAsStringSync(),
          'PRE preserved',
        );
        final groupProbe = await Process.run('/bin/bash', [
          '-c',
          'kill -0 -- -$group',
        ]);
        expect(
          groupProbe.exitCode,
          isNot(0),
          reason: 'Owned bootstrap group leaked',
        );
      } finally {
        child.kill(ProcessSignal.sigterm);
        await child.exitCode.timeout(const Duration(seconds: 15));
      }
    });

    test('visual waits for bound child receipt before declaring cleanup', () {
      final cleanup = shellFunction(fixtureSource, 'cleanup');
      expect(
        cleanup.indexOf(r'wait "$BACKEND_PID"'),
        lessThan(cleanup.indexOf('local child_receipt=')),
      );
      expect(cleanup, contains(r'"manaloom_s1_api_$receipt_run_id"'));
      expect(cleanup, contains(r'Z_${BACKEND_PID}$'));
      expect(cleanup, contains("seen[\$1]++"));
      expect(cleanup, contains("grep -qx 'result=pass'"));
      expect(cleanup, contains('backend_cleanup=missing'));
      expect(cleanup, contains('database_remaining=unknown'));
      expect(
        cleanup.indexOf(r'rm -f -- "$CREDENTIALS_FILE"'),
        lessThan(cleanup.indexOf('jq -n')),
      );
      expect(cleanup, isNot(contains('credentials_file_removed: true')));
      expect(fixtureSource, contains(r'completion_file: $completion_file'));
      expect(fixtureSource, contains(r'export DB_PASS="$FIXTURE_DB_PASSWORD"'));
    });
  });

  group('authenticated visual fixture Commander contract', () {
    test('resolves Talrand and Wastes by exact card name', () {
      expect(
        fixtureSource,
        contains(
          r'$API_BASE_URL/cards?name=Talrand%2C%20Sky%20Summoner&limit=10',
        ),
      );
      expect(
        fixtureSource,
        contains(r'select(.name == "Talrand, Sky Summoner")'),
      );
      expect(
        fixtureSource,
        contains(r'$API_BASE_URL/cards?name=Wastes&limit=10'),
      );
      expect(fixtureSource, contains(r'select(.name == "Wastes")'));
      expect(
        RegExp(r'select\(\.id\s*!=\s*\$card_id\)').hasMatch(fixtureSource),
        isFalse,
        reason: 'A commander cannot be selected as an arbitrary second card.',
      );
    });

    test('builds both Commander decks as Talrand plus 99 Wastes', () {
      expect(
        RegExp(r'format:\s*"commander"').allMatches(fixtureSource).length,
        greaterThanOrEqualTo(2),
      );

      for (final deckVariable in const ['deck_id', 'peer_deck_id']) {
        expect(
          fixtureSource,
          contains(
            "(:'$deckVariable'::uuid, :'basic_land_card_id'::uuid, 99, FALSE)",
          ),
          reason: '$deckVariable must contain exactly 99 Wastes.',
        );
        expect(
          fixtureSource,
          contains(
            "(:'$deckVariable'::uuid, :'commander_card_id'::uuid, 1, TRUE)",
          ),
          reason: '$deckVariable must contain Talrand in the commander slot.',
        );
      }
    });

    test(
      'validates both decks through POST /validate and never forges state',
      () {
        for (final deckVariable in const [
          'SEED_DECK_ID',
          'SEED_PEER_DECK_ID',
        ]) {
          final apiValidationCall = RegExp(
            '-X POST[\\s\\S]{0,320}'
                    r'\$API_BASE_URL/decks/\$' +
                deckVariable +
                r'/validate',
          );
          expect(
            apiValidationCall.hasMatch(fixtureSource),
            isTrue,
            reason: '$deckVariable must be validated by the authenticated API.',
          );
        }

        expect(fixtureSource, contains(r'<<<"$deck_validation_response"'));
        expect(fixtureSource, contains(r'<<<"$peer_deck_validation_response"'));
        expect(
          RegExp(
            r'UPDATE\s+decks\b[\s\S]{0,500}?\bvalidation_state\s*=',
            caseSensitive: false,
          ).hasMatch(fixtureSource),
          isFalse,
          reason:
              'Only POST /decks/:id/validate may persist the validated state.',
        );
      },
    );
  });

  group('authenticated visual fixture interactive Battle contract', () {
    test('welcome is an empty PG list, never an engine readiness claim', () {
      expect(fixtureSource, contains('export INTERACTIVE_BATTLE_ENABLED=true'));
      expect(
        fixtureSource,
        contains(r'XMAGE_SIDECAR_URL="http://127.0.0.1:$INACTIVE_BATCH_PORT"'),
      );
      expect(
        fixtureSource,
        contains(
          r'XMAGE_INTERACTIVE_SIDECAR_URL="http://127.0.0.1:$INACTIVE_INTERACTIVE_PORT"',
        ),
      );
      final guard = shellFunction(fixtureSource, 'verify_empty_session_list');
      expect(
        guard.indexOf('SELECT COUNT(*) FROM interactive_battle_sessions'),
        lessThan(guard.indexOf('curl -sS')),
      );
      expect(guard, isNot(contains('-X POST')));
      expect(
        fixtureSource.indexOf('verify_empty_session_list ||'),
        lessThan(fixtureSource.indexOf('VISUAL_READY=1')),
      );
      expect(
        fixtureSource,
        contains('empty session list from disposable PostgreSQL'),
      );
      expect(fixtureSource, contains('engine: "NOT_STARTED"'));
      expect(fixtureSource, contains('readiness: "NOT_PROVEN"'));
    });

    for (final scenario in [
      'ok',
      'database_nonempty',
      'database_error',
      'listener_present',
      'listener_error',
      'http_error',
      'transport_error',
      'malformed',
      'wrong_schema',
      'sessions_nonempty',
    ]) {
      test('empty session probe fails closed: $scenario', () async {
        final root = Directory.systemTemp.createTempSync(
          'manaloom-list-probe.',
        );
        addTearDown(() => root.deleteSync(recursive: true));
        final script = <String>[
          'set -euo pipefail',
          shellFunction(fixtureSource, 'verify_empty_session_list'),
          r'''run_visual_pg() {
  [[ "$SCENARIO" != database_error ]] || return 1
  if [[ "$SCENARIO" == database_nonempty ]]; then printf '1'; else printf '0'; fi
}
listener_count() {
  [[ "$SCENARIO" != listener_error ]] || return 1
  if [[ "$SCENARIO" == listener_present ]]; then printf '1'; else printf '0'; fi
}
curl() {
  printf 'called\n' >>"$RUN_DIR/http-called"
  [[ "$SCENARIO" != transport_error ]] || return 1
  local output=""
  while (( $# )); do
    if [[ "$1" == -o ]]; then output="$2"; shift; fi
    shift
  done
  printf '%s' "$PROBE_BODY" >"$output"
  if [[ "$SCENARIO" == http_error ]]; then printf '401'; else printf '200'; fi
}
verify_empty_session_list
''',
        ].join('\n');
        final body = switch (scenario) {
          'malformed' => '{',
          'wrong_schema' => '{"schema_version":"wrong","sessions":[]}',
          'sessions_nonempty' =>
            '{"schema_version":"interactive_battle_session_list_v1","sessions":[{}]}',
          _ =>
            '{"schema_version":"interactive_battle_session_list_v1","sessions":[]}',
        };
        final result = await Process.run(
          '/bin/bash',
          ['-c', script],
          environment: {
            'RUN_DIR': root.path,
            'SCENARIO': scenario,
            'PROBE_BODY': body,
            'DB_HOST': '127.0.0.1',
            'DB_PORT': '1',
            'DB_USER': 'fixture',
            'DATABASE': 'fixture',
            'INACTIVE_BATCH_PORT': '2',
            'INACTIVE_INTERACTIVE_PORT': '3',
            'API_BASE_URL': 'http://127.0.0.1:4',
            'SEED_DECK_ID': 'fixture-deck',
            'seed_token': 'synthetic-contract-token',
          },
        );
        expect(
          result.exitCode == 0,
          scenario == 'ok',
          reason: '${result.stderr}',
        );
        if (scenario.startsWith('database_') ||
            scenario.startsWith('listener_')) {
          expect(File('${root.path}/http-called').existsSync(), isFalse);
        }
      });
    }

    test('builds the Web fixture with the Battle Coach entry enabled', () {
      expect(
        fixtureSource,
        contains('--dart-define=ENABLE_INTERACTIVE_BATTLE=true'),
      );
    });

    test('forwards the isolated interactive runtime configuration', () {
      for (final variable in const [
        'INTERACTIVE_BATTLE_ENABLED',
        'XMAGE_SIDECAR_URL',
        'XMAGE_INTERACTIVE_SIDECAR_URL',
        'XMAGE_EXPECTED_COMMIT',
        'XMAGE_EXPECTED_PATCH_COMMIT',
        'XMAGE_EXPECTED_VERSION',
        'BATTLE_ALLOW_LEGACY_SIDECAR_IDENTITY',
      ]) {
        expect(
          serverFixtureSource,
          contains('$variable="\${$variable:-'),
          reason:
              '$variable must reach the isolated backend process when the '
              'caller opts into the interactive runtime.',
        );
      }
    });
  });
}

String shellFunction(String source, String name) {
  final start = source.indexOf('$name() ');
  expect(
    start,
    greaterThanOrEqualTo(0),
    reason: 'Missing shell function $name',
  );
  final closing = source[start + name.length + 3] == '(' ? '\n)\n' : '\n}\n';
  final end = source.indexOf(closing, start);
  expect(end, greaterThan(start), reason: 'Unterminated shell function $name');
  return source.substring(start, end + closing.length);
}
