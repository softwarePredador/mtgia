import 'dart:io';

import 'package:test/test.dart';

void main() {
  late String source;

  setUpAll(() {
    source = File('bin/semantic_layer_v2_backfill.dart').readAsStringSync();
  });

  test('apply is fail-closed and partial authoritative apply is forbidden', () {
    expect(source, contains('MANALOOM_CONFIRM_POSTGRES_WRITES'));
    expect(source, contains('I_HAVE_EXPLICIT_APPROVAL'));
    expect(source, contains('PostgreSQL write refused'));
    expect(source, contains("final apply = args.contains('--apply')"));
    expect(source, contains("'mode': apply ? 'apply' : 'dry_run'"));
    expect(source, contains('--limit e permitido somente em dry-run'));

    final writeGate = source.indexOf('PostgreSQL write refused');
    final databaseConnect = source.indexOf('await database.connect()');
    expect(writeGate, greaterThanOrEqualTo(0));
    expect(writeGate, lessThan(databaseConnect));
  });

  test('complete in-memory plan keeps empty-tag semantic snapshots', () {
    expect(source, contains('final plan = _buildPlan(cards)'));
    expect(source, contains('FROM cards\nORDER BY id ASC'));
    expect(source, isNot(contains("WHERE COALESCE(type_line, '') <> ''")));
    expect(source, isNot(contains("COALESCE(oracle_text, '') <> ''")));
    expect(
      source,
      contains('One authoritative snapshot row per analyzed card'),
    );
    expect(source, contains('semanticRows.add'));
    expect(source, isNot(contains('if (semantic.tags.isEmpty) continue')));
    expect(source, contains('validateSemanticLayerV2PlannedDatasets'));
    expect(source, contains('final totalCardRows = await _loadTotalCardCount'));
    expect(source, contains('expectedAuthoritativeCardCount: limit == 0'));
    expect(source, contains('exactly one snapshot for every cards row'));
    expect(source, contains('snapshot row per analyzed card'));
    expect(source, contains('exactly mirror snapshot tags'));
    expect(source, contains('planned_datasets'));
    expect(source, contains('semanticLayerV2RowsDigest'));
  });

  test(
    'schema, locks, rechecks, mutations, and prunes share one transaction',
    () {
      expect(source, contains('pool.runTx<Map<String, int>>'));
      expect(source, contains('pg_advisory_xact_lock'));
      expect(source, contains('_ensureSchema(session)'));
      expect(source, contains('_lockAuthoritativeTables(session)'));
      expect(source, contains('LOCK TABLE cards IN SHARE MODE'));
      expect(
        source,
        contains(
          'LOCK TABLE card_semantic_tags_v2 IN SHARE ROW EXCLUSIVE MODE',
        ),
      );
      expect(
        source,
        contains('LOCK TABLE card_function_tags IN SHARE ROW EXCLUSIVE MODE'),
      );
      expect(source, contains('_guardSourceDatasetUnchanged'));
      expect(source, contains('_guardStalePreviewUnchanged'));
      expect(source, contains('IS DISTINCT FROM'));
      expect(source, contains('RETURNING 1'));
      expect(source, contains('_pruneSemanticRows'));
      expect(source, contains('_pruneFunctionRows'));
      expect(source, contains('existing.source = @source'));
      expect(source, contains('--max-stale-prune-on-apply'));
      expect(source, contains('--allow-large-stale-prune'));
    },
  );

  test('failure injection is guarded and covers each transactional lane', () {
    expect(source, contains('--test-fail-after-lane='));
    expect(
      source,
      contains('MANALOOM_ENABLE_SEMANTIC_BACKFILL_FAILURE_INJECTION'),
    );
    expect(source, contains('I_UNDERSTAND_THIS_MUST_ROLL_BACK'));
    expect(source, contains("completedLane: 'card_semantic_tags_v2'"));
    expect(source, contains("completedLane: 'card_function_tags'"));
    expect(source, contains("completedLane: 'prunes'"));
    expect(source, contains('the global transaction must roll back'));
  });

  test('artifacts are aggregate-only and apply reports actual mutations', () {
    expect(source, contains("'aggregate_only': true"));
    expect(source, contains("'raw_rules_text_saved': false"));
    expect(source, contains("'card_ids_saved': false"));
    expect(source, contains("'card_names_saved': false"));
    expect(source, contains("'full_row_payloads_saved': false"));
    expect(source, contains('stalePreviewSummary'));
    expect(source, contains('missingPreviewSummary'));
    expect(source, contains('missing_owned_rows_before_apply'));
    expect(source, contains("'tag_counts': _sorted(tagCounts)"));
    expect(source, contains('--review-sample-limit='));
    expect(source, contains('_printFunctionRowReviewSamples'));
    expect(source, isNot(contains('rows_preview.json')));
    expect(source, isNot(contains('rows_full.json')));
    expect(source, contains('mutationCounts.values.any((count) => count > 0)'));
    expect(source, contains("'apply_executed': apply"));
    expect(source, contains("'db_mutations': dbMutations"));
  });
}
