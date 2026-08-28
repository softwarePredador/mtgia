// ignore_for_file: depend_on_referenced_packages, implementation_imports

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:dart_frog_cli/src/commands/build/templates/dart_frog_prod_server_bundle.dart';
import 'package:dart_frog_cli/src/runtime_compatibility.dart';
import 'package:dart_frog_cli/src/version.dart' as dart_frog_cli;
import 'package:dart_frog_gen/dart_frog_gen.dart';
import 'package:mason/mason.dart';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

const adapterVersion = '1';
const expectedDartVersion = '3.12.2';
const expectedFlutterVersion = '3.44.6';
const expectedPackageCount = 110;
const ownershipMarkerName = '.manaloom_offline_build_owner';
const expectedPackageVersions = <String, String>{
  'dart_frog': '1.2.6',
  'dart_frog_cli': '1.2.14',
  'dart_frog_gen': '2.1.0',
  'mason': '0.1.2',
};
const expectedHostedPackageHashes = <String, String>{
  'dart_frog':
      '4ab2323ad74f935f5f76cb2de7e699d0319245e8029753878b0ddc35984f9cfe',
  'dart_frog_cli':
      'ee67e845345c631962c94dda30892dd3a5f90b6fdc3c57ef32d805920d20e8db',
  'dart_frog_gen':
      'f706052ef3423f48e946dd3d794f522fd79d73874b8cf6fed0631ed4ffe69a89',
  'mason': '515b28eedc3e106bbbfb95f0ff63471003396978d3413daeba0a64bcac01367b',
};
const expectedBundleFileHashes = <String, String>{
  'build/.dockerignore':
      'dbb2b319672b2913dca15c0ff07e90d21f2f05baa745b05f0534ac56ae055423',
  'build/bin/server.dart':
      '35e00a9b8afb11c30e5aee8ed1fad766e368e5e58aeec494ae7018bffd37af3e',
  'build/{{#addDockerfile}}Dockerfile{{/addDockerfile}}':
      '512175678e99218bf5634f67a5913d9a21b6c01b082bb2500fb190f1e39a7752',
};

final class OfflineBuildFailure implements Exception {
  const OfflineBuildFailure(this.code, this.reason);

  final String code;
  final String reason;

  @override
  String toString() => 'BLOCKED_OFFLINE_BUILD_ADAPTER[$code]: $reason';
}

final class PinnedMetadata {
  const PinnedMetadata({
    required this.packageConfig,
    required this.packageGraph,
    required this.pubspec,
    required this.pubspecLock,
    required this.dartVersion,
    required this.flutterVersion,
    required this.buildExists,
    required this.dartFrogStateExists,
  });

  final Map<String, dynamic> packageConfig;
  final Map<String, dynamic> packageGraph;
  final Map<Object?, Object?> pubspec;
  final Map<Object?, Object?> pubspecLock;
  final String dartVersion;
  final String flutterVersion;
  final bool buildExists;
  final bool dartFrogStateExists;
}

void validatePinnedDigest({
  required String label,
  required String actual,
  required String expected,
}) {
  if (actual != expected) {
    throw OfflineBuildFailure(
      '${label}_digest_mismatch',
      'digest de $label diverge do pin versionado',
    );
  }
}

