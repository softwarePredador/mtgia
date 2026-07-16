import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('AI routes do not print or expose raw exception messages', () {
    final routeFiles = <File>[];
    for (final root in <Directory>[
      Directory('routes/ai'),
      Directory('routes/decks/[id]/ai-analysis'),
      Directory('routes/decks/[id]/recommendations'),
    ]) {
      for (final entity in root.listSync(recursive: true)) {
        if (entity is File && entity.path.endsWith('.dart')) {
          routeFiles.add(entity);
        }
      }
    }

    expect(routeFiles, isNotEmpty);
    for (final file in routeFiles) {
      final source = file.readAsStringSync();
      expect(
        source,
        isNot(contains('print(')),
        reason: '${file.path} must use the sanitized logger',
      );
      expect(
        source,
        isNot(
          contains(
            RegExp(
              r'''['"](?:error|details|message)['"]\s*:\s*(?:e|error|exception)\.toString\(\)''',
            ),
          ),
        ),
        reason: '${file.path} must not expose raw exception text',
      );
      expect(
        source,
        isNot(
          contains(
            RegExp(
              r'''['"](?:error|details|message)['"]\s*:\s*['"]\$(?:e|error|exception)['"]''',
            ),
          ),
        ),
        reason: '${file.path} must not interpolate raw exceptions in responses',
      );
      expect(
        source,
        isNot(
          contains(
            RegExp(
              r'''Log\.[diwe]\([^;]*(?:\$(?:e|error|exception|stackTrace)\b|\$\{(?:e|error|exception|stackTrace)\})[^;]*\);''',
              multiLine: true,
            ),
          ),
        ),
        reason: '${file.path} must not write raw exceptions to logs',
      );
      for (final rawInterpolation in <String>[
        r'error=$error',
        r'error=$e',
        r': $error',
        r': $e',
        r'$stackTrace',
      ]) {
        expect(
          source,
          isNot(contains(rawInterpolation)),
          reason:
              '${file.path} must not log raw interpolation '
              '$rawInterpolation',
        );
      }
    }
  });

  test('top-level AI failures are captured by observability', () {
    const observedRoutes = <String>[
      'routes/ai/archetypes/index.dart',
      'routes/ai/commander-learning/index.dart',
      'routes/ai/explain/index.dart',
      'routes/ai/generate/index.dart',
      'routes/ai/generate/jobs/[id].dart',
      'routes/ai/optimize/index.dart',
      'routes/ai/optimize/jobs/[id].dart',
      'routes/ai/optimize/telemetry/index.dart',
      'routes/ai/rebuild/index.dart',
      'routes/ai/simulate/index.dart',
      'routes/ai/simulate-matchup/index.dart',
      'routes/ai/weakness-analysis/index.dart',
      'routes/ai/commander-reference/index.dart',
      'routes/ai/ml-status/index.dart',
      'routes/decks/[id]/ai-analysis/index.dart',
      'routes/decks/[id]/recommendations/index.dart',
    ];

    for (final path in observedRoutes) {
      final source = File(path).readAsStringSync();
      expect(
        source,
        contains('captureRouteException('),
        reason: '$path must report unexpected failures without exposing them',
      );
    }
  });
}
