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
    expect(stats['database_tables'], 79);
    expect(stats['database_views'], 6);
    expect(stats['migrations'], 58);
    expect(stats['flows'], 8);
  });

  test('publishes the following feed as an explicit API route alias', () {
    final routes = (result.manifest['api_routes'] as List<dynamic>)
        .cast<Map<String, Object?>>();
    final following = routes.singleWhere(
      (route) => route['path'] == '/community/decks/following',
    );

    expect(following['methods'], ['GET']);
    expect(
      following['source'],
      'server/routes/community/decks/[id]/index.dart',
    );
    expect(following['method_contract'], 'declared_alias');
    expect(
      File(
        p.join(root.path, 'server/routes/community/decks/following/index.dart'),
      ).existsSync(),
      isFalse,
    );
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

    final semanticJson = jsonEncode(semantic);
    expect(semanticJson, isNot(contains(root.absolute.path)));
    expect(semanticJson, isNot(contains('file://')));
    expect(semanticJson, contains('workspace:server/bin/'));
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
    expect(digestInputs.toSet().length, digestInputs.length);
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
    expect(
      canonicalDocuments,
      contains('docs/BREWTACT_MASTER_EXECUTION_BACKLOG_2026-08-12.md'),
    );
    expect(
      canonicalDocuments,
      contains('docs/BREWTACT_DECKBUILDER_AI_CURRENT_FLOW_2026-08-12.md'),
    );
    expect(canonicalDocuments, contains('docs/execution/README.md'));
    expect(
      canonicalDocuments,
      contains('docs/adr/0012-xmage-human-spike-go.md'),
    );
    expect(
      canonicalDocuments,
      isNot(contains('docs/adr/0004-xmage-human-spike-go.md')),
    );
  });

  test(
    'publishes a validated task registry with an acyclic dependency DAG',
    () {
      final registry = result.manifest['task_registry'] as Map<String, Object?>;
      final tasks = (registry['tasks'] as List<dynamic>)
          .cast<Map<String, Object?>>();
      final ids = tasks.map((task) => task['id']! as String).toList();
      final idsSet = ids.toSet();
      final topologicalOrder = (registry['topological_order'] as List<dynamic>)
          .cast<String>();
      final guards = registry['guards'] as Map<String, Object?>;

      expect(registry['schema_version'], 1);
      expect(registry['task_count'], 217);
      expect(tasks, hasLength(217));
      expect(idsSet, hasLength(ids.length));
      expect(ids.where((id) => id.contains('*') || id.contains('..')), isEmpty);
      expect(topologicalOrder, hasLength(tasks.length));
      expect(topologicalOrder.toSet(), idsSet);
      expect(
        tasks.expand(
          (task) => (task['depends_on'] as List<dynamic>).cast<String>(),
        ),
        everyElement(isIn(idsSet)),
      );
      expect(guards, containsPair('dependency_graph_acyclic', true));
      expect(guards, containsPair('out_of_table_task_definitions', 0));

      final databaseBaseline = tasks.singleWhere(
        (task) => task['id'] == 'BT-DB-005',
      );
      final legacyAiLane = tasks.singleWhere(
        (task) => task['id'] == 'BT-AI-027',
      );
      expect(databaseBaseline['depends_on'], ['BT-DB-001']);
      expect(legacyAiLane['depends_on'], contains('BT-DB-005'));

      final generated =
          jsonDecode(result.outputs['docs/generated/TASK_REGISTRY.json']!)
              as Map<String, dynamic>;
      expect(
        generated['project_logic_source_digest_sha256'],
        result.manifest['source_digest_sha256'],
      );
      expect(generated['task_count'], tasks.length);
    },
  );

  test(
    'rejects duplicate, unresolved, cyclic and shorthand task definitions',
    () {
      final generator = ProjectLogicGenerator(root);
      const header = '''
| ID | Pri. | Estado | Entrega | Depende de | Aceite mínimo |
|---|---|---|---|---|---|
''';
      String row(String id, String dependencies) =>
          '| `$id` | P1 | TODO | Entrega. | $dependencies | Aceite. |';

      expect(
        () => generator.taskBacklogForTesting(
          '$header${row('BT-TST-001', '—')}\n'
          '${row('BT-TST-001', '—')}',
        ),
        throwsA(isA<ProjectLogicException>()),
      );
      expect(
        () => generator.taskBacklogForTesting(
          '$header${row('BT-TST-001', '`BT-TST-404`')}',
        ),
        throwsA(isA<ProjectLogicException>()),
      );
      expect(
        () => generator.taskBacklogForTesting(
          '$header${row('BT-TST-001', '`BT-TST-002`')}\n'
          '${row('BT-TST-002', '`BT-TST-001`')}',
        ),
        throwsA(isA<ProjectLogicException>()),
      );
      expect(
        () => generator.taskBacklogForTesting(
          '$header${row('BT-TST-001', '`BT-TST-002..003`')}',
        ),
        throwsA(isA<ProjectLogicException>()),
      );
      expect(
        () => generator.taskBacklogForTesting(
          '- `BT-TST-001`: definição fora da tabela',
        ),
        throwsA(isA<ProjectLogicException>()),
      );
      expect(
        () => generator.taskBacklogForTesting(
          '$header| BT-TST-001 | P1 | TODO | Entrega. | — | Aceite. |',
        ),
        throwsA(isA<ProjectLogicException>()),
      );
    },
  );

  test('resolves document lifecycle, route consumers and receipt bindings', () {
    final registry = result.manifest['task_registry'] as Map<String, Object?>;
    final lifecycle =
        registry['documentation_lifecycle'] as Map<String, Object?>;
    final canonical = (lifecycle['canonical_documents'] as List<dynamic>)
        .cast<Map<String, Object?>>();
    final overrides = (lifecycle['document_overrides'] as List<dynamic>)
        .cast<Map<String, Object?>>();
    final routes = (registry['route_consumers'] as List<dynamic>)
        .cast<Map<String, Object?>>();
    final receipts = (registry['receipt_contracts'] as List<dynamic>)
        .cast<Map<String, Object?>>();

    expect(
      canonical.singleWhere(
        (document) =>
            document['path'] == 'docs/status/CURRENT_PRODUCT_DECISION.md',
      )['state'],
      'current_decision',
    );
    expect(
      canonical.singleWhere(
        (document) =>
            document['path'] ==
            'docs/BREWTACT_MASTER_EXECUTION_BACKLOG_2026-08-12.md',
      )['state'],
      'current_task_index',
    );
    final executionQueue = overrides.singleWhere(
      (document) => document['path'] == 'docs/execution/CURRENT_QUEUE.md',
    );
    expect(executionQueue['state'], 'current_context');
    expect(executionQueue['priority_authority'], false);
    expect(executionQueue['mutation_authority'], false);
    for (final path in [
      'docs/MANALOOM_BATTLE_LAB_DELIVERY_PLAN.md',
      'docs/MANALOOM_BATTLE_LAB_TRACKER.md',
    ]) {
      expect(
        overrides.singleWhere((document) => document['path'] == path)['state'],
        'historical_evidence',
      );
      expect(
        canonical.map((document) => document['path']),
        isNot(contains(path)),
      );
    }

    final generate = routes.singleWhere(
      (route) =>
          route['flow_id'] == 'deck_ai' &&
          route['entrypoint'] == '/ai/generate',
    );
    expect(generate['surfaces'], contains('api'));
    expect(
      generate['consumers'],
      contains(
        'app/lib/features/decks/providers/deck_provider_support_ai.dart',
      ),
    );
    expect(
      generate['receipt_contract_ids'],
      contains('deck_ai_learning_gate_v2'),
    );
    final battleCoach = routes.singleWhere(
      (route) =>
          route['flow_id'] == 'battle_replay' &&
          route['entrypoint'] == '/decks/{id}/battle-coach',
    );
    expect(battleCoach['surfaces'], contains('app'));

    final deckReceipt = receipts.singleWhere(
      (receipt) => receipt['id'] == 'deck_ai_learning_gate_v2',
    );
    expect(
      deckReceipt['required_bindings'],
      containsAll([
        'project_logic_source_digest',
        'source.start',
        'source.end',
        'source.stable',
        'evidence.artifact_manifest_sha256',
        'release_eligible',
      ]),
    );
    expect(deckReceipt['allowed_statuses'], [
      'PASS_CODE_ONLY',
      'PASS',
      'BLOCKED',
      'FAIL',
    ]);

    final e2eReceipt = receipts.singleWhere(
      (receipt) => receipt['id'] == 'manaloom_e2e_suite_v1',
    );
    final statusSemantics =
        e2eReceipt['status_semantics'] as Map<String, dynamic>;
    expect(statusSemantics['PARTIAL'], {
      'strict_exit_code': 3,
      'diagnostic_gate_eligible': false,
    });
    expect(e2eReceipt['required_bindings'], contains('gate_eligible'));
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

  test('preserves composite foreign-key column order', () {
    final database = result.manifest['database'] as Map<String, Object?>;
    final relations = (database['relations'] as List<dynamic>)
        .cast<Map<String, Object?>>();
    final relation = relations.singleWhere(
      (candidate) =>
          candidate['from_table'] == 'battle_jobs' &&
          candidate['to_table'] == 'battle_simulation_attempts' &&
          (candidate['from_columns'] as List<dynamic>).length == 2,
    );

    expect(relation['from_columns'], ['attempt_id', 'replay_id']);
    expect(relation['to_columns'], ['id', 'replay_id']);
    expect(relation, isNot(contains('from_column')));
    expect(relation, isNot(contains('to_column')));
  });

  test('keeps PostgreSQL canonical and Hermes non-canonical', () {
    final policy = result.manifest['source_policy'] as Map<String, dynamic>;
    expect(policy['product_data'], contains('PostgreSQL'));
    expect(policy['cache_and_laboratory'], contains('never product source'));
    final database = result.manifest['database'] as Map<String, Object?>;
    expect(database['source_of_truth'], 'PostgreSQL/backend');
    expect(database['latest_migration'], '058');
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

  test(
    'dependency inventory is independent from transient pub caches',
    () async {
      final temp = Directory.systemTemp.createTempSync(
        'manaloom_logic_dependencies_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      void writePackage(String relativeDirectory, String name) {
        final directory = Directory(p.join(temp.path, relativeDirectory))
          ..createSync(recursive: true);
        File(p.join(directory.path, 'pubspec.yaml')).writeAsStringSync('''
name: $name
publish_to: none
environment:
  sdk: ">=3.9.0 <4.0.0"
''');
        File(p.join(directory.path, 'pubspec.lock')).writeAsStringSync('''
# Generated by pub
packages: {}
sdks:
  dart: ">=3.9.0 <4.0.0"
''');
      }

      writePackage('.', 'workspace_fixture');
      writePackage('app', 'app_fixture');
      writePackage('server', 'server_fixture');
      writePackage('tools/local_tool', 'local_tool_fixture');

      final generator = ProjectLogicGenerator(temp);
      final cold = await generator.dependencyInventoryForTesting();
      final coldTrees = (cold['resolved_trees'] as List<dynamic>)
          .cast<Map<String, Object?>>();
      expect(coldTrees.map((tree) => tree['source']), [
        'app/pubspec.yaml',
        'pubspec.yaml',
        'server/pubspec.yaml',
      ]);

      for (final relative in ['.', 'app', 'server']) {
        final cache = Directory(p.join(temp.path, relative, '.dart_tool'));
        if (cache.existsSync()) cache.deleteSync(recursive: true);
      }
      final transientCache = Directory(
        p.join(temp.path, 'tools/local_tool/.dart_tool'),
      )..createSync(recursive: true);
      File(
        p.join(transientCache.path, 'package_config.json'),
      ).writeAsStringSync('{"configVersion":2,"packages":[]}');

      final warm = await generator.dependencyInventoryForTesting();
      expect(warm, cold);
      expect(
        generator.dependencyInputPathsForTesting(),
        isNot(contains('tools/local_tool/pubspec.lock')),
      );

      for (final tree in coldTrees) {
        final packages = (tree['packages'] as List<dynamic>)
            .cast<Map<String, Object?>>();
        final encoded = packages.map(jsonEncode).toList();
        expect(encoded, orderedEquals(encoded.toList()..sort()));
        for (final package in packages) {
          for (final key in [
            'dependencies',
            'devDependencies',
            'directDependencies',
          ]) {
            final names = (package[key] as List<dynamic>? ?? const [])
                .cast<String>();
            expect(names, orderedEquals(names.toList()..sort()));
          }
        }
      }
    },
  );

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
    expect(
      digestInputs,
      isNot(
        contains(
          'app/android/app/src/main/java/io/flutter/plugins/'
          'GeneratedPluginRegistrant.java',
        ),
      ),
    );
    expect(
      digestInputs,
      isNot(contains('app/ios/Runner/GeneratedPluginRegistrant.m')),
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
