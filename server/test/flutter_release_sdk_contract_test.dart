import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('quality gate honors the explicitly selected Flutter SDK', () {
    final source = File('../scripts/quality_gate.sh').readAsStringSync();

    expect(source, contains(r'FLUTTER_BIN="$MANALOOM_FLUTTER_BIN"'));
    expect(
      source,
      contains(
        r'PINNED_FLUTTER="$HOME/.manaloom/toolchains/flutter-3.44.6/bin/flutter"',
      ),
    );
    expect(source, contains('resolve_manaloom_dart'));
    expect(source, contains(r'flutter_bin_dir="$(dirname "$FLUTTER_BIN")"'));
    expect(
      source,
      contains(r'export PATH="$(dirname "$DART_BIN"):$flutter_bin_dir:$PATH"'),
    );
    expect(
      source,
      contains(r'"$FLUTTER_BIN" analyze --no-pub --no-fatal-infos'),
    );
    expect(
      source,
      contains(
        r'"$FLUTTER_BIN" test --no-pub --no-version-check --reporter compact',
      ),
    );
  });

  test('project logic and local gates require the pinned Dart SDK', () async {
    final helper =
        File(
          '../scripts/lib/manaloom_dart_toolchain.sh',
        ).absolute.resolveSymbolicLinksSync();
    final fixture = Directory.systemTemp.createTempSync(
      'manaloom-dart-toolchain-contract.',
    );
    try {
      final fakeDart = File('${fixture.path}/dart')
        ..writeAsStringSync('''#!/bin/sh
printf 'Dart SDK version: %s (stable) on "test"\\n' "\${FAKE_DART_VERSION}"
''');
      final chmod = Process.runSync('/bin/chmod', ['+x', fakeDart.path]);
      expect(chmod.exitCode, 0);

      Future<ProcessResult> resolve(String version) => Process.run(
        '/bin/bash',
        [
          '-c',
          'set -e; . "\$HELPER"; resolve_manaloom_dart; '
              'printf "%s\\n" "\$MANALOOM_DART_BIN_RESOLVED"',
        ],
        environment: {
          'PATH': '/usr/bin:/bin',
          'HELPER': helper,
          'MANALOOM_DART_BIN': fakeDart.path,
          'FAKE_DART_VERSION': version,
        },
      );

      final approved = await resolve('3.12.2');
      expect(approved.exitCode, 0);
      expect(
        File((approved.stdout as String).trim()).resolveSymbolicLinksSync(),
        fakeDart.resolveSymbolicLinksSync(),
      );

      final rejected = await resolve('3.11.4');
      expect(rejected.exitCode, 2);
      expect(rejected.stderr, contains('esperado 3.12.2'));
      expect(rejected.stderr, contains('encontrado 3.11.4'));
    } finally {
      fixture.deleteSync(recursive: true);
    }

    for (final path in [
      '../scripts/manaloom_project_logic.sh',
      '../scripts/manaloom_dart_doc.sh',
      '../scripts/manaloom_dart_mcp_preflight.sh',
      '../scripts/manaloom_tbls_local_gate.sh',
      '../scripts/manaloom_local_ci.sh',
    ]) {
      expect(File(path).readAsStringSync(), contains('resolve_manaloom_dart'));
    }
    final dartDoc = File('../scripts/manaloom_dart_doc.sh').readAsStringSync();
    expect(dartDoc, contains('resolve_manaloom_flutter_root'));
    expect(
      dartDoc,
      contains(r'export FLUTTER_ROOT="$MANALOOM_FLUTTER_ROOT_RESOLVED"'),
    );
  });

  test('release Flutter helper accepts only the pinned SDK', () async {
    final helper =
        File(
          '../scripts/lib/manaloom_flutter_release_sdk.sh',
        ).absolute.resolveSymbolicLinksSync();
    final fixture = Directory.systemTemp.createTempSync(
      'manaloom-flutter-sdk-contract.',
    );
    try {
      final fakeJq = File('${fixture.path}/jq')..writeAsStringSync('''#!/bin/sh
python3 -c 'import json,sys; print(json.load(sys.stdin)[sys.argv[1].lstrip(".")])' "\$2"
''');
      final sdkDirectory = Directory('${fixture.path}/sdk')..createSync();
      final callerDirectory = Directory('${fixture.path}/caller')..createSync();
      final fakeFlutter = File('${sdkDirectory.path}/flutter')
        ..writeAsStringSync('''#!/bin/sh
printf '{"frameworkVersion":"%s","frameworkRevision":"%s","engineRevision":"%s","dartSdkVersion":"%s"}\\n' \\
  "\${FAKE_FLUTTER_VERSION}" \\
  "\${FAKE_FLUTTER_REVISION}" \\
  "\${FAKE_ENGINE_REVISION}" \\
  "\${FAKE_DART_VERSION}"
''');
      final fakeDart = File('${sdkDirectory.path}/dart')
        ..writeAsStringSync('''#!/bin/sh
printf 'Dart from pinned Flutter SDK\\n'
''');
      for (final file in [fakeJq, fakeFlutter, fakeDart]) {
        final chmod = Process.runSync('/bin/chmod', ['+x', file.path]);
        expect(chmod.exitCode, 0);
      }

      Future<ProcessResult> resolve(String version) => Process.run(
        '/bin/bash',
        [
          '-c',
          'set -e; . "\$HELPER"; '
              'resolve_manaloom_release_flutter; '
              'printf "%s\\n" "\$MANALOOM_FLUTTER_BIN_RESOLVED"; '
              'printf "%s\\n" "\$MANALOOM_RELEASE_DART_BIN_RESOLVED"; '
              'cd /; '
              '"\$MANALOOM_FLUTTER_BIN_RESOLVED" --version --machine; '
              '"\$MANALOOM_RELEASE_DART_BIN_RESOLVED" --version',
        ],
        workingDirectory: callerDirectory.path,
        environment: {
          'PATH': '${fixture.path}:/usr/bin:/bin',
          'HELPER': helper,
          'MANALOOM_FLUTTER_BIN': '../sdk/flutter',
          'FAKE_FLUTTER_VERSION': version,
          'FAKE_FLUTTER_REVISION': 'ee80f08bbf97172ec030b8751ceab557177a34a6',
          'FAKE_ENGINE_REVISION': '83675ed27633283e7fc296c8bca22e841224c096',
          'FAKE_DART_VERSION': '3.12.2',
        },
      );

      final approved = await resolve('3.44.6');
      expect(approved.exitCode, 0);
      final approvedOutput = (approved.stdout as String).trim().split('\n');
      expect(approvedOutput.first, fakeFlutter.resolveSymbolicLinksSync());
      expect(approvedOutput[1], fakeDart.resolveSymbolicLinksSync());
      expect(
        approvedOutput[2],
        contains('"frameworkVersion":"3.44.6"'),
        reason: 'o caminho absoluto deve continuar valido depois de cd /',
      );
      expect(approvedOutput.last, 'Dart from pinned Flutter SDK');

      final rejected = await resolve('3.41.6');
      expect(rejected.exitCode, 2);
      expect(rejected.stderr, contains('esperado 3.44.6'));
      expect(rejected.stderr, contains('encontrado 3.41.6'));
    } finally {
      fixture.deleteSync(recursive: true);
    }
  });
}
