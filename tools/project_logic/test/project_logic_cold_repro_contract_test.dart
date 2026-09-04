import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:manaloom_project_logic/project_logic_generator.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

const _baseCommit = '406d7dd533f0ff0ae8294f8b9de94fecc07bf24e';
const _baseTree = '860242551a71c8733916208ff3f73bc11c26a965';
const _expectedFlutterVersion = '3.44.6';
const _expectedFlutterRevision = 'ee80f08bbf97172ec030b8751ceab557177a34a6';
const _expectedEngineRevision = '83675ed27633283e7fc296c8bca22e841224c096';
const _expectedDartVersion = '3.12.2';

const _sourcePaths = <String>[
  'scripts/manaloom_project_logic.sh',
  'scripts/quality_gate.ps1',
  'tools/project_logic/bin/manaloom_project_logic.dart',
  'tools/project_logic/lib/project_logic_generator.dart',
  'tools/project_logic/test/project_logic_generator_test.dart',
  'tools/project_logic/test/project_logic_cold_repro_contract_test.dart',
  'server/test/flutter_release_sdk_contract_test.dart',
];

const _outputPaths = <String>[
  'project_logic_manifest.json',
  'docs/generated/CURRENT_SYSTEM.md',
  'docs/generated/ARCHITECTURE.md',
  'docs/generated/FLOWS.md',
  'docs/generated/API_MAP.md',
  'docs/generated/openapi.generated.json',
  'docs/generated/DATABASE_ERD.md',
  'docs/generated/TRACEABILITY_MATRIX.md',
  'docs/generated/TASK_REGISTRY.json',
];

const _lockPaths = <String>[
  'pubspec.lock',
  'app/pubspec.lock',
  'server/pubspec.lock',
  'tools/project_logic/pubspec.lock',
  'tools/manaloom_lints/pubspec.lock',
];

