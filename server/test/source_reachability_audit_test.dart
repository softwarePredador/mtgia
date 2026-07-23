import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:server/source_reachability_audit.dart';
import 'package:test/test.dart';

const _fixturePackageName = 'fixture';

void main() {
  test('classifies runtime, operational, validation, and orphan libraries', () {
    final root = Directory.systemTemp.createTempSync(
      'manaloom-source-reachability-',
    );
    addTearDown(() => root.deleteSync(recursive: true));

    _write(root, 'lib/main.dart', '''
import 'src/barrel.dart'
    if (dart.library.html) 'src/web.dart';
void main() {}
''');
    _write(root, 'lib/src/barrel.dart', "export 'helper.dart';");
    _write(root, 'lib/src/helper.dart', "part 'piece.dart';");
    _write(root, 'lib/src/piece.dart', 'part of "helper.dart";');
    _write(root, 'lib/src/web.dart', 'const isWeb = true;');
    _write(root, 'lib/cli.dart', 'void runCli() {}');
    _write(root, 'lib/test_only.dart', 'void testHelper() {}');
    _write(root, 'lib/orphan.dart', 'void unused() {}');
    _write(
      root,
      'bin/tool.dart',
      _packageImport(_fixturePackageName, 'cli.dart'),
    );
    _write(
      root,
      'test/tool_test.dart',
      _packageImport(_fixturePackageName, 'test_only.dart'),
    );

    final audit = SourceReachabilityAudit(
      projectRoot: root.path,
      packageName: _fixturePackageName,
    );
    final result = audit.analyze(
      runtimeRoots: const ['lib/main.dart'],
      operationalRoots: const ['bin/tool.dart'],
      validationRoots: const ['test/tool_test.dart'],
    );

    expect(result.runtimeFiles, {
      'lib/main.dart',
      'lib/src/barrel.dart',
      'lib/src/helper.dart',
      'lib/src/piece.dart',
      'lib/src/web.dart',
    });
    expect(result.operationalOnlyFiles, {'lib/cli.dart'});
    expect(result.validationOnlyFiles, {'lib/test_only.dart'});
    expect(result.orphanFiles, {'lib/orphan.dart'});
  });
}

void _write(Directory root, String relativePath, String contents) {
  final file = File(path.join(root.path, relativePath));
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(contents);
}

String _packageImport(String packageName, String libraryPath) {
  // dependency_validator scans raw Dart text and would otherwise interpret a
  // package directive embedded in this fixture as a dependency of this test.
  const scheme = 'package';
  return "import '$scheme:$packageName/$libraryPath';";
}
