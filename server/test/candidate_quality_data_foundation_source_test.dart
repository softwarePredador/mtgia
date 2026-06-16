import 'dart:io';

import 'package:test/test.dart';

void main() {
  test(
      'candidate quality apply requires explicit override for large stale prune',
      () {
    final source =
        File('bin/candidate_quality_data_foundation.dart').readAsStringSync();

    expect(source, contains('--allow-large-stale-prune'));
    expect(source, contains('--max-stale-prune-on-apply'));
    expect(source, contains('_guardApplyStalePrune'));
    expect(source, contains('Apply abortado: stale prune acima do limite'));
    expect(source, contains('stale_generated_rows_preview'));
  });
}