void validatePinnedMetadata(PinnedMetadata metadata) {
  if (metadata.buildExists) {
    throw const OfflineBuildFailure(
      'preexisting_build',
      'server/build preexistente não pode ser apagado nem reutilizado',
    );
  }
  if (metadata.dartFrogStateExists) {
    throw const OfflineBuildFailure(
      'preexisting_dart_frog_state',
      'server/.dart_frog preexistente não pode ser reutilizado',
    );
  }
  if (metadata.dartVersion != expectedDartVersion) {
    throw const OfflineBuildFailure(
      'dart_sdk_mismatch',
      'o adapter exige Dart 3.12.2',
    );
  }
  if (metadata.flutterVersion != expectedFlutterVersion) {
    throw const OfflineBuildFailure(
      'flutter_sdk_mismatch',
      'o adapter exige Flutter 3.44.6',
    );
  }
  if (dart_frog_cli.packageVersion !=
      expectedPackageVersions['dart_frog_cli']) {
    throw const OfflineBuildFailure(
      'loaded_dart_frog_cli_mismatch',
      'o código carregado não é dart_frog_cli 1.2.14',
    );
  }

  final packageConfig = metadata.packageConfig;
  if (packageConfig['generator'] != 'pub' ||
      packageConfig['generatorVersion'] != expectedDartVersion) {
    throw const OfflineBuildFailure(
      'package_config_generator_mismatch',
      'package_config não foi gerado pelo Pub/Dart pinado',
    );
  }
  final configPackages = _jsonMapList(
    packageConfig['packages'],
    label: 'package_config.packages',
  );
  if (configPackages.length != expectedPackageCount) {
    throw const OfflineBuildFailure(
      'package_config_count_mismatch',
      'package_config deve conter exatamente 110 pacotes',
    );
  }
  final configByName = _uniqueByName(configPackages, label: 'package_config');
  _expectConfigRoot(configByName, 'server', '../');
  _expectConfigRoot(
    configByName,
    'manaloom_lints',
    '../../tools/manaloom_lints',
  );
  for (final entry in expectedPackageVersions.entries) {
    final package = configByName[entry.key];
    if (package == null ||
        package['rootUri'] is! String ||
        !(package['rootUri'] as String).endsWith(
          '${entry.key}-${entry.value}',
        )) {
      throw OfflineBuildFailure(
        'package_config_${entry.key}_mismatch',
        'rootUri de ${entry.key} não resolve a versão ${entry.value}',
      );
    }
  }

  final packageGraph = metadata.packageGraph;
  final roots = packageGraph['roots'];
  if (roots is! List || roots.length != 1 || roots.single != 'server') {
    throw const OfflineBuildFailure(
      'package_graph_roots_mismatch',
      'package_graph deve declarar apenas server como raiz',
    );
  }
  final graphPackages = _jsonMapList(
    packageGraph['packages'],
    label: 'package_graph.packages',
  );
  if (graphPackages.length != expectedPackageCount) {
    throw const OfflineBuildFailure(
      'package_graph_count_mismatch',
      'package_graph deve conter exatamente 110 pacotes',
    );
  }
  final graphByName = _uniqueByName(graphPackages, label: 'package_graph');
  if (configByName.keys
          .toSet()
          .difference(graphByName.keys.toSet())
          .isNotEmpty ||
      graphByName.keys
          .toSet()
          .difference(configByName.keys.toSet())
          .isNotEmpty) {
    throw const OfflineBuildFailure(
      'package_graph_closure_mismatch',
      'package_config e package_graph não têm o mesmo fechamento',
    );
  }
  for (final entry in expectedPackageVersions.entries) {
    if (graphByName[entry.key]?['version'] != entry.value) {
      throw OfflineBuildFailure(
        'package_graph_${entry.key}_mismatch',
        'package_graph não fixa ${entry.key} ${entry.value}',
      );
    }
  }

  final dependencies = _yamlMap(
    metadata.pubspec['dependencies'],
    label: 'pubspec.dependencies',
  );
  final devDependencies = _yamlMap(
    metadata.pubspec['dev_dependencies'],
    label: 'pubspec.dev_dependencies',
  );
  if (dependencies['dart_frog'] != '^1.0.0') {
    throw const OfflineBuildFailure(
      'pubspec_dart_frog_mismatch',
      'pubspec deve preservar dart_frog ^1.0.0',
    );
  }
  if (devDependencies['dart_frog_cli'] != '1.2.14') {
    throw const OfflineBuildFailure(
      'pubspec_dart_frog_cli_mismatch',
      'pubspec deve fixar dart_frog_cli 1.2.14',
    );
  }
  for (final dependency in dependencies.entries) {
    final value = dependency.value;
    if (value is Map && value.containsKey('path')) {
      throw OfflineBuildFailure(
        'production_path_dependency_${dependency.key}',
        'dependência path de produção não foi autorizada',
      );
    }
  }
  final lintDependency = devDependencies['manaloom_lints'];
  if (lintDependency is! Map ||
      lintDependency['path'] != '../tools/manaloom_lints') {
    throw const OfflineBuildFailure(
      'manaloom_lints_path_mismatch',
      'única dependência path esperada deve ser ../tools/manaloom_lints',
    );
  }

  final lockPackages = _yamlMap(
    metadata.pubspecLock['packages'],
    label: 'pubspec.lock packages',
  );
  for (final entry in expectedPackageVersions.entries) {
    final locked = _yamlMap(
      lockPackages[entry.key],
      label: 'pubspec.lock ${entry.key}',
    );
    final description = _yamlMap(
      locked['description'],
      label: 'pubspec.lock ${entry.key}.description',
    );
    if (locked['source'] != 'hosted' ||
        locked['version'] != entry.value ||
        description['name'] != entry.key ||
        description['sha256'] != expectedHostedPackageHashes[entry.key] ||
        description['url'] != 'https://pub.dev') {
      throw OfflineBuildFailure(
        'pubspec_lock_${entry.key}_mismatch',
        'lock não preserva versão e checksum de ${entry.key}',
      );
    }
  }
}

void validateBundleContract(MasonBundle bundle) {
  if (bundle.name != 'dart_frog_prod_server' ||
      bundle.version != '0.1.0+1' ||
      bundle.files.length != expectedBundleFileHashes.length) {
    throw const OfflineBuildFailure(
      'bundle_metadata_mismatch',
      'bundle de produção Dart Frog diverge do contrato 1.2.14',
    );
  }
  final actualPaths = bundle.files.map((file) => file.path).toSet();
  if (actualPaths
          .difference(expectedBundleFileHashes.keys.toSet())
          .isNotEmpty ||
      expectedBundleFileHashes.keys
          .toSet()
          .difference(actualPaths)
          .isNotEmpty) {
    throw const OfflineBuildFailure(
      'bundle_paths_mismatch',
      'bundle deve conter somente os três templates pinados',
    );
  }
  for (final file in bundle.files) {
    if (file.type != 'text') {
      throw OfflineBuildFailure(
        'bundle_type_${file.path}',
        'o bundle pinado não contém templates binários',
      );
    }
    final bytes = base64.decode(file.data);
    validatePinnedDigest(
      label: 'bundle_${file.path.replaceAll(RegExp('[^a-zA-Z0-9]+'), '_')}',
      actual: sha256.convert(bytes).toString(),
      expected: expectedBundleFileHashes[file.path]!,
    );
    final text = utf8.decode(bytes);
    if (file.path.contains('{{%') || text.contains('{{%')) {
      throw const OfflineBuildFailure(
        'bundle_remote_partial',
        'partial remoto Mason não é permitido no adapter offline',
      );
    }
  }
}