void main() {
  test('declares the exact seven-source and nine-output boundary', () {
    expect(_sourcePaths, hasLength(7));
    expect(_sourcePaths.toSet(), hasLength(7));
    expect(_outputPaths, hasLength(9));
    expect(_outputPaths.toSet(), hasLength(9));
    expect(_outputPaths, ProjectLogicGenerator.outputPaths);
    expect(_sourcePaths.toSet().intersection(_outputPaths.toSet()), isEmpty);
  });

  test(
    'launcher installs cleanup before mutation and denies linked metadata',
    () {
      final root = _findWorkspaceRoot();
      final source = File(
        p.join(root.path, 'scripts', 'manaloom_project_logic.sh'),
      ).readAsStringSync();
      expect(source, contains('paths_overlap()'));
      expect(
        source.indexOf('trap early_cleanup EXIT'),
        lessThan(source.indexOf('mktemp -d')),
      );
      expect(
        source,
        contains('Caches Pub task-scoped e global não podem se sobrepor.'),
      );
      expect(
        source,
        contains('Metadata de pacote linked/não regular é proibida:'),
      );
    },
  );

  test(
    'launcher rejects cache ancestry in both directions before use',
    () async {
      final root = _findWorkspaceRoot();
      final fixture = Directory.systemTemp.createTempSync(
        'manaloom_project_logic_overlap_negative.',
      );
      addTearDown(() {
        if (fixture.existsSync()) fixture.deleteSync(recursive: true);
      });
      final nestedGlobal = Directory(p.join(fixture.path, 'global'))
        ..createSync();
      final nestedTask = p.join(nestedGlobal.path, 'task');
      final ancestorTask = Directory(p.join(fixture.path, 'task-parent'))
        ..createSync();
      final ancestorGlobal = Directory(p.join(ancestorTask.path, 'global'))
        ..createSync();
      final before = _treeFingerprint(fixture);

      for (final pair in [
        (global: nestedGlobal.path, task: nestedTask),
        (global: ancestorGlobal.path, task: ancestorTask.path),
      ]) {
        final environment = Map<String, String>.from(Platform.environment)
          ..['MANALOOM_PROJECT_LOGIC_GLOBAL_PUB_CACHE'] = pair.global
          ..['MANALOOM_PROJECT_LOGIC_TASK_PUB_CACHE'] = pair.task
          ..['MANALOOM_FLUTTER_ROOT'] = _pinnedFlutterRoot()
          ..['MANALOOM_DART_BIN'] = Platform.resolvedExecutable;
        final result = await Process.run(
          '/bin/bash',
          [
            p.join(root.path, 'scripts', 'manaloom_project_logic.sh'),
            '--check',
          ],
          workingDirectory: root.path,
          environment: environment,
        );
        expect(result.exitCode, 2);
        expect(result.stderr, contains('não podem se sobrepor'));
      }
      expect(Directory(nestedTask).existsSync(), isFalse);
      expect(_treeFingerprint(fixture), before);
    },
  );

  test(
    'launcher removes owned temporaries after early attestation failure',
    () async {
      final root = _findWorkspaceRoot();
      final fixture = Directory.systemTemp.createTempSync(
        'manaloom_project_logic_cleanup_negative.',
      );
      addTearDown(() {
        if (fixture.existsSync()) fixture.deleteSync(recursive: true);
      });
      final tempRoot = Directory(p.join(fixture.path, 'tmp'))..createSync();
      final emptyGlobal = Directory(p.join(fixture.path, 'global'))
        ..createSync();
      final environment = Map<String, String>.from(Platform.environment)
        ..remove('MANALOOM_PROJECT_LOGIC_TASK_PUB_CACHE')
        ..['TMPDIR'] = tempRoot.path
        ..['MANALOOM_PROJECT_LOGIC_GLOBAL_PUB_CACHE'] = emptyGlobal.path
        ..['MANALOOM_FLUTTER_ROOT'] = _pinnedFlutterRoot()
        ..['MANALOOM_DART_BIN'] = Platform.resolvedExecutable;

      final result = await Process.run(
        '/bin/bash',
        [p.join(root.path, 'scripts', 'manaloom_project_logic.sh'), '--check'],
        workingDirectory: root.path,
        environment: environment,
      );
      expect(result.exitCode, 2);
      expect(result.stderr, contains('Cache offline incompleto'));
      expect(tempRoot.listSync(), isEmpty);
      expect(emptyGlobal.listSync(), isEmpty);
    },
  );

  test('PowerShell static result is source-bound and runtime-limited', () {
    final proof = _powerShellStaticContract(_findWorkspaceRoot());
    expect(proof['status'], 'POWERSHELL_SOURCE_CONTRACT_PASS_STATIC');
    expect(proof['runtime_status'], 'WINDOWS_NOT_RUN');
    expect(() => _validatePowerShellStaticContract(proof), returnsNormally);
  });

  test(
    'runtime-path detector is targeted rather than a generic absolute regex',
    () {
      const payload = <String, Object?>{
        'api_routes': ['/capabilities', '/decks/:id'],
        'documentation': 'Use /tmp only for an isolated local gate.',
      };
      expect(
        _forbiddenRuntimeLeak(jsonEncode(payload), const [
          '/private/tmp/project-logic-cold-logical',
          '/private/tmp/project-logic-cache-logical',
        ]),
        isNull,
      );
      expect(
        _forbiddenRuntimeLeak(
          jsonEncode({'library': 'file:///private/tmp/source.dart'}),
          const <String>[],
        ),
        contains('file://'),
      );
      expect(
        _forbiddenRuntimeLeak(
          jsonEncode({'root': '/private/tmp/project-logic-cold-logical'}),
          const ['/private/tmp/project-logic-cold-logical'],
        ),
        '/private/tmp/project-logic-cold-logical',
      );
    },
  );

  test('receipt validator rejects malformed and cross-run evidence', () {
    final darwin = _samplePlatformReceipt(
      campaignId: 'campaign-a',
      platformRunId: 'darwin-a',
      platform: 'darwin',
      status: 'PASS_MACOS_COLD_REPRO',
    );
    expect(() => _validatePlatformReceipt(darwin), returnsNormally);

    final malformed = Map<String, Object?>.from(darwin)
      ..remove('cleanup_status');
    expect(
      () => _validatePlatformReceipt(malformed),
      throwsA(isA<FormatException>()),
    );

    final nonPass = _cloneMap(darwin)..['status'] = 'PARTIAL';
    expect(
      () => _validatePlatformReceipt(nonPass),
      throwsA(isA<FormatException>()),
    );

    final opaqueCell = _cloneMap(darwin);
    (opaqueCell['cells'] as List<dynamic>)[0] = {
      'cell_id': 'darwin_logical_tmp',
    };
    expect(
      () => _validatePlatformReceipt(opaqueCell),
      throwsA(isA<FormatException>()),
    );

    final linuxOtherCampaign = _samplePlatformReceipt(
      campaignId: 'campaign-b',
      platformRunId: 'linux-b',
      platform: 'linux',
      status: 'PASS_LINUX_COLD_REPRO',
    );
    expect(
      () => _aggregateReceipts(
        campaignId: 'campaign-a',
        darwin: darwin,
        linux: linuxOtherCampaign,
      ),
      throwsA(isA<FormatException>()),
    );

    final macOnly = _aggregateReceipts(
      campaignId: 'campaign-a',
      darwin: darwin,
    );
    expect(macOnly['status'], 'PASS_MACOS_COLD_REPRO');
    expect(macOnly['linux_status'], 'LINUX_NOT_RUN');
    expect(macOnly['windows_status'], 'WINDOWS_NOT_RUN');
    expect(
      macOnly['powershell_status'],
      'POWERSHELL_SOURCE_CONTRACT_PASS_STATIC',
    );
    expect(macOnly['cross_platform_status'], 'NOT_ESTABLISHED');

    final linux = _samplePlatformReceipt(
      campaignId: 'campaign-a',
      platformRunId: 'linux-a',
      platform: 'linux',
      status: 'PASS_LINUX_COLD_REPRO',
    );
    expect(
      _aggregateReceipts(
        campaignId: 'campaign-a',
        darwin: darwin,
        linux: linux,
      )['cross_platform_status'],
      'PASS_DARWIN_LINUX_COLD_REPRO',
    );

    final duplicateRun = _samplePlatformReceipt(
      campaignId: 'campaign-a',
      platformRunId: 'darwin-a',
      platform: 'linux',
      status: 'PASS_LINUX_COLD_REPRO',
    );
    expect(
      () => _aggregateReceipts(
        campaignId: 'campaign-a',
        darwin: darwin,
        linux: duplicateRun,
      ),
      throwsA(isA<FormatException>()),
    );

    final divergentLinux = Map<String, Object?>.from(linux)
      ..['source_digest_sha256'] = _repeatedHex('f');
    expect(
      () => _aggregateReceipts(
        campaignId: 'campaign-a',
        darwin: darwin,
        linux: divergentLinux,
      ),
      throwsA(isA<FormatException>()),
    );
  });

  test('cold campaign requires owned temporary and durable receipt roots', () {
    void validate(String temporary, String receipts, {bool owned = true}) =>
        _validateColdRootLayout(
          temporary,
          receipts,
          systemTemp: '/private/var/folders/test/T',
          owned: owned,
        );

    const temporary = '/private/tmp/manaloom_project_logic_cold_run.abc123';
    const receipts = '/Users/fixture/evidence/cold-run';
    expect(() => validate(temporary, receipts), returnsNormally);
    for (final invalid in [
      ('relative/root', receipts),
      ('/private/tmp/unowned', receipts),
      ('/Users/fixture/tmp', receipts),
      (temporary, 'relative/receipts'),
      (temporary, '/tmp/receipts'),
      (temporary, '/private/tmp/receipts'),
      (temporary, '/private/var/folders/test/T/receipts'),
      (temporary, '$temporary/receipts'),
      (temporary, '/private'),
    ]) {
      expect(
        () => validate(invalid.$1, invalid.$2),
        throwsA(isA<StateError>()),
      );
    }
    expect(
      () => validate(temporary, receipts, owned: false),
      throwsA(isA<StateError>()),
    );
  });

  if (Platform.environment['MANALOOM_RUN_PROJECT_LOGIC_COLD_REPRO'] == '1') {
    test(
      'runs independent Darwin logical and physical cold-first/second cells',
      _runDarwinCampaign,
      timeout: const Timeout(Duration(minutes: 60)),
    );
  }
}

void _validateColdRootLayout(
  String temporary,
  String receipts, {
  required String systemTemp,
  required bool owned,
}) {
  final paths = p.posix;
  bool within(String parent, String child) =>
      parent == child || paths.isWithin(parent, child);
  if (!owned ||
      !paths.isAbsolute(temporary) ||
      !paths.isAbsolute(receipts) ||
      paths.normalize(temporary) != temporary ||
      paths.normalize(receipts) != receipts ||
      paths.dirname(temporary) != '/private/tmp' ||
      !paths
          .basename(temporary)
          .startsWith('manaloom_project_logic_cold_run.') ||
      within('/tmp', receipts) ||
      within('/private/tmp', receipts) ||
      within(systemTemp, receipts) ||
      within(temporary, receipts) ||
      within(receipts, temporary)) {
    throw StateError('Cold campaign roots must be owned and receipts durable.');
  }
}

