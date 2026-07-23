import 'dart:io';

import 'package:path/path.dart' as path;

class SourceReachabilityResult {
  const SourceReachabilityResult({
    required this.runtimeFiles,
    required this.operationalOnlyFiles,
    required this.validationOnlyFiles,
    required this.orphanFiles,
  });

  final Set<String> runtimeFiles;
  final Set<String> operationalOnlyFiles;
  final Set<String> validationOnlyFiles;
  final Set<String> orphanFiles;

  bool get hasOrphans => orphanFiles.isNotEmpty;
}

class SourceReachabilityAudit {
  const SourceReachabilityAudit({
    required this.projectRoot,
    required this.packageName,
  });

  final String projectRoot;
  final String packageName;

  SourceReachabilityResult analyze({
    required Iterable<String> runtimeRoots,
    Iterable<String> operationalRoots = const <String>[],
    Iterable<String> validationRoots = const <String>[],
  }) {
    final libraryFiles = _dartFilesUnder('lib');
    final runtimeFiles = _reachableLibraryFiles(runtimeRoots);
    final operationalFiles = _reachableLibraryFiles(operationalRoots);
    final validationFiles = _reachableLibraryFiles(validationRoots);
    final supportedFiles = <String>{...runtimeFiles, ...operationalFiles};

    return SourceReachabilityResult(
      runtimeFiles: runtimeFiles,
      operationalOnlyFiles: operationalFiles.difference(runtimeFiles),
      validationOnlyFiles: validationFiles.difference(supportedFiles),
      orphanFiles: libraryFiles
          .difference(supportedFiles)
          .difference(validationFiles),
    );
  }

  Set<String> dartFilesUnder(String relativeDirectory) {
    return _dartFilesUnder(relativeDirectory);
  }

  Set<String> _reachableLibraryFiles(Iterable<String> roots) {
    final reachableLibraries = <String>{};
    final processed = <String>{};
    final queue = roots.map(_normalizeRelative).toList(growable: true);

    while (queue.isNotEmpty) {
      final current = queue.removeLast();
      if (!processed.add(current)) continue;

      final file = File(path.join(projectRoot, current));
      if (!file.existsSync()) continue;
      if (current == 'lib' || current.startsWith('lib/')) {
        reachableLibraries.add(current);
      }

      final source = file.readAsStringSync();
      for (final uri in _directiveUris(source)) {
        final resolved = _resolveUri(current, uri);
        if (resolved == null || processed.contains(resolved)) continue;
        if (File(path.join(projectRoot, resolved)).existsSync()) {
          queue.add(resolved);
        }
      }
    }

    return reachableLibraries;
  }

  Set<String> _dartFilesUnder(String relativeDirectory) {
    final directory = Directory(path.join(projectRoot, relativeDirectory));
    if (!directory.existsSync()) return <String>{};

    return directory
        .listSync(recursive: true, followLinks: false)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .map((file) => path.relative(file.path, from: projectRoot))
        .map(_normalizeRelative)
        .toSet();
  }

  String? _resolveUri(String sourcePath, String uri) {
    String? resolved;
    final packagePrefix = 'package:$packageName/';
    if (uri.startsWith(packagePrefix)) {
      resolved = 'lib/${uri.substring(packagePrefix.length)}';
    } else if (!uri.startsWith('package:') && !uri.startsWith('dart:')) {
      resolved = path.join(path.dirname(sourcePath), uri);
    }
    if (resolved == null) return null;

    final normalized = _normalizeRelative(resolved);
    if (normalized == '..' || normalized.startsWith('../')) return null;
    return normalized;
  }
}

final _directivePattern = RegExp(
  r'''^\s*(?:import|export|part)\s+([^;]+);''',
  multiLine: true,
);
final _quotedUriPattern = RegExp(r'''['"]([^'"]+)['"]''');

Iterable<String> _directiveUris(String source) sync* {
  for (final directive in _directivePattern.allMatches(source)) {
    final body = directive.group(1);
    if (body == null || body.trimLeft().startsWith('of ')) continue;
    for (final uri in _quotedUriPattern.allMatches(body)) {
      final value = uri.group(1);
      if (value != null) yield value;
    }
  }
}

String _normalizeRelative(String value) {
  return path.normalize(value).replaceAll(r'\', '/');
}
