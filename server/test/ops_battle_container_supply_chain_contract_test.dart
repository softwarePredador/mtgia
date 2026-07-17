import 'dart:io';

import 'package:test/test.dart';

const _dartRuntime =
    'dart:3.12.2@sha256:'
    '13140e26d84f4fda57cea31942222112aeb2eec10e5e6874c1c0f70beed189ab';
const _mavenJava17Builder =
    'maven:3.9.16-eclipse-temurin-17-noble@sha256:'
    '1ed5d1f54416b706707b4f3238f63a20bb06aab27c6d240090a2bb9ad895ed45';
const _temurinJava17Runtime =
    'eclipse-temurin:17.0.19_10-jre-noble@sha256:'
    '543aebd60ff1deb9e906a8d4b117a7eda68a7f8e0d71041db2b5839d7fa057b8';

void main() {
  test('ManaLoom Ops uses the exact supported Dart runtime image', () {
    final dockerfile = File('Dockerfile.manaloom-ops').readAsStringSync();

    expect(dockerfile, startsWith('FROM $_dartRuntime\n'));
    _expectEveryBasePinned(dockerfile);
  });

  test('XMage build and runtime bases are exact and multi-arch capable', () {
    final dockerfile =
        File('../services/xmage-sidecar/Dockerfile').readAsStringSync();

    expect(dockerfile, startsWith('FROM $_mavenJava17Builder AS build\n'));
    expect(dockerfile, contains('FROM $_temurinJava17Runtime\n'));
    _expectEveryBasePinned(dockerfile);
  });

  test('Forge build and runtime bases match the XMage Java toolchain', () {
    final dockerfile =
        File('../services/forge-sidecar/Dockerfile').readAsStringSync();

    expect(
      dockerfile,
      startsWith('FROM $_mavenJava17Builder AS forge-build\n'),
    );
    expect(dockerfile, contains('FROM $_temurinJava17Runtime\n'));
    expect(
      dockerfile,
      contains('-DskipLaunch4j'),
      reason:
          'the Linux container consumes the Forge fat JAR and must not build '
          'the Windows Launch4j executable',
    );
    _expectEveryBasePinned(dockerfile);
  });
}

void _expectEveryBasePinned(String dockerfile) {
  final fromLines = dockerfile
      .split('\n')
      .where((line) => line.startsWith('FROM '))
      .toList(growable: false);
  expect(fromLines, isNotEmpty);
  for (final line in fromLines) {
    expect(
      line,
      matches(RegExp(r'^FROM [^ ]+@sha256:[0-9a-f]{64}(?: AS [^ ]+)?$')),
      reason: 'mutable container base: $line',
    );
  }
}