({String temporary, String receipts}) _coldCampaignRoots() {
  String resolve(String name) {
    final configured = Platform.environment[name];
    if (configured == null ||
        !p.isAbsolute(configured) ||
        FileSystemEntity.typeSync(configured, followLinks: false) !=
            FileSystemEntityType.directory) {
      throw StateError('Required owned cold campaign directory: $name');
    }
    return Directory(configured).resolveSymbolicLinksSync();
  }

  final temporary = resolve('MANALOOM_PROJECT_LOGIC_COLD_TEMP_ROOT');
  final receipts = resolve('MANALOOM_PROJECT_LOGIC_COLD_RECEIPT_ROOT');
  final token = Platform.environment['MANALOOM_PROJECT_LOGIC_COLD_OWNER_TOKEN'];
  bool owned(String root) {
    final marker = File(p.join(root, '.manaloom-cold-owner'));
    return token != null &&
        RegExp(r'^[a-zA-Z0-9._-]{16,160}$').hasMatch(token) &&
        FileSystemEntity.typeSync(marker.path, followLinks: false) ==
            FileSystemEntityType.file &&
        marker.readAsStringSync().trim() == token;
  }

  _validateColdRootLayout(
    temporary,
    receipts,
    systemTemp: Directory.systemTemp.resolveSymbolicLinksSync(),
    owned: owned(temporary) && owned(receipts),
  );
  return (temporary: temporary, receipts: receipts);
}

Future<void> _runDarwinCampaign() async {
  if (!Platform.isMacOS) {
    throw StateError(
      'The real campaign is Darwin-only; Linux must use an independent runner.',
    );
  }
  final sourceRoot = _findWorkspaceRoot();
  _assertWorkspaceBoundary(sourceRoot);

  final sourceHashesBefore = _hashPaths(sourceRoot, _sourcePaths);
  final outputHashesExpected = _hashPaths(sourceRoot, _outputPaths);
  final lockHashes = _hashPaths(sourceRoot, _lockPaths);
  final overlaySourceDigest = _hashMap(sourceHashesBefore);
  final manifest =
      jsonDecode(
            File(
              p.join(sourceRoot.path, 'project_logic_manifest.json'),
            ).readAsStringSync(),
          )
          as Map<String, dynamic>;
  final projectSourceDigest = manifest['source_digest_sha256'];
  if (projectSourceDigest is! String ||
      !RegExp(r'^[0-9a-f]{64}$').hasMatch(projectSourceDigest)) {
    throw StateError('Generated project source digest is absent or malformed.');
  }

  final toolchain = _readPinnedToolchain();
  final powerShellStaticContract = _powerShellStaticContract(sourceRoot);
  final campaignSeed = _hashText(
    [
      _baseCommit,
      _baseTree,
      projectSourceDigest,
      overlaySourceDigest,
      _hashMap(lockHashes),
      jsonEncode(toolchain),
      jsonEncode(powerShellStaticContract),
    ].join('\u0000'),
  );
  final runNonce = '${DateTime.now().toUtc().microsecondsSinceEpoch}-$pid';
  final campaignId = 'project-logic-cold-${campaignSeed.substring(0, 20)}';
  final platformRunId =
      'darwin-${_hashText('$campaignId\u0000$runNonce').substring(0, 20)}';
  final roots = _coldCampaignRoots();
  final receiptRoot = Directory(p.join(roots.receipts, platformRunId));
  if (receiptRoot.existsSync()) {
    throw StateError('Cross-run receipt directory already exists.');
  }
  receiptRoot.createSync(recursive: true);

  final logicalParent = p.join('/tmp', p.basename(roots.temporary));
  final logicalRoot = Directory(p.join(logicalParent, 'snapshot-L'));
  final physicalRoot = Directory(p.join(roots.temporary, 'snapshot-P'));
  final logicalCache = Directory(p.join(logicalParent, 'cache-L'));
  final physicalCache = Directory(p.join(roots.temporary, 'cache-P'));
  final owned = [logicalRoot, physicalRoot, logicalCache, physicalCache];
  for (final directory in owned) {
    if (directory.existsSync() || Link(directory.path).existsSync()) {
      throw StateError(
        'Cold campaign target already exists: ${directory.path}',
      );
    }
  }

  final archive = File(p.join(receiptRoot.path, 'base-tree.tar'));
  final cellReceipts = <Map<String, Object?>>[];
  Object? runError;
  StackTrace? runStack;
  try {
    _runChecked(
      '/usr/bin/git',
      ['archive', '--format=tar', '--output=${archive.path}', _baseCommit],
      workingDirectory: sourceRoot.path,
      label: 'git archive base snapshot',
    );
    for (final root in [logicalRoot, physicalRoot]) {
      root.createSync(recursive: true);
      _runChecked('/usr/bin/tar', [
        '-xf',
        archive.path,
        '-C',
        root.path,
      ], label: 'extract independent base snapshot');
      _applyOverlay(sourceRoot, root, _sourcePaths);
      _applyOverlay(sourceRoot, root, _outputPaths);
      _assertSnapshotInputs(root, sourceHashesBefore, outputHashesExpected);
    }
    archive.deleteSync();

    final logicalPhysical = logicalRoot.resolveSymbolicLinksSync();
    final physicalPhysical = physicalRoot.resolveSymbolicLinksSync();
    if (!logicalPhysical.startsWith('/private/tmp/') ||
        !physicalPhysical.startsWith('/private/tmp/') ||
        logicalPhysical == physicalPhysical) {
      throw StateError('Logical/physical snapshot roots are not independent.');
    }
    final logicalInode = _inode(p.join(logicalRoot.path, 'pubspec.yaml'));
    final physicalInode = _inode(p.join(physicalRoot.path, 'pubspec.yaml'));
    if (logicalInode == physicalInode) {
      throw StateError(
        'Logical/physical snapshots unexpectedly share an inode.',
      );
    }

    cellReceipts.add(
      await _runCell(
        id: 'darwin_logical_tmp',
        logicalRoot: logicalRoot,
        taskCache: logicalCache,
        receiptRoot: receiptRoot,
        expectedOutputs: outputHashesExpected,
      ),
    );
    cellReceipts.add(
      await _runCell(
        id: 'darwin_physical_tmp',
        logicalRoot: physicalRoot,
        taskCache: physicalCache,
        receiptRoot: receiptRoot,
        expectedOutputs: outputHashesExpected,
      ),
    );

    final firstOutputs = cellReceipts.first['output_hashes'];
    if (cellReceipts.any(
      (cell) => !_deepEqual(cell['output_hashes'], firstOutputs),
    )) {
      throw StateError(
        'Logical/physical cells emitted divergent output hashes.',
      );
    }
  } catch (error, stack) {
    runError = error;
    runStack = stack;
  } finally {
    final cleanupFailures = <String>[];
    if (archive.existsSync()) {
      try {
        archive.deleteSync();
      } on FileSystemException catch (error) {
        cleanupFailures.add('archive: $error');
      }
    }
    for (final directory in owned) {
      if (directory.existsSync() || Link(directory.path).existsSync()) {
        try {
          directory.deleteSync(recursive: true);
        } on FileSystemException catch (error) {
          cleanupFailures.add('${directory.path}: $error');
        }
      }
      if (directory.existsSync() || Link(directory.path).existsSync()) {
        cleanupFailures.add('residual: ${directory.path}');
      }
    }
    if (cleanupFailures.isNotEmpty) {
      throw StateError(
        'Cold campaign cleanup is incomplete: ${cleanupFailures.join('; ')}',
      );
    }
  }
  if (runError != null) {
    Error.throwWithStackTrace(runError, runStack!);
  }

  _assertWorkspaceBoundary(sourceRoot);
  final sourceHashesAfter = _hashPaths(sourceRoot, _sourcePaths);
  if (!_deepEqual(sourceHashesBefore, sourceHashesAfter)) {
    throw StateError('Source changed after the cold campaign freeze.');
  }
  if (cellReceipts.length != 2) {
    throw StateError('The Darwin campaign did not complete both cells.');
  }
  final snapshotFingerprint = cellReceipts.first['snapshot_fingerprint_sha256'];
  if (snapshotFingerprint is! String ||
      cellReceipts.any(
        (cell) => cell['snapshot_fingerprint_sha256'] != snapshotFingerprint,
      )) {
    throw StateError('Logical/physical snapshot fingerprints diverged.');
  }

  final platformReceipt = <String, Object?>{
    'schema': 'manaloom.project_logic_cold_repro_platform_receipt.v1',
    'campaign_id': campaignId,
    'platform_run_id': platformRunId,
    'platform': 'darwin',
    'status': 'PASS_MACOS_COLD_REPRO',
    'base_commit': _baseCommit,
    'base_tree': _baseTree,
    'source_digest_sha256': projectSourceDigest,
    'overlay_source_digest_sha256': overlaySourceDigest,
    'lock_hashes': lockHashes,
    'toolchain': toolchain,
    'seed_sha256': campaignSeed,
    'snapshot_fingerprint_sha256': snapshotFingerprint,
    'output_hashes': outputHashesExpected,
    'network_policy': 'sandbox-exec deny network*',
    'powershell_static_contract': powerShellStaticContract,
    'cells': cellReceipts,
    'cleanup_status': 'PASS_ZERO_OWNED_RESIDUE',
  };
  _validatePlatformReceipt(platformReceipt);
  final platformReceiptFile = File(
    p.join(receiptRoot.path, 'darwin-platform-receipt.json'),
  )..writeAsStringSync('${_canonicalJson(platformReceipt)}\n');

  final aggregate = _aggregateReceipts(
    campaignId: campaignId,
    darwin: platformReceipt,
  )..['darwin_receipt_sha256'] = _sha256File(platformReceiptFile);
  final aggregateFile = File(p.join(receiptRoot.path, 'aggregate-receipt.json'))
    ..writeAsStringSync('${_canonicalJson(aggregate)}\n');
  stdout.writeln('PROJECT_LOGIC_COLD_REPRO_RECEIPT=${receiptRoot.path}');
  stdout.writeln(
    'PROJECT_LOGIC_COLD_REPRO_AGGREGATE_SHA256=${_sha256File(aggregateFile)}',
  );
}

