// ignore_for_file: depend_on_referenced_packages, implementation_imports

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dart_frog_cli/src/commands/build/templates/dart_frog_prod_server_bundle.dart';
import 'package:mason/mason.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

import '../../scripts/manaloom_dart_frog_offline_build.dart' as adapter;

void main() {
  final serverDirectory = Directory.current;
  final repositoryRoot = serverDirectory.parent;
  final shellAdapter = File(
    '${repositoryRoot.path}/scripts/manaloom_dart_frog_offline_build.sh',
  );
  final dartAdapter = File(
    '${repositoryRoot.path}/scripts/manaloom_dart_frog_offline_build.dart',
  );
  final isolatedHarness = File(
    '${repositoryRoot.path}/scripts/manaloom_server_contract_e2e_isolated.sh',
  );
  final uiDigest = File(
    '${repositoryRoot.path}/scripts/manaloom_ui_source_digest.sh',
  );

  late Map<String, dynamic> packageConfig;
  late Map<String, dynamic> packageGraph;
  late Map<Object?, Object?> pubspec;
  late Map<Object?, Object?> pubspecLock;

  setUpAll(() {
    for (final file in [shellAdapter, dartAdapter, isolatedHarness, uiDigest]) {
      expect(file.existsSync(), isTrue, reason: file.path);
    }
    packageConfig =
        jsonDecode(File('.dart_tool/package_config.json').readAsStringSync())
            as Map<String, dynamic>;
    packageGraph =
        jsonDecode(File('.dart_tool/package_graph.json').readAsStringSync())
            as Map<String, dynamic>;
    pubspec = _plainMap(loadYaml(File('pubspec.yaml').readAsStringSync()));
    pubspecLock = _plainMap(loadYaml(File('pubspec.lock').readAsStringSync()));
  });

  adapter.PinnedMetadata metadata({
    Map<String, dynamic>? config,
    Map<String, dynamic>? graph,
    Map<Object?, Object?>? spec,
    Map<Object?, Object?>? lock,
    String dartVersion = adapter.expectedDartVersion,
    String flutterVersion = adapter.expectedFlutterVersion,
    bool buildExists = false,
    bool dartFrogStateExists = false,
  }) {
    return adapter.PinnedMetadata(
      packageConfig: config ?? _jsonCopy(packageConfig),
      packageGraph: graph ?? _jsonCopy(packageGraph),
      pubspec: spec ?? _deepCopy(pubspec) as Map<Object?, Object?>,
      pubspecLock: lock ?? _deepCopy(pubspecLock) as Map<Object?, Object?>,
      dartVersion: dartVersion,
      flutterVersion: flutterVersion,
      buildExists: buildExists,
      dartFrogStateExists: dartFrogStateExists,
    );
  }

  group('first-party updater-free wiring', () {
    test('shell accepts only build and invokes the pinned helper', () {
      final shell = shellAdapter.readAsStringSync();
      expect(shell, contains(r'[[ "$#" -ne 1 || "$1" != "build" ]]'));
      expect(shell, contains('manaloom_dart_frog_offline_build.dart'));
      expect(shell, contains(r'--packages="$PACKAGE_CONFIG"'));
      expect(shell, contains('(deny network*)'));
      expect(
        RegExp(r'^\s*sandbox-exec -p ', multiLine: true).allMatches(shell),
        hasLength(2),
      );
      final versionSandbox = shell.indexOf(
        "sandbox-exec -p '(version 1) (allow default) (deny network*)'",
      );
      final versionDart = shell.indexOf(
        r'"$DART_BIN" --version',
        versionSandbox,
      );
      final helperSandbox = shell.indexOf(
        r'sandbox-exec -p "$NETWORK_SANDBOX_PROFILE"',
      );
      final helperDart = shell.indexOf(r'"$DART_BIN"', helperSandbox);
      final helperPackages = shell.indexOf(
        r'--packages="$PACKAGE_CONFIG"',
        helperDart,
      );
      final helperBuild = shell.indexOf(
        r'"$HELPER" build "$SERVER_DIR"',
        helperPackages,
      );
      for (final index in [
        versionSandbox,
        versionDart,
        helperSandbox,
        helperDart,
        helperPackages,
        helperBuild,
      ]) {
        expect(index, greaterThanOrEqualTo(0));
      }
      expect(versionSandbox, lessThan(versionDart));
      expect(helperSandbox, lessThan(helperDart));
      expect(helperDart, lessThan(helperPackages));
      expect(helperPackages, lessThan(helperBuild));
      expect(shell, contains('PATH="/usr/bin:/bin"'));
      expect(shell, contains('DART_DISABLE_ANALYTICS=1'));
      expect(shell, contains('EXPECTED_DART_VM_SHA256'));
      expect(shell, contains('EXPECTED_DARTDEV_SNAPSHOT_SHA256'));
      expect(shell, contains('EXPECTED_DART_SDK_TREE_SHA256'));
      expect(shell, contains('ADAPTER_PUBLISHED_INODE'));
      expect(shell, contains('MANALOOM_OFFLINE_BUILD_OWNER_NONCE'));
      expect(shell, contains('MANALOOM_OFFLINE_BUILD_HELPER_SHA256'));
      expect(shell, contains('MANALOOM_OFFLINE_BUILD_PACKAGE_CONFIG_SHA256'));
      expect(shell, contains('MANALOOM_OFFLINE_BUILD_PACKAGE_GRAPH_SHA256'));
      expect(shell, isNot(contains('dart_frog build')));
      expect(shell, isNot(contains('dart pub get')));
      expect(shell, isNot(contains('MasonGenerator.fromBundle')));
      expect(shell, isNot(contains('resolve_manaloom_dart')));
    });

    test(
      'Dart helper cannot run updater, resolver, process, or socket APIs',
      () {
        final source = dartAdapter.readAsStringSync();
        expect(source, contains('for (final bundledFile in bundle.files)'));
        expect(source, contains('template.runSubstitution('));
        expect(source, contains('DirectoryGeneratorTarget(stagingRoot)'));
        expect(source, contains('buildRouteConfiguration(stagingBuild)'));
        expect(source, contains('Directory.current = stagingBuild'));
        expect(source, contains('_validateBootstrapInputs('));
        expect(source, contains('_sourceTreeHashes(serverDirectory)'));
        expect(source, contains("label: 'source_before_template'"));
        expect(source, contains("label: 'source_before_publish'"));
        expect(source, contains("label: 'source_after_publish'"));
        expect(source, contains("'concurrent_build_publication'"));
        expect(source, contains('ownershipMarkerName'));
        expect(source, isNot(contains('DartFrogCommandRunner')));
        expect(source, isNot(contains('BuildCommand(')));
        expect(source, isNot(contains('ProdServerBuilder')));
        expect(source, isNot(contains('MasonGenerator.fromBundle')));
        expect(source, isNot(contains('MasonGenerator(')));
        expect(source, isNot(contains('Isolate.run')));
        expect(source, isNot(contains('.hooks.')));
        expect(source, isNot(contains('Process.run')));
        expect(source, isNot(contains('Process.start')));
        expect(source, isNot(contains('HttpClient')));
        expect(source, isNot(contains('Socket')));
        expect(source, isNot(contains('pub get')));
      },
    );

    test(
      'isolated harness uses the adapter and self-contained package config',
      () {
        final source = isolatedHarness.readAsStringSync();
        expect(source, contains('manaloom_dart_frog_offline_build.sh\" build'));
        expect(
          RegExp(
            r'^"\$ROOT_DIR/scripts/manaloom_dart_frog_offline_build\.sh" build \\$',
            multiLine: true,
          ).hasMatch(source),
          isTrue,
        );
        expect(
          RegExp(
            r'run_no_egress\s+\\\s*'
            r'"\$ROOT_DIR/scripts/manaloom_dart_frog_offline_build\.sh"\s+build',
          ).hasMatch(source),
          isFalse,
        );
        expect(
          source,
          contains(
            '--packages=\"\$SERVER_DIR/build/.dart_tool/package_config.json\"',
          ),
        );
        expect(source, contains('build_adapter=PASS_OFFLINE_BUILD_ADAPTER'));
        expect(source, contains('BUILD_OWNED=1'));
        expect(source, contains('build_tree_digest'));
        const adapterCall = 'manaloom_dart_frog_offline_build.sh" build';
        const adapterSummary = 'BUILD_ADAPTER_SUMMARY=';
        const adapterAttestation =
            '.classification == "PASS_OFFLINE_BUILD_ADAPTER"';
        const guardedDartConsumer = r'exec "${EGRESS_GUARD[@]}" "$DART_BIN"';
        final adapterCallIndex = source.indexOf(adapterCall);
        final adapterSummaryIndex = source.indexOf(adapterSummary);
        final adapterAttestationIndex = source.indexOf(adapterAttestation);
        final migrateIndex = source.indexOf(
          r'exec "${EGRESS_GUARD[@]}" "$DART_BIN" run bin/migrate.dart',
        );
        for (final index in [
          adapterCallIndex,
          adapterSummaryIndex,
          adapterAttestationIndex,
          migrateIndex,
        ]) {
          expect(index, greaterThanOrEqualTo(0));
        }
        expect(adapterCallIndex, lessThan(adapterSummaryIndex));
        expect(adapterSummaryIndex, lessThan(adapterAttestationIndex));
        expect(adapterAttestationIndex, lessThan(migrateIndex));
        expect(source.split(guardedDartConsumer).length - 1, 3);
        expect(source, contains('adapter offline não produziu atestado PASS'));
        expect(source, isNot(contains('resolve_manaloom_dart')));
        expect(source, isNot(contains('run_no_egress dart_frog build')));
      },
    );

    test('UI digest covers every versioned adapter input', () {
      final source = uiDigest.readAsStringSync();
      for (final requiredPath in const [
        'server/pubspec.yaml',
        'server/pubspec.lock',
        'server/test/manaloom_offline_dart_frog_build_adapter_contract_test.dart',
        'tools/manaloom_lints',
        'scripts/manaloom_dart_frog_offline_build.sh',
        'scripts/manaloom_dart_frog_offline_build.dart',
        'scripts/lib/manaloom_dart_toolchain.sh',
      ]) {
        expect(source, contains('\"$requiredPath\"'), reason: requiredPath);
      }
    });

    test('helper fails closed when wrapper attestations are absent', () async {
      final environment =
          Map<String, String>.from(Platform.environment)
            ..removeWhere((key, _) => key.startsWith('MANALOOM_OFFLINE_BUILD_'))
            ..['MANALOOM_OFFLINE_BUILD_FLUTTER_VERSION'] =
                adapter.expectedFlutterVersion;
      final result = await Process.run(
        Platform.resolvedExecutable,
        [
          '--packages=${File('.dart_tool/package_config.json').absolute.path}',
          dartAdapter.path,
          'build',
          serverDirectory.path,
        ],
        workingDirectory: repositoryRoot.path,
        environment: environment,
      );
      expect(result.exitCode, 66);
      expect(result.stderr, contains('bootstrap_attestation_missing'));
      expect(Directory('build').existsSync(), isFalse);
      expect(
        Directory('.dart_tool/manaloom_offline_build_adapter').existsSync(),
        isFalse,
      );
    });
  });

  group('pinned metadata validation', () {
    test('accepts the cleanroom documents and exact toolchain', () {
      expect(() => adapter.validatePinnedMetadata(metadata()), returnsNormally);
    });

    test(
      'rejects all canonical implementation version values when changed',
      () {
        for (final entry in adapter.expectedPackageVersions.entries) {
          final graph = _jsonCopy(packageGraph);
          final package = (graph['packages'] as List<dynamic>)
              .cast<Map<String, dynamic>>()
              .singleWhere((candidate) => candidate['name'] == entry.key);
          package['version'] = '0.0.0-test';
          expect(
            () => adapter.validatePinnedMetadata(metadata(graph: graph)),
            throwsA(isA<adapter.OfflineBuildFailure>()),
            reason: entry.key,
          );
        }
      },
    );

    test('rejects lock version and checksum divergence', () {
      final changedVersion = _deepCopy(pubspecLock) as Map<Object?, Object?>;
      final packages = changedVersion['packages']! as Map<Object?, Object?>;
      final cli = packages['dart_frog_cli']! as Map<Object?, Object?>;
      cli['version'] = '1.2.13';
      expect(
        () => adapter.validatePinnedMetadata(metadata(lock: changedVersion)),
        throwsA(isA<adapter.OfflineBuildFailure>()),
      );

      final changedHash = _deepCopy(pubspecLock) as Map<Object?, Object?>;
      final changedPackages = changedHash['packages']! as Map<Object?, Object?>;
      final frog = changedPackages['dart_frog']! as Map<Object?, Object?>;
      final description = frog['description']! as Map<Object?, Object?>;
      description['sha256'] = List<String>.filled(64, '0').join();
      expect(
        () => adapter.validatePinnedMetadata(metadata(lock: changedHash)),
        throwsA(isA<adapter.OfflineBuildFailure>()),
      );
    });

    test(
      'rejects package_config generator, root, removal, and duplication',
      () {
        final generator = _jsonCopy(packageConfig)
          ..['generatorVersion'] = '3.12.1';
        expect(
          () => adapter.validatePinnedMetadata(metadata(config: generator)),
          throwsA(isA<adapter.OfflineBuildFailure>()),
        );

        final root = _jsonCopy(packageConfig);
        final rootPackages =
            (root['packages'] as List<dynamic>).cast<Map<String, dynamic>>();
        rootPackages.singleWhere(
              (item) => item['name'] == 'server',
            )['rootUri'] =
            '../../wrong';
        expect(
          () => adapter.validatePinnedMetadata(metadata(config: root)),
          throwsA(isA<adapter.OfflineBuildFailure>()),
        );

        final removed = _jsonCopy(packageConfig);
        (removed['packages'] as List<dynamic>).removeWhere(
          (item) => (item as Map<String, dynamic>)['name'] == 'mason',
        );
        expect(
          () => adapter.validatePinnedMetadata(metadata(config: removed)),
          throwsA(isA<adapter.OfflineBuildFailure>()),
        );

        final duplicated = _jsonCopy(packageConfig);
        final duplicatedPackages = duplicated['packages'] as List<dynamic>;
        duplicatedPackages.add(
          _jsonCopy(duplicatedPackages.first as Map<String, dynamic>),
        );
        expect(
          () => adapter.validatePinnedMetadata(metadata(config: duplicated)),
          throwsA(isA<adapter.OfflineBuildFailure>()),
        );
      },
    );

    test('rejects package graph root, closure, and version divergence', () {
      final roots = _jsonCopy(packageGraph)..['roots'] = ['other'];
      expect(
        () => adapter.validatePinnedMetadata(metadata(graph: roots)),
        throwsA(isA<adapter.OfflineBuildFailure>()),
      );

      final closure = _jsonCopy(packageGraph);
      (closure['packages'] as List<dynamic>).removeLast();
      expect(
        () => adapter.validatePinnedMetadata(metadata(graph: closure)),
        throwsA(isA<adapter.OfflineBuildFailure>()),
      );
    });

    test('rejects SDK, Flutter, build, and Dart Frog transient state', () {
      for (final changed in [
        metadata(dartVersion: '3.12.1'),
        metadata(flutterVersion: '3.44.5'),
        metadata(buildExists: true),
        metadata(dartFrogStateExists: true),
      ]) {
        expect(
          () => adapter.validatePinnedMetadata(changed),
          throwsA(isA<adapter.OfflineBuildFailure>()),
        );
      }
    });

    test('rejects an unapproved production path dependency', () {
      final changed = _deepCopy(pubspec) as Map<Object?, Object?>;
      final dependencies = changed['dependencies']! as Map<Object?, Object?>;
      dependencies['unapproved'] = <Object?, Object?>{'path': '../other'};
      expect(
        () => adapter.validatePinnedMetadata(metadata(spec: changed)),
        throwsA(isA<adapter.OfflineBuildFailure>()),
      );
    });
  });

  group('bundle, cache, and tree fail-closed behavior', () {
    test('accepts only the exact hook-free three-file bundle', () {
      expect(
        () => adapter.validateBundleContract(dartFrogProdServerBundle),
        returnsNormally,
      );
      final changedFiles = [...dartFrogProdServerBundle.files];
      final original = changedFiles.first;
      changedFiles[0] = MasonBundledFile(
        original.path,
        base64.encode(utf8.encode('{{% https://example.invalid/x %}}')),
        original.type,
      );
      final changedBundle = MasonBundle(
        name: dartFrogProdServerBundle.name,
        description: dartFrogProdServerBundle.description,
        version: dartFrogProdServerBundle.version,
        environment: dartFrogProdServerBundle.environment,
        vars: dartFrogProdServerBundle.vars,
        files: changedFiles,
        hooks: dartFrogProdServerBundle.hooks,
      );
      expect(
        () => adapter.validateBundleContract(changedBundle),
        throwsA(isA<adapter.OfflineBuildFailure>()),
      );
    });

    test(
      'cache digest mismatch, removal, and byte corruption are distinct',
      () {
        final directory = Directory.systemTemp.createTempSync(
          'manaloom_offline_adapter_contract.',
        );
        addTearDown(() => directory.deleteSync(recursive: true));
        final first = File('${directory.path}/a')..writeAsStringSync('alpha');
        final second = File('${directory.path}/b')..writeAsStringSync('beta');

        Map<String, String> hashes() => <String, String>{
          if (first.existsSync()) 'a': _sha256(first),
          if (second.existsSync()) 'b': _sha256(second),
        };

        final pinned = adapter.normalizedTreeDigest(hashes());
        second.writeAsStringSync('changed');
        final corrupt = adapter.normalizedTreeDigest(hashes());
        expect(corrupt, isNot(pinned));
        second.deleteSync();
        final missing = adapter.normalizedTreeDigest(hashes());
        expect(missing, isNot(pinned));
        expect(missing, isNot(corrupt));
        expect(
          () => adapter.validatePinnedDigest(
            label: 'hosted_cache',
            actual: corrupt,
            expected: pinned,
          ),
          throwsA(isA<adapter.OfflineBuildFailure>()),
        );
      },
    );

    test('tree digest is deterministic and path-sensitive', () {
      const left = <String, String>{'b': '2', 'a': '1'};
      const reordered = <String, String>{'a': '1', 'b': '2'};
      expect(
        adapter.normalizedTreeDigest(left),
        adapter.normalizedTreeDigest(reordered),
      );
      expect(
        adapter.normalizedTreeDigest(left),
        isNot(adapter.normalizedTreeDigest(const {'a': '2', 'b': '1'})),
      );
    });

    test('stale, secret-adjacent, and nested build artifacts are excluded', () {
      for (final sourcePath in const [
        '.dart_tool/package_config.json',
        '.dart_frog/state',
        'build/bin/server.dart',
        'build/build/server.dart',
        'cache/cards.json',
        'bin/__pycache__/tool.pyc',
        'test/.pytest_cache/state',
        'coverage/lcov.info',
        'trace.log',
      ]) {
        expect(
          adapter.excludesSourcePath(sourcePath),
          isTrue,
          reason: sourcePath,
        );
      }
      expect(adapter.excludesSourcePath('.env.example'), isFalse);
      expect(adapter.excludesSourcePath('routes/cards/index.dart'), isFalse);
    });

    test('credentials and legacy resolver state are rejected fail-closed', () {
      for (final sourcePath in const [
        '.env',
        '.env.local',
        '.env.production',
        '.credentials.env',
        '.packages',
        'firebase-service-account.json',
        'signing/release.jks',
        'signing/release.keystore',
        'signing/release.p12',
        'signing/release.pfx',
        'signing/release.mobileprovision',
      ]) {
        expect(
          adapter.isForbiddenSourcePath(sourcePath),
          isTrue,
          reason: sourcePath,
        );
      }
      expect(adapter.isForbiddenSourcePath('.env.example'), isFalse);
      expect(adapter.isForbiddenSourcePath('lib/config.dart'), isFalse);
    });
  });

  group('public command negatives do not reach the generator', () {
    test(
      'missing, extra, and nonallowlisted commands exit with usage',
      () async {
        for (final arguments in const <List<String>>[
          [],
          ['pub-get'],
          ['build', '--verbose'],
        ]) {
          final result = await Process.run('/bin/bash', [
            shellAdapter.path,
            ...arguments,
          ], workingDirectory: repositoryRoot.path);
          expect(result.exitCode, 64, reason: '$arguments: ${result.stderr}');
          expect(Directory('build').existsSync(), isFalse);
        }
      },
    );

    test('preexisting build sentinel is rejected without mutation', () async {
      final build = Directory('build');
      expect(build.existsSync(), isFalse);
      build.createSync();
      final sentinel = File('${build.path}/sentinel')
        ..writeAsStringSync('owned');
      addTearDown(() {
        if (build.existsSync()) build.deleteSync(recursive: true);
      });

      final result = await Process.run('/bin/bash', [
        shellAdapter.path,
        'build',
      ], workingDirectory: repositoryRoot.path);
      expect(result.exitCode, 66);
      expect(result.stderr, contains('preexisting_build'));
      expect(sentinel.readAsStringSync(), 'owned');
    });

    test('divergent toolchain fails before creating build', () async {
      final environment = Map<String, String>.from(Platform.environment)
        ..['MANALOOM_DART_BIN'] = '/usr/bin/false';
      final result = await Process.run(
        '/bin/bash',
        [shellAdapter.path, 'build'],
        workingDirectory: repositoryRoot.path,
        environment: environment,
      );
      expect(result.exitCode, isNot(0));
      expect(Directory('build').existsSync(), isFalse);
    });
  });
}

Map<String, dynamic> _jsonCopy(Map<String, dynamic> value) {
  return jsonDecode(jsonEncode(value)) as Map<String, dynamic>;
}

Object? _deepCopy(Object? value) {
  if (value is Map) {
    return <Object?, Object?>{
      for (final entry in value.entries) entry.key: _deepCopy(entry.value),
    };
  }
  if (value is List) return value.map(_deepCopy).toList();
  return value;
}

Map<Object?, Object?> _plainMap(Object? value) {
  final result = _deepCopy(value);
  if (result is! Map<Object?, Object?>) {
    throw StateError('expected YAML map');
  }
  return result;
}

String _sha256(File file) {
  return sha256.convert(file.readAsBytesSync()).toString();
}
