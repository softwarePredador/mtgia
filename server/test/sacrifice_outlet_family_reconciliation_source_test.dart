import 'dart:io';

import 'package:test/test.dart';

const _reportDir = '../docs/hermes-analysis/master_optimizer_reports';
const _prefix =
    '$_reportDir/pg873_sacrifice_outlet_family_reconciliation_20260715';

String _read(String suffix) => File('$_prefix$suffix').readAsStringSync();

void main() {
  group('PG873 sacrifice outlet family package', () {
    test('keeps precheck and postcheck read only with exact live guards', () {
      final precheck = _read('_precheck.sql');
      final postcheck = _read('_postcheck.sql');

      for (final sql in [precheck, postcheck]) {
        expect(sql, contains('BEGIN TRANSACTION READ ONLY'));
        expect(sql, isNot(contains('INSERT INTO public.')));
        expect(sql, isNot(contains('UPDATE public.')));
        expect(sql, isNot(contains('DELETE FROM public.')));
        expect(sql, contains('51272701cdb5b277'));
        expect(sql, contains('512cb67eca26b4c8'));
      }

      expect(precheck, contains('PG873_PRECHECK_ABORT_'));
      expect(precheck, contains('semantic_snapshot_count = 1557'));
      expect(precheck, contains('expected_semantic_rows_missing = 52'));
      expect(postcheck, contains('PG873_POSTCHECK_ABORT_'));
      expect(postcheck, contains('live_manifest_diff_rows=0'));
      expect(postcheck, contains('tag_order_violations=0'));
    });

    test('snapshots every changed lane and has a guarded exact rollback', () {
      final apply = _read('_apply.sql');
      final rollback = _read('_rollback.sql');

      expect(
        apply,
        startsWith(
          '-- MUTATING. Requires explicit PostgreSQL approval for this execution.',
        ),
      );
      expect(apply, contains('pg873_sac_outlet_expected_20260715'));
      expect(apply, contains('pg873_sac_outlet_function_backup_20260715'));
      expect(apply, contains('pg873_sac_outlet_semantic_backup_20260715'));
      expect(apply, contains('pg873_sac_outlet_post_semantic_20260715'));
      expect(
        apply,
        contains(
          r'\ir pg873_sacrifice_outlet_family_reconciliation_20260715_missing_semantic_manifest.sql',
        ),
      );
      expect(apply, contains("f.tag = 'sacrifice_outlet'"));
      expect(
        apply,
        contains(
          "f.source IN ('deterministic_heuristic_v1', 'deterministic_semantic_v2')",
        ),
      );
      expect(apply, contains('external_activated_sacrifice_outlet_cost'));

      expect(rollback, contains('current semantic target rows drifted'));
      expect(rollback, contains('function restore differs from snapshot'));
      expect(rollback, contains('semantic restore differs from snapshot'));
      expect(rollback, contains('v_h_count<>1357'));
      expect(rollback, contains('v_s_count<>1380'));
    });

    test('missing semantic manifest is outlet-only and bounded to 52 rows', () {
      final manifest = _read('_missing_semantic_manifest.sql');
      final cardIds = RegExp(r'"card_id":"[0-9a-f-]{36}"').allMatches(manifest);

      expect(cardIds, hasLength(52));
      expect(
        RegExp(r'"tags":\[\{"tag":"sacrifice_outlet"').allMatches(manifest),
        hasLength(52),
      );
      expect(manifest, contains('validated outlet tag'));
      expect(manifest, isNot(contains('"tag":"ramp"')));
      expect(manifest, isNot(contains('"tag":"engine"')));
    });

    test('does not prune neighboring generated data families', () {
      final package = [
        _read('_apply.sql'),
        _read('_rollback.sql'),
        _read('_missing_semantic_manifest.sql'),
      ].join('\n');

      expect(package, isNot(contains('card_role_scores')));
      expect(package, isNot(contains('commander_card_synergy')));
      expect(package, isNot(contains('optimize_rejection_penalties')));
      expect(package, isNot(contains("tag = 'sacrifice'")));
    });
  });
}