Future<Map<String, Object?>> _runCell({
  required String id,
  required Directory logicalRoot,
  required Directory taskCache,
  required Directory receiptRoot,
  required Map<String, String> expectedOutputs,
}) async {
  final physicalRoot = logicalRoot.resolveSymbolicLinksSync();
  final snapshotBefore = _treeFingerprint(logicalRoot);
  final runs = <Map<String, Object?>>[];
  for (final phase in const ['cold_first', 'cold_second']) {
    stdout.writeln('PROJECT_LOGIC_COLD_REPRO_CELL=$id PHASE=$phase');
    final result = await _runSandboxedCheck(
      logicalRoot: logicalRoot,
      taskCache: taskCache,
    );
    final stdoutText = result.stdout as String;
    final stderrText = result.stderr as String;
    final stdoutFile = File(p.join(receiptRoot.path, '$id-$phase.stdout.log'))
      ..writeAsStringSync(stdoutText);
    final stderrFile = File(p.join(receiptRoot.path, '$id-$phase.stderr.log'))
      ..writeAsStringSync(stderrText);
    if (result.exitCode != 0) {
      throw StateError(
        '$id/$phase failed with exit ${result.exitCode}: $stderrText',
      );
    }
    if (!stdoutText.contains('Project logic is synchronized (9 artifacts).')) {
      throw StateError('$id/$phase did not complete the nine-output check.');
    }
    _assertNoTransientPackageMetadata(logicalRoot);
    final snapshotAfter = _treeFingerprint(logicalRoot);
    if (snapshotAfter != snapshotBefore) {
      throw StateError('$id/$phase changed the frozen snapshot.');
    }
    final outputs = _hashPaths(logicalRoot, _outputPaths);
    if (!_deepEqual(outputs, expectedOutputs)) {
      throw StateError('$id/$phase output hashes diverged.');
    }
    _assertSemanticPayloadPortable(
      logicalRoot,
      forbiddenPaths: [
        logicalRoot.path,
        physicalRoot,
        taskCache.path,
        taskCache.absolute.path,
        taskCache.resolveSymbolicLinksSync(),
        Platform.environment['HOME'] == null
            ? ''
            : p.join(Platform.environment['HOME']!, '.pub-cache'),
        Platform.environment['HOME'] == null
            ? ''
            : Directory(
                p.join(Platform.environment['HOME']!, '.pub-cache'),
              ).resolveSymbolicLinksSync(),
        _pinnedFlutterRoot(),
      ],
    );
    runs.add({
      'phase': phase,
      'exit_code': result.exitCode,
      'stdout_sha256': _sha256File(stdoutFile),
      'stderr_sha256': _sha256File(stderrFile),
      'snapshot_fingerprint_sha256': snapshotAfter,
      'output_hashes': outputs,
    });
  }
  if (!_deepEqual(runs.first['output_hashes'], runs.last['output_hashes']) ||
      runs.first['snapshot_fingerprint_sha256'] !=
          runs.last['snapshot_fingerprint_sha256']) {
    throw StateError('$id cold-first and cold-second are not byte-identical.');
  }
  return <String, Object?>{
    'cell_id': id,
    'logical_root': logicalRoot.path,
    'physical_root': physicalRoot,
    'task_cache': taskCache.path,
    'snapshot_fingerprint_sha256': snapshotBefore,
    'output_hashes': expectedOutputs,
    'runs': runs,
  };
}