bool excludesSourcePath(String relativePath) {
  final normalized = relativePath.replaceAll('\\', '/');
  final segments = normalized.split('/');
  const excludedSegments = <String>{
    '.dart_tool',
    '.dart_frog',
    '.git',
    '.pytest_cache',
    '.venv',
    '__pycache__',
    'build',
    'cache',
    'coverage',
    'observability-evidence',
    'release-evidence',
    'restore-evidence',
  };
  if (segments.any(excludedSegments.contains)) return true;
  final basename = segments.last;
  return basename == '.DS_Store' ||
      basename == 'AtomicCards.json' ||
      basename.endsWith('.log') ||
      basename.endsWith('.pyc') ||
      basename.endsWith('.pyo');
}

bool isForbiddenSourcePath(String relativePath) {
  final normalized = relativePath.replaceAll('\\', '/');
  final basename = path.basename(normalized).toLowerCase();
  if (basename == '.env.example') return false;
  if (basename == '.env' ||
      basename.startsWith('.env.') ||
      basename == '.credentials.env' ||
      basename == 'firebase-service-account.json' ||
      basename == '.packages') {
    return true;
  }
  return const <String>{
    '.jks',
    '.keystore',
    '.p12',
    '.pfx',
    '.mobileprovision',
  }.any(basename.endsWith);
}

String normalizedTreeDigest(Map<String, String> fileHashes) {
  final bytes = BytesBuilder(copy: false);
  final paths = fileHashes.keys.toList()..sort();
  for (final relativePath in paths) {
    bytes
      ..add(utf8.encode(relativePath))
      ..add(const [0])
      ..add(utf8.encode(fileHashes[relativePath]!))
      ..add(const [0]);
  }
  return sha256.convert(bytes.takeBytes()).toString();
}

String _requiredBootstrapDigest(String environmentKey) {
  final value = Platform.environment[environmentKey] ?? '';
  if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(value)) {
    throw OfflineBuildFailure(
      'bootstrap_attestation_missing',
      'atestado SHA-256 obrigatório ausente: $environmentKey',
    );
  }
  return value;
}

String _regularFileDigest(File file, String label) {
  if (FileSystemEntity.typeSync(file.path, followLinks: false) !=
      FileSystemEntityType.file) {
    throw OfflineBuildFailure(
      '${label}_missing_or_linked',
      '$label deve ser arquivo regular não linked',
    );
  }
  return sha256.convert(file.readAsBytesSync()).toString();
}

void _validateBootstrapInputs({
  required File packageConfig,
  required File packageGraph,
  required File pubspec,
  required File pubspecLock,
}) {
  if (Platform.script.scheme != 'file') {
    throw const OfflineBuildFailure(
      'helper_source_uri_invalid',
      'helper versionado deve ser carregado por URI file local',
    );
  }
  final inputs = <({String environmentKey, File file, String label})>[
    (
      environmentKey: 'MANALOOM_OFFLINE_BUILD_HELPER_SHA256',
      file: File(Platform.script.toFilePath()),
      label: 'adapter_helper',
    ),
    (
      environmentKey: 'MANALOOM_OFFLINE_BUILD_PUBSPEC_SHA256',
      file: pubspec,
      label: 'pubspec',
    ),
    (
      environmentKey: 'MANALOOM_OFFLINE_BUILD_LOCK_SHA256',
      file: pubspecLock,
      label: 'pubspec_lock',
    ),
    (
      environmentKey: 'MANALOOM_OFFLINE_BUILD_PACKAGE_CONFIG_SHA256',
      file: packageConfig,
      label: 'package_config',
    ),
    (
      environmentKey: 'MANALOOM_OFFLINE_BUILD_PACKAGE_GRAPH_SHA256',
      file: packageGraph,
      label: 'package_graph',
    ),
    (
      environmentKey: 'MANALOOM_OFFLINE_BUILD_DART_BIN_SHA256',
      file: File(Platform.resolvedExecutable),
      label: 'dart_binary',
    ),
    (
      environmentKey: 'MANALOOM_OFFLINE_BUILD_DART_VM_SHA256',
      file: File(
        path.join(File(Platform.resolvedExecutable).parent.path, 'dartvm'),
      ),
      label: 'dart_vm',
    ),
    (
      environmentKey: 'MANALOOM_OFFLINE_BUILD_DARTDEV_SNAPSHOT_SHA256',
      file: File(
        path.join(
          File(Platform.resolvedExecutable).parent.path,
          'snapshots',
          'dartdev_aot.dart.snapshot',
        ),
      ),
      label: 'dartdev_snapshot',
    ),
  ];
  for (final input in inputs) {
    validatePinnedDigest(
      label: input.label,
      actual: _regularFileDigest(input.file, input.label),
      expected: _requiredBootstrapDigest(input.environmentKey),
    );
  }
  final dartSdkRoot = File(Platform.resolvedExecutable).parent.parent;
  validatePinnedDigest(
    label: 'dart_sdk_tree',
    actual: normalizedTreeDigest(_treeHashes(dartSdkRoot)),
    expected: _requiredBootstrapDigest(
      'MANALOOM_OFFLINE_BUILD_DART_SDK_TREE_SHA256',
    ),
  );
}

