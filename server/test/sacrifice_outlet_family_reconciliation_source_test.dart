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
        expect(sql, contains('573c94fad8b4ba9d'));
      }

      expect(precheck, contains('PG873_PRECHECK_ABORT_'));
      expect(precheck, contains('semantic_snapshot_count = 1557'));
      expect(precheck, contains('deferred_semantic_backfill_count = 52'));
      expect(postcheck, contains('PG873_POSTCHECK_ABORT_'));
      expect(postcheck, contains('manifest_semantic_count=684'));
      expect(postcheck, contains('deferred_manifest_count=52'));
      expect(postcheck, contains('post_semantic_count=1524'));
      expect(postcheck, contains('live_manifest_diff_rows=0'));
      expect(postcheck, contains('tag_order_violations=0'));
      expect(
        postcheck,
        isNot(contains('pg873_sac_outlet_missing_semantic_20260715')),
      );
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
      expect(apply, contains('pg873_sac_outlet_deferred_semantic_20260715'));
      expect(apply, contains('pg873_sac_outlet_post_semantic_20260715'));
      expect(apply, isNot(contains(r'\ir')));
      expect(
        apply,
        isNot(contains('INSERT INTO public.card_semantic_tags_v2')),
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
      expect(rollback, contains('deferred semantic backlog changed'));
    });

    test(
      'defers incomplete semantic snapshots instead of materializing them',
      () {
        final apply = _read('_apply.sql');
        final legacyManifest = File('${_prefix}_missing_semantic_manifest.sql');

        expect(legacyManifest.existsSync(), isFalse);
        expect(apply, contains('v_count <> 52'));
        expect(
          apply,
          contains(
            "v_sha <> '4f29cbcbbdaa9a10bf285ff808c40ab8f3026367a2b3bc873fd51424cad5b199'",
          ),
        );
        expect(apply, contains('full semantic'));
        expect(apply, isNot(contains('no_primary_function_detected')));
      },
    );

    test('does not prune neighboring generated data families', () {
      final package = [_read('_apply.sql'), _read('_rollback.sql')].join('\n');

      expect(package, isNot(contains('card_role_scores')));
      expect(package, isNot(contains('commander_card_synergy')));
      expect(package, isNot(contains('optimize_rejection_penalties')));
      expect(package, isNot(contains("tag = 'sacrifice'")));
    });
  });
}