Future<ProcessResult> _runSandboxedCheck({
  required Directory logicalRoot,
  required Directory taskCache,
}) {
  final home = Platform.environment['HOME'];
  if (home == null || home.isEmpty) {
    throw StateError('HOME is required to locate the read-only Pub cache.');
  }
  final environment = Map<String, String>.from(Platform.environment)
    ..remove('PUB_CACHE')
    ..['CELL_ROOT'] = logicalRoot.path
    ..['MANALOOM_PROJECT_LOGIC_TASK_PUB_CACHE'] = taskCache.path
    ..['MANALOOM_PROJECT_LOGIC_GLOBAL_PUB_CACHE'] = p.join(home, '.pub-cache')
    ..['MANALOOM_FLUTTER_ROOT'] = _pinnedFlutterRoot()
    ..['MANALOOM_DART_BIN'] = Platform.resolvedExecutable
    ..['CI'] = 'true';
  return Process.run(
    '/usr/bin/sandbox-exec',
    const [
      '-p',
      '(version 1)(allow default)(deny network*)',
      '/bin/bash',
      '-c',
      r'cd -- "$CELL_ROOT"; exec ./scripts/manaloom_project_logic.sh --check',
    ],
    environment: environment,
    includeParentEnvironment: false,
  );
}

void _assertWorkspaceBoundary(Directory root) {
  final head = _git(root, ['rev-parse', 'HEAD']).trim();
  final tree = _git(root, ['rev-parse', 'HEAD^{tree}']).trim();
  if (head != _baseCommit || tree != _baseTree) {
    throw StateError('Cold proof base commit/tree diverged: $head / $tree.');
  }
  final staged = _git(root, [
    'diff',
    '--cached',
    '--name-only',
  ]).split('\n').where((value) => value.isNotEmpty).toSet();
  if (staged.isNotEmpty) {
    throw StateError('Cold proof refuses a non-empty index: $staged');
  }
  _runChecked(
    '/usr/bin/git',
    ['diff', '--check'],
    workingDirectory: root.path,
    label: 'git diff --check',
  );
  final tracked = _git(root, [
    'diff',
    '--name-only',
    'HEAD',
  ]).split('\n').where((value) => value.isNotEmpty).toSet();
  final untracked = _git(root, [
    'ls-files',
    '--others',
    '--exclude-standard',
  ]).split('\n').where((value) => value.isNotEmpty).toSet();
  final delta = <String>{...tracked, ...untracked};
  final allowed = <String>{..._sourcePaths, ..._outputPaths};
  final unexpected = delta.difference(allowed);
  if (unexpected.isNotEmpty) {
    throw StateError('Cold proof found an out-of-allowlist delta: $unexpected');
  }
  final missingSources = _sourcePaths.toSet().difference(delta);
  if (missingSources.isNotEmpty) {
    throw StateError(
      'Cold proof source overlay is incomplete: $missingSources',
    );
  }
  for (final path in [..._sourcePaths, ..._outputPaths, ..._lockPaths]) {
    final type = FileSystemEntity.typeSync(
      p.join(root.path, path),
      followLinks: false,
    );
    if (type != FileSystemEntityType.file) {
      throw StateError(
        'Required cold proof input is not a regular file: $path',
      );
    }
  }
}

void _assertSnapshotInputs(
  Directory root,
  Map<String, String> expectedSources,
  Map<String, String> expectedOutputs,
) {
  if (!_deepEqual(_hashPaths(root, _sourcePaths), expectedSources) ||
      !_deepEqual(_hashPaths(root, _outputPaths), expectedOutputs)) {
    throw StateError('Snapshot overlay bytes diverge from the frozen inputs.');
  }
  _assertNoTransientPackageMetadata(root);
}

void _assertNoTransientPackageMetadata(Directory root) {
  for (final relative in const ['', 'app', 'server', 'tools/project_logic']) {
    final dotTool = Directory(
      relative.isEmpty
          ? p.join(root.path, '.dart_tool')
          : p.join(root.path, relative, '.dart_tool'),
    );
    if (dotTool.existsSync() || Link(dotTool.path).existsSync()) {
      throw StateError(
        'Transient package metadata remains at ${dotTool.path}.',
      );
    }
  }
}

void _assertSemanticPayloadPortable(
  Directory root, {
  required List<String> forbiddenPaths,
}) {
  final manifest =
      jsonDecode(
            File(
              p.join(root.path, 'project_logic_manifest.json'),
            ).readAsStringSync(),
          )
          as Map<String, dynamic>;
  final payload = jsonEncode(manifest['semantic_analysis']);
  final leak = _forbiddenRuntimeLeak(payload, forbiddenPaths);
  if (leak != null) {
    throw StateError('Semantic payload leaked a runtime path: $leak');
  }
}

String? _forbiddenRuntimeLeak(String payload, Iterable<String> paths) {
  if (payload.contains('file://')) return 'file://';
  for (final raw in paths) {
    final value = raw.trim();
    if (value.length < 2) continue;
    for (final candidate in {
      value,
      p.normalize(value),
      value.replaceAll('\\', '/'),
    }) {
      if (candidate.length >= 2 && payload.contains(candidate)) {
        return candidate;
      }
    }
  }
  return null;
}

Map<String, Object?> _powerShellStaticContract(Directory root) {
  final sourceFile = File(p.join(root.path, 'scripts', 'quality_gate.ps1'));
  final contractFile = File(
    p.join(
      root.path,
      'server',
      'test',
      'flutter_release_sdk_contract_test.dart',
    ),
  );
  final source = sourceFile.readAsStringSync();
  final start = source.indexOf('function Run-ProjectLogic {');
  final end = source.indexOf('function Show-Usage {', start);
  if (start < 0 || end <= start) {
    throw StateError('PowerShell Run-ProjectLogic block is absent.');
  }
  final block = source.substring(start, end);
  final checks = <String, bool>{
    'pinned_flutter_version': source.contains(_expectedFlutterVersion),
    'pinned_flutter_revision': source.contains(_expectedFlutterRevision),
    'pinned_engine_revision': source.contains(_expectedEngineRevision),
    'pinned_dart_version': source.contains(_expectedDartVersion),
    'offline_enforce_lockfile': source.contains(
      '& \$DartBin pub get --offline --enforce-lockfile --no-precompile',
    ),
    'lints_lock_included': block.contains('tools/manaloom_lints/pubspec.lock'),
    'all_project_logic_dart_is_pinned':
        block.contains(r'$dartBin = $toolchain.DartBin') &&
        block.contains(r'& $dartBin test') &&
        block.contains(r'& $dartBin doc --dry-run') &&
        !RegExp(
          r'^\s*(?:dart|flutter)(?:\s|$)',
          multiLine: true,
        ).hasMatch(block),
    'task_global_cache_overlap_denied': source.contains(
      'Test-ProjectLogicPathsOverlap \$taskCache \$globalCache',
    ),
    'metadata_links_denied':
        block.contains(r'$metadataItem.LinkType') &&
        block.contains(r'$dotToolItem.LinkType'),
    'global_cache_fingerprinted':
        block.contains('Get-ProjectLogicCacheFingerprint') &&
        block.contains('Get-ProjectLogicActiveRootsFingerprint'),
    'metadata_restored_after_post_cli_checks':
        block.indexOf(r'& $dartBin test') < block.indexOf('finally {') &&
        block.contains(r'$state.ConfigBytes') &&
        block.contains(r'$state.GraphBytes'),
  };
  final failed = checks.entries
      .where((entry) => !entry.value)
      .map((entry) => entry.key)
      .toList();
  if (failed.isNotEmpty) {
    throw StateError('PowerShell static contract failed: ${failed.join(', ')}');
  }
  return <String, Object?>{
    'status': 'POWERSHELL_SOURCE_CONTRACT_PASS_STATIC',
    'runtime_status': 'WINDOWS_NOT_RUN',
    'source_sha256': _sha256File(sourceFile),
    'contract_test_sha256': _sha256File(contractFile),
    'checks_sha256': _hashText(_canonicalJson(checks)),
  };
}