void _validatePortableRelativePath(String relativePath, String label) {
  if (relativePath.isEmpty ||
      relativePath.contains('\u0000') ||
      relativePath.contains('\n') ||
      relativePath.contains('\r') ||
      relativePath.codeUnits.any((unit) => unit < 0x20 || unit > 0x7e) ||
      path.isAbsolute(relativePath) ||
      path.split(relativePath).contains('..')) {
    throw OfflineBuildFailure(
      '${label}_path_invalid',
      '$label contém path não portável',
    );
  }
}

Map<String, String> _sourceTreeHashes(Directory source) {
  if (FileSystemEntity.typeSync(source.path, followLinks: false) !=
      FileSystemEntityType.directory) {
    throw OfflineBuildFailure(
      'source_root_invalid',
      'raiz de fonte deve ser diretório regular: ${path.basename(source.path)}',
    );
  }
  final hashes = <String, String>{};

  void visit(Directory current, String prefix) {
    final entities = current.listSync(followLinks: false)
      ..sort((left, right) => left.path.compareTo(right.path));
    for (final entity in entities) {
      final name = path.basename(entity.path);
      final relativePath = prefix.isEmpty ? name : '$prefix/$name';
      _validatePortableRelativePath(relativePath, 'source');
      if (isForbiddenSourcePath(relativePath)) {
        throw OfflineBuildFailure(
          'forbidden_source_path',
          'segredo, credencial ou estado de resolver não pode entrar no build: '
              '$relativePath',
        );
      }
      if (excludesSourcePath(relativePath)) continue;
      final type = FileSystemEntity.typeSync(entity.path, followLinks: false);
      if (type == FileSystemEntityType.link ||
          (type != FileSystemEntityType.file &&
              type != FileSystemEntityType.directory)) {
        throw OfflineBuildFailure(
          'source_special_entity',
          'symlink ou entidade especial não é permitido: $relativePath',
        );
      }
      if (type == FileSystemEntityType.directory) {
        visit(Directory(entity.path), relativePath);
      } else {
        if (relativePath == '.env') {
          throw const OfflineBuildFailure(
            'source_secret_env',
            'server/.env não pode entrar no build',
          );
        }
        hashes[relativePath] =
            sha256.convert(File(entity.path).readAsBytesSync()).toString();
      }
    }
  }

  visit(source, '');
  return hashes;
}

void _requireTreeSnapshot({
  required String label,
  required Map<String, String> expected,
  required Map<String, String> actual,
}) {
  validatePinnedDigest(
    label: label,
    actual: normalizedTreeDigest(actual),
    expected: normalizedTreeDigest(expected),
  );
}

Map<String, dynamic> _readJsonMap(File file, String label) {
  try {
    final decoded = jsonDecode(file.readAsStringSync());
    if (decoded is Map<String, dynamic>) return decoded;
  } on Object catch (error) {
    throw OfflineBuildFailure('${label}_invalid', '$label inválido: $error');
  }
  throw OfflineBuildFailure('${label}_invalid', '$label não é um objeto JSON');
}

Map<Object?, Object?> _readYamlMap(File file, String label) {
  try {
    final decoded = loadYaml(file.readAsStringSync());
    if (decoded is Map) return Map<Object?, Object?>.from(decoded);
  } on Object catch (error) {
    throw OfflineBuildFailure('${label}_invalid', '$label inválido: $error');
  }
  throw OfflineBuildFailure('${label}_invalid', '$label não é um mapa YAML');
}

List<Map<String, dynamic>> _jsonMapList(
  Object? value, {
  required String label,
}) {
  if (value is! List) {
    throw OfflineBuildFailure('${label}_invalid', '$label não é uma lista');
  }
  return value.map((item) {
    if (item is! Map<String, dynamic>) {
      throw OfflineBuildFailure(
        '${label}_invalid',
        '$label contém item inválido',
      );
    }
    return item;
  }).toList();
}

Map<String, Map<String, dynamic>> _uniqueByName(
  List<Map<String, dynamic>> packages, {
  required String label,
}) {
  final result = <String, Map<String, dynamic>>{};
  for (final package in packages) {
    final name = package['name'];
    if (name is! String || name.isEmpty || result.containsKey(name)) {
      throw OfflineBuildFailure(
        '${label}_duplicate_or_invalid_name',
        '$label contém nome ausente ou duplicado',
      );
    }
    result[name] = package;
  }
  return result;
}

Map<Object?, Object?> _yamlMap(Object? value, {required String label}) {
  if (value is! Map) {
    throw OfflineBuildFailure('${label}_invalid', '$label não é um mapa');
  }
  return Map<Object?, Object?>.from(value);
}

void _expectConfigRoot(
  Map<String, Map<String, dynamic>> packages,
  String name,
  String rootUri,
) {
  if (packages[name]?['rootUri'] != rootUri) {
    throw OfflineBuildFailure(
      'package_config_${name}_root_mismatch',
      'rootUri de $name deve ser $rootUri',
    );
  }
}

