import 'dart:convert';
import 'dart:io';

import 'package:manaloom_project_logic/project_logic_generator.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory root;
  late ProjectLogicResult result;

  setUpAll(() async {
    root = _findWorkspaceRoot();
    result = await ProjectLogicGenerator(root).generate();
  });

  test('builds the complete deterministic artifact set', () {
    expect(
      result.outputs.keys.toSet(),
      ProjectLogicGenerator.outputPaths.toSet(),
    );
    expect(
      result.outputs.values.every((value) => value.endsWith('\n')),
      isTrue,
    );
  });

  test('indexes the executable product surfaces', () {
    final stats = result.manifest['statistics'] as Map<String, Object?>;
    expect(stats['app_routes'] as int, greaterThanOrEqualTo(36));
    expect(stats['web_routes'] as int, greaterThanOrEqualTo(10));
    expect(stats['non_dart_product_files'] as int, greaterThanOrEqualTo(45));
    expect(stats['api_routes'] as int, greaterThanOrEqualTo(95));
    expect(stats['database_tables'], 73);
    expect(stats['database_views'], 6);
    expect(stats['migrations'], 51);
    expect(stats['flows'], 8);
  });

  test('resolves production types and calls with package:analyzer', () {
    final stats = result.manifest['statistics'] as Map<String, Object?>;
    final semantic =
        result.manifest['semantic_analysis'] as Map<String, Object?>;

    expect(semantic['coverage_status'], 'complete');
    expect(semantic['resolved_file_count'], stats['dart_source_files']);
    expect(semantic['unresolved_file_count'], 0);
    expect(semantic['files_with_error_diagnostics'], isEmpty);
    expect(semantic['resolved_call_edge_count'] as int, greaterThan(1000));
    expect(semantic['workspace_call_edge_count'] as int, greaterThan(500));
    expect(semantic['resolved_type_reference_count'] as int, greaterThan(500));
    expect(semantic['workspace_type_reference_count'] as int, greaterThan(100));
    expect(semantic['resolved_call_edges_scope'], 'workspace_targets_only');
    expect(
      semantic['resolved_type_references_scope'],
      'workspace_targets_only',
    );
  });

  test('includes integration tests in inventory and source digest lineage', () {
    final tests = (result.manifest['tests'] as List<dynamic>).cast<String>();
    final lineage = result.manifest['lineage'] as Map<String, Object?>;
    final digestInputs = (lineage['digest_inputs'] as List<dynamic>)
        .cast<String>();

    expect(
      tests.where((path) => path.startsWith('app/integration_test/')).length,
      greaterThanOrEqualTo(130),
    );
    expect(
      digestInputs
          .where((path) => path.startsWith('app/integration_test/'))
          .length,
      greaterThanOrEqualTo(130),
    );
  });

  test('keeps the complete battle sidecar source surface in lineage', () {
    final lineage = result.manifest['lineage'] as Map<String, Object?>;
    final digestInputs = (lineage['digest_inputs'] as List<dynamic>)
        .cast<String>();
    final sidecarInputs = (lineage['battle_sidecar_inputs'] as List<dynamic>)
        .cast<String>();
    const criticalInputs = <String>{
      'services/forge-sidecar/.dockerignore',
      'services/forge-sidecar/Dockerfile',
      'services/forge-sidecar/FORGE_COMMIT',
      'services/forge-sidecar/README.md',
      'services/forge-sidecar/SeededForgeMain.java',
      'services/forge-sidecar/forge.profile.properties',
      'services/forge-sidecar/sidecar.py',
      'services/forge-sidecar/test_sidecar.py',
      'services/xmage-sidecar/.dockerignore',
      'services/xmage-sidecar/Dockerfile',
      'services/xmage-sidecar/README.md',
      'services/xmage-sidecar/XMAGE_COMMIT',
      'services/xmage-sidecar/bin/benchmark.sh',
      'services/xmage-sidecar/bin/bootstrap_pinned_xmage_maven.sh',
      'services/xmage-sidecar/entrypoint.sh',
      'services/xmage-sidecar/pom.xml',
      'services/xmage-sidecar/src/main/java/com/manaloom/xmage/ReplayNormalizer.java',
      'services/xmage-sidecar/src/main/java/com/manaloom/xmage/SidecarMain.java',
      'services/xmage-sidecar/src/main/java/com/manaloom/xmage/TrackingMageClient.java',
      'services/xmage-sidecar/src/main/java/com/manaloom/xmage/XmageBattleService.java',
      'services/xmage-sidecar/src/test/java/com/manaloom/xmage/XmageBattleServiceTest.java',
    };

    expect(sidecarInputs.toSet(), containsAll(criticalInputs));
    expect(digestInputs.toSet(), containsAll(sidecarInputs));
    expect(
      sidecarInputs.where(
        (path) =>
            path.contains('/target/') ||
            path.contains('/db/') ||
            path.contains('__pycache__'),
      ),
      isEmpty,
    );
    final canonicalDocuments =
        (result.manifest['canonical_documents'] as List<dynamic>)
            .cast<String>();
    expect(
      canonicalDocuments,
      contains('docs/hermes-analysis/EXTERNAL_BATTLE_EXECUTION_CONTRACT.md'),
    );
  });

  test('extracts imported SQL schema constants without comment pollution', () {
    final database = result.manifest['database'] as Map<String, Object?>;
    final tables = (database['tables'] as List<dynamic>)
        .cast<Map<String, Object?>>();
    final views = (database['views'] as List<dynamic>).cast<String>();
    final byName = {for (final table in tables) table['name']: table};

    expect(byName, contains('card_semantic_tags_v2'));
    expect(byName, contains('commander_card_synergy'));
    expect(views, contains('card_intelligence_snapshot'));
    final cards = byName['cards']!;
    final columns = (cards['columns'] as List<dynamic>)
        .cast<Map<String, Object?>>()
        .map((column) => column['name']);
    expect(columns, containsAll(['name', 'image_url', 'color_identity']));
    expect(columns, isNot(contains('Falta')));
    expect(columns, isNot(contains('NULL')));
  });

  test('keeps PostgreSQL canonical and Hermes non-canonical', () {
    final policy = result.manifest['source_policy'] as Map<String, dynamic>;
    expect(policy['product_data'], contains('PostgreSQL'));
    expect(policy['cache_and_laboratory'], contains('never product source'));
    final database = result.manifest['database'] as Map<String, Object?>;
    expect(database['source_of_truth'], 'PostgreSQL/backend');
    expect(database['latest_migration'], '051');
  });

  test('does not capture environment values', () {
    final variables =
        (result.manifest['environment_variables'] as List<dynamic>)
            .cast<Map<String, Object?>>();
    expect(variables, isNotEmpty);
    for (final variable in variables) {
      expect(variable.keys, containsAll(['name', 'classification', 'sources']));
      expect(variable['value_captured'], isFalse);
      expect(variable.containsKey('value'), isFalse);
    }
  });

  test('captures declared and resolved dependency trees', () {
    final dependencies =
        result.manifest['dependencies'] as Map<String, Object?>;
    final declared = dependencies['declared'] as List<dynamic>;
    final resolved = (dependencies['resolved_trees'] as List<dynamic>)
        .cast<Map<String, Object?>>();

    expect(declared, isNotEmpty);
    expect(
      resolved.map((tree) => tree['source']),
      contains('app/pubspec.yaml'),
    );
    expect(
      resolved.map((tree) => tree['source']),
      contains('server/pubspec.yaml'),
    );
    expect(
      resolved.every((tree) => (tree['packages'] as List<dynamic>).isNotEmpty),
      isTrue,
    );
    final node = dependencies['node'] as Map<String, Object?>;
    expect(node['status'], 'locked');
    expect(node['lockfile_version'], 3);
    expect(
      (node['resolved'] as List<dynamic>).length,
      greaterThanOrEqualTo(400),
    );
  });

  test('indexes public web routes and non-Dart product sources', () {
    final routes = (result.manifest['web_routes'] as List<dynamic>)
        .cast<Map<String, Object?>>();
    final paths = routes.map((route) => route['path']);
    final lineage = result.manifest['lineage'] as Map<String, Object?>;
    final digestInputs = (lineage['digest_inputs'] as List<dynamic>)
        .cast<String>();

    expect(paths, containsAll(['/', '/pricing', '/healthz', '/robots.txt']));
    expect(digestInputs, contains('web-public/src/app/page.tsx'));
    expect(digestInputs, contains('web-public/package-lock.json'));
    expect(
      digestInputs,
      contains('app/android/app/src/main/AndroidManifest.xml'),
    );
  });

  test('indexes backend and app operational tools', () {
    final scripts = (result.manifest['scripts_and_jobs'] as List<dynamic>)
        .cast<Map<String, Object?>>();
    final paths = scripts.map((script) => script['path']);

    expect(paths, contains('server/bin/manaloom_battle_product_e2e_audit.py'));
    expect(paths, contains('server/bin/migrate.dart'));
    expect(paths, contains('app/tool/authenticated_visual_diff.dart'));
  });

  test('emits the expected Mermaid diagram families', () {
    final flowsDocument = result.outputs['docs/generated/FLOWS.md']!;
    expect(
      result.outputs['docs/generated/ARCHITECTURE.md'],
      contains('flowchart LR'),
    );
    expect(flowsDocument, contains('sequenceDiagram'));
    expect(flowsDocument, isNot(contains(RegExp(r'[ \t]+\n'))));
    expect(flowsDocument, isNot(endsWith('\n\n')));
    expect(
      result.outputs['docs/generated/DATABASE_ERD.md'],
      contains('erDiagram'),
    );
  });

  test('emits valid structural OpenAPI with no unresolved method route', () {
    final openApi =
        jsonDecode(result.outputs['docs/generated/openapi.generated.json']!)
            as Map<String, dynamic>;
    expect(openApi['openapi'], '3.1.0');
    expect(openApi['x-manaloom-unresolved-method-paths'], isEmpty);
    expect(
      (openApi['paths'] as Map<String, dynamic>).length,
      greaterThanOrEqualTo(95),
    );
  });

  test('checked-in artifacts have no drift', () {
    expect(result.driftedFiles(), isEmpty);
  });

  test('drift detector fails closed for missing and changed artifacts', () {
    final temp = Directory.systemTemp.createTempSync('manaloom_logic_drift_');
    addTearDown(() => temp.deleteSync(recursive: true));
    final subject = ProjectLogicResult(temp, {
      'docs/generated/example.md': 'expected\n',
    }, const {});

    expect(subject.driftedFiles(), ['docs/generated/example.md']);
    subject.write();
    expect(subject.driftedFiles(), isEmpty);
    File(
      p.join(temp.path, 'docs/generated/example.md'),
    ).writeAsStringSync('changed\n');
    expect(subject.driftedFiles(), ['docs/generated/example.md']);
  });
}

Directory _findWorkspaceRoot() {
  var current = Directory.current.absolute;
  while (current.parent.path != current.path) {
    if (File(p.join(current.path, 'melos.yaml')).existsSync() &&
        Directory(p.join(current.path, 'app')).existsSync() &&
        Directory(p.join(current.path, 'server')).existsSync()) {
      return current;
    }
    current = current.parent;
  }
  throw StateError('ManaLoom workspace root not found.');
}