Map<String, Object?> _readPinnedToolchain() {
  final flutterRoot = Directory(
    _pinnedFlutterRoot(),
  ).resolveSymbolicLinksSync();
  final versionFile = File(
    p.join(flutterRoot, 'bin', 'cache', 'flutter.version.json'),
  );
  final identity =
      jsonDecode(versionFile.readAsStringSync()) as Map<String, dynamic>;
  final expected = <String, String>{
    'frameworkVersion': _expectedFlutterVersion,
    'frameworkRevision': _expectedFlutterRevision,
    'engineRevision': _expectedEngineRevision,
    'dartSdkVersion': _expectedDartVersion,
  };
  for (final entry in expected.entries) {
    if (identity[entry.key] != entry.value) {
      throw StateError('Pinned toolchain ${entry.key} diverged.');
    }
  }
  final dart = File(Platform.resolvedExecutable).resolveSymbolicLinksSync();
  final expectedDart = File(
    p.join(flutterRoot, 'bin', 'cache', 'dart-sdk', 'bin', 'dart'),
  ).resolveSymbolicLinksSync();
  if (dart != expectedDart ||
      Platform.version.split(' ').first != _expectedDartVersion) {
    throw StateError('Cold proof is not running under the pinned Dart binary.');
  }
  return <String, Object?>{
    ...expected,
    'flutter_identity_sha256': _sha256File(versionFile),
    'dart_sha256': _sha256File(File(dart)),
    'git_sha256': _sha256File(File('/usr/bin/git')),
    'tar_sha256': _sha256File(File('/usr/bin/tar')),
    'sandbox_exec_sha256': _sha256File(File('/usr/bin/sandbox-exec')),
  };
}

String _pinnedFlutterRoot() {
  final configuredRoot = Platform.environment['MANALOOM_FLUTTER_ROOT']?.trim();
  if (configuredRoot != null && configuredRoot.isNotEmpty) {
    return configuredRoot;
  }
  final home = Platform.environment['HOME'];
  if (home == null || home.isEmpty) {
    throw StateError('HOME is required for the pinned Flutter toolchain.');
  }
  return p.join(home, '.manaloom', 'toolchains', 'flutter-3.44.6');
}

void _applyOverlay(
  Directory source,
  Directory destination,
  List<String> paths,
) {
  for (final relative in paths) {
    final input = File(p.join(source.path, relative));
    final output = File(p.join(destination.path, relative));
    if (FileSystemEntity.typeSync(input.path, followLinks: false) !=
        FileSystemEntityType.file) {
      throw StateError('Overlay input is not a regular file: $relative');
    }
    output.parent.createSync(recursive: true);
    input.copySync(output.path);
  }
}

Map<String, String> _hashPaths(Directory root, Iterable<String> paths) => {
  for (final relative in paths)
    relative: _sha256File(File(p.join(root.path, relative))),
};

String _sha256File(File file) =>
    sha256.convert(file.readAsBytesSync()).toString();

String _hashMap(Map<String, String> values) => _hashText(
  (values.entries.toList()..sort((a, b) => a.key.compareTo(b.key)))
      .map((entry) => '${entry.key}\u0000${entry.value}\u0000')
      .join(),
);

String _hashText(String value) => sha256.convert(utf8.encode(value)).toString();

String _treeFingerprint(Directory root) {
  final records = <String>[];
  final entities = root.listSync(recursive: true, followLinks: false)
    ..sort((left, right) => left.path.compareTo(right.path));
  for (final entity in entities) {
    final type = FileSystemEntity.typeSync(entity.path, followLinks: false);
    if (type != FileSystemEntityType.file &&
        type != FileSystemEntityType.link) {
      continue;
    }
    final relative = p
        .relative(entity.path, from: root.path)
        .replaceAll('\\', '/');
    if (type == FileSystemEntityType.link) {
      records.add(
        '$relative\u0000link\u0000${Link(entity.path).targetSync()}\u0000',
      );
    } else {
      final mode = FileStat.statSync(entity.path).mode & 0x1ff;
      records.add(
        '$relative\u0000file\u0000${mode.toRadixString(8)}\u0000'
        '${_sha256File(File(entity.path))}\u0000',
      );
    }
  }
  return _hashText(records.join());
}

String _inode(String path) => _runChecked('/usr/bin/stat', [
  '-f',
  '%i',
  path,
], label: 'inode check').stdout.toString().trim();

Directory _findWorkspaceRoot() {
  var current = Directory.current.absolute;
  while (true) {
    if (File(
          p.join(current.path, 'project_logic_manifest.json'),
        ).existsSync() &&
        File(
          p.join(current.path, 'tools', 'project_logic', 'pubspec.yaml'),
        ).existsSync()) {
      return Directory(current.resolveSymbolicLinksSync());
    }
    if (current.parent.path == current.path) {
      throw StateError('Unable to locate the ManaLoom workspace root.');
    }
    current = current.parent;
  }
}

String _git(Directory root, List<String> arguments) => _runChecked(
  '/usr/bin/git',
  arguments,
  workingDirectory: root.path,
  label: 'git ${arguments.join(' ')}',
).stdout.toString();

ProcessResult _runChecked(
  String executable,
  List<String> arguments, {
  String? workingDirectory,
  required String label,
}) {
  final result = Process.runSync(
    executable,
    arguments,
    workingDirectory: workingDirectory,
  );
  if (result.exitCode != 0) {
    throw StateError(
      '$label failed with exit ${result.exitCode}: ${result.stderr}',
    );
  }
  return result;
}

