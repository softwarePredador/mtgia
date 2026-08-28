import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

void main() {
  late String fixtureSource;
  late String serverFixtureSource;
  late String fixturePath;
  late String serverFixturePath;

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
    fixturePath = fixture.absolute.path;
    serverFixturePath = serverFixture.absolute.path;
    fixtureSource = fixture.readAsStringSync();
    serverFixtureSource = serverFixture.readAsStringSync();
  });

  group('authenticated visual fixture PostgreSQL coordinates', () {
    test('validates loopback coordinates before PostgreSQL or fixture use', () {
      expect(fixtureSource, contains(r'DB_HOST="${DB_HOST-127.0.0.1}"'));
      expect(fixtureSource, contains(r'DB_PORT="${DB_PORT-5432}"'));
      expect(fixtureSource, contains(r'DB_USER_SET="${DB_USER+x}"'));
      expect(fixtureSource, contains(r'DB_USER_VALUE="${DB_USER-}"'));
      expect(fixtureSource, contains(r'DB_USER="$(id -un)"'));
      expect(fixtureSource, contains(r'DB_PASS="${DB_PASS-}"'));
      expect(
        fixtureSource,
        contains(r'DB_ADMIN="${DB_ADMIN-${MANALOOM_S1_PG_ADMIN_DB-postgres}}"'),
      );
      expect(fixtureSource, contains(r'if [[ "$DB_HOST" != "127.0.0.1" ]]'));
      expect(
        fixtureSource,
        contains(r'[[ ! "$DB_PORT" =~ ^[0-9]+$ || ${#DB_PORT} -gt 5 ]]'),
      );
      expect(
        fixtureSource,
        contains(r'((DB_PORT_NUMBER < 1 || DB_PORT_NUMBER > 65535))'),
      );
      expect(
        fixtureSource,
        contains(
          'export -n DB_HOST DB_PORT DB_USER DB_PASS DB_ADMIN '
          'MANALOOM_S1_PG_ADMIN_DB',
        ),
      );

      final validationEnd = fixtureSource.indexOf(
        'readonly DB_HOST DB_PORT DB_PORT_NUMBER DB_USER DB_PASS DB_ADMIN',
      );
      expect(validationEnd, greaterThan(0));
      for (final laterOperation in const [
        r'source "$ROOT_DIR/scripts/lib/manaloom_dart_toolchain.sh"',
        'if ! configured_pg_isready',
        r'mkdir -p "$RUN_DIR"',
        r'"$ROOT_DIR/scripts/manaloom_server_contract_e2e_isolated.sh"',
      ]) {
        expect(
          fixtureSource.indexOf(laterOperation),
          greaterThan(validationEnd),
          reason:
              '$laterOperation must occur only after coordinate validation.',
        );
      }

      expect(
        RegExp(
          r'\b(?:pg_isready|psql)\b[^\n]*-p\s+5432',
        ).hasMatch(fixtureSource),
        isFalse,
        reason: 'Operational PostgreSQL commands cannot pin port 5432.',
      );
      expect(
        RegExp(
          r'\b(?:pg_isready|psql)\b[^\n]*-h\s+127\.0\.0\.1',
        ).hasMatch(fixtureSource),
        isFalse,
        reason: 'Operational PostgreSQL commands must use DB_HOST.',
      );
      expect(
        fixtureSource,
        contains('-h "\$DB_HOST" -p "\$DB_PORT" -U "\$DB_USER"'),
      );
      expect(
        fixtureSource,
        contains("-c 'SELECT current_user, current_database()'"),
      );
      expect(fixtureSource, contains('DATABASE_REMAINING="not_reported"'));
      expect(fixtureSource, contains('DATABASE_REMAINING="probe_failed"'));

      final directPgCommands =
          fixtureSource
              .split('\n')
              .where(
                (line) =>
                    RegExp(r'\b(?:pg_isready|psql)\b').hasMatch(line) &&
                    !line.contains('for tool in'),
              )
              .map((line) => line.trim())
              .toList();
      expect(
        directPgCommands,
        equals([
          r'run_configured_pg pg_isready \',
          r'run_configured_pg psql -X -w \',
        ]),
        reason: 'Every PostgreSQL command must use the sanitized helpers.',
      );
      expect(
        RegExp(r'\bconfigured_pg_isready\b').allMatches(fixtureSource),
        hasLength(2),
      );
      expect(
        RegExp(r'\bconfigured_psql\b').allMatches(fixtureSource),
        hasLength(greaterThanOrEqualTo(5)),
      );
    });

    test(
      'rejects invalid coordinates before PostgreSQL or fixture startup',
      () async {
        final cases = <({String host, String port, String user, String admin})>[
          (
            host: 'localhost',
            port: '5432',
            user: 'visual_user',
            admin: 'postgres',
          ),
          (host: '::1', port: '5432', user: 'visual_user', admin: 'postgres'),
          (host: '', port: '5432', user: 'visual_user', admin: 'postgres'),
          (host: '127.0.0.1', port: '', user: 'visual_user', admin: 'postgres'),
          (
            host: '127.0.0.1',
            port: 'abc',
            user: 'visual_user',
            admin: 'postgres',
          ),
          (
            host: '127.0.0.1',
            port: '0',
            user: 'visual_user',
            admin: 'postgres',
          ),
          (
            host: '127.0.0.1',
            port: '65536',
            user: 'visual_user',
            admin: 'postgres',
          ),
          (host: '127.0.0.1', port: '65432', user: '', admin: 'postgres'),
          (host: '127.0.0.1', port: '65432', user: 'visual_user', admin: ''),
        ];

        for (final testCase in cases) {
          final tempRoot = Directory.systemTemp.createTempSync(
            'manaloom_visual_pg_coordinates.',
          );
          try {
            final fakeBin = Directory('${tempRoot.path}/bin')..createSync();
            final marker = File('${tempRoot.path}/postgres-called');
            for (final tool in const ['pg_isready', 'psql']) {
              final stub = File('${fakeBin.path}/$tool')
                ..writeAsStringSync(r'''#!/bin/sh
/usr/bin/touch "$MANALOOM_PG_CALL_MARKER"
exit 97
''');
              final chmod = Process.runSync('/bin/chmod', ['700', stub.path]);
              expect(chmod.exitCode, 0);
            }

            const passwordSentinel = 'pg-password-must-not-be-logged';
            final runRoot = Directory('${tempRoot.path}/runs');
            final environment =
                Map<String, String>.from(Platform.environment)
                  ..['PATH'] =
                      '${fakeBin.path}:${Platform.environment['PATH'] ?? ''}'
                  ..['MANALOOM_PG_CALL_MARKER'] = marker.path
                  ..['MANALOOM_VISUAL_QA_ROOT'] = runRoot.path
                  ..['DB_HOST'] = testCase.host
                  ..['DB_PORT'] = testCase.port
                  ..['DB_USER'] = testCase.user
                  ..['DB_PASS'] = passwordSentinel
                  ..['DB_ADMIN'] = testCase.admin;

            final result = await Process.run('/bin/bash', [
              fixturePath,
            ], environment: environment);
            expect(result.exitCode, 2, reason: '$testCase must fail closed.');
            expect(
              marker.existsSync(),
              isFalse,
              reason: '$testCase reached PG.',
            );
            expect(
              runRoot.existsSync(),
              isFalse,
              reason: '$testCase started fixture.',
            );
            expect(result.stdout.toString(), isNot(contains(passwordSentinel)));
            expect(result.stderr.toString(), isNot(contains(passwordSentinel)));
          } finally {
            tempRoot.deleteSync(recursive: true);
          }
        }
      },
    );

    test('scopes DB_PASS only to the intended PostgreSQL child', () async {
      final tempRoot = Directory.systemTemp.createTempSync(
        'manaloom_visual_pg_secret_scope.',
      );
      try {
        final fakeBin = Directory('${tempRoot.path}/bin')..createSync();
        final nonPgLeakMarker = File('${tempRoot.path}/non-pg-secret-leak');
        final pgLeakMarker = File('${tempRoot.path}/pg-db-pass-leak');
        final pgArgvLeakMarker = File('${tempRoot.path}/pg-argv-secret-leak');
        final pgPasswordMarker = File('${tempRoot.path}/pgpassword-present');
        final pgCallMarker = File('${tempRoot.path}/postgres-called');

        final dirnameStub = File('${fakeBin.path}/dirname')
          ..writeAsStringSync(r'''#!/bin/sh
if [ "${DB_PASS+x}" = x ] || [ "${PGPASSWORD+x}" = x ]; then
  /usr/bin/touch "$MANALOOM_NON_PG_SECRET_LEAK_MARKER"
fi
exec /usr/bin/dirname "$@"
''');
        expect(
          Process.runSync('/bin/chmod', ['700', dirnameStub.path]).exitCode,
          0,
        );

        for (final tool in const ['pg_isready', 'psql']) {
          final stub = File('${fakeBin.path}/$tool')
            ..writeAsStringSync(r'''#!/bin/sh
if [ "${DB_PASS+x}" = x ]; then
  /usr/bin/touch "$MANALOOM_PG_DB_PASS_LEAK_MARKER"
fi
if [ "${PGPASSWORD+x}" = x ]; then
  /usr/bin/touch "$MANALOOM_PGPASSWORD_PRESENT_MARKER"
fi
for argument in "$@"; do
  if [ "$argument" = "${PGPASSWORD-}" ]; then
    /usr/bin/touch "$MANALOOM_PG_ARGV_SECRET_LEAK_MARKER"
  fi
done
/usr/bin/touch "$MANALOOM_PG_CALL_MARKER"
exit 97
''');
          expect(Process.runSync('/bin/chmod', ['700', stub.path]).exitCode, 0);
        }

        const passwordSentinel = 'pg-password-must-remain-process-scoped';
        final runRoot = Directory('${tempRoot.path}/runs');
        final environment =
            Map<String, String>.from(Platform.environment)
              ..['PATH'] =
                  '${fakeBin.path}:${Platform.environment['PATH'] ?? ''}'
              ..['MANALOOM_NON_PG_SECRET_LEAK_MARKER'] = nonPgLeakMarker.path
              ..['MANALOOM_PG_DB_PASS_LEAK_MARKER'] = pgLeakMarker.path
              ..['MANALOOM_PG_ARGV_SECRET_LEAK_MARKER'] = pgArgvLeakMarker.path
              ..['MANALOOM_PGPASSWORD_PRESENT_MARKER'] = pgPasswordMarker.path
              ..['MANALOOM_PG_CALL_MARKER'] = pgCallMarker.path
              ..['MANALOOM_VISUAL_QA_ROOT'] = runRoot.path
              ..['MANALOOM_CONFIRM_POSTGRES_WRITES'] =
                  'I_HAVE_EXPLICIT_APPROVAL'
              ..['MANALOOM_CONFIRM_LIVE_MUTATIONS'] = 'I_HAVE_EXPLICIT_APPROVAL'
              ..['DB_HOST'] = '127.0.0.1'
              ..['DB_PORT'] = '65432'
              ..['DB_USER'] = 'visual_user'
              ..['DB_PASS'] = passwordSentinel
              ..['DB_ADMIN'] = 'postgres';

        final result = await Process.run('/bin/bash', [
          fixturePath,
        ], environment: environment);
        expect(result.exitCode, 2);
        expect(pgCallMarker.existsSync(), isTrue);
        expect(pgPasswordMarker.existsSync(), isTrue);
        expect(pgLeakMarker.existsSync(), isFalse);
        expect(pgArgvLeakMarker.existsSync(), isFalse);
        expect(nonPgLeakMarker.existsSync(), isFalse);
        expect(runRoot.existsSync(), isFalse);
        expect(result.stdout.toString(), isNot(contains(passwordSentinel)));
        expect(result.stderr.toString(), isNot(contains(passwordSentinel)));
      } finally {
        tempRoot.deleteSync(recursive: true);
      }
    });

    test('propagates exact coordinates without serializing DB_PASS', () {
      final childStart = fixtureSource.indexOf('run_backend_fixture() (');
      final childEnd = fixtureSource.indexOf(
        '\n)\n\nset -m\nrun_backend_fixture',
        childStart,
      );
      expect(childStart, greaterThan(0));
      expect(childEnd, greaterThan(childStart));
      final childBlock = fixtureSource.substring(childStart, childEnd);
      expect(childBlock, contains('export DB_HOST DB_PORT DB_USER DB_PASS'));
      expect(
        childBlock,
        contains(r'export MANALOOM_S1_PG_ADMIN_DB="$DB_ADMIN"'),
      );
      expect(
        childBlock,
        contains(
          r'exec "$ROOT_DIR/scripts/manaloom_server_contract_e2e_isolated.sh"',
        ),
      );

      expect(fixtureSource, contains('run_configured_pg() ('));
      expect(fixtureSource, contains(r'export PGPASSWORD="$DB_PASS"'));
      expect(fixtureSource, contains(r'exec "$@"'));
      expect(fixtureSource, isNot(contains('run_configured_pg env')));
      expect(
        RegExp(r'\benv\b[^\n]*(?:DB_PASS|PGPASSWORD)=').hasMatch(fixtureSource),
        isFalse,
      );
      final dbPassExports =
          fixtureSource
              .split('\n')
              .where(
                (line) =>
                    line.trim() == 'export DB_HOST DB_PORT DB_USER DB_PASS',
              )
              .toList();
      expect(dbPassExports, hasLength(1));
      expect(
        RegExp(
          r'^\s*(?:echo|printf|tee|jq)\b[^\n]*DB_PASS',
          multiLine: true,
        ).hasMatch(fixtureSource),
        isFalse,
      );

      final credentialsStart = fixtureSource.indexOf('umask 077');
      final credentialsEnd = fixtureSource.indexOf(
        '>"\$CREDENTIALS_FILE"',
        credentialsStart,
      );
      expect(credentialsStart, greaterThan(0));
      expect(credentialsEnd, greaterThan(credentialsStart));
      expect(
        fixtureSource.substring(credentialsStart, credentialsEnd),
        isNot(anyOf(contains('DB_PASS'), contains('PGPASSWORD'))),
      );

      final readyStart = fixtureSource.indexOf('bundle_sha256=');
      final readyEnd = fixtureSource.indexOf('>"\$READY_MANIFEST"', readyStart);
      expect(readyStart, greaterThan(0));
      expect(readyEnd, greaterThan(readyStart));
      expect(
        fixtureSource.substring(readyStart, readyEnd),
        isNot(anyOf(contains('DB_PASS'), contains('PGPASSWORD'))),
      );
      expect(fixtureSource, contains('rm -f "\$CREDENTIALS_FILE"'));

      expect(
        serverFixtureSource,
        contains(r'DB_ADMIN="${MANALOOM_S1_PG_ADMIN_DB:-postgres}"'),
      );
      expect(
        serverFixtureSource,
        contains(r'-h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER"'),
      );
    });

    test('keeps child database credentials out of argv and global env', () {
      expect(serverFixtureSource, contains(r'DB_PASS="${DB_PASS-}"'));
      expect(
        serverFixtureSource,
        contains(
          'export -n DB_HOST DB_PORT DB_USER DB_PASS DB_ADMIN '
          'MANALOOM_S1_PG_ADMIN_DB PGPASSWORD',
        ),
      );
      expect(
        RegExp(
          r'\benv\b[^\n]*(?:DB_PASS|PGPASSWORD)=',
        ).hasMatch(serverFixtureSource),
        isFalse,
      );
      expect(serverFixtureSource, isNot(contains(r'DB_PASS="$DB_PASS"')));

      final validationEnd = serverFixtureSource.indexOf(
        'readonly DB_HOST DB_PORT DB_PORT_NUMBER DB_USER DB_PASS DB_ADMIN',
      );
      expect(validationEnd, greaterThan(0));
      expect(
        serverFixtureSource.indexOf('ROOT_DIR='),
        greaterThan(validationEnd),
      );

      String functionBlock(String name) {
        final start = serverFixtureSource.indexOf('$name() (');
        final end = serverFixtureSource.indexOf('\n)\n', start);
        expect(start, greaterThan(0), reason: '$name must remain versioned.');
        expect(end, greaterThan(start));
        return serverFixtureSource.substring(start, end);
      }

      final postgresBlock = functionBlock('run_postgres_no_egress');
      expect(postgresBlock, contains(r'export PGPASSWORD="$DB_PASS"'));
      expect(postgresBlock, isNot(contains('export DB_HOST')));
      expect(postgresBlock, contains(r'exec "${EGRESS_GUARD[@]}" "$@"'));
      expect(
        serverFixtureSource
            .split('\n')
            .where((line) => line.trim() == r'export PGPASSWORD="$DB_PASS"'),
        hasLength(1),
      );

      final consumers = <String, String>{
        'run_migration_consumer': r'"$DART_BIN" run bin/migrate.dart',
        'run_server_consumer': r'"$SERVER_DIR/build/bin/server.dart"',
        'run_test_consumer': r'"$DART_BIN" test -j 1 "${tests[@]}"',
      };
      for (final entry in consumers.entries) {
        final block = functionBlock(entry.key);
        expect(block, contains('unset PGPASSFILE PGPASSWORD'));
        expect(block, contains('export DB_HOST DB_PORT DB_USER DB_PASS'));
        expect(block, contains(r'exec "${EGRESS_GUARD[@]}"'));
        expect(block, contains(entry.value));
      }
      expect(
        serverFixtureSource
            .split('\n')
            .where(
              (line) => line.trim() == 'export DB_HOST DB_PORT DB_USER DB_PASS',
            ),
        hasLength(3),
      );

      final directPgCommands =
          serverFixtureSource
              .split('\n')
              .where(
                (line) =>
                    RegExp(r'\b(?:createdb|dropdb|psql)\b').hasMatch(line) &&
                    !line.contains('for tool in'),
              )
              .map((line) => line.trim())
              .toList();
      expect(directPgCommands, hasLength(8));
      expect(
        directPgCommands.every(
          (line) =>
              line.startsWith('run_postgres_no_egress ') ||
              line.startsWith('if ! run_postgres_no_egress '),
        ),
        isTrue,
      );
      expect(
        RegExp(
          r'^\s*(?:echo|printf|tee|jq)\b[^\n]*DB_PASS',
          multiLine: true,
        ).hasMatch(serverFixtureSource),
        isFalse,
      );
    });

    test(
      'rejects invalid child coordinates before any child process',
      () async {
        final cases = <({String host, String port})>[
          (host: 'database.internal', port: '5432'),
          (host: '', port: '5432'),
          (host: '127.0.0.1', port: ''),
          (host: '127.0.0.1', port: 'abc'),
          (host: '127.0.0.1', port: '0'),
          (host: '127.0.0.1', port: '65536'),
        ];

        for (final testCase in cases) {
          final tempRoot = Directory.systemTemp.createTempSync(
            'manaloom_server_pg_invalid.',
          );
          try {
            final fakeBin = Directory('${tempRoot.path}/bin')..createSync();
            final childMarker = File('${tempRoot.path}/child-called');
            final dirnameStub = File('${fakeBin.path}/dirname')
              ..writeAsStringSync(r'''#!/bin/sh
/usr/bin/touch "$MANALOOM_CHILD_CALL_MARKER"
exit 97
''');
            expect(
              Process.runSync('/bin/chmod', ['700', dirnameStub.path]).exitCode,
              0,
            );

            const passwordSentinel = 'child-password-must-not-be-logged';
            final environment =
                Map<String, String>.from(Platform.environment)
                  ..['PATH'] =
                      '${fakeBin.path}:${Platform.environment['PATH'] ?? ''}'
                  ..['MANALOOM_CHILD_CALL_MARKER'] = childMarker.path
                  ..['DB_HOST'] = testCase.host
                  ..['DB_PORT'] = testCase.port
                  ..['DB_USER'] = 'visual_user'
                  ..['DB_PASS'] = passwordSentinel
                  ..['MANALOOM_S1_PG_ADMIN_DB'] = 'postgres';
            final result = await Process.run('/bin/bash', [
              serverFixturePath,
            ], environment: environment);
            expect(result.exitCode, 2, reason: '$testCase must fail closed.');
            expect(childMarker.existsSync(), isFalse);
            expect(result.stdout.toString(), isNot(contains(passwordSentinel)));
            expect(result.stderr.toString(), isNot(contains(passwordSentinel)));
          } finally {
            tempRoot.deleteSync(recursive: true);
          }
        }
      },
    );

    test('does not export DB_PASS to a non-PostgreSQL child', () async {
      final tempRoot = Directory.systemTemp.createTempSync(
        'manaloom_server_pg_secret_scope.',
      );
      try {
        final fakeBin = Directory('${tempRoot.path}/bin')..createSync();
        final leakMarker = File('${tempRoot.path}/non-pg-secret-leak');
        final unameMarker = File('${tempRoot.path}/uname-called');

        final dirnameStub = File('${fakeBin.path}/dirname')
          ..writeAsStringSync(r'''#!/bin/sh
if [ "${DB_PASS+x}" = x ] || [ "${PGPASSWORD+x}" = x ]; then
  /usr/bin/touch "$MANALOOM_NON_PG_SECRET_LEAK_MARKER"
fi
exec /usr/bin/dirname "$@"
''');
        final unameStub = File('${fakeBin.path}/uname')
          ..writeAsStringSync(r'''#!/bin/sh
if [ "${DB_PASS+x}" = x ] || [ "${PGPASSWORD+x}" = x ]; then
  /usr/bin/touch "$MANALOOM_NON_PG_SECRET_LEAK_MARKER"
fi
/usr/bin/touch "$MANALOOM_UNAME_CALL_MARKER"
printf 'Unsupported\n'
''');
        for (final stub in [dirnameStub, unameStub]) {
          expect(Process.runSync('/bin/chmod', ['700', stub.path]).exitCode, 0);
        }
        for (final tool in const [
          'createdb',
          'curl',
          'dropdb',
          'find',
          'head',
          'jq',
          'psql',
          'python3',
          'sed',
          'shasum',
          'sort',
          'xargs',
        ]) {
          final stub = File('${fakeBin.path}/$tool')
            ..writeAsStringSync('#!/bin/sh\nexit 97\n');
          expect(Process.runSync('/bin/chmod', ['700', stub.path]).exitCode, 0);
        }

        const passwordSentinel = 'child-password-must-remain-shell-local';
        final environment =
            Map<String, String>.from(Platform.environment)
              ..['PATH'] =
                  '${fakeBin.path}:${Platform.environment['PATH'] ?? ''}'
              ..['MANALOOM_NON_PG_SECRET_LEAK_MARKER'] = leakMarker.path
              ..['MANALOOM_UNAME_CALL_MARKER'] = unameMarker.path
              ..['MANALOOM_CONFIRM_POSTGRES_WRITES'] =
                  'I_HAVE_EXPLICIT_APPROVAL'
              ..['MANALOOM_CONFIRM_LIVE_MUTATIONS'] = 'I_HAVE_EXPLICIT_APPROVAL'
              ..['DB_HOST'] = '127.0.0.1'
              ..['DB_PORT'] = '65432'
              ..['DB_USER'] = 'visual_user'
              ..['DB_PASS'] = passwordSentinel
              ..['MANALOOM_S1_PG_ADMIN_DB'] = 'postgres';

        final result = await Process.run('/bin/bash', [
          serverFixturePath,
        ], environment: environment);
        expect(result.exitCode, 2);
        expect(unameMarker.existsSync(), isTrue);
        expect(leakMarker.existsSync(), isFalse);
        expect(result.stdout.toString(), isNot(contains(passwordSentinel)));
        expect(result.stderr.toString(), isNot(contains(passwordSentinel)));
      } finally {
        tempRoot.deleteSync(recursive: true);
      }
    });
  });

  group('authenticated visual fixture READY jq contract', () {
    String extractReadyJqFilter() {
      final readyStart = fixtureSource.indexOf('bundle_sha256=');
      expect(readyStart, greaterThan(0));
      final jqStart = fixtureSource.indexOf(r'jq -n \', readyStart);
      expect(jqStart, greaterThan(readyStart));

      const filterPrefix = "\n  '";
      const filterStartMarker = "\n  '{\n    status: \"ready\",";
      const filterEndMarker = "\n  }' >\"\$READY_MANIFEST\"";
      final filterStart = fixtureSource.indexOf(filterStartMarker, jqStart);
      final filterEnd = fixtureSource.indexOf(filterEndMarker, filterStart);
      expect(filterStart, greaterThan(jqStart));
      expect(filterEnd, greaterThan(filterStart));
      expect(
        fixtureSource.indexOf(filterStartMarker, filterStart + 1),
        -1,
        reason: 'The READY jq filter must remain unique.',
      );

      return fixtureSource.substring(
        filterStart + filterPrefix.length,
        filterEnd + '\n  }'.length,
      );
    }

    String resolveGovernedJq() {
      final resolution = Process.runSync('/bin/bash', [
        '-c',
        'command -v -- jq',
      ]);
      expect(resolution.exitCode, 0, reason: resolution.stderr.toString());
      final jqPath = resolution.stdout.toString().trim();
      expect(jqPath, startsWith('/'));
      expect(File(jqPath).existsSync(), isTrue);
      final version = Process.runSync(jqPath, ['--version']);
      expect(version.exitCode, 0, reason: version.stderr.toString());
      expect(version.stdout.toString().trim(), startsWith('jq-'));
      return jqPath;
    }

    List<String> jqArguments(String filter, String runDir) {
      final variableNames = <String>[];
      for (final match in RegExp(r'\$([a-z][a-z0-9_]*)').allMatches(filter)) {
        final name = match.group(1)!;
        if (!variableNames.contains(name)) {
          variableNames.add(name);
        }
      }
      expect(variableNames, contains('run_dir'));

      return <String>[
        '-n',
        for (final name in variableNames) ...[
          '--arg',
          name,
          name == 'run_dir' ? runDir : 'fixture_$name',
        ],
        filter,
      ];
    }

    test('compiles and executes the versioned READY filter with real jq', () {
      final filter = extractReadyJqFilter();
      final jqPath = resolveGovernedJq();
      final runDir =
          Directory.systemTemp.uri
              .resolve('manaloom_ready_manifest_contract/run')
              .toFilePath();
      final result = Process.runSync(jqPath, jqArguments(filter, runDir));
      expect(result.exitCode, 0, reason: result.stderr.toString());

      final document = jsonDecode(result.stdout.toString()) as Map;
      final cleanup = document['cleanup']! as Map;
      expect(document['status'], 'ready');
      expect(document['run_dir'], runDir);
      expect(cleanup['global_receipt'], '$runDir/global-cleanup-receipt.json');
    });

    test('rejects the unparenthesized READY path regression', () {
      const compatibleExpression =
          r'global_receipt: ($run_dir + "/global-cleanup-receipt.json")';
      const regressedExpression =
          r'global_receipt: $run_dir + "/global-cleanup-receipt.json"';
      final filter = extractReadyJqFilter();
      expect(
        RegExp(RegExp.escape(compatibleExpression)).allMatches(filter),
        hasLength(1),
      );
      expect(filter, isNot(contains(regressedExpression)));

      final regressedFilter = filter.replaceFirst(
        compatibleExpression,
        regressedExpression,
      );
      expect(regressedFilter, isNot(filter));
      final runDir =
          Directory.systemTemp.uri
              .resolve('manaloom_ready_manifest_contract/regression')
              .toFilePath();
      final result = Process.runSync(
        resolveGovernedJq(),
        jqArguments(regressedFilter, runDir),
      );
      expect(result.exitCode, isNot(0));
      expect(result.stderr.toString(), contains('syntax error'));
    });
  });

  group('canonical cleanup receipts', () {
    String markedBlock(String source, String begin, String end) {
      final start = source.indexOf(begin);
      final finish = source.indexOf(end, start);
      expect(start, greaterThanOrEqualTo(0), reason: 'Missing $begin');
      expect(finish, greaterThan(start), reason: 'Missing $end');
      return source.substring(start + begin.length, finish);
    }

    test('backend cleanup is one-shot, owned and fail-closed', () {
      final cleanup = markedBlock(
        serverFixtureSource,
        '# BEGIN MANALOOM_BACKEND_CLEANUP_CONTRACT',
        '# END MANALOOM_BACKEND_CLEANUP_CONTRACT',
      );
      expect(cleanup, isNot(contains('|| true')));
      for (final required in const [
        r'"$CLEANUP_STATE" == "running"',
        'CLEANUP_STATE="complete"',
        'capture_owned_process_group',
        'send_owned_signal TERM',
        'send_owned_signal KILL',
        r'${label}_term_failed',
        r'${label}_wait_failed',
        r'${label}_group_residual',
        'dropdb --if-exists --force',
        r'--maintenance-db="$DB_ADMIN"',
        'dropdb_failed',
        'database_residual',
        'api_listener_residual',
        'email_listener_residual',
        'build_digest_mismatch',
        'build_remove_failed',
        'build_residual',
        'dart_frog_residual',
        'governed_temp_residual',
        'manaloom.server_contract_e2e_cleanup_receipt.v1',
        'cleanup_invocations: 1',
        r'chmod 600 "$temp_file"',
        r'mv "$temp_file" "$BACKEND_CLEANUP_RECEIPT"',
      ]) {
        expect(cleanup, contains(required), reason: required);
      }

      expect(serverFixtureSource, contains('trap on_backend_exit EXIT'));
      expect(serverFixtureSource, contains("trap 'exit 130' INT"));
      expect(serverFixtureSource, contains("trap 'exit 143' TERM"));
      expect(
        RegExp(
          r'^set -m\nrun_no_egress env',
          multiLine: true,
        ).hasMatch(serverFixtureSource),
        isTrue,
      );
      expect(
        RegExp(
          r'^set -m\nrun_server_consumer',
          multiLine: true,
        ).hasMatch(serverFixtureSource),
        isTrue,
      );

      final receiptCall = cleanup.indexOf(
        r'if ! write_backend_cleanup_receipt "$original_status"',
      );
      final passOutput = cleanup.indexOf(
        "printf 'PASS: isolated server contract E2E\\n'",
      );
      expect(receiptCall, greaterThan(0));
      expect(passOutput, greaterThan(receiptCall));
      expect(
        cleanup.indexOf(r'rm -f "$BACKEND_CLEANUP_RECEIPT"'),
        greaterThan(receiptCall),
      );
    });

    test('visual receipt validates backend before global closure', () {
      final cleanup = markedBlock(
        fixtureSource,
        '# BEGIN MANALOOM_VISUAL_CLEANUP_CONTRACT',
        '# END MANALOOM_VISUAL_CLEANUP_CONTRACT',
      );
      expect(cleanup, isNot(contains('|| true')));
      for (final required in const [
        'manaloom.authenticated_visual_cleanup_summary.v1',
        'manaloom.authenticated_visual_cleanup_receipt.v1',
        'backend_cleanup_receipt_invalid',
        'chromedriver_listener_residual',
        'chromedriver_process_residual',
        'credentials_remove_failed',
        'capability_policy_remove_failed',
        'web_build_remove_failed',
        'cleanup_invocations: 1',
        r'chmod 600 "$temp_file"',
        r'mv "$temp_file" "$GLOBAL_CLEANUP_RECEIPT"',
      ]) {
        expect(cleanup, contains(required), reason: required);
      }

      final performStart = cleanup.indexOf('perform_visual_cleanup_once()');
      final performEnd = cleanup.indexOf(
        '\n}\n\non_visual_exit()',
        performStart,
      );
      final perform = cleanup.substring(performStart, performEnd);
      final backendStop = perform.indexOf(
        'terminate_visual_owned_process_group \\\n    "backend"',
      );
      final backendValidation = perform.indexOf(
        'if validate_backend_cleanup_receipt',
      );
      final webStop = perform.indexOf(
        'terminate_visual_owned_process_group "web"',
      );
      final artifactRemoval = perform.indexOf(
        'remove_visual_artifacts_and_prove_absent',
      );
      final summaryWrite = perform.indexOf(
        r'write_visual_cleanup_summary "$original_status" "$final_status"',
      );
      final globalWrite = perform.indexOf(
        r'write_global_cleanup_receipt "$original_status"',
      );
      expect(backendStop, greaterThan(0));
      expect(backendValidation, greaterThan(backendStop));
      expect(webStop, greaterThan(backendValidation));
      expect(artifactRemoval, greaterThan(webStop));
      expect(summaryWrite, greaterThan(artifactRemoval));
      expect(globalWrite, greaterThan(summaryWrite));
      expect(fixtureSource, contains('trap on_visual_exit EXIT'));
      expect(fixtureSource, contains('readonly CHROMEDRIVER_PORT=4444'));
      expect(
        fixtureSource,
        contains(r'export MANALOOM_PARENT_VISUAL_RUN_ID="$RUN_ID"'),
      );
    });

    test(
      'validates positive and hostile backend receipts without PG',
      () async {
        final start = fixtureSource.indexOf(
          'validate_backend_cleanup_receipt() {',
        );
        final end = fixtureSource.indexOf(
          '\n}\n\nprobe_database_absence()',
          start,
        );
        expect(start, greaterThan(0));
        expect(end, greaterThan(start));
        final validator = fixtureSource.substring(start, end + 2);
        final tempRoot = Directory.systemTemp.createTempSync(
          'manaloom_cleanup_receipt_validator.',
        );
        try {
          final runDir = Directory('${tempRoot.path}/backend-run')
            ..createSync();
          final receipt = File('${runDir.path}/backend-cleanup-receipt.json');
          final script = File('${tempRoot.path}/validate.sh')
            ..writeAsStringSync(
              '#!/bin/bash\nset -euo pipefail\n$validator\n'
              'validate_backend_cleanup_receipt "\$1" "\$2" "\$3" '
              '"\$4" "\$5" "\$6" "\$7"\n',
            );
          const runId = 'backend_run_1';
          const parentRunId = 'visual_run_1';
          const database = 'manaloom_s1_api_backend_run_1';
          const apiPort = '61234';
          const emailPort = '61235';
          final valid = <String, Object?>{
            'schema': 'manaloom.server_contract_e2e_cleanup_receipt.v1',
            'status': 'PASS_CLEANUP',
            'run_id': runId,
            'parent_visual_run_id': parentRunId,
            'run_dir': runDir.path,
            'database': database,
            'api_port': int.parse(apiPort),
            'email_port': int.parse(emailPort),
            'original_exit_code': 143,
            'checks': <String, Object?>{
              'database_remaining': 0,
              'api_listeners': 0,
              'email_listeners': 0,
              'server_process_group_remaining': 0,
              'email_process_group_remaining': 0,
              'build_remaining': 0,
              'dart_frog_remaining': 0,
              'governed_temp_remaining': 0,
            },
            'cleanup_invocations': 1,
            'idempotent': true,
          };

          Future<ProcessResult> validate() => Process.run('/bin/bash', [
            script.path,
            receipt.path,
            runId,
            parentRunId,
            runDir.path,
            database,
            apiPort,
            emailPort,
          ]);

          receipt.writeAsStringSync(jsonEncode(valid));
          expect((await validate()).exitCode, 0);

          receipt.deleteSync();
          expect((await validate()).exitCode, isNot(0), reason: 'missing');

          receipt.writeAsStringSync('{not-json');
          expect((await validate()).exitCode, isNot(0), reason: 'malformed');

          receipt.writeAsStringSync(
            jsonEncode(<String, Object?>{...valid, 'run_id': 'other_run'}),
          );
          expect((await validate()).exitCode, isNot(0), reason: 'cross-run');

          final residualChecks = Map<String, Object?>.from(
            valid['checks']! as Map<String, Object?>,
          )..['database_remaining'] = 1;
          receipt.writeAsStringSync(
            jsonEncode(<String, Object?>{...valid, 'checks': residualChecks}),
          );
          expect((await validate()).exitCode, isNot(0), reason: 'residual');

          final outside = File('${tempRoot.path}/outside.json')
            ..writeAsStringSync(jsonEncode(valid));
          receipt.deleteSync();
          Link(receipt.path).createSync(outside.path);
          expect((await validate()).exitCode, isNot(0), reason: 'symlink');
        } finally {
          tempRoot.deleteSync(recursive: true);
        }
      },
    );

    test(
      'backend process ownership detects kill, wait and residual failures',
      () async {
        final cleanup = markedBlock(
          serverFixtureSource,
          '# BEGIN MANALOOM_BACKEND_CLEANUP_CONTRACT',
          '# END MANALOOM_BACKEND_CLEANUP_CONTRACT',
        );
        final tempRoot = Directory.systemTemp.createTempSync(
          'manaloom_cleanup_process_faults.',
        );
        try {
          final script = File('${tempRoot.path}/faults.sh');
          script.writeAsStringSync(
            '#!/bin/bash\nset -u\n$cleanup\n'
            r'''
CLEANUP_FAILURE_COUNT=0
CLEANUP_FAILURES=""
OWNED_GROUP_REMAINING="unknown"
scenario="$1"
counter="$2"
printf '0\n' >"$counter"
seq() { printf '1\n'; }
sleep() { :; }
process_group_count() {
  local calls
  calls="$(cat "$counter")"
  calls=$((calls + 1))
  printf '%s\n' "$calls" >"$counter"
  case "$scenario" in
    residual) printf '1' ;;
    *) if [[ "$calls" == "1" ]]; then printf '1'; else printf '0'; fi ;;
  esac
}
send_owned_signal() {
  [[ "$scenario" != "kill_failure" ]]
}
wait_owned_process() {
  [[ "$scenario" != "wait_failure" ]] || return 127
}
terminate_owned_process_group probe 4242 4242
status="$?"
case "$scenario" in
  success)
    [[ "$status" == "0" && "$CLEANUP_FAILURE_COUNT" == "0" ]]
    ;;
  kill_failure)
    [[ "$CLEANUP_FAILURES" == *probe_term_failed* ]]
    ;;
  wait_failure)
    [[ "$CLEANUP_FAILURES" == *probe_wait_failed* ]]
    ;;
  residual)
    [[ "$CLEANUP_FAILURES" == *probe_group_residual* ]]
    ;;
esac
''',
          );
          for (final scenario in const [
            'success',
            'kill_failure',
            'wait_failure',
            'residual',
          ]) {
            final result = await Process.run('/bin/bash', [
              script.path,
              scenario,
              '${tempRoot.path}/$scenario.counter',
            ]);
            expect(
              result.exitCode,
              0,
              reason: '$scenario\n${result.stdout}\n${result.stderr}',
            );
          }
        } finally {
          tempRoot.deleteSync(recursive: true);
        }
      },
    );

    test(
      'backend cleanup rejects database, listener and build residue',
      () async {
        final cleanup = markedBlock(
          serverFixtureSource,
          '# BEGIN MANALOOM_BACKEND_CLEANUP_CONTRACT',
          '# END MANALOOM_BACKEND_CLEANUP_CONTRACT',
        );
        final tempRoot = Directory.systemTemp.createTempSync(
          'manaloom_cleanup_residue_faults.',
        );
        try {
          final script = File('${tempRoot.path}/residue.sh');
          script.writeAsStringSync(
            '#!/bin/bash\nset -u\n$cleanup\n'
            r'''
CLEANUP_STATE="idle"
CLEANUP_FINAL_STATUS=1
CLEANUP_FAILURE_COUNT=0
CLEANUP_FAILURES=""
SERVER_PID=""
SERVER_PGID=""
EMAIL_FIXTURE_PID=""
EMAIL_FIXTURE_PGID=""
OWNED_GROUP_REMAINING="unknown"
SERVER_GROUP_REMAINING="unknown"
EMAIL_GROUP_REMAINING="unknown"
DATABASE_REMAINING="unknown"
API_LISTENERS="unknown"
EMAIL_LISTENERS="unknown"
BUILD_REMAINING="unknown"
DART_FROG_REMAINING="unknown"
GOVERNED_TEMP_REMAINING="unknown"
PORT="61001"
EMAIL_FIXTURE_PORT="61002"
BACKEND_CLEANUP_RECEIPT="$2"
scenario="$1"
receipt_calls=0
diagnostic_calls=0
terminate_owned_process_group() { OWNED_GROUP_REMAINING="0"; }
drop_owned_database_and_prove_absent() {
  if [[ "$scenario" == "database" ]]; then
    DATABASE_REMAINING="1"
    record_cleanup_failure "database_residual"
  else
    DATABASE_REMAINING="0"
  fi
}
listener_count() {
  if [[ "$scenario" == "listener" && "$1" == "$PORT" ]]; then
    printf '1'
  else
    printf '0'
  fi
}
remove_backend_artifacts_and_prove_absent() {
  DART_FROG_REMAINING="0"
  GOVERNED_TEMP_REMAINING="0"
  if [[ "$scenario" == "build" ]]; then
    BUILD_REMAINING="1"
    record_cleanup_failure "build_residual"
  else
    BUILD_REMAINING="0"
  fi
}
write_backend_cleanup_receipt() { receipt_calls=$((receipt_calls + 1)); }
write_backend_cleanup_diagnostic() { diagnostic_calls=$((diagnostic_calls + 1)); }
set +e
perform_backend_cleanup_once 0
first="$?"
perform_backend_cleanup_once 0
second="$?"
[[ "$first" == "1" && "$second" == "1" ]]
[[ "$receipt_calls" == "0" && "$diagnostic_calls" == "1" ]]
case "$scenario" in
  database) [[ "$CLEANUP_FAILURES" == *database_residual* ]] ;;
  listener) [[ "$CLEANUP_FAILURES" == *api_listener_residual* ]] ;;
  build) [[ "$CLEANUP_FAILURES" == *build_residual* ]] ;;
esac
''',
          );
          for (final scenario in const ['database', 'listener', 'build']) {
            final result = await Process.run('/bin/bash', [
              script.path,
              scenario,
              '${tempRoot.path}/$scenario-receipt.json',
            ]);
            expect(
              result.exitCode,
              0,
              reason: '$scenario\n${result.stdout}\n${result.stderr}',
            );
          }
        } finally {
          tempRoot.deleteSync(recursive: true);
        }
      },
    );

    test('cleanup workers preserve exit and execute effects once', () async {
      final backendCleanup = markedBlock(
        serverFixtureSource,
        '# BEGIN MANALOOM_BACKEND_CLEANUP_CONTRACT',
        '# END MANALOOM_BACKEND_CLEANUP_CONTRACT',
      );
      final visualCleanup = markedBlock(
        fixtureSource,
        '# BEGIN MANALOOM_VISUAL_CLEANUP_CONTRACT',
        '# END MANALOOM_VISUAL_CLEANUP_CONTRACT',
      );
      final tempRoot = Directory.systemTemp.createTempSync(
        'manaloom_cleanup_idempotence.',
      );
      try {
        final backendScript = File('${tempRoot.path}/backend.sh');
        backendScript.writeAsStringSync(
          '#!/bin/bash\nset -u\n$backendCleanup\n'
          r'''
CLEANUP_STATE="idle"
CLEANUP_FINAL_STATUS=1
CLEANUP_FAILURE_COUNT=0
CLEANUP_FAILURES=""
SERVER_PID=""
SERVER_PGID=""
EMAIL_FIXTURE_PID=""
EMAIL_FIXTURE_PGID=""
OWNED_GROUP_REMAINING="unknown"
SERVER_GROUP_REMAINING="unknown"
EMAIL_GROUP_REMAINING="unknown"
DATABASE_REMAINING="unknown"
API_LISTENERS="unknown"
EMAIL_LISTENERS="unknown"
BUILD_REMAINING="unknown"
DART_FROG_REMAINING="unknown"
GOVERNED_TEMP_REMAINING="unknown"
PORT="61001"
EMAIL_FIXTURE_PORT="61002"
BACKEND_CLEANUP_RECEIPT="$1"
receipt_calls=0
diagnostic_calls=0
terminate_owned_process_group() { OWNED_GROUP_REMAINING="0"; }
drop_owned_database_and_prove_absent() { DATABASE_REMAINING="0"; }
listener_count() { printf '0'; }
remove_backend_artifacts_and_prove_absent() {
  BUILD_REMAINING="0"
  DART_FROG_REMAINING="0"
  GOVERNED_TEMP_REMAINING="0"
}
write_backend_cleanup_receipt() { receipt_calls=$((receipt_calls + 1)); }
write_backend_cleanup_diagnostic() { diagnostic_calls=$((diagnostic_calls + 1)); }
set +e
perform_backend_cleanup_once 7
first="$?"
perform_backend_cleanup_once 7
second="$?"
[[ "$first" == "7" && "$second" == "7" ]]
[[ "$receipt_calls" == "1" && "$diagnostic_calls" == "0" ]]

CLEANUP_STATE="idle"
CLEANUP_FINAL_STATUS=1
CLEANUP_FAILURE_COUNT=0
CLEANUP_FAILURES=""
receipt_calls=0
diagnostic_calls=0
drop_owned_database_and_prove_absent() {
  DATABASE_REMAINING="1"
  record_cleanup_failure "dropdb_failed"
}
perform_backend_cleanup_once 0
failed="$?"
[[ "$failed" == "1" && "$receipt_calls" == "0" ]]
[[ "$diagnostic_calls" == "1" ]]
''',
        );
        final backendResult = await Process.run('/bin/bash', [
          backendScript.path,
          '${tempRoot.path}/backend-cleanup-receipt.json',
        ]);
        expect(
          backendResult.exitCode,
          0,
          reason: '${backendResult.stdout}\n${backendResult.stderr}',
        );

        final backendReceipt = File('${tempRoot.path}/backend-receipt.json')
          ..writeAsStringSync('{}');
        final visualScript = File('${tempRoot.path}/visual.sh');
        visualScript.writeAsStringSync(
          '#!/bin/bash\nset -u\n$visualCleanup\n'
          r'''
CLEANUP_STATE="idle"
CLEANUP_FINAL_STATUS=1
CLEANUP_FAILURE_COUNT=0
CLEANUP_FAILURES=""
BACKEND_PID=""
BACKEND_PGID=""
WEB_PID=""
WEB_PGID=""
OWNED_GROUP_REMAINING="unknown"
BACKEND_GROUP_REMAINING="unknown"
WEB_GROUP_REMAINING="unknown"
BACKEND_CLEANUP_RECEIPT="$1"
BACKEND_CLEANUP_RECEIPT_SHA256=""
BACKEND_RUN_ID="backend"
BACKEND_RUN_DIR="/tmp/backend"
BACKEND_API_PORT="61001"
BACKEND_EMAIL_PORT="61002"
RUN_ID="visual"
DATABASE="db"
DATABASE_REMAINING="unknown"
API_LISTENERS="unknown"
WEB_LISTENERS="unknown"
CHROMEDRIVER_LISTENERS="unknown"
CHROMEDRIVER_PROCESSES="unknown"
BACKEND_RECEIPT_STATUS="not_checked"
CREDENTIALS_FILE_REMOVED="false"
CAPABILITY_POLICY_FILE_REMOVED="false"
WEB_BUILD_REMAINING="unknown"
summary_calls=0
global_calls=0
terminate_visual_owned_process_group() { OWNED_GROUP_REMAINING="0"; }
validate_backend_cleanup_receipt() { return 0; }
probe_database_absence() { DATABASE_REMAINING="0"; }
probe_visual_boundaries() {
  API_LISTENERS="0"
  WEB_LISTENERS="0"
  CHROMEDRIVER_LISTENERS="0"
  CHROMEDRIVER_PROCESSES="0"
}
remove_visual_artifacts_and_prove_absent() {
  CREDENTIALS_FILE_REMOVED="true"
  CAPABILITY_POLICY_FILE_REMOVED="true"
  WEB_BUILD_REMAINING="0"
}
write_visual_cleanup_summary() { summary_calls=$((summary_calls + 1)); }
write_global_cleanup_receipt() { global_calls=$((global_calls + 1)); }
set +e
perform_visual_cleanup_once 9
first="$?"
perform_visual_cleanup_once 9
second="$?"
[[ "$first" == "9" && "$second" == "9" ]]
[[ "$summary_calls" == "1" && "$global_calls" == "1" ]]
''',
        );
        final visualResult = await Process.run('/bin/bash', [
          visualScript.path,
          backendReceipt.path,
        ]);
        expect(
          visualResult.exitCode,
          0,
          reason: '${visualResult.stdout}\n${visualResult.stderr}',
        );
      } finally {
        tempRoot.deleteSync(recursive: true);
      }
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
