import 'dart:convert';
import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

const _generatorVersion = '1.2.0';

class ProjectLogicException implements Exception {
  ProjectLogicException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ProjectLogicResult {
  ProjectLogicResult(this.root, this.outputs, this.manifest);

  final Directory root;
  final Map<String, String> outputs;
  final Map<String, Object?> manifest;

  List<String> driftedFiles() {
    final drift = <String>[];
    for (final entry in outputs.entries) {
      final file = File(p.join(root.path, entry.key));
      if (!file.existsSync() || file.readAsStringSync() != entry.value) {
        drift.add(entry.key);
      }
    }
    return drift..sort();
  }

  void write() {
    for (final entry in outputs.entries) {
      final file = File(p.join(root.path, entry.key));
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(entry.value);
    }
  }
}

class ProjectLogicGenerator {
  ProjectLogicGenerator(this.root);

  final Directory root;

  static const outputPaths = <String>[
    'project_logic_manifest.json',
    'docs/generated/CURRENT_SYSTEM.md',
    'docs/generated/ARCHITECTURE.md',
    'docs/generated/FLOWS.md',
    'docs/generated/API_MAP.md',
    'docs/generated/openapi.generated.json',
    'docs/generated/DATABASE_ERD.md',
    'docs/generated/TRACEABILITY_MATRIX.md',
  ];

