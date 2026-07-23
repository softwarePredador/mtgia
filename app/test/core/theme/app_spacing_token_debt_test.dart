import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('raw spacing debt cannot grow while canonical tokens are migrated', () {
    final manifest =
        jsonDecode(
              File(
                'test/core/theme/fixtures/raw_spacing_debt.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
    final expectedByFile = (manifest['files'] as Map<String, dynamic>).map(
      (path, count) => MapEntry(path, count as int),
    );
    final baselineLines = manifest['baseline_total'] as int;
    final pattern = RegExp(
      r'EdgeInsets\.(all|symmetric|only|fromLTRB)\([^A-Za-z\n]*[0-9]'
      r'|SizedBox\((width|height):\s*[0-9]'
      r'|Gap\([0-9]',
    );
    final countsByFile = <String, int>{};

    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final count = entity.readAsLinesSync().where(pattern.hasMatch).length;
      if (count > 0) countsByFile[entity.path] = count;
    }

    final total = countsByFile.values.fold<int>(0, (sum, value) => sum + value);
    final unclassifiedFiles = countsByFile.keys.toSet().difference(
      expectedByFile.keys.toSet(),
    );
    final regressions = <String>[];
    for (final entry in countsByFile.entries) {
      final expected = expectedByFile[entry.key];
      if (expected != null && entry.value > expected) {
        regressions.add('${entry.key}: ${entry.value} > $expected');
      }
    }

    final worst = countsByFile.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final summary = worst
        .take(10)
        .map((entry) => '${entry.key}: ${entry.value}')
        .join('\n');

    expect(unclassifiedFiles, isEmpty, reason: 'New raw spacing files found.');
    expect(
      regressions,
      isEmpty,
      reason: 'Per-file raw spacing debt grew:\n${regressions.join('\n')}',
    );
    expect(
      total,
      lessThanOrEqualTo(baselineLines),
      reason:
          'Raw spacing debt grew from the frozen Sprint 2 baseline. '
          'Use AppTheme tokens or reduce another classified legacy site.\n'
          'Largest current files:\n$summary',
    );
  });
}
