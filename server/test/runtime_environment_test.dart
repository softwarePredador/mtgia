import 'dart:io';

import 'package:server/runtime_environment.dart';
import 'package:test/test.dart';

void main() {
  test('process environment overrides values loaded from dotenv', () {
    final directory = Directory.systemTemp.createTempSync(
      'manaloom-runtime-environment-',
    );
    addTearDown(() => directory.deleteSync(recursive: true));
    final envFile = File('${directory.path}/test.env')..writeAsStringSync(
      'OPENAI_API_KEY=from-file\n'
      'ENVIRONMENT=development\n'
      'FILE_ONLY=retained\n',
    );

    final env = loadRuntimeEnvironment(
      filenames: [envFile.path],
      processEnvironment: const {
        'OPENAI_API_KEY': 'from-process',
        'ENVIRONMENT': 'production',
        'PROCESS_ONLY': 'retained',
      },
    );

    expect(env['OPENAI_API_KEY'], 'from-process');
    expect(env['ENVIRONMENT'], 'production');
    expect(env['FILE_ONLY'], 'retained');
    expect(env['PROCESS_ONLY'], 'retained');
  });

  test('missing dotenv file still preserves process configuration', () {
    final env = loadRuntimeEnvironment(
      filenames: const ['/definitely/missing/manaloom.env'],
      processEnvironment: const {'JWT_SECRET': 'runtime-secret'},
    );

    expect(env['JWT_SECRET'], 'runtime-secret');
  });

  test('runtime surfaces use the centralized environment loader', () {
    final serverRoot = Directory.current;
    final directLoaders = <String>[];

    for (final relativeRoot in const ['bin', 'lib', 'routes']) {
      final root = Directory('${serverRoot.path}/$relativeRoot');
      for (final entity in root.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        if (entity.path.endsWith('/lib/runtime_environment.dart')) continue;
        if (entity.readAsStringSync().contains('DotEnv(')) {
          directLoaders.add(
            entity.path.replaceFirst('${serverRoot.path}/', ''),
          );
        }
      }
    }

    expect(
      directLoaders,
      isEmpty,
      reason:
          'Direct DotEnv construction can let .env override container values. '
          'Use loadRuntimeEnvironment instead.',
    );
  });
}