  Future<ProjectLogicResult> generate() async {
    final contractFile = _file('docs/project_logic_contracts.json');
    final inventoryFile = _file(
      'app/test/ui/fixtures/ui_surface_inventory.json',
    );
    final migrationFile = _file('server/bin/migrate.dart');
    final databaseSetupFile = _file('server/database_setup.sql');

    for (final file in [
      contractFile,
      inventoryFile,
      migrationFile,
      databaseSetupFile,
    ]) {
      if (!file.existsSync()) {
        throw ProjectLogicException('Required source is missing: ${file.path}');
      }
    }

    final contracts = _decodeMap(contractFile);
    final surfaceInventory = _decodeMap(inventoryFile);
    _validateContracts(contracts);

    final dartFiles = _dartSourceFiles();
    final units = <_DartUnit>[];
    for (final file in dartFiles) {
      units.add(_readDartUnit(file));
    }
    final semanticAnalysis = await _semanticAnalysis(dartFiles);

    final testFiles = _testFiles();
    final scriptFiles = _scriptFiles();
    final nonDartProductFiles = _nonDartProductFiles();
    final battleSidecarSourceFiles = _battleSidecarSourceFiles();
    final appRoutes = _appRoutes(surfaceInventory, units);
    final webRoutes = _webRoutes();
    final apiRoutes = _apiRoutes(contracts, testFiles);
    final database = _databaseModel(
      databaseSetupFile.readAsStringSync(),
      migrationFile.readAsStringSync(),
      units,
    );
    final modules = _modules(units);
    final dependencies = await _dependencies();
    final scripts = _scripts(scriptFiles);
    final environment = _environmentVariables(units, scriptFiles);
    final tests = testFiles.map(_relative).toList()..sort();
    final qualityGates = _qualityGates();

    _validateDeclaredPaths(contracts);
    _validateDeclaredTables(contracts, database);

    final canonicalDocumentFiles = _canonicalDocumentFiles(contracts);

    final digestInputs = <File>{
      contractFile,
      inventoryFile,
      migrationFile,
      databaseSetupFile,
      ...canonicalDocumentFiles,
      ...dartFiles,
      ...testFiles,
      ...scriptFiles,
      ...nonDartProductFiles,
      ...battleSidecarSourceFiles,
      ..._dependencyFiles(),
      ..._generatorSourceFiles(),
      ..._governanceFiles(),
    }.toList()..sort((a, b) => _relative(a).compareTo(_relative(b)));

    final sourceDigest = _sourceDigest(digestInputs);
    final digestInputPaths = digestInputs.map(_relative).toList()..sort();
    final symbols =
        units
            .expand((unit) => unit.symbols)
            .map((symbol) => symbol.toJson())
            .toList()
          ..sort(_compareJsonBySourceName);

    final flows = (contracts['flows'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    final traceability = (contracts['traceability'] as List<dynamic>)
        .cast<Map<String, dynamic>>();

    final manifest = <String, Object?>{
      'schema_version': 1,
      'generator': {
        'name': 'manaloom_project_logic',
        'version': _generatorVersion,
        'command': 'scripts/manaloom_project_logic.sh --write',
        'check_command': 'scripts/manaloom_project_logic.sh --check',
        'generated_files': outputPaths,
      },
      'source_digest_sha256': sourceDigest,
      'source_policy': contracts['source_policy'],
      'canonical_documents': contracts['canonical_documents'],
      'statistics': {
        'dart_source_files': dartFiles.length,
        'non_dart_product_files': nonDartProductFiles.length,
        'battle_sidecar_source_files': battleSidecarSourceFiles.length,
        'dart_symbols': symbols.length,
        'semantic_resolved_files': semanticAnalysis['resolved_file_count'],
        'semantic_unresolved_files': semanticAnalysis['unresolved_file_count'],
        'semantic_resolved_call_edges':
            semanticAnalysis['resolved_call_edge_count'],
        'semantic_resolved_call_sites':
            semanticAnalysis['resolved_call_site_count'],
        'semantic_resolved_type_references':
            semanticAnalysis['resolved_type_reference_count'],
        'modules': modules.length,
        'app_routes': appRoutes.length,
        'web_routes': webRoutes.length,
        'api_routes': apiRoutes.length,
        'database_tables': (database['tables'] as List).length,
        'database_views': (database['views'] as List).length,
        'migrations': (database['migrations'] as List).length,
        'scripts_and_jobs': scripts.length,
        'environment_variables': environment.length,
        'tests': tests.length,
        'flows': flows.length,
        'traceability_rules': traceability.length,
      },
      'modules': modules,
      'dart_symbols': symbols,
      'semantic_analysis': semanticAnalysis,
      'providers': _symbolsWithSuffix(symbols, 'Provider'),
      'services': _symbolsWithSuffix(symbols, 'Service'),
      'dependencies': dependencies,
      'app_routes': appRoutes,
      'web_routes': webRoutes,
      'api_routes': apiRoutes,
      'database': database,
      'scripts_and_jobs': scripts,
      'quality_gates': qualityGates,
      'environment_variables': environment,
      'tests': tests,
      'flows': flows,
      'traceability': traceability,
      'runtime_introspection': contracts['runtime_introspection'],
      'known_limits': contracts['known_limits'],
      'lineage': {
        'digest_algorithm': 'sha256(path + file_sha256)',
        'digest_inputs': digestInputPaths,
        'battle_sidecar_inputs': battleSidecarSourceFiles
            .map(_relative)
            .toList(),
      },
    };

    final openApi = _openApi(apiRoutes, contracts, sourceDigest);
    final outputs = <String, String>{
      'project_logic_manifest.json': _prettyJson(manifest),
      'docs/generated/CURRENT_SYSTEM.md': _currentSystem(manifest),
      'docs/generated/ARCHITECTURE.md': _architecture(manifest),
      'docs/generated/FLOWS.md': _flowsDocument(manifest),
      'docs/generated/API_MAP.md': _apiMap(manifest),
      'docs/generated/openapi.generated.json': _prettyJson(openApi),
      'docs/generated/DATABASE_ERD.md': _databaseErd(manifest),
      'docs/generated/TRACEABILITY_MATRIX.md': _traceability(manifest),
    };
    return ProjectLogicResult(root, outputs, manifest);
  }

  File _file(String relativePath) => File(p.join(root.path, relativePath));

  String _relative(File file) => p
      .relative(file.absolute.path, from: root.absolute.path)
      .replaceAll('\\', '/');

  Map<String, dynamic> _decodeMap(File file) {
    try {
      return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    } on Object catch (error) {
      throw ProjectLogicException('Invalid JSON in ${_relative(file)}: $error');
    }
  }

  void _validateContracts(Map<String, dynamic> contracts) {
    if (contracts['schema_version'] != 1) {
      throw ProjectLogicException(
        'docs/project_logic_contracts.json must use schema_version 1.',
      );
    }
    for (final key in [
      'source_policy',
      'canonical_documents',
      'flows',
      'traceability',
      'runtime_introspection',
      'known_limits',
    ]) {
      if (!contracts.containsKey(key)) {
        throw ProjectLogicException('Missing project logic contract key: $key');
      }
    }
    final flowIds = <String>{};
    for (final flow in (contracts['flows'] as List<dynamic>)) {
      final map = flow as Map<String, dynamic>;
      final id = map['id'] as String?;
      if (id == null || id.isEmpty || !flowIds.add(id)) {
        throw ProjectLogicException('Flow ids must be present and unique: $id');
      }
      for (final key in [
        'name',
        'status',
        'source_of_truth',
        'entrypoints',
        'implementation',
        'storage',
        'tests',
        'gates',
        'sequence',
      ]) {
        if (!map.containsKey(key)) {
          throw ProjectLogicException('Flow $id is missing $key.');
        }
      }
    }
  }

  void _validateDeclaredPaths(Map<String, dynamic> contracts) {
    final paths = <String>{
      ...(contracts['canonical_documents'] as List<dynamic>).cast<String>(),
    };
    for (final flow in (contracts['flows'] as List<dynamic>)) {
      final map = flow as Map<String, dynamic>;
      for (final key in ['implementation', 'tests', 'gates']) {
        for (final path in (map[key] as List<dynamic>).cast<String>()) {
          paths.add(path);
        }
      }
    }
    for (final rule in (contracts['traceability'] as List<dynamic>)) {
      final map = rule as Map<String, dynamic>;
      for (final key in ['implementation', 'tests']) {
        for (final path in (map[key] as List<dynamic>).cast<String>()) {
          paths.add(path);
        }
      }
    }
    final missing = paths.where((path) => !_file(path).existsSync()).toList()
      ..sort();
    if (missing.isNotEmpty) {
      throw ProjectLogicException(
        'Declared project logic paths do not exist:\n${missing.join('\n')}',
      );
    }
  }

  void _validateDeclaredTables(
    Map<String, dynamic> contracts,
    Map<String, Object?> database,
  ) {
    final known = (database['tables'] as List<dynamic>)
        .cast<Map<String, Object?>>()
        .map((table) => table['name'] as String)
        .toSet();
    final declared = <String>{};
    for (final flow in (contracts['flows'] as List<dynamic>)) {
      declared.addAll(
        ((flow as Map<String, dynamic>)['storage'] as List<dynamic>)
            .cast<String>()
            .where((value) => !value.startsWith('local:')),
      );
    }
    for (final rule in (contracts['traceability'] as List<dynamic>)) {
      declared.addAll(
        ((rule as Map<String, dynamic>)['tables'] as List<dynamic>)
            .cast<String>()
            .where((value) => !value.startsWith('local:')),
      );
    }
    final missing = declared.difference(known).toList()..sort();
    if (missing.isNotEmpty) {
      throw ProjectLogicException(
        'Declared PostgreSQL tables were not found in schema/migrations: '
        '${missing.join(', ')}',
      );
    }
  }

  List<File> _dartSourceFiles() => _filesUnder([
    'app/lib',
    'server/lib',
    'server/routes',
    'server/bin',
  ], (file) => file.path.endsWith('.dart'));

  List<File> _testFiles() => _filesUnder(
    [
      'app/test',
      'app/integration_test',
      'app/patrol_test',
      'server/test',
      'server/bin',
      'services',
      'tools',
      'docs/hermes-analysis/manaloom-knowledge/scripts',
    ],
    (file) {
      final name = p.basename(file.path);
      return name.endsWith('_test.dart') ||
          name.startsWith('test_') && name.endsWith('.py') ||
          name.endsWith('_test.py') ||
          name.endsWith('Test.java');
    },
  );

  List<File> _scriptFiles() => _filesUnder(
    [
      'scripts',
      'app/tool',
      'server/bin',
      'docs/hermes-analysis/manaloom-knowledge/scripts',
      'services',
    ],
    (file) {
      final name = p.basename(file.path);
      if (name.startsWith('test_') || name.endsWith('_test.py')) {
        return false;
      }
      return name.endsWith('.sh') ||
          name.endsWith('.py') ||
          name.endsWith('.ps1') ||
          name.endsWith('.dart');
    },
  );

  List<File> _nonDartProductFiles() {
    final extensions = <String>{
      '.css',
      '.gradle',
      '.html',
      '.java',
      '.js',
      '.json',
      '.kts',
      '.m',
      '.mm',
      '.plist',
      '.properties',
      '.swift',
      '.ts',
      '.tsx',
      '.xml',
    };
    final files = _filesUnder([
      'web-public/src',
      'app/web',
      'app/android/app/src/main',
      'app/ios/Runner',
    ], (file) => extensions.contains(p.extension(file.path).toLowerCase()));
    for (final path in [
      'web-public/package.json',
      'web-public/package-lock.json',
      'web-public/next.config.ts',
      'web-public/postcss.config.js',
      'web-public/tailwind.config.ts',
      'web-public/tsconfig.json',
      'server/Dockerfile',
      'app/Dockerfile.web',
    ]) {
      final file = _file(path);
      if (file.existsSync()) files.add(file);
    }
    return files.toSet().toList()
      ..sort((left, right) => _relative(left).compareTo(_relative(right)));
  }

  List<File> _battleSidecarSourceFiles() {
    const exactNames = <String>{
      '.dockerignore',
      'Dockerfile',
      'FORGE_COMMIT',
      'README.md',
      'XMAGE_COMMIT',
      'pom.xml',
      'requirements.txt',
    };
    const sourceExtensions = <String>{
      '.java',
      '.md',
      '.properties',
      '.py',
      '.sh',
      '.xml',
    };

    return _filesUnder(['services/xmage-sidecar', 'services/forge-sidecar'], (
      file,
    ) {
      final relative = _relative(file);
      if (relative.contains('/__pycache__/') ||
          relative.contains('/target/') ||
          relative.contains('/db/')) {
        return false;
      }
      final name = p.basename(file.path);
      return exactNames.contains(name) ||
          name.startsWith('requirements') && name.endsWith('.txt') ||
          sourceExtensions.contains(p.extension(name).toLowerCase());
    });
  }

  List<File> _pubspecFiles() {
    final files = <File>[
      _file('pubspec.yaml'),
      _file('app/pubspec.yaml'),
      _file('server/pubspec.yaml'),
      ..._filesUnder([
        'tools',
      ], (file) => p.basename(file.path) == 'pubspec.yaml'),
    ].where((file) => file.existsSync()).toSet().toList();
    return files..sort((a, b) => _relative(a).compareTo(_relative(b)));
  }

  List<File> _dependencyFiles() {
    final files = <File>{..._pubspecFiles()};
    for (final pubspec in _pubspecFiles()) {
      final lock = File(p.join(pubspec.parent.path, 'pubspec.lock'));
      if (lock.existsSync()) files.add(lock);
    }
    return files.toList()..sort((a, b) => _relative(a).compareTo(_relative(b)));
  }

  List<File> _canonicalDocumentFiles(Map<String, dynamic> contracts) =>
      (contracts['canonical_documents'] as List<dynamic>)
          .cast<String>()
          .map(_file)
          .toList()
        ..sort((a, b) => _relative(a).compareTo(_relative(b)));

  List<File> _governanceFiles() =>
      [
          _file('AGENTS.md'),
          _file('.tbls.yml'),
          _file('melos.yaml'),
          _file('.githooks/pre-commit'),
          _file('.githooks/pre-push'),
        ].where((file) => file.existsSync()).toList()
        ..sort((a, b) => _relative(a).compareTo(_relative(b)));

  List<File> _generatorSourceFiles() => _filesUnder(
    ['tools/project_logic'],
    (file) =>
        file.path.endsWith('.dart') ||
        file.path.endsWith('.yaml') ||
        file.path.endsWith('.yml'),
  );

  List<File> _filesUnder(
    List<String> roots,
    bool Function(File file) include, {
    bool recursive = true,
  }) {
    final result = <File>[];
    final seen = <String>{};
    for (final relativeRoot in roots) {
      final directory = Directory(p.join(root.path, relativeRoot));
      if (!directory.existsSync()) continue;
      final entities = directory.listSync(
        recursive: recursive,
        followLinks: false,
      );
      for (final entity in entities) {
        if (entity is! File) continue;
        final relative = _relative(entity);
        if (relative.contains('/.dart_tool/') ||
            relative.contains('/build/') ||
            relative.contains('/node_modules/')) {
          continue;
        }
        if (include(entity) && seen.add(entity.absolute.path)) {
          result.add(entity);
        }
      }
    }
    return result..sort((a, b) => _relative(a).compareTo(_relative(b)));
  }

  _DartUnit _readDartUnit(File file) {
    final source = file.readAsStringSync();
    final parsed = parseString(
      content: source,
      path: file.path,
      throwIfDiagnostics: false,
    );
    final visitor = _ProjectLogicAstVisitor(
      source: _relative(file),
      lineInfo: parsed.lineInfo,
    );
    parsed.unit.accept(visitor);
    final imports =
        parsed.unit.directives
            .whereType<UriBasedDirective>()
            .map((directive) => directive.uri.stringValue)
            .whereType<String>()
            .toList()
          ..sort();
    return _DartUnit(
      source: _relative(file),
      content: source,
      imports: imports,
      symbols: visitor.symbols,
      routes: visitor.routes,
      sqlLiterals: visitor.sqlLiterals,
    );
  }

  Future<Map<String, Object?>> _semanticAnalysis(List<File> dartFiles) async {
    final includedPaths = <String>[
      p.normalize(Directory(p.join(root.path, 'app')).absolute.path),
      p.normalize(Directory(p.join(root.path, 'server')).absolute.path),
    ].where((path) => Directory(path).existsSync()).toList();
    final excludedPaths = <String>[
      for (final package in ['app', 'server'])
        for (final directory in ['.dart_tool', 'build'])
          p.normalize(
            Directory(p.join(root.path, package, directory)).absolute.path,
          ),
    ].where((path) => Directory(path).existsSync()).toList();

    final resolvedFiles = <String>[];
    final unresolvedFiles = <Map<String, Object?>>[];
    final resolvedCalls = <String, Map<String, Object?>>{};
    final unresolvedCalls = <String, Map<String, Object?>>{};
    final resolvedTypes = <String, Map<String, Object?>>{};
    final unresolvedTypes = <String, Map<String, Object?>>{};
    final diagnosticCounts = <String, int>{};
    final filesWithErrorDiagnostics = <String>[];

    final collection = AnalysisContextCollection(
      includedPaths: includedPaths,
      excludedPaths: excludedPaths,
    );
    try {
      for (final file in dartFiles) {
        final source = _relative(file);
        final path = p.normalize(file.absolute.path);
        try {
          final context = collection.contextFor(path);
          final analysis = await context.currentSession.getResolvedUnit(path);
          if (analysis is! ResolvedUnitResult) {
            unresolvedFiles.add({
              'source': source,
              'reason': analysis.runtimeType.toString(),
            });
            continue;
          }

          resolvedFiles.add(source);
          var hasError = false;
          for (final diagnostic in analysis.diagnostics) {
            final severity = diagnostic.diagnosticCode.severity.name;
            diagnosticCounts.update(
              severity,
              (value) => value + 1,
              ifAbsent: () => 1,
            );
            if (severity == 'ERROR') hasError = true;
          }
          if (hasError) filesWithErrorDiagnostics.add(source);

          final visitor = _ProjectLogicSemanticVisitor(
            source: source,
            lineInfo: analysis.lineInfo,
          );
          analysis.unit.accept(visitor);
          _mergeSemanticAggregates(resolvedCalls, visitor.resolvedCalls);
          _mergeSemanticAggregates(unresolvedCalls, visitor.unresolvedCalls);
          _mergeSemanticAggregates(resolvedTypes, visitor.resolvedTypes);
          _mergeSemanticAggregates(unresolvedTypes, visitor.unresolvedTypes);
        } on Object catch (error) {
          unresolvedFiles.add({
            'source': source,
            'reason': error.runtimeType.toString(),
          });
        }
      }
    } finally {
      await collection.dispose();
    }

    resolvedFiles.sort();
    unresolvedFiles.sort(
      (left, right) =>
          (left['source'] as String).compareTo(right['source'] as String),
    );
    filesWithErrorDiagnostics.sort();
    final resolvedCallList = _sortedSemanticAggregates(resolvedCalls);
    final unresolvedCallList = _sortedSemanticAggregates(unresolvedCalls);
    final resolvedTypeList = _sortedSemanticAggregates(resolvedTypes);
    final unresolvedTypeList = _sortedSemanticAggregates(unresolvedTypes);
    final workspaceCallList = resolvedCallList
        .where((entry) => entry['target_scope'] == 'workspace')
        .toList();
    final workspaceTypeList = resolvedTypeList
        .where((entry) => entry['target_scope'] == 'workspace')
        .toList();

    return {
      'engine': 'package:analyzer AnalysisContextCollection/ResolvedUnitResult',
      'coverage_status': unresolvedFiles.isEmpty ? 'complete' : 'partial',
      'resolved_file_count': resolvedFiles.length,
      'unresolved_file_count': unresolvedFiles.length,
      'resolved_files': resolvedFiles,
      'unresolved_files': unresolvedFiles,
      'diagnostic_counts': {
        for (final key in diagnosticCounts.keys.toList()..sort())
          key: diagnosticCounts[key],
      },
      'files_with_error_diagnostics': filesWithErrorDiagnostics,
      'resolved_call_edge_count': resolvedCallList.length,
      'resolved_call_site_count': _semanticOccurrenceCount(resolvedCallList),
      'workspace_call_edge_count': workspaceCallList.length,
      'unresolved_call_edge_count': unresolvedCallList.length,
      'unresolved_call_site_count': _semanticOccurrenceCount(
        unresolvedCallList,
      ),
      'resolved_call_edges_scope': 'workspace_targets_only',
      'resolved_call_edges': workspaceCallList,
      'resolved_call_dependency_summary': _semanticLibrarySummary(
        resolvedCallList,
      ),
      'unresolved_call_sites': unresolvedCallList,
      'resolved_type_reference_count': resolvedTypeList.length,
      'workspace_type_reference_count': workspaceTypeList.length,
      'unresolved_type_reference_count': unresolvedTypeList.length,
      'resolved_type_references_scope': 'workspace_targets_only',
      'resolved_type_references': workspaceTypeList,
      'resolved_type_dependency_summary': _semanticLibrarySummary(
        resolvedTypeList,
      ),
      'unresolved_type_references': unresolvedTypeList,
    };
  }

  void _mergeSemanticAggregates(
    Map<String, Map<String, Object?>> target,
    Map<String, Map<String, Object?>> source,
  ) {
    for (final entry in source.entries) {
      final existing = target[entry.key];
      if (existing == null) {
        target[entry.key] = Map<String, Object?>.from(entry.value);
      } else {
        existing['occurrences'] =
            (existing['occurrences'] as int) +
            (entry.value['occurrences'] as int);
      }
    }
  }

  List<Map<String, Object?>> _sortedSemanticAggregates(
    Map<String, Map<String, Object?>> values,
  ) =>
      values.values.toList()
        ..sort((left, right) => jsonEncode(left).compareTo(jsonEncode(right)));

  int _semanticOccurrenceCount(List<Map<String, Object?>> values) =>
      values.fold(0, (total, value) => total + (value['occurrences'] as int));

  List<Map<String, Object?>> _semanticLibrarySummary(
    List<Map<String, Object?>> values,
  ) {
    final summary = <String, Map<String, Object?>>{};
    for (final value in values) {
      final scope = value['target_scope'] as String? ?? 'unknown';
      final library = value['target_library'] as String? ?? '<unresolved>';
      final key = '$scope\u0000$library';
      final entry = summary.putIfAbsent(
        key,
        () => {
          'target_scope': scope,
          'target_library': library,
          'unique_references': 0,
          'occurrences': 0,
        },
      );
      entry['unique_references'] = (entry['unique_references'] as int) + 1;
      entry['occurrences'] =
          (entry['occurrences'] as int) + (value['occurrences'] as int);
    }
    return summary.values.toList()
      ..sort((left, right) => jsonEncode(left).compareTo(jsonEncode(right)));
  }

  List<Map<String, Object?>> _modules(List<_DartUnit> units) {
    final grouped = <String, List<_DartUnit>>{};
    for (final unit in units) {
      final id = _moduleId(unit.source);
      grouped.putIfAbsent(id, () => []).add(unit);
    }
    final modules = <Map<String, Object?>>[];
    for (final entry in grouped.entries) {
      final symbols = entry.value.expand((unit) => unit.symbols).toList();
      modules.add({
        'id': entry.key,
        'layer': entry.key.split('/').first,
        'files': entry.value.map((unit) => unit.source).toList()..sort(),
        'file_count': entry.value.length,
        'symbol_count': symbols.length,
        'providers':
            symbols
                .where((symbol) => symbol.name.endsWith('Provider'))
                .map((symbol) => symbol.name)
                .toSet()
                .toList()
              ..sort(),
        'services':
            symbols
                .where((symbol) => symbol.name.endsWith('Service'))
                .map((symbol) => symbol.name)
                .toSet()
                .toList()
              ..sort(),
      });
    }
    return modules
      ..sort((a, b) => (a['id'] as String).compareTo(b['id'] as String));
  }

  String _moduleId(String source) {
    final parts = p.posix.split(source);
    if (parts.length >= 4 && parts[0] == 'app' && parts[1] == 'lib') {
      if (parts[2] == 'features') return 'app/${parts[3]}';
      return 'app/${parts[2]}';
    }
    if (parts.length >= 3 && parts[0] == 'server') {
      if (parts[1] == 'routes') return 'server/routes/${parts[2]}';
      if (parts[1] == 'lib') {
        return 'server/lib/${parts[2].replaceAll('.dart', '')}';
      }
      if (parts[1] == 'bin') return 'server/bin';
    }
    return parts.take(2).join('/');
  }

  List<Map<String, Object?>> _appRoutes(
    Map<String, dynamic> inventory,
    List<_DartUnit> units,
  ) {
    final astRoutes = units
        .where((unit) => unit.source == 'app/lib/main.dart')
        .expand((unit) => unit.routes)
        .toList();
    final byPath = <String, List<_RouteSymbol>>{};
    for (final route in astRoutes) {
      byPath.putIfAbsent(route.path, () => []).add(route);
    }
    final routeSurfaces = (inventory['route_surfaces'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    final routes = <Map<String, Object?>>[];
    for (final route in routeSurfaces) {
      final declaredPath = route['declared_path'] as String;
      final candidates = byPath[declaredPath] ?? const <_RouteSymbol>[];
      final ast = candidates.isEmpty ? null : candidates.first;
      routes.add({
        ...route,
        'source': 'app/lib/main.dart',
        'line': ast?.line,
        'ast_screen': ast?.target,
        'extraction': ast == null ? 'inventory_only' : 'inventory_plus_ast',
      });
    }
    return routes;
  }

  List<Map<String, Object?>> _webRoutes() {
    final appRoot = p.join(root.path, 'web-public/src/app');
    final files = _filesUnder(['web-public/src/app'], (file) {
      final name = p.basename(file.path);
      return name == 'page.tsx' ||
          name == 'page.ts' ||
          name == 'route.ts' ||
          name == 'route.tsx' ||
          name == 'robots.ts' ||
          name == 'sitemap.ts';
    });
    final routes = <Map<String, Object?>>[];
    for (final file in files) {
      final relative = p
          .relative(file.path, from: appRoot)
          .replaceAll('\\', '/');
      final name = p.posix.basename(relative);
      String route;
      String kind;
      if (name == 'robots.ts') {
        route = '/robots.txt';
        kind = 'metadata';
      } else if (name == 'sitemap.ts') {
        route = '/sitemap.xml';
        kind = 'metadata';
      } else {
        final parts = p.posix.split(relative)..removeLast();
        route = parts.isEmpty
            ? '/'
            : '/${parts.map((part) {
                final dynamicSegment = RegExp(r'^\[(.+)\]$').firstMatch(part);
                return dynamicSegment == null ? part : '{${dynamicSegment.group(1)}}';
              }).join('/')}';
        kind = name.startsWith('route.') ? 'route_handler' : 'page';
      }
      routes.add({'path': route, 'kind': kind, 'source': _relative(file)});
    }
    return routes..sort(
      (left, right) =>
          (left['path'] as String).compareTo(right['path'] as String),
    );
  }

  List<Map<String, Object?>> _apiRoutes(
    Map<String, dynamic> contracts,
    List<File> testFiles,
  ) {
    final overrides =
        ((contracts['api_method_overrides'] ?? const {})
                as Map<String, dynamic>)
            .map((key, value) => MapEntry(key, (value as List).cast<String>()));
    final routeFiles = _filesUnder(
      ['server/routes'],
      (file) =>
          file.path.endsWith('.dart') &&
          p.basename(file.path) != '_middleware.dart',
    );
    final result = <Map<String, Object?>>[];
    for (final file in routeFiles) {
      final source = file.readAsStringSync();
      final apiPath = _apiPath(file);
      final methods =
          RegExp(r'HttpMethod\.(get|post|put|patch|delete|options|head)')
              .allMatches(source)
              .map((match) => match.group(1)!.toUpperCase())
              .toSet();
      methods.addAll(overrides[apiPath] ?? const []);
      final middleware = _middlewareFor(file);
      final segment = apiPath
          .split('/')
          .where((part) => part.isNotEmpty && !part.startsWith('{'))
          .firstOrNull;
      final matchingTests = segment == null
          ? <String>[]
          : testFiles
                .where(
                  (test) => p
                      .basename(test.path)
                      .toLowerCase()
                      .contains(segment.toLowerCase()),
                )
                .map(_relative)
                .take(12)
                .toList();
      result.add({
        'path': apiPath,
        'methods': (methods.toList()..sort()),
        'source': _relative(file),
        'middleware': middleware,
        'tests': matchingTests,
        'method_contract': overrides.containsKey(apiPath)
            ? 'source_plus_manual_override'
            : methods.isEmpty
            ? 'unresolved'
            : 'source',
      });
    }
    return result
      ..sort((a, b) => (a['path'] as String).compareTo(b['path'] as String));
  }

  String _apiPath(File file) {
    var relative = p
        .relative(file.path, from: p.join(root.path, 'server/routes'))
        .replaceAll('\\', '/');
    relative = relative.replaceFirst(RegExp(r'\.dart$'), '');
    final parts = p.posix.split(relative);
    if (parts.last == 'index') parts.removeLast();
    final converted = parts.map((part) {
      final match = RegExp(r'^\[(.+)\]$').firstMatch(part);
      return match == null ? part : '{${match.group(1)}}';
    }).toList();
    return converted.isEmpty ? '/' : '/${converted.join('/')}';
  }

  List<String> _middlewareFor(File routeFile) {
    final middleware = <String>[];
    var directory = routeFile.parent;
    final routesRoot = Directory(
      p.join(root.path, 'server/routes'),
    ).absolute.path;
    while (p.isWithin(routesRoot, directory.absolute.path) ||
        directory.absolute.path == routesRoot) {
      final candidate = File(p.join(directory.path, '_middleware.dart'));
      if (candidate.existsSync()) middleware.add(_relative(candidate));
      if (directory.absolute.path == routesRoot) break;
      directory = directory.parent;
    }
    return middleware.reversed.toList();
  }

  Map<String, Object?> _databaseModel(
    String setupSql,
    String migrationsSource,
    List<_DartUnit> units,
  ) {
    final migrations = <Map<String, Object?>>[];
    final migrationPattern = RegExp(
      r"Migration\(\s*version:\s*'([0-9]+)'\s*,\s*name:\s*'([^']+)'",
      dotAll: true,
    );
    for (final match in migrationPattern.allMatches(migrationsSource)) {
      migrations.add({
        'version': match.group(1),
        'name': match.group(2),
        'source': 'server/bin/migrate.dart',
      });
    }

    final schemaUnits = units
        .where(
          (unit) =>
              unit.source.startsWith('server/lib/') ||
              unit.source.startsWith('server/bin/'),
        )
        .where((unit) => unit.sqlLiterals.isNotEmpty)
        .toList();
    final sql = _stripSqlComments(
      '$setupSql\n$migrationsSource\n'
      '${schemaUnits.expand((unit) => unit.sqlLiterals).join(';\n')}',
    );
    final tables = <String, _SqlTable>{};
    final relations = <_SqlRelation>{};
    final createPattern = RegExp(
      r'CREATE\s+TABLE\s+(?:IF\s+NOT\s+EXISTS\s+)?(["A-Za-z_][\w."]*)\s*\((.*?)\)\s*;',
      caseSensitive: false,
      dotAll: true,
    );
    for (final match in createPattern.allMatches(sql)) {
      final tableName = _sqlName(match.group(1)!);
      final table = tables.putIfAbsent(tableName, () => _SqlTable(tableName));
      for (final item in _splitSqlItems(match.group(2)!)) {
        _mergeSqlItem(table, item, relations);
      }
    }

    final alterColumnPattern = RegExp(
      r'ALTER\s+TABLE(?:\s+IF\s+EXISTS)?\s+(["A-Za-z_][\w."]*)\s+ADD\s+COLUMN(?:\s+IF\s+NOT\s+EXISTS)?\s+"?([A-Za-z_]\w*)"?\s+([^;]+);',
      caseSensitive: false,
      dotAll: true,
    );
    for (final match in alterColumnPattern.allMatches(sql)) {
      final tableName = _sqlName(match.group(1)!);
      final table = tables.putIfAbsent(tableName, () => _SqlTable(tableName));
      final definition = match.group(3)!.replaceAll(RegExp(r'\s+'), ' ').trim();
      table.mergeColumn(
        _SqlColumn(
          match.group(2)!,
          _sqlType(definition),
          primaryKey: definition.toUpperCase().contains('PRIMARY KEY'),
          nullable: !definition.toUpperCase().contains('NOT NULL'),
        ),
      );
      final reference = RegExp(
        r'REFERENCES\s+(["A-Za-z_][\w."]*)\s*\(\s*"?([A-Za-z_]\w*)"?\s*\)',
        caseSensitive: false,
      ).firstMatch(definition);
      if (reference != null) {
        relations.add(
          _SqlRelation(
            tableName,
            match.group(2)!,
            _sqlName(reference.group(1)!),
            reference.group(2)!,
          ),
        );
      }
    }

    final views =
        RegExp(
              r'CREATE\s+(?:OR\s+REPLACE\s+)?VIEW\s+(["A-Za-z_][\w."]*)',
              caseSensitive: false,
            )
            .allMatches(sql)
            .map((match) => _sqlName(match.group(1)!))
            .toSet()
            .toList()
          ..sort();
    final tableList = tables.values.map((table) => table.toJson()).toList()
      ..sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
    final relationList = relations.map((relation) => relation.toJson()).toList()
      ..sort((a, b) => jsonEncode(a).compareTo(jsonEncode(b)));
    return {
      'source_of_truth': 'PostgreSQL/backend',
      'schema_sources': [
        'server/database_setup.sql',
        'server/bin/migrate.dart',
        ...schemaUnits.map((unit) => unit.source),
      ],
      'migration_count': migrations.length,
      'latest_migration': migrations.isEmpty
          ? null
          : migrations.last['version'],
      'migrations': migrations,
      'tables': tableList,
      'views': views,
      'relations': relationList,
      'runtime_validation': 'cd server && dart run bin/migrate.dart --status',
      'hermes_policy': 'cache_or_laboratory_not_product_truth',
    };
  }

  String _stripSqlComments(String source) {
    final output = StringBuffer();
    var inSingleQuote = false;
    var index = 0;
    while (index < source.length) {
      final char = source[index];
      final next = index + 1 < source.length ? source[index + 1] : '';
      if (char == "'") {
        if (inSingleQuote && next == "'") {
          output.write("''");
          index += 2;
          continue;
        }
        inSingleQuote = !inSingleQuote;
        output.write(char);
        index++;
        continue;
      }
      if (!inSingleQuote && char == '-' && next == '-') {
        while (index < source.length && source[index] != '\n') {
          index++;
        }
        output.write('\n');
        if (index < source.length) index++;
        continue;
      }
      if (!inSingleQuote && char == '/' && next == '*') {
        index += 2;
        while (index + 1 < source.length &&
            !(source[index] == '*' && source[index + 1] == '/')) {
          if (source[index] == '\n') output.write('\n');
          index++;
        }
        index = index + 1 < source.length ? index + 2 : source.length;
        continue;
      }
      output.write(char);
      index++;
    }
    return output.toString();
  }

  void _mergeSqlItem(_SqlTable table, String raw, Set<_SqlRelation> relations) {
    final item = raw.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (item.isEmpty) return;
    final upper = item.toUpperCase();
    final foreignKey = RegExp(
      r'FOREIGN\s+KEY\s*\(\s*"?([A-Za-z_]\w*)"?\s*\).*?REFERENCES\s+(["A-Za-z_][\w."]*)\s*\(\s*"?([A-Za-z_]\w*)"?\s*\)',
      caseSensitive: false,
    ).firstMatch(item);
    if (foreignKey != null) {
      relations.add(
        _SqlRelation(
          table.name,
          foreignKey.group(1)!,
          _sqlName(foreignKey.group(2)!),
          foreignKey.group(3)!,
        ),
      );
      return;
    }
    if (upper.startsWith('CONSTRAINT ') ||
        upper.startsWith('PRIMARY KEY') ||
        upper.startsWith('UNIQUE ') ||
        upper.startsWith('CHECK ')) {
      return;
    }
    final column = RegExp(r'^"?([A-Za-z_]\w*)"?\s+(.+)$').firstMatch(item);
    if (column == null) return;
    final definition = column.group(2)!;
    table.mergeColumn(
      _SqlColumn(
        column.group(1)!,
        _sqlType(definition),
        primaryKey: definition.toUpperCase().contains('PRIMARY KEY'),
        nullable: !definition.toUpperCase().contains('NOT NULL'),
      ),
    );
    final reference = RegExp(
      r'REFERENCES\s+(["A-Za-z_][\w."]*)\s*\(\s*"?([A-Za-z_]\w*)"?\s*\)',
      caseSensitive: false,
    ).firstMatch(definition);
    if (reference != null) {
      relations.add(
        _SqlRelation(
          table.name,
          column.group(1)!,
          _sqlName(reference.group(1)!),
          reference.group(2)!,
        ),
      );
    }
  }

  List<String> _splitSqlItems(String block) {
    final items = <String>[];
    var depth = 0;
    var start = 0;
    var quoted = false;
    for (var index = 0; index < block.length; index++) {
      final char = block[index];
      if (char == "'") quoted = !quoted;
      if (quoted) continue;
      if (char == '(') depth++;
      if (char == ')') depth--;
      if (char == ',' && depth == 0) {
        items.add(block.substring(start, index));
        start = index + 1;
      }
    }
    items.add(block.substring(start));
    return items;
  }

  String _sqlName(String value) => value.replaceAll('"', '').split('.').last;

  String _sqlType(String definition) {
    final match = RegExp(
      r'^(.*?)(?=\s+(?:NOT\s+NULL|NULL|DEFAULT|PRIMARY\s+KEY|REFERENCES|UNIQUE|CHECK|CONSTRAINT)\b|$)',
      caseSensitive: false,
    ).firstMatch(definition.trim());
    return (match?.group(1) ?? definition).trim().replaceAll(
      RegExp(r'\s+'),
      ' ',
    );
  }

  Future<Map<String, Object?>> _dependencies() async {
    final packages = <Map<String, Object?>>[];
    for (final file in _pubspecFiles()) {
      final lines = file.readAsLinesSync();
      String? section;
      for (final line in lines) {
        if (line == 'dependencies:' || line == 'dev_dependencies:') {
          section = line.substring(0, line.length - 1);
          continue;
        }
        if (line.isNotEmpty && !line.startsWith(' ') && line.endsWith(':')) {
          section = null;
        }
        if (section == null) continue;
        final match = RegExp(
          r'^  ([A-Za-z0-9_]+):(?:\s*(.*))?$',
        ).firstMatch(line);
        if (match == null) continue;
        final value = (match.group(2) ?? '').trim();
        packages.add({
          'package': match.group(1),
          'scope': section,
          'constraint': value.isEmpty ? 'structured_or_sdk' : value,
          'source': _relative(file),
        });
      }
    }
    packages.sort((a, b) {
      final bySource = (a['source'] as String).compareTo(b['source'] as String);
      return bySource != 0
          ? bySource
          : (a['package'] as String).compareTo(b['package'] as String);
    });
    final resolvedTrees = <Map<String, Object?>>[];
    for (final pubspec in _pubspecFiles()) {
      final packageConfig = File(
        p.join(pubspec.parent.path, '.dart_tool/package_config.json'),
      );
      if (!packageConfig.existsSync()) continue;
      final process = await Process.run(Platform.resolvedExecutable, [
        'pub',
        'deps',
        '--json',
      ], workingDirectory: pubspec.parent.path);
      if (process.exitCode != 0) {
        throw ProjectLogicException(
          'dart pub deps failed for ${_relative(pubspec)}: ${process.stderr}',
        );
      }
      final tree = jsonDecode(process.stdout as String) as Map<String, dynamic>;
      resolvedTrees.add({
        'source': _relative(pubspec),
        'root': tree['root'],
        'packages': tree['packages'],
      });
    }
    return {
      'declared': packages,
      'resolved_trees': resolvedTrees,
      'node': _nodeDependencies(),
    };
  }

  Map<String, Object?> _nodeDependencies() {
    final packageFile = _file('web-public/package.json');
    final lockFile = _file('web-public/package-lock.json');
    if (!packageFile.existsSync() || !lockFile.existsSync()) {
      return {'status': 'not_present'};
    }
    final package = _decodeMap(packageFile);
    final lock = _decodeMap(lockFile);
    final declared = <Map<String, Object?>>[];
    for (final section in ['dependencies', 'devDependencies']) {
      final dependencies =
          (package[section] as Map<String, dynamic>? ?? const {});
      for (final entry in dependencies.entries) {
        declared.add({
          'package': entry.key,
          'scope': section,
          'constraint': entry.value,
        });
      }
    }
    declared.sort(
      (left, right) =>
          (left['package'] as String).compareTo(right['package'] as String),
    );

    final resolved = <Map<String, Object?>>[];
    final lockedPackages =
        lock['packages'] as Map<String, dynamic>? ?? const {};
    for (final entry in lockedPackages.entries) {
      if (entry.key.isEmpty || !entry.key.contains('node_modules/')) continue;
      final metadata = entry.value as Map<String, dynamic>;
      resolved.add({
        'package': entry.key.split('node_modules/').last,
        'version': metadata['version'],
        'dev': metadata['dev'] == true,
        'optional': metadata['optional'] == true,
      });
    }
    resolved.sort(
      (left, right) =>
          (left['package'] as String).compareTo(right['package'] as String),
    );
    return {
      'status': 'locked',
      'source': 'web-public/package.json',
      'lock_source': 'web-public/package-lock.json',
      'lockfile_version': lock['lockfileVersion'],
      'declared': declared,
      'resolved': resolved,
    };
  }

  List<Map<String, Object?>> _scripts(List<File> files) {
    final scripts = <Map<String, Object?>>[];
    for (final file in files) {
      final relative = _relative(file);
      final content = file.readAsStringSync();
      final lower = relative.toLowerCase();
      final mutatingSignal = RegExp(
        r'(CONFIRM_LIVE_MUTATIONS|CONFIRM_POSTGRES_WRITES|deploy|publish|migrate|backfill|INSERT\s+INTO|UPDATE\s+[A-Za-z_]|DELETE\s+FROM)',
        caseSensitive: false,
      ).hasMatch(content);
      final role = lower.contains('battle')
          ? 'battle'
          : lower.contains('deploy') || lower.contains('publish')
          ? 'release'
          : lower.contains('backup') || lower.contains('restore')
          ? 'disaster_recovery'
          : lower.contains('audit') || lower.contains('validate')
          ? 'audit'
          : lower.contains('test') || lower.contains('quality_gate')
          ? 'test_or_gate'
          : 'operation';
      scripts.add({
        'path': relative,
        'role': role,
        'mutation_class': mutatingSignal
            ? 'guarded_or_review_required'
            : 'read_only_or_unknown',
        'environment_variables': _extractEnvironmentNames(content).toList()
          ..sort(),
      });
    }
    return scripts
      ..sort((a, b) => (a['path'] as String).compareTo(b['path'] as String));
  }

  List<Map<String, Object?>> _environmentVariables(
    List<_DartUnit> units,
    List<File> scriptFiles,
  ) {
    final sources = <String, Set<String>>{};
    for (final unit in units) {
      for (final name in _extractEnvironmentNames(unit.content)) {
        sources.putIfAbsent(name, () => {}).add(unit.source);
      }
    }
    for (final file in scriptFiles) {
      for (final name in _extractEnvironmentNames(file.readAsStringSync())) {
        sources.putIfAbsent(name, () => {}).add(_relative(file));
      }
    }
    final result = <Map<String, Object?>>[];
    for (final entry in sources.entries) {
      final sensitive = RegExp(
        r'(SECRET|TOKEN|PASSWORD|PASS|PRIVATE|DSN|DATABASE_URL|KEY|CREDENTIAL)',
        caseSensitive: false,
      ).hasMatch(entry.key);
      result.add({
        'name': entry.key,
        'classification': sensitive ? 'sensitive_name_only' : 'configuration',
        'sources': entry.value.toList()..sort(),
        'value_captured': false,
      });
    }
    return result
      ..sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
  }

  Set<String> _extractEnvironmentNames(String content) {
    final names = <String>{};
    final patterns = <RegExp>[
      RegExp(
        r'''(?:String|bool|int|double)\.fromEnvironment\(\s*['"]([A-Z][A-Z0-9_]*)''',
      ),
      RegExp(
        r'''(?:Platform\.)?environment\s*\[\s*['"]([A-Z][A-Z0-9_]*)['"]\s*\]''',
      ),
      RegExp(
        r'''(?:os\.environ|getenv)\s*(?:\.get)?\(\s*['"]([A-Z][A-Z0-9_]*)['"]''',
      ),
      RegExp(r'\$\{([A-Z][A-Z0-9_]*)[:}]'),
    ];
    for (final pattern in patterns) {
      for (final match in pattern.allMatches(content)) {
        names.add(match.group(1)!);
      }
    }
    return names;
  }

  List<Map<String, Object?>> _qualityGates() {
    final source = _file('scripts/quality_gate.sh').readAsStringSync();
    final modes =
        RegExp(r'^\s{4}([a-z][a-z0-9-]*)\)\s*$', multiLine: true)
            .allMatches(source)
            .map((match) => match.group(1)!)
            .where((mode) => mode != 'help')
            .toSet()
            .toList()
          ..sort();
    return modes
        .map(
          (mode) => <String, Object?>{
            'mode': mode,
            'command': './scripts/quality_gate.sh $mode',
            'source': 'scripts/quality_gate.sh',
          },
        )
        .toList();
  }

  List<Map<String, Object?>> _symbolsWithSuffix(
    List<Map<String, Object?>> symbols,
    String suffix,
  ) => symbols
      .where((symbol) => (symbol['name'] as String).endsWith(suffix))
      .toList();

  Map<String, Object?> _openApi(
    List<Map<String, Object?>> apiRoutes,
    Map<String, dynamic> contracts,
    String digest,
  ) {
    final publicPaths =
        ((contracts['public_api_paths'] ?? const []) as List<dynamic>)
            .cast<String>()
            .toSet();
    final paths = <String, Object?>{};
    final unresolved = <String>[];
    for (final route in apiRoutes) {
      final apiPath = route['path'] as String;
      final methods = (route['methods'] as List<dynamic>).cast<String>();
      if (methods.isEmpty) {
        unresolved.add(apiPath);
        continue;
      }
      final pathItem = <String, Object?>{};
      for (final method in methods) {
        final parameters = RegExp(r'\{([^}]+)\}')
            .allMatches(apiPath)
            .map(
              (match) => <String, Object?>{
                'name': match.group(1),
                'in': 'path',
                'required': true,
                'schema': {'type': 'string'},
              },
            )
            .toList();
        pathItem[method.toLowerCase()] = {
          'operationId': _operationId(method, apiPath),
          'summary': '$method $apiPath',
          'tags': [_apiTag(apiPath)],
          'x-manaloom-source': route['source'],
          'x-manaloom-contract-level': 'structural_generated',
          if ((route['tests'] as List).isNotEmpty)
            'x-manaloom-tests': route['tests'],
          if (parameters.isNotEmpty) 'parameters': parameters,
          if (!publicPaths.contains(apiPath))
            'security': [
              {'bearerAuth': <String>[]},
            ],
          'responses': {
            'default': {
              'description':
                  'Shape is governed by server/doc/API_CONTRACTS_AND_DATA_MAP.md and route tests.',
            },
          },
        };
      }
      paths[apiPath] = pathItem;
    }
    return {
      'openapi': '3.1.0',
      'info': {
        'title': 'ManaLoom structural API contract',
        'version': '1.0.0',
        'description':
            'Generated route/method inventory. Payload shapes remain canonical in route tests and API_CONTRACTS_AND_DATA_MAP.md until typed DTO coverage is complete.',
      },
      'x-manaloom-source-digest-sha256': digest,
      'x-manaloom-unresolved-method-paths': unresolved,
      'servers': [
        {'url': '/'},
      ],
      'components': {
        'securitySchemes': {
          'bearerAuth': {
            'type': 'http',
            'scheme': 'bearer',
            'bearerFormat': 'JWT',
          },
        },
      },
      'paths': paths,
    };
  }

  String _operationId(String method, String path) {
    final suffix = path
        .replaceAll(RegExp(r'[{}]'), '')
        .split('/')
        .where((part) => part.isNotEmpty)
        .map(_pascal)
        .join();
    return '${method.toLowerCase()}$suffix';
  }

  String _apiTag(String path) =>
      path
          .split('/')
          .where((part) => part.isNotEmpty && !part.startsWith('{'))
          .firstOrNull ??
      'root';

  String _pascal(String value) => value
      .split(RegExp(r'[-_]'))
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join();

  String _sourceDigest(List<File> files) {
    final index = StringBuffer();
    for (final file in files) {
      index
        ..write(_relative(file))
        ..write('\u0000')
        ..write(sha256.convert(file.readAsBytesSync()))
        ..write('\u0000');
    }
    return sha256.convert(utf8.encode(index.toString())).toString();
  }

  String _prettyJson(Object? value) =>
      '${const JsonEncoder.withIndent('  ').convert(value)}\n';

  String _currentSystem(Map<String, Object?> manifest) {
    final stats = manifest['statistics'] as Map<String, Object?>;
    final policy = manifest['source_policy'] as Map<String, dynamic>;
    final flows = (manifest['flows'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    final buffer = StringBuffer()
      ..writeln('# ManaLoom — sistema atual gerado')
      ..writeln()
      ..writeln(
        '> Gerado por `scripts/manaloom_project_logic.sh --write`. Não editar manualmente.',
      )
      ..writeln()
      ..writeln('**Digest das fontes:** `${manifest['source_digest_sha256']}`')
      ..writeln()
      ..writeln('## Fontes de verdade')
      ..writeln()
      ..writeln('- Produto e persistência: **${policy['product_data']}**.')
      ..writeln('- Cache/laboratório: **${policy['cache_and_laboratory']}**.')
      ..writeln('- Runtime de cartas: **${policy['card_runtime']}**.')
      ..writeln('- Intenção/decisões: **${policy['human_decisions']}**.')
      ..writeln()
      ..writeln('## Inventário')
      ..writeln()
      ..writeln('| Superfície | Quantidade |')
      ..writeln('|---|---:|');
    for (final entry in stats.entries) {
      buffer.writeln('| `${entry.key}` | ${entry.value} |');
    }
    buffer
      ..writeln()
      ..writeln('## Fluxos canônicos')
      ..writeln()
      ..writeln('| Fluxo | Estado declarado | Fonte de verdade |')
      ..writeln('|---|---|---|');
    for (final flow in flows) {
      buffer.writeln(
        '| ${flow['name']} | `${flow['status']}` | ${flow['source_of_truth']} |',
      );
    }
    buffer
      ..writeln()
      ..writeln('## Como validar')
      ..writeln()
      ..writeln('```bash')
      ..writeln('./scripts/manaloom_project_logic.sh --check')
      ..writeln('./scripts/manaloom_local_ci.sh schema')
      ..writeln('./scripts/manaloom_local_ci.sh full')
      ..writeln('```')
      ..writeln()
      ..writeln(
        'Consulte `project_logic_manifest.json` para a estrutura completa e `docs/generated/TRACEABILITY_MATRIX.md` para regra → implementação → teste → banco.',
      );
    return buffer.toString();
  }

  String _architecture(Map<String, Object?> manifest) {
    final modules = (manifest['modules'] as List<dynamic>)
        .cast<Map<String, Object?>>();
    final layerCounts = <String, int>{};
    for (final module in modules) {
      layerCounts.update(
        module['layer'] as String,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    }
    return '''# ManaLoom — arquitetura gerada

> Gerado. A topologia vem do manifesto; razões arquiteturais continuam em ADRs/documentos canônicos.

```mermaid
flowchart LR
    UI["Flutter app (${layerCounts['app'] ?? 0} módulos)"] --> API["Dart Frog routes"]
    WEB["Next.js público (${(manifest['web_routes'] as List).length} rotas)"] --> API
    API --> DOMAIN["Backend services (${layerCounts['server'] ?? 0} módulos)"]
    DOMAIN --> PG[("PostgreSQL — fonte de verdade")]
    DOMAIN --> AI["Deckbuilder / Optimize"]
    DOMAIN --> BATTLE["Battle router"]
    BATTLE --> NATIVE["ManaLoom native"]
    BATTLE --> XMAGE["XMage pinado"]
    BATTLE --> FORGE["Forge pinado para gaps"]
    PG --> HERMES[("Hermes / SQLite — cache e laboratório")]
    SRC["Código + migrations + contratos manuais"] --> GEN["manaloom_project_logic"]
    GEN --> MANIFEST["project_logic_manifest.json"]
    MANIFEST --> DOCS["Markdown + Mermaid + OpenAPI + ERD"]
    MANIFEST --> LOCAL["Hooks e gates locais gratuitos"]
    LOCAL --> TBLS["PostgreSQL descartável + tbls"]
    MCP["Dart/Flutter MCP + DTD"] --> UI
    MCP --> DOMAIN
```

## Política

- O gerador extrai estrutura; não promove hipótese histórica a verdade.
- PostgreSQL/backend prevalece sobre Hermes/SQLite.
- OpenAPI é estrutural enquanto handlers não tiverem DTOs tipados completos.
- Runtime MCP confirma árvore, erros e estado vivo; não substitui testes nem contratos.
''';
  }

  String _flowsDocument(Map<String, Object?> manifest) {
    final flows = (manifest['flows'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    final buffer = StringBuffer()
      ..writeln('# ManaLoom — fluxos gerados')
      ..writeln()
      ..writeln(
        '> As sequências são declaradas em `docs/project_logic_contracts.json`; paths são validados pelo gerador.',
      )
      ..writeln();
    for (final flow in flows) {
      buffer
        ..writeln('## ${flow['name']}')
        ..writeln()
        ..writeln('Estado: `${flow['status']}`')
        ..writeln('Fonte de verdade: ${flow['source_of_truth']}')
        ..writeln()
        ..writeln('```mermaid')
        ..writeln('sequenceDiagram');
      final participants = <String>{};
      for (final step in (flow['sequence'] as List<dynamic>)) {
        final map = step as Map<String, dynamic>;
        participants.add(map['from'] as String);
        participants.add(map['to'] as String);
      }
      for (final participant in participants) {
        buffer.writeln(
          '    participant ${_mermaidId(participant)} as ${_mermaidText(participant)}',
        );
      }
      for (final step in (flow['sequence'] as List<dynamic>)) {
        final map = step as Map<String, dynamic>;
        buffer.writeln(
          '    ${_mermaidId(map['from'] as String)}->>${_mermaidId(map['to'] as String)}: ${_mermaidText(map['message'] as String)}',
        );
      }
      buffer
        ..writeln('```')
        ..writeln()
        ..writeln(
          'Implementação: ${(flow['implementation'] as List).map((value) => '`$value`').join(', ')}.',
        )
        ..writeln(
          'Testes: ${(flow['tests'] as List).map((value) => '`$value`').join(', ')}.',
        )
        ..writeln(
          'Gates: ${(flow['gates'] as List).map((value) => '`$value`').join(', ')}.',
        )
        ..writeln();
    }
    return '${buffer.toString().trimRight()}\n';
  }

  String _apiMap(Map<String, Object?> manifest) {
    final routes = (manifest['api_routes'] as List<dynamic>)
        .cast<Map<String, Object?>>();
    final buffer = StringBuffer()
      ..writeln('# ManaLoom — mapa estrutural de API')
      ..writeln()
      ..writeln(
        '> Gerado das convenções de `server/routes` e dos métodos encontrados no código. Shapes detalhados continuam em `server/doc/API_CONTRACTS_AND_DATA_MAP.md`.',
      )
      ..writeln()
      ..writeln('| Path | Métodos | Handler | Middleware | Prova |')
      ..writeln('|---|---|---|---|---|');
    for (final route in routes) {
      final methods = (route['methods'] as List).join(', ');
      final middleware = (route['middleware'] as List).length;
      buffer.writeln(
        '| `${route['path']}` | `${methods.isEmpty ? 'UNRESOLVED' : methods}` | `${route['source']}` | $middleware | `${route['method_contract']}` |',
      );
    }
    buffer
      ..writeln()
      ..writeln(
        'Contrato OpenAPI estrutural: `docs/generated/openapi.generated.json`.',
      );
    return buffer.toString();
  }

  String _databaseErd(Map<String, Object?> manifest) {
    final database = manifest['database'] as Map<String, Object?>;
    final tables = (database['tables'] as List<dynamic>)
        .cast<Map<String, Object?>>();
    final relations = (database['relations'] as List<dynamic>)
        .cast<Map<String, Object?>>();
    final buffer = StringBuffer()
      ..writeln('# ManaLoom — ERD PostgreSQL gerado')
      ..writeln()
      ..writeln(
        '> Extraído de `server/database_setup.sql`, migrations e constantes SQL importadas pelo backend. Confirme o schema aplicado com o gate `tbls` local descartável.',
      )
      ..writeln()
      ..writeln('```mermaid')
      ..writeln('erDiagram');
    for (final relation in relations) {
      buffer.writeln(
        '    ${_mermaidId(relation['to_table'] as String)} ||--o{ ${_mermaidId(relation['from_table'] as String)} : "${_mermaidText('${relation['from_column']} -> ${relation['to_column']}')}"',
      );
    }
    for (final table in tables) {
      buffer.writeln('    ${_mermaidId(table['name'] as String)} {');
      final columns = (table['columns'] as List<dynamic>)
          .cast<Map<String, Object?>>();
      if (columns.isEmpty) {
        buffer.writeln('        string unknown');
      } else {
        for (final column in columns.take(24)) {
          final type = _mermaidType(column['type'] as String);
          final marker = column['primary_key'] == true ? ' PK' : '';
          buffer.writeln(
            '        $type ${_mermaidId(column['name'] as String)}$marker',
          );
        }
      }
      buffer.writeln('    }');
    }
    buffer
      ..writeln('```')
      ..writeln()
      ..writeln(
        'Tabelas: ${tables.length}; views: ${(database['views'] as List).length}; migrations: ${database['migration_count']} (latest `${database['latest_migration']}`).',
      );
    return buffer.toString();
  }

  String _traceability(Map<String, Object?> manifest) {
    final rules = (manifest['traceability'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    final buffer = StringBuffer()
      ..writeln('# ManaLoom — matriz de rastreabilidade gerada')
      ..writeln()
      ..writeln(
        '| Regra | Implementação | Teste | PostgreSQL/local | Fonte canônica |',
      )
      ..writeln('|---|---|---|---|---|');
    for (final rule in rules) {
      buffer.writeln(
        '| ${_markdownCell(rule['rule'] as String)} | ${(rule['implementation'] as List).map((value) => '`$value`').join('<br>')} | ${(rule['tests'] as List).map((value) => '`$value`').join('<br>')} | ${(rule['tables'] as List).map((value) => '`$value`').join('<br>')} | ${_markdownCell(rule['canonical_source'] as String)} |',
      );
    }
    return buffer.toString();
  }

  String _mermaidId(String value) =>
      value.replaceAll(RegExp(r'[^A-Za-z0-9_]'), '_');
  String _mermaidText(String value) =>
      value.replaceAll('"', "'").replaceAll('\n', ' ');
  String _markdownCell(String value) =>
      value.replaceAll('|', '\\|').replaceAll('\n', ' ');
  String _mermaidType(String value) {
    final normalized = value.toLowerCase();
    if (normalized.contains('int') ||
        normalized.contains('decimal') ||
        normalized.contains('numeric')) {
      return 'number';
    }
    if (normalized.contains('bool')) return 'boolean';
    if (normalized.contains('time') || normalized == 'date') return 'datetime';
    if (normalized.contains('json')) return 'json';
    if (normalized.contains('uuid')) return 'uuid';
    return 'string';
  }
}

int _compareJsonBySourceName(
  Map<String, Object?> left,
  Map<String, Object?> right,
) {
  final bySource = (left['source'] as String).compareTo(
    right['source'] as String,
  );
  if (bySource != 0) return bySource;
  return (left['name'] as String).compareTo(right['name'] as String);
}

class _DartUnit {
  _DartUnit({
    required this.source,
    required this.content,
    required this.imports,
    required this.symbols,
    required this.routes,
    required this.sqlLiterals,
  });

  final String source;
  final String content;
  final List<String> imports;
  final List<_DartSymbol> symbols;
  final List<_RouteSymbol> routes;
  final List<String> sqlLiterals;
}

class _DartSymbol {
  _DartSymbol(this.name, this.kind, this.source, this.line, this.members);

  final String name;
  final String kind;
  final String source;
  final int line;
  final List<String> members;

  Map<String, Object?> toJson() => {
    'name': name,
    'kind': kind,
    'source': source,
    'line': line,
    if (members.isNotEmpty) 'members': members,
  };
}

class _RouteSymbol {
  _RouteSymbol(this.path, this.target, this.line);

  final String path;
  final String? target;
  final int line;
}

class _ProjectLogicAstVisitor extends RecursiveAstVisitor<void> {
  _ProjectLogicAstVisitor({required this.source, required this.lineInfo});

  final String source;
  final LineInfo lineInfo;
  final symbols = <_DartSymbol>[];
  final routes = <_RouteSymbol>[];
  final sqlLiterals = <String>[];

  int _line(AstNode node) => lineInfo.getLocation(node.offset).lineNumber;

  @override
  void visitSimpleStringLiteral(SimpleStringLiteral node) {
    if (RegExp(
      r'CREATE\s+(?:OR\s+REPLACE\s+)?(?:TABLE|VIEW)\b',
      caseSensitive: false,
    ).hasMatch(node.value)) {
      sqlLiterals.add(node.value);
    }
    super.visitSimpleStringLiteral(node);
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final members =
        node.members
            .whereType<MethodDeclaration>()
            .map((member) => member.name.lexeme)
            .toSet()
            .toList()
          ..sort();
    symbols.add(
      _DartSymbol(node.name.lexeme, 'class', source, _line(node), members),
    );
    super.visitClassDeclaration(node);
  }

  @override
  void visitEnumDeclaration(EnumDeclaration node) {
    symbols.add(
      _DartSymbol(node.name.lexeme, 'enum', source, _line(node), const []),
    );
    super.visitEnumDeclaration(node);
  }

  @override
  void visitMixinDeclaration(MixinDeclaration node) {
    symbols.add(
      _DartSymbol(node.name.lexeme, 'mixin', source, _line(node), const []),
    );
    super.visitMixinDeclaration(node);
  }

  @override
  void visitExtensionDeclaration(ExtensionDeclaration node) {
    symbols.add(
      _DartSymbol(
        node.name?.lexeme ?? 'unnamed_extension_${_line(node)}',
        'extension',
        source,
        _line(node),
        const [],
      ),
    );
    super.visitExtensionDeclaration(node);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    symbols.add(
      _DartSymbol(node.name.lexeme, 'function', source, _line(node), const []),
    );
    super.visitFunctionDeclaration(node);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final type = node.constructorName.type.toSource().split('<').first;
    if (type == 'GoRoute') {
      String? path;
      for (final argument in node.argumentList.arguments) {
        if (argument is NamedExpression &&
            argument.name.label.name == 'path' &&
            argument.expression is StringLiteral) {
          path = (argument.expression as StringLiteral).stringValue;
        }
      }
      if (path != null) {
        final target =
            RegExp(r'\b([A-Z][A-Za-z0-9_]*(?:Screen|Page|View))\s*\(')
                .allMatches(node.toSource())
                .map((match) => match.group(1)!)
                .firstOrNull;
        routes.add(_RouteSymbol(path, target, _line(node)));
      }
    }
    super.visitInstanceCreationExpression(node);
  }
}

class _ProjectLogicSemanticVisitor extends RecursiveAstVisitor<void> {
  _ProjectLogicSemanticVisitor({required this.source, required this.lineInfo});

  final String source;
  final LineInfo lineInfo;
  final resolvedCalls = <String, Map<String, Object?>>{};
  final unresolvedCalls = <String, Map<String, Object?>>{};
  final resolvedTypes = <String, Map<String, Object?>>{};
  final unresolvedTypes = <String, Map<String, Object?>>{};

  int _line(AstNode node) => lineInfo.getLocation(node.offset).lineNumber;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    _recordCall(
      node: node,
      kind: 'method',
      lexicalTarget: node.methodName.name,
      element: node.methodName.element,
    );
    super.visitMethodInvocation(node);
  }

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    _recordCall(
      node: node,
      kind: 'function_expression',
      lexicalTarget: node.function.toSource(),
      element: node.element,
    );
    super.visitFunctionExpressionInvocation(node);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    _recordCall(
      node: node,
      kind: 'constructor',
      lexicalTarget: node.constructorName.toSource(),
      element: node.constructorName.element,
    );
    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitNamedType(NamedType node) {
    final element = node.element;
    final resolvedType = node.type?.getDisplayString();
    if (element == null || resolvedType == null) {
      _upsert(
        unresolvedTypes,
        {
          'source': source,
          'line': _line(node),
          'lexical_type': node.toSource(),
        },
        keyParts: [source, node.toSource()],
      );
    } else {
      _upsert(
        resolvedTypes,
        {
          'source': source,
          'line': _line(node),
          'lexical_type': node.toSource(),
          'resolved_type': resolvedType,
          'target': _qualifiedElementName(element),
          'target_library': element.library?.uri.toString(),
          'target_scope': _targetScope(element.library?.uri.toString()),
        },
        keyParts: [
          source,
          node.toSource(),
          resolvedType,
          element.library?.uri.toString() ?? '',
        ],
      );
    }
    super.visitNamedType(node);
  }

  void _recordCall({
    required AstNode node,
    required String kind,
    required String lexicalTarget,
    required Element? element,
  }) {
    final caller = _callerName(node);
    if (element == null) {
      _upsert(
        unresolvedCalls,
        {
          'source': source,
          'line': _line(node),
          'caller': caller,
          'kind': kind,
          'lexical_target': lexicalTarget,
        },
        keyParts: [source, caller, kind, lexicalTarget],
      );
      return;
    }
    final targetLibrary = element.library?.uri.toString();
    _upsert(
      resolvedCalls,
      {
        'source': source,
        'line': _line(node),
        'caller': caller,
        'kind': kind,
        'lexical_target': lexicalTarget,
        'target': _qualifiedElementName(element),
        'target_library': targetLibrary,
        'target_scope': _targetScope(targetLibrary),
      },
      keyParts: [
        source,
        caller,
        kind,
        _qualifiedElementName(element),
        targetLibrary ?? '',
      ],
    );
  }

  void _upsert(
    Map<String, Map<String, Object?>> target,
    Map<String, Object?> value, {
    required List<String> keyParts,
  }) {
    final key = keyParts.join('\u0000');
    final existing = target[key];
    if (existing == null) {
      target[key] = {...value, 'occurrences': 1};
    } else {
      existing['occurrences'] = (existing['occurrences'] as int) + 1;
    }
  }

  String _callerName(AstNode node) {
    AstNode? current = node.parent;
    while (current != null) {
      if (current is MethodDeclaration) {
        final owner = current.thisOrAncestorOfType<ClassDeclaration>();
        return owner == null
            ? current.name.lexeme
            : '${owner.name.lexeme}.${current.name.lexeme}';
      }
      if (current is FunctionDeclaration) return current.name.lexeme;
      if (current is ConstructorDeclaration) {
        final owner = current.thisOrAncestorOfType<ClassDeclaration>();
        return owner == null
            ? '<constructor>'
            : '${owner.name.lexeme}.<constructor>';
      }
      current = current.parent;
    }
    return '<top-level>';
  }

  String _qualifiedElementName(Element element) {
    final parts = <String>[];
    Element? current = element;
    while (current != null && current is! LibraryElement) {
      if (current.displayName.isNotEmpty) parts.add(current.displayName);
      current = current.enclosingElement;
    }
    return parts.reversed.join('.');
  }

  String _targetScope(String? library) {
    if (library == null) return 'unknown';
    if (library.startsWith('dart:')) return 'dart_sdk';
    if (library.startsWith('package:manaloom/') ||
        library.startsWith('package:server/')) {
      return 'workspace';
    }
    if (library.startsWith('package:')) return 'dependency';
    return 'other';
  }
}

class _SqlTable {
  _SqlTable(this.name);

  final String name;
  final Map<String, _SqlColumn> columns = {};

  void mergeColumn(_SqlColumn column) {
    final previous = columns[column.name];
    columns[column.name] = previous == null
        ? column
        : _SqlColumn(
            column.name,
            column.type == 'unknown' ? previous.type : column.type,
            primaryKey: previous.primaryKey || column.primaryKey,
            nullable: previous.nullable && column.nullable,
          );
  }

  Map<String, Object?> toJson() => {
    'name': name,
    'columns':
        (columns.values.toList()..sort((a, b) => a.name.compareTo(b.name)))
            .map((column) => column.toJson())
            .toList(),
  };
}

class _SqlColumn {
  _SqlColumn(
    this.name,
    this.type, {
    required this.primaryKey,
    required this.nullable,
  });

  final String name;
  final String type;
  final bool primaryKey;
  final bool nullable;

  Map<String, Object?> toJson() => {
    'name': name,
    'type': type,
    'primary_key': primaryKey,
    'nullable': nullable,
  };
}

class _SqlRelation {
  const _SqlRelation(
    this.fromTable,
    this.fromColumn,
    this.toTable,
    this.toColumn,
  );

  final String fromTable;
  final String fromColumn;
  final String toTable;
  final String toColumn;

  Map<String, Object?> toJson() => {
    'from_table': fromTable,
    'from_column': fromColumn,
    'to_table': toTable,
    'to_column': toColumn,
  };

  @override
  bool operator ==(Object other) =>
      other is _SqlRelation &&
      fromTable == other.fromTable &&
      fromColumn == other.fromColumn &&
      toTable == other.toTable &&
      toColumn == other.toColumn;

  @override
  int get hashCode => Object.hash(fromTable, fromColumn, toTable, toColumn);
}