Map<String, Object?> _samplePlatformReceipt({
  required String campaignId,
  required String platformRunId,
  required String platform,
  required String status,
}) {
  final snapshot = _repeatedHex('6');
  final outputs = {
    for (final outputPath in _outputPaths) outputPath: _repeatedHex('e'),
  };
  final toolchain = <String, Object?>{
    'frameworkVersion': _expectedFlutterVersion,
    'frameworkRevision': _expectedFlutterRevision,
    'engineRevision': _expectedEngineRevision,
    'dartSdkVersion': _expectedDartVersion,
    'flutter_identity_sha256': _repeatedHex('1'),
    'dart_sha256': _repeatedHex('2'),
    'git_sha256': _repeatedHex('3'),
    'tar_sha256': _repeatedHex('4'),
    if (platform == 'darwin')
      'sandbox_exec_sha256': _repeatedHex('5')
    else
      'network_guard_sha256': _repeatedHex('5'),
  };
  final powerShell = <String, Object?>{
    'status': 'POWERSHELL_SOURCE_CONTRACT_PASS_STATIC',
    'runtime_status': 'WINDOWS_NOT_RUN',
    'source_sha256': _repeatedHex('7'),
    'contract_test_sha256': _repeatedHex('8'),
    'checks_sha256': _repeatedHex('9'),
  };
  Map<String, Object?> cell(String kind) {
    final cellId = '${platform}_${kind}_tmp';
    final root = '/tmp/project-logic-$platform-$kind';
    return <String, Object?>{
      'cell_id': cellId,
      'logical_root': root,
      'physical_root': '/private$root',
      'task_cache': '/tmp/project-logic-cache-$platform-$kind',
      'snapshot_fingerprint_sha256': snapshot,
      'output_hashes': outputs,
      'runs': [
        for (final phase in const ['cold_first', 'cold_second'])
          <String, Object?>{
            'phase': phase,
            'exit_code': 0,
            'stdout_sha256': _repeatedHex('a'),
            'stderr_sha256': _repeatedHex('b'),
            'snapshot_fingerprint_sha256': snapshot,
            'output_hashes': outputs,
          },
      ],
    };
  }

  return <String, Object?>{
    'schema': 'manaloom.project_logic_cold_repro_platform_receipt.v1',
    'campaign_id': campaignId,
    'platform_run_id': platformRunId,
    'platform': platform,
    'status': status,
    'base_commit': _baseCommit,
    'base_tree': _baseTree,
    'source_digest_sha256': _repeatedHex('a'),
    'overlay_source_digest_sha256': _repeatedHex('b'),
    'lock_hashes': {
      for (final lockPath in _lockPaths) lockPath: _repeatedHex('c'),
    },
    'toolchain': toolchain,
    'seed_sha256': _repeatedHex('d'),
    'snapshot_fingerprint_sha256': snapshot,
    'output_hashes': outputs,
    'network_policy': platform == 'darwin'
        ? 'sandbox-exec deny network*'
        : 'linux network namespace deny network*',
    'powershell_static_contract': powerShell,
    'cells': [cell('logical'), cell('physical')],
    'cleanup_status': 'PASS_ZERO_OWNED_RESIDUE',
  };
}

void _validatePlatformReceipt(Map<String, Object?> receipt) {
  const required = <String>{
    'schema',
    'campaign_id',
    'platform_run_id',
    'platform',
    'status',
    'base_commit',
    'base_tree',
    'source_digest_sha256',
    'overlay_source_digest_sha256',
    'lock_hashes',
    'toolchain',
    'seed_sha256',
    'snapshot_fingerprint_sha256',
    'output_hashes',
    'network_policy',
    'powershell_static_contract',
    'cells',
    'cleanup_status',
  };
  final platform = receipt['platform'];
  final expectedStatus = switch (platform) {
    'darwin' => 'PASS_MACOS_COLD_REPRO',
    'linux' => 'PASS_LINUX_COLD_REPRO',
    _ => null,
  };
  final expectedNetworkPolicy = switch (platform) {
    'darwin' => 'sandbox-exec deny network*',
    'linux' => 'linux network namespace deny network*',
    _ => null,
  };
  if (!receipt.keys.toSet().containsAll(required) ||
      receipt['schema'] !=
          'manaloom.project_logic_cold_repro_platform_receipt.v1' ||
      receipt['campaign_id'] is! String ||
      (receipt['campaign_id'] as String).isEmpty ||
      receipt['platform_run_id'] is! String ||
      (receipt['platform_run_id'] as String).isEmpty ||
      expectedStatus == null ||
      receipt['status'] != expectedStatus ||
      receipt['base_commit'] != _baseCommit ||
      receipt['base_tree'] != _baseTree ||
      receipt['network_policy'] != expectedNetworkPolicy ||
      receipt['cleanup_status'] != 'PASS_ZERO_OWNED_RESIDUE') {
    throw const FormatException('Malformed project logic platform receipt.');
  }
  for (final key in [
    'source_digest_sha256',
    'overlay_source_digest_sha256',
    'seed_sha256',
    'snapshot_fingerprint_sha256',
  ]) {
    _requireHex(receipt[key], 'platform receipt digest $key');
  }

  _validateHashMap(receipt['lock_hashes'], _lockPaths, 'lock hashes');
  _validateHashMap(receipt['output_hashes'], _outputPaths, 'output hashes');

  final toolchain = _requireObjectMap(receipt['toolchain'], 'toolchain');
  const expectedToolchain = <String, String>{
    'frameworkVersion': _expectedFlutterVersion,
    'frameworkRevision': _expectedFlutterRevision,
    'engineRevision': _expectedEngineRevision,
    'dartSdkVersion': _expectedDartVersion,
  };
  for (final entry in expectedToolchain.entries) {
    if (toolchain[entry.key] != entry.value) {
      throw FormatException('Toolchain mismatch at ${entry.key}.');
    }
  }
  final toolHashes = <String>{
    'flutter_identity_sha256',
    'dart_sha256',
    'git_sha256',
    'tar_sha256',
    if (platform == 'darwin') 'sandbox_exec_sha256' else 'network_guard_sha256',
  };
  for (final key in toolHashes) {
    _requireHex(toolchain[key], 'toolchain $key');
  }
  _validatePowerShellStaticContract(receipt['powershell_static_contract']);

  final cellsValue = receipt['cells'];
  if (cellsValue is! List || cellsValue.length != 2) {
    throw const FormatException('Receipt must contain exactly two cells.');
  }
  final expectedCellIds = <String>{
    '${platform}_logical_tmp',
    '${platform}_physical_tmp',
  };
  final seenCellIds = <String>{};
  final seenRoots = <String>{};
  final seenCaches = <String>{};
  for (final cellValue in cellsValue) {
    final cell = _requireObjectMap(cellValue, 'cell');
    const cellKeys = <String>{
      'cell_id',
      'logical_root',
      'physical_root',
      'task_cache',
      'snapshot_fingerprint_sha256',
      'output_hashes',
      'runs',
    };
    if (!cell.keys.toSet().containsAll(cellKeys) ||
        cell['cell_id'] is! String ||
        !expectedCellIds.contains(cell['cell_id']) ||
        !seenCellIds.add(cell['cell_id']! as String) ||
        cell['logical_root'] is! String ||
        !p.isAbsolute(cell['logical_root']! as String) ||
        !seenRoots.add(cell['logical_root']! as String) ||
        cell['physical_root'] is! String ||
        !p.isAbsolute(cell['physical_root']! as String) ||
        cell['task_cache'] is! String ||
        !p.isAbsolute(cell['task_cache']! as String) ||
        !seenCaches.add(cell['task_cache']! as String) ||
        cell['snapshot_fingerprint_sha256'] !=
            receipt['snapshot_fingerprint_sha256'] ||
        !_deepEqual(cell['output_hashes'], receipt['output_hashes'])) {
      throw const FormatException('Malformed or duplicate cold cell.');
    }
    final runs = cell['runs'];
    if (runs is! List || runs.length != 2) {
      throw const FormatException('Cold cell must contain exactly two runs.');
    }
    const phases = ['cold_first', 'cold_second'];
    for (var index = 0; index < runs.length; index += 1) {
      final run = _requireObjectMap(runs[index], 'cell run');
      const runKeys = <String>{
        'phase',
        'exit_code',
        'stdout_sha256',
        'stderr_sha256',
        'snapshot_fingerprint_sha256',
        'output_hashes',
      };
      if (!run.keys.toSet().containsAll(runKeys) ||
          run['phase'] != phases[index] ||
          run['exit_code'] != 0 ||
          run['snapshot_fingerprint_sha256'] !=
              receipt['snapshot_fingerprint_sha256'] ||
          !_deepEqual(run['output_hashes'], receipt['output_hashes'])) {
        throw const FormatException('Malformed cold run evidence.');
      }
      _requireHex(run['stdout_sha256'], 'run stdout hash');
      _requireHex(run['stderr_sha256'], 'run stderr hash');
    }
  }
  if (!_sameStringSet(seenCellIds, expectedCellIds)) {
    throw const FormatException('Cold receipt cell set is incomplete.');
  }
}

