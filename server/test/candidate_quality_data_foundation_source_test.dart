import 'dart:io';

import 'package:test/test.dart';

void main() {
  test(
    'candidate quality apply requires explicit override for large stale prune',
    () {
      final source =
          File('bin/candidate_quality_data_foundation.dart').readAsStringSync();

      expect(source, contains('--allow-large-stale-prune'));
      expect(source, contains('MANALOOM_CONFIRM_POSTGRES_WRITES'));
      expect(source, contains('I_HAVE_EXPLICIT_APPROVAL'));
      expect(source, contains('PostgreSQL write refused'));
      expect(source, contains('--max-stale-prune-on-apply'));
      expect(source, contains('_guardApplyStalePrune'));
      expect(source, contains('Apply abortado: stale prune acima do limite'));
      expect(source, contains('stale_generated_rows_preview'));
      expect(source, contains('--full-artifacts'));
      expect(source, contains('planned_dataset_sha256'));
      expect(source, contains('planned_dataset_unique_rows'));
      expect(source, contains('validateCandidateQualityPlannedDatasets'));
      expect(source, contains('Planned dataset uniqueness preflight failed'));
      expect(source, contains('pg_advisory_xact_lock'));
      expect(source, contains('_guardStalePreviewUnchanged'));
      expect(source, contains('pool.runTx<Map<String, int>>'));
      expect(source, contains('IS DISTINCT FROM'));
      expect(source, contains('RETURNING 1'));
      expect(
        source,
        contains('mutationCounts.values.any((count) => count > 0)'),
        reason: 'idempotent apply must report no database mutations',
      );
      expect(source, contains('--test-fail-after-lane='));
      expect(source, contains('the global transaction must roll back'));
      expect(source, contains('function_tag_rows_full.json'));
      expect(
        source,
        contains(
          'enabled through persisted functional_tags, semantic_tags_v2, and card_role_scores',
        ),
      );
      expect(
        source,
        isNot(contains('not enabled in request path during stage 1')),
      );
    },
  );
}