Map<String, String> _copyTree({
  required Directory source,
  required Directory destination,
}) {
  final hashes = <String, String>{};
  if (FileSystemEntity.typeSync(source.path, followLinks: false) !=
      FileSystemEntityType.directory) {
    throw OfflineBuildFailure(
      'copy_source_missing',
      'fonte ausente para cópia: ${path.basename(source.path)}',
    );
  }
  destination.createSync(recursive: true);
  void visit(Directory current, String prefix) {
    final entities = current.listSync(followLinks: false)
      ..sort((left, right) => left.path.compareTo(right.path));
    for (final entity in entities) {
      final name = path.basename(entity.path);
      final relativePath = prefix.isEmpty ? name : '$prefix/$name';
      _validatePortableRelativePath(relativePath, 'source');
      if (isForbiddenSourcePath(relativePath)) {
        throw OfflineBuildFailure(
          'forbidden_source_path',
          'segredo, credencial ou estado de resolver não pode entrar no build: '
              '$relativePath',
        );
      }
      if (excludesSourcePath(relativePath)) continue;
      final type = FileSystemEntity.typeSync(entity.path, followLinks: false);
      if (type == FileSystemEntityType.link ||
          (type != FileSystemEntityType.file &&
              type != FileSystemEntityType.directory)) {
        throw OfflineBuildFailure(
          'source_special_entity',
          'symlink ou entidade especial não é permitido: $relativePath',
        );
      }
      final targetPath = path.join(destination.path, relativePath);
      if (type == FileSystemEntityType.directory) {
        Directory(targetPath).createSync(recursive: true);
        visit(Directory(entity.path), relativePath);
      } else {
        if (relativePath == '.env') {
          throw const OfflineBuildFailure(
            'source_secret_env',
            'server/.env não pode entrar no build',
          );
        }
        final bytes = File(entity.path).readAsBytesSync();
        File(targetPath)
          ..parent.createSync(recursive: true)
          ..writeAsBytesSync(bytes, flush: true);
        hashes[relativePath] = sha256.convert(bytes).toString();
      }
    }
  }

  visit(source, '');
  return hashes;
}

void _writeBuildPackageConfig({
  required Map<String, dynamic> packageConfig,
  required Directory buildDirectory,
}) {
  final copy = jsonDecode(jsonEncode(packageConfig)) as Map<String, dynamic>;
  final packages = _jsonMapList(copy['packages'], label: 'package_config copy');
  for (final package in packages) {
    if (package['name'] == 'manaloom_lints') {
      package['rootUri'] = '../.dart_frog_path_dependencies/manaloom_lints';
    }
  }
  final output = File(
    path.join(buildDirectory.path, '.dart_tool', 'package_config.json'),
  )..parent.createSync(recursive: true);
  output.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(copy)}\n',
  );
}

void _validateRoutes(RouteConfiguration configuration) {
  final violations = <String>[];
  reportRouteConflicts(
    configuration,
    onRouteConflict: (original, conflicting, endpoint) {
      violations.add('conflict:$original:$conflicting:$endpoint');
    },
  );
  reportRogueRoutes(
    configuration,
    onRogueRoute: (filePath, idealPath) {
      violations.add('rogue:$filePath:$idealPath');
    },
  );
  if (violations.isNotEmpty) {
    throw OfflineBuildFailure(
      'route_configuration_invalid',
      violations.join(','),
    );
  }
}

Map<String, dynamic> _buildVars(RouteConfiguration configuration) {
  return <String, dynamic>{
    'directories':
        configuration.directories.map((item) => item.toJson()).toList(),
    'routes': configuration.routes.map((item) => item.toJson()).toList(),
    'middleware':
        configuration.middleware.map((item) => item.toJson()).toList(),
    'globalMiddleware': configuration.globalMiddleware?.toJson() ?? false,
    'serveStaticFiles': configuration.serveStaticFiles,
    'invokeCustomEntrypoint': configuration.invokeCustomEntrypoint,
    'invokeCustomInit': configuration.invokeCustomInit,
    'pathDependencies': <String>[],
    'hasExternalDependencies': true,
    'dartVersion': expectedDartVersion,
    'addDockerfile': false,
  };
}

Future<void> _generatePinnedTemplates({
  required MasonBundle bundle,
  required Directory stagingRoot,
  required Map<String, dynamic> vars,
}) async {
  final target = DirectoryGeneratorTarget(stagingRoot);
  for (final bundledFile in bundle.files) {
    final template = TemplateFile.fromBytes(
      bundledFile.path,
      base64.decode(bundledFile.data),
    );
    final renderedFiles = template.runSubstitution(
      Map<String, dynamic>.of(vars),
      const <String, List<int>>{},
    );
    for (final renderedFile in renderedFiles) {
      final renderedPath = renderedFile.path.replaceAll('\\', '/');
      if (renderedPath.isEmpty ||
          renderedPath.endsWith('/') ||
          renderedPath.split('/').contains('')) {
        continue;
      }
      if (path.isAbsolute(renderedPath) ||
          path.split(renderedPath).contains('..')) {
        throw OfflineBuildFailure(
          'rendered_template_path_invalid',
          'template tentou escrever fora do stage: $renderedPath',
        );
      }
      await target.createFile(
        renderedPath,
        renderedFile.content,
        overwriteRule: OverwriteRule.alwaysOverwrite,
      );
    }
  }
}

Map<String, String> _treeHashes(
  Directory directory, {
  bool excludeOwnershipMarker = false,
}) {
  final hashes = <String, String>{};
  for (final entity in directory.listSync(
    recursive: true,
    followLinks: false,
  )) {
    final relativePath = path
        .relative(entity.path, from: directory.path)
        .replaceAll('\\', '/');
    _validatePortableRelativePath(relativePath, 'output');
    if (excludeOwnershipMarker && relativePath == ownershipMarkerName) {
      continue;
    }
    final type = FileSystemEntity.typeSync(entity.path, followLinks: false);
    if (type == FileSystemEntityType.link ||
        (type != FileSystemEntityType.file &&
            type != FileSystemEntityType.directory)) {
      throw OfflineBuildFailure(
        'output_special_entity',
        'saída contém symlink ou entidade especial: $relativePath',
      );
    }
    if (type == FileSystemEntityType.file) {
      hashes[relativePath] =
          sha256.convert(File(entity.path).readAsBytesSync()).toString();
    }
  }
  return hashes;
}