Map<String, Object?> _aggregateReceipts({
  required String campaignId,
  required Map<String, Object?> darwin,
  Map<String, Object?>? linux,
}) {
  _validatePlatformReceipt(darwin);
  if (darwin['campaign_id'] != campaignId ||
      darwin['platform'] != 'darwin' ||
      darwin['status'] != 'PASS_MACOS_COLD_REPRO') {
    throw const FormatException('Darwin receipt does not bind the campaign.');
  }
  if (linux != null) {
    _validatePlatformReceipt(linux);
    if (linux['campaign_id'] != campaignId ||
        linux['platform'] != 'linux' ||
        linux['status'] != 'PASS_LINUX_COLD_REPRO' ||
        linux['platform_run_id'] == darwin['platform_run_id']) {
      throw const FormatException('Linux receipt does not bind the campaign.');
    }
    for (final key in [
      'base_commit',
      'base_tree',
      'source_digest_sha256',
      'overlay_source_digest_sha256',
      'lock_hashes',
      'output_hashes',
      'snapshot_fingerprint_sha256',
      'powershell_static_contract',
    ]) {
      if (!_deepEqual(darwin[key], linux[key])) {
        throw FormatException('Darwin/Linux receipt mismatch at $key.');
      }
    }
    final darwinToolchain = _requireObjectMap(darwin['toolchain'], 'toolchain');
    final linuxToolchain = _requireObjectMap(linux['toolchain'], 'toolchain');
    for (final key in const [
      'frameworkVersion',
      'frameworkRevision',
      'engineRevision',
      'dartSdkVersion',
    ]) {
      if (darwinToolchain[key] != linuxToolchain[key]) {
        throw FormatException('Darwin/Linux toolchain mismatch at $key.');
      }
    }
  }
  final powerShell = _requireObjectMap(
    darwin['powershell_static_contract'],
    'PowerShell static contract',
  );
  return <String, Object?>{
    'schema': 'manaloom.project_logic_cold_repro_aggregate_receipt.v1',
    'campaign_id': campaignId,
    'status': linux == null
        ? 'PASS_MACOS_COLD_REPRO'
        : 'PASS_DARWIN_LINUX_COLD_REPRO',
    'darwin_status': darwin['status'],
    'linux_status': linux?['status'] ?? 'LINUX_NOT_RUN',
    'windows_status': 'WINDOWS_NOT_RUN',
    'powershell_status': powerShell['status'],
    'powershell_proof_sha256': _hashText(_canonicalJson(powerShell)),
    'cross_platform_status': linux == null
        ? 'NOT_ESTABLISHED'
        : 'PASS_DARWIN_LINUX_COLD_REPRO',
    'darwin_platform_run_id': darwin['platform_run_id'],
    'linux_platform_run_id': linux?['platform_run_id'],
  };
}

void _validatePowerShellStaticContract(Object? value) {
  final proof = _requireObjectMap(value, 'PowerShell static contract');
  if (proof['status'] != 'POWERSHELL_SOURCE_CONTRACT_PASS_STATIC' ||
      proof['runtime_status'] != 'WINDOWS_NOT_RUN') {
    throw const FormatException(
      'PowerShell proof overclaims runtime coverage.',
    );
  }
  for (final key in [
    'source_sha256',
    'contract_test_sha256',
    'checks_sha256',
  ]) {
    _requireHex(proof[key], 'PowerShell proof $key');
  }
}

Map<String, Object?> _requireObjectMap(Object? value, String label) {
  if (value is! Map || value.keys.any((key) => key is! String)) {
    throw FormatException('$label must be an object with string keys.');
  }
  return Map<String, Object?>.from(value);
}

void _validateHashMap(Object? value, Iterable<String> keys, String label) {
  final hashes = _requireObjectMap(value, label);
  if (!_sameStringSet(hashes.keys, keys)) {
    throw FormatException('$label has an unexpected path set.');
  }
  for (final entry in hashes.entries) {
    _requireHex(entry.value, '$label ${entry.key}');
  }
}

void _requireHex(Object? value, String label) {
  if (value is! String || !RegExp(r'^[0-9a-f]{64}$').hasMatch(value)) {
    throw FormatException('$label must be a lowercase SHA-256 digest.');
  }
}

Map<String, Object?> _cloneMap(Map<String, Object?> value) =>
    Map<String, Object?>.from(jsonDecode(jsonEncode(value)) as Map);

bool _deepEqual(Object? left, Object? right) =>
    _canonicalJson(left) == _canonicalJson(right);

bool _sameStringSet(Iterable<String> left, Iterable<String> right) {
  final leftSet = left.toSet();
  final rightSet = right.toSet();
  return leftSet.length == rightSet.length && leftSet.containsAll(rightSet);
}

String _repeatedHex(String digit) => List.filled(64, digit).join();

String _canonicalJson(Object? value) =>
    const JsonEncoder.withIndent('  ').convert(_sortJson(value));

Object? _sortJson(Object? value) {
  if (value is Map) {
    final keys = value.keys.map((key) => key.toString()).toList()..sort();
    return <String, Object?>{
      for (final key in keys) key: _sortJson(value[key]),
    };
  }
  if (value is List) return value.map(_sortJson).toList();
  return value;
}
