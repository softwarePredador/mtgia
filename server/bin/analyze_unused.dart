import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:server/source_reachability_audit.dart';

void main(List<String> args) {
  final workspaceRoot = _findWorkspaceRoot();
  final check = args.contains('--check');

  final appRoot = path.join(workspaceRoot.path, 'app');
  final appAudit = SourceReachabilityAudit(
    projectRoot: appRoot,
    packageName: 'manaloom',
  );
  final appResult = appAudit.analyze(
    runtimeRoots: const ['lib/main.dart'],
    validationRoots: {
      ...appAudit.dartFilesUnder('test'),
      ...appAudit.dartFilesUnder('integration_test'),
      ...appAudit.dartFilesUnder('test_driver'),
    },
  );

  final serverRoot = path.join(workspaceRoot.path, 'server');
  final serverAudit = SourceReachabilityAudit(
    projectRoot: serverRoot,
    packageName: 'server',
  );
  final serverResult = serverAudit.analyze(
    runtimeRoots: {'main.dart', ...serverAudit.dartFilesUnder('routes')},
    operationalRoots: serverAudit.dartFilesUnder('bin'),
    validationRoots: serverAudit.dartFilesUnder('test'),
  );

  _printResult('APP (Flutter)', appResult);
  _printResult('SERVER (Dart Frog + operational jobs)', serverResult);

  final orphanCount =
      appResult.orphanFiles.length + serverResult.orphanFiles.length;
  if (check && orphanCount > 0) {
    stderr.writeln(
      '[FAIL] $orphanCount library file(s) have no runtime, operational, '
      'or validation consumer.',
    );
    exitCode = 1;
  }
}

Directory _findWorkspaceRoot() {
  var candidate = Directory.current.absolute;
  while (true) {
    final hasApp =
        File(path.join(candidate.path, 'app', 'pubspec.yaml')).existsSync();
    final hasServer =
        File(path.join(candidate.path, 'server', 'pubspec.yaml')).existsSync();
    if (hasApp && hasServer) return candidate;

    final parent = candidate.parent;
    if (parent.path == candidate.path) {
      throw StateError(
        'ManaLoom workspace root not found from ${Directory.current.path}.',
      );
    }
    candidate = parent;
  }
}

void _printResult(String label, SourceReachabilityResult result) {
  stdout.writeln('--- $label ---');
  stdout.writeln('[PASS] Runtime libraries: ${result.runtimeFiles.length}');
  stdout.writeln(
    '[INFO] Operational-only libraries: '
    '${result.operationalOnlyFiles.length}',
  );
  _printFiles(result.operationalOnlyFiles);
  stdout.writeln(
    '[INFO] Validation-only libraries: ${result.validationOnlyFiles.length}',
  );
  _printFiles(result.validationOnlyFiles);

  if (result.orphanFiles.isEmpty) {
    stdout.writeln('[PASS] No orphan library files.');
  } else {
    stdout.writeln('[FAIL] Orphan library files: ${result.orphanFiles.length}');
    _printFiles(result.orphanFiles);
  }
}

void _printFiles(Set<String> files) {
  final sorted = files.toList()..sort();
  for (final file in sorted) {
    stdout.writeln(' - $file');
  }
}
