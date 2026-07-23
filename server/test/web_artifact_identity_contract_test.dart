import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

void main() {
  test(
    'web identity guard accepts the matching bundle and rejects stale SHA',
    () async {
      final root = Directory.current.parent;
      final script = File(
        '${root.path}/scripts/manaloom_web_artifact_identity.sh',
      );
      expect(script.existsSync(), isTrue);

      final fixture = await Directory.systemTemp.createTemp(
        'manaloom_web_identity_',
      );
      addTearDown(() => fixture.deleteSync(recursive: true));
      final main = File('${fixture.path}/main.dart.js')
        ..writeAsStringSync('bundle-current');
      File(
        '${fixture.path}/index.html',
      ).writeAsStringSync('<base href="/app/">');
      final mainSha =
          (await Process.run('shasum', [
            '-a',
            '256',
            main.path,
          ])).stdout.toString().split(RegExp(r'\s+')).first;
      File('${fixture.path}/release.json').writeAsStringSync(
        jsonEncode({
          'git_sha': 'expected-sha',
          'source_patch_sha256': 'expected-patch',
          'flutter_version': '3.44.6',
          'renderer_contract': 'flutter-auto',
          'artifacts': {'main.dart.js': mainSha},
        }),
      );

      final output = '${fixture.path}/identity.json';
      final accepted = await Process.run('bash', [
        script.path,
        '--build-dir',
        fixture.path,
        '--expected-git-sha',
        'expected-sha',
        '--expected-source-patch-sha256',
        'expected-patch',
        '--viewport',
        '1440x900',
        '--dpr',
        '2',
        '--dataset',
        'visual-fixture-v1',
        '--renderer',
        'canvaskit',
        '--output',
        output,
      ]);
      expect(accepted.exitCode, 0, reason: accepted.stderr.toString());
      final identity =
          jsonDecode(File(output).readAsStringSync()) as Map<String, dynamic>;
      expect(identity['git_sha'], 'expected-sha');
      expect(identity['source_patch_sha256'], 'expected-patch');
      expect(identity['main_dart_js_sha256'], mainSha);
      expect(identity['viewport'], '1440x900');
      expect(identity['dpr'], 2);
      expect(identity['dataset'], 'visual-fixture-v1');
      expect(identity['stale_override'], isFalse);

      final rejected = await Process.run('bash', [
        script.path,
        '--build-dir',
        fixture.path,
        '--expected-git-sha',
        'different-sha',
        '--viewport',
        '390x844',
        '--dpr',
        '1',
        '--dataset',
        'visual-fixture-v1',
        '--renderer',
        'canvaskit',
      ]);
      expect(rejected.exitCode, 1);
      expect(rejected.stderr.toString(), contains('bundle Web antigo'));

      final stalePatch = await Process.run('bash', [
        script.path,
        '--build-dir',
        fixture.path,
        '--expected-git-sha',
        'expected-sha',
        '--expected-source-patch-sha256',
        'different-patch',
        '--viewport',
        '390x844',
        '--dpr',
        '1',
        '--dataset',
        'visual-fixture-v1',
        '--renderer',
        'canvaskit',
      ]);
      expect(stalePatch.exitCode, 1);
      expect(stalePatch.stderr.toString(), contains('patch das fontes'));

      final sourceRoot = await Directory.systemTemp.createTemp(
        'manaloom_web_source_',
      );
      addTearDown(() => sourceRoot.deleteSync(recursive: true));
      Directory('${sourceRoot.path}/app/lib').createSync(recursive: true);
      Directory('${sourceRoot.path}/app/web').createSync(recursive: true);
      Directory('${sourceRoot.path}/app/assets').createSync(recursive: true);
      File(
        '${sourceRoot.path}/app/lib/main.dart',
      ).writeAsStringSync('runtime-source');
      File('${sourceRoot.path}/app/pubspec.yaml').writeAsStringSync('name: qa');
      File(
        '${sourceRoot.path}/app/pubspec.lock',
      ).writeAsStringSync('packages:');

      final staleSourceTree = await Process.run('bash', [
        script.path,
        '--build-dir',
        fixture.path,
        '--expected-git-sha',
        'expected-sha',
        '--source-root',
        sourceRoot.path,
        '--viewport',
        '390x844',
        '--dpr',
        '1',
        '--dataset',
        'visual-fixture-v1',
        '--renderer',
        'canvaskit',
      ]);
      expect(staleSourceTree.exitCode, 1);
      expect(
        staleSourceTree.stderr.toString(),
        contains('arvore das fontes runtime'),
      );

      final invalidDpr = await Process.run('bash', [
        script.path,
        '--build-dir',
        fixture.path,
        '--expected-git-sha',
        'expected-sha',
        '--viewport',
        '390x844',
        '--dpr',
        '0.0',
        '--dataset',
        'visual-fixture-v1',
        '--renderer',
        'canvaskit',
      ]);
      expect(invalidDpr.exitCode, 2);
      expect(invalidDpr.stderr.toString(), contains('DPR invalido'));
    },
  );

  test('web deploy release manifest carries reproducibility coordinates', () {
    final source =
        File(
          '${Directory.current.parent.path}/scripts/manaloom_deploy_flutter_web.sh',
        ).readAsStringSync();

    for (final field in const [
      'flutter_version',
      'dart_version',
      'renderer_contract',
      'base_href',
      'main.dart.js',
    ]) {
      expect(source, contains(field), reason: 'missing release field $field');
    }
  });
}