void _validateBuildOutput({
  required Directory buildDirectory,
  required Map<String, String> sourceHashes,
  required Map<String, String> pathDependencyHashes,
  required RouteConfiguration configuration,
}) {
  final outputHashes = _treeHashes(buildDirectory);
  for (final entry in sourceHashes.entries) {
    if (entry.key == '.dockerignore') continue;
    if (outputHashes[entry.key] != entry.value) {
      throw OfflineBuildFailure(
        'source_copy_mismatch',
        'cópia divergiu para ${entry.key}',
      );
    }
  }
  for (final entry in pathDependencyHashes.entries) {
    final outputPath =
        '.dart_frog_path_dependencies/manaloom_lints/${entry.key}';
    if (outputHashes[outputPath] != entry.value) {
      throw OfflineBuildFailure(
        'path_dependency_copy_mismatch',
        'cópia de manaloom_lints divergiu para ${entry.key}',
      );
    }
  }
  const requiredFiles = <String>{
    '.dockerignore',
    '.dart_tool/package_config.json',
    '.dart_frog_path_dependencies/manaloom_lints/pubspec.yaml',
    'Dockerfile',
    'bin/server.dart',
    'main.dart',
    'pubspec.lock',
    'pubspec.yaml',
    'pubspec_overrides.yaml',
  };
  final missing = requiredFiles.difference(outputHashes.keys.toSet());
  if (missing.isNotEmpty) {
    throw OfflineBuildFailure(
      'output_required_files_missing',
      'build incompleto: ${missing.toList()..sort()}',
    );
  }
  final expectedOutputPaths = <String>{
    ...sourceHashes.keys.where((sourcePath) => sourcePath != '.dockerignore'),
    '.dockerignore',
    '.dart_tool/package_config.json',
    'bin/server.dart',
    'pubspec_overrides.yaml',
    for (final dependencyPath in pathDependencyHashes.keys)
      '.dart_frog_path_dependencies/manaloom_lints/$dependencyPath',
    '.dart_frog_path_dependencies/manaloom_lints/pubspec_overrides.yaml',
  };
  final unexpected = outputHashes.keys.toSet().difference(expectedOutputPaths);
  final absent = expectedOutputPaths.difference(outputHashes.keys.toSet());
  if (unexpected.isNotEmpty || absent.isNotEmpty) {
    throw OfflineBuildFailure(
      'output_inventory_mismatch',
      'inventário divergente; extras=${unexpected.toList()..sort()} '
          'ausentes=${absent.toList()..sort()}',
    );
  }
  validatePinnedDigest(
    label: 'generated_dockerignore',
    actual: outputHashes['.dockerignore'] ?? '',
    expected: expectedBundleFileHashes['build/.dockerignore']!,
  );
  for (final outputPath in outputHashes.keys) {
    if (excludesSourcePath(outputPath) &&
        outputPath != '.dart_tool/package_config.json') {
      throw OfflineBuildFailure(
        'stale_output_artifact',
        'artefato transitório entrou no build: $outputPath',
      );
    }
    if (outputPath.startsWith('build/')) {
      throw OfflineBuildFailure(
        'nested_build_output',
        'build/build não é permitido',
      );
    }
  }

  final generatedServer =
      File(
        path.join(buildDirectory.path, 'bin', 'server.dart'),
      ).readAsStringSync();
  if (generatedServer.contains('{{') || generatedServer.contains('}}')) {
    throw const OfflineBuildFailure(
      'unrendered_server_template',
      'bin/server.dart contém marcador Mason não resolvido',
    );
  }
  final expectedImports = <String>{
    for (final route in configuration.routes) route.toJson()['path'] as String,
    for (final middleware in configuration.middleware)
      middleware.toJson()['path'] as String,
    if (configuration.globalMiddleware != null)
      configuration.globalMiddleware!.toJson()['path'] as String,
  };
  for (final importPath in expectedImports) {
    if (!generatedServer.contains("import '$importPath' as ")) {
      throw OfflineBuildFailure(
        'generated_route_import_missing',
        'import de rota/middleware ausente: $importPath',
      );
    }
  }
  if (!generatedServer.contains('Handler buildRootHandler()')) {
    throw const OfflineBuildFailure(
      'generated_server_entrypoint_missing',
      'bin/server.dart não contém o handler raiz de produção',
    );
  }
}

