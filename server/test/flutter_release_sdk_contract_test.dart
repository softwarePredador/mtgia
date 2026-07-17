import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('quality gate honors the explicitly selected Flutter SDK', () {
    final source = File('../scripts/quality_gate.sh').readAsStringSync();

    expect(source, contains(r'FLUTTER_BIN="${MANALOOM_FLUTTER_BIN:-flutter}"'));
    expect(source, contains(r'flutter_bin_dir="$(dirname "$FLUTTER_BIN")"'));
    expect(source, contains(r'export PATH="$flutter_bin_dir:$PATH"'));
    expect(source, contains(r'"$FLUTTER_BIN" analyze --no-fatal-infos'));
    expect(
      source,
      contains(r'"$FLUTTER_BIN" test --no-version-check --reporter compact'),
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