Future<Map<String, dynamic>> buildOffline(Directory serverDirectory) async {
  final buildDirectory = Directory(path.join(serverDirectory.path, 'build'));
  final dartFrogState = Directory(
    path.join(serverDirectory.path, '.dart_frog'),
  );
  final packageConfigFile = File(
    path.join(serverDirectory.path, '.dart_tool', 'package_config.json'),
  );
  final packageGraphFile = File(
    path.join(serverDirectory.path, '.dart_tool', 'package_graph.json'),
  );
  final pubspecFile = File(path.join(serverDirectory.path, 'pubspec.yaml'));
  final pubspecLockFile = File(path.join(serverDirectory.path, 'pubspec.lock'));
  for (final requiredFile in <File>[
    packageConfigFile,
    packageGraphFile,
    pubspecFile,
    pubspecLockFile,
  ]) {
    if (FileSystemEntity.typeSync(requiredFile.path, followLinks: false) !=
        FileSystemEntityType.file) {
      throw OfflineBuildFailure(
        'required_input_missing',
        'entrada obrigatória ausente: ${path.basename(requiredFile.path)}',
      );
    }
  }

  _validateBootstrapInputs(
    packageConfig: packageConfigFile,
    packageGraph: packageGraphFile,
    pubspec: pubspecFile,
    pubspecLock: pubspecLockFile,
  );
  final packageConfig = _readJsonMap(packageConfigFile, 'package_config');
  final packageGraph = _readJsonMap(packageGraphFile, 'package_graph');
  final metadata = PinnedMetadata(
    packageConfig: packageConfig,
    packageGraph: packageGraph,
    pubspec: _readYamlMap(pubspecFile, 'pubspec'),
    pubspecLock: _readYamlMap(pubspecLockFile, 'pubspec_lock'),
    dartVersion: Platform.version.split(' ').first,
    flutterVersion:
        Platform.environment['MANALOOM_OFFLINE_BUILD_FLUTTER_VERSION'] ?? '',
    buildExists:
        FileSystemEntity.typeSync(buildDirectory.path, followLinks: false) !=
        FileSystemEntityType.notFound,
    dartFrogStateExists:
        FileSystemEntity.typeSync(dartFrogState.path, followLinks: false) !=
        FileSystemEntityType.notFound,
  );
  validatePinnedMetadata(metadata);
  validateBundleContract(dartFrogProdServerBundle);

  final localDependency = Directory(
    path.normalize(
      path.join(serverDirectory.path, '..', 'tools', 'manaloom_lints'),
    ),
  );
  final initialSourceHashes = _sourceTreeHashes(serverDirectory);
  final initialPathDependencyHashes = _sourceTreeHashes(localDependency);

  final adapterWorkDirectory = Directory(
    path.join(
      serverDirectory.path,
      '.dart_tool',
      'manaloom_offline_build_adapter',
    ),
  );
  if (FileSystemEntity.typeSync(
        adapterWorkDirectory.path,
        followLinks: false,
      ) !=
      FileSystemEntityType.notFound) {
    throw const OfflineBuildFailure(
      'preexisting_adapter_workspace',
      'workspace transitório preexistente não pode ser reutilizado',
    );
  }

  var published = false;
  String? publishedDigest;
  final ownerNonce = Platform.environment['MANALOOM_OFFLINE_BUILD_OWNER_NONCE'];
  if (ownerNonce == null ||
      !RegExp(
        r'^[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}$',
      ).hasMatch(ownerNonce)) {
    throw const OfflineBuildFailure(
      'owner_nonce_missing_or_invalid',
      'nonce de ownership process-scoped ausente ou inválido',
    );
  }
  try {
    final stagingRoot = Directory(path.join(adapterWorkDirectory.path, 'stage'))
      ..createSync(recursive: true);
    final stagingBuild = Directory(path.join(stagingRoot.path, 'build'));
    final sourceHashes = _copyTree(
      source: serverDirectory,
      destination: stagingBuild,
    );
    final pathDependencyHashes = _copyTree(
      source: localDependency,
      destination: Directory(
        path.join(
          stagingBuild.path,
          '.dart_frog_path_dependencies',
          'manaloom_lints',
        ),
      ),
    );
    _requireTreeSnapshot(
      label: 'source_copy_snapshot',
      expected: initialSourceHashes,
      actual: sourceHashes,
    );
    _requireTreeSnapshot(
      label: 'path_dependency_copy_snapshot',
      expected: initialPathDependencyHashes,
      actual: pathDependencyHashes,
    );
    File(
      path.join(stagingBuild.path, 'pubspec_overrides.yaml'),
    ).writeAsStringSync('''resolution: null
dependency_overrides:
  manaloom_lints:
    path: .dart_frog_path_dependencies/manaloom_lints
''');
    File(
      path.join(
        stagingBuild.path,
        '.dart_frog_path_dependencies',
        'manaloom_lints',
        'pubspec_overrides.yaml',
      ),
    ).writeAsStringSync('resolution: null\n');
    _writeBuildPackageConfig(
      packageConfig: packageConfig,
      buildDirectory: stagingBuild,
    );

    _validateBootstrapInputs(
      packageConfig: packageConfigFile,
      packageGraph: packageGraphFile,
      pubspec: pubspecFile,
      pubspecLock: pubspecLockFile,
    );
    _requireTreeSnapshot(
      label: 'source_before_template',
      expected: initialSourceHashes,
      actual: _sourceTreeHashes(serverDirectory),
    );
    _requireTreeSnapshot(
      label: 'path_dependency_before_template',
      expected: initialPathDependencyHashes,
      actual: _sourceTreeHashes(localDependency),
    );

    ensureRuntimeCompatibility(stagingBuild);
    final previousWorkingDirectory = Directory.current;
    late final RouteConfiguration routeConfiguration;
    try {
      Directory.current = stagingBuild;
      routeConfiguration = buildRouteConfiguration(stagingBuild);
    } finally {
      Directory.current = previousWorkingDirectory;
    }
    _validateRoutes(routeConfiguration);
    await _generatePinnedTemplates(
      bundle: dartFrogProdServerBundle,
      stagingRoot: stagingRoot,
      vars: _buildVars(routeConfiguration),
    );
    _validateBuildOutput(
      buildDirectory: stagingBuild,
      sourceHashes: sourceHashes,
      pathDependencyHashes: pathDependencyHashes,
      configuration: routeConfiguration,
    );

    _validateBootstrapInputs(
      packageConfig: packageConfigFile,
      packageGraph: packageGraphFile,
      pubspec: pubspecFile,
      pubspecLock: pubspecLockFile,
    );
    _requireTreeSnapshot(
      label: 'source_before_publish',
      expected: initialSourceHashes,
      actual: _sourceTreeHashes(serverDirectory),
    );
    _requireTreeSnapshot(
      label: 'path_dependency_before_publish',
      expected: initialPathDependencyHashes,
      actual: _sourceTreeHashes(localDependency),
    );
    if (FileSystemEntity.typeSync(buildDirectory.path, followLinks: false) !=
        FileSystemEntityType.notFound) {
      throw const OfflineBuildFailure(
        'concurrent_build_publication',
        'server/build surgiu durante a rodada; publicação recusada',
      );
    }

    final sourceDigest = normalizedTreeDigest(sourceHashes);
    final dependencyDigest = normalizedTreeDigest(pathDependencyHashes);
    final buildDigest = normalizedTreeDigest(_treeHashes(stagingBuild));
    stagingBuild.renameSync(buildDirectory.path);
    published = true;
    publishedDigest = buildDigest;

    _validateBootstrapInputs(
      packageConfig: packageConfigFile,
      packageGraph: packageGraphFile,
      pubspec: pubspecFile,
      pubspecLock: pubspecLockFile,
    );
    _requireTreeSnapshot(
      label: 'source_after_publish',
      expected: initialSourceHashes,
      actual: _sourceTreeHashes(serverDirectory),
    );
    _requireTreeSnapshot(
      label: 'path_dependency_after_publish',
      expected: initialPathDependencyHashes,
      actual: _sourceTreeHashes(localDependency),
    );
    validatePinnedDigest(
      label: 'published_build',
      actual: normalizedTreeDigest(
        _treeHashes(buildDirectory, excludeOwnershipMarker: true),
      ),
      expected: buildDigest,
    );
    adapterWorkDirectory.deleteSync(recursive: true);
    final ownerMarker = File(
      path.join(buildDirectory.path, ownershipMarkerName),
    );
    ownerMarker.writeAsStringSync('$ownerNonce\n', flush: true);
    final ownerMarkerDigest = sha256.convert(ownerMarker.readAsBytesSync());

    return <String, dynamic>{
      'adapter_version': adapterVersion,
      'classification': 'PASS_OFFLINE_BUILD_ADAPTER',
      'dart': expectedDartVersion,
      'flutter': expectedFlutterVersion,
      'dart_frog_cli': expectedPackageVersions['dart_frog_cli'],
      'dart_frog': expectedPackageVersions['dart_frog'],
      'process_id': pid,
      'routes': routeConfiguration.routes.length,
      'middleware': routeConfiguration.middleware.length,
      'source_digest': sourceDigest,
      'path_dependency_digest': dependencyDigest,
      'build_digest': buildDigest,
      'ownership_marker_sha256': ownerMarkerDigest.toString(),
    };
  } on Object {
    if (published && publishedDigest != null) {
      try {
        if (FileSystemEntity.typeSync(
              buildDirectory.path,
              followLinks: false,
            ) ==
            FileSystemEntityType.directory) {
          final ownerMarker = File(
            path.join(buildDirectory.path, ownershipMarkerName),
          );
          final ownerMarkerType = FileSystemEntity.typeSync(
            ownerMarker.path,
            followLinks: false,
          );
          final ownerMatches =
              ownerMarkerType == FileSystemEntityType.file &&
              ownerMarker.readAsStringSync() == '$ownerNonce\n';
          final currentDigest = normalizedTreeDigest(
            _treeHashes(buildDirectory, excludeOwnershipMarker: true),
          );
          if (currentDigest == publishedDigest &&
              (ownerMarkerType == FileSystemEntityType.notFound ||
                  ownerMatches)) {
            buildDirectory.deleteSync(recursive: true);
          }
        }
      } on Object {
        // Fail closed: a changed or uninspectable publication is preserved.
      }
    }
    rethrow;
  } finally {
    if (adapterWorkDirectory.existsSync()) {
      adapterWorkDirectory.deleteSync(recursive: true);
    }
  }
}

Future<void> main(List<String> arguments) async {
  if (arguments.length != 2 || arguments.first != 'build') {
    stderr.writeln(
      'BLOCKED_OFFLINE_BUILD_ADAPTER[usage]: helper aceita somente build <server>',
    );
    exitCode = 64;
    return;
  }
  try {
    final summary = await buildOffline(Directory(arguments.last));
    stdout.writeln(jsonEncode(summary));
  } on OfflineBuildFailure catch (error) {
    stderr.writeln(error);
    exitCode = 66;
  } on Object catch (error, stackTrace) {
    stderr
      ..writeln('BLOCKED_OFFLINE_BUILD_ADAPTER[unexpected]: $error')
      ..writeln(stackTrace);
    exitCode = 70;
  }
}
