import 'dart:io';

import 'package:test/test.dart';

const _prefix =
    '../docs/hermes-analysis/master_optimizer_reports/pg874_ramp_family_reconciliation_20260716';

String _read(String suffix) => File('$_prefix$suffix').readAsStringSync();

void main() {
  group('PG874 ramp family package', () {
    test('precheck and postcheck are read only and exact', () {
      final precheck = _read('_precheck.sql');
      final postcheck = _read('_postcheck.sql');
      for (final sql in [precheck, postcheck]) {
        expect(sql, contains('BEGIN TRANSACTION READ ONLY'));
        expect(sql, isNot(contains('DELETE FROM public.')));
        expect(sql, isNot(contains('UPDATE public.')));
        expect(sql, isNot(contains('INSERT INTO public.')));
      }
      expect(precheck, contains('PG874_PRECHECK_PASS'));
      expect(precheck, contains('tc=1377'));
      expect(precheck, contains('hc=1302'));
      expect(precheck, contains('rc=1322'));
      expect(precheck, contains('sc=1350'));
      expect(postcheck, contains('PG874_POSTCHECK_PASS'));
      expect(postcheck, contains('target_function_rows=0'));
      expect(postcheck, contains('post_semantic_diff=0'));
    });

    test('apply is remove only, fully snapshotted and semantic-safe', () {
      final apply = _read('_apply.sql');
      expect(apply, startsWith('-- MUTATING.'));
      expect(apply, contains('pg874_ramp_target_20260716'));
      expect(apply, contains('pg874_ramp_function_backup_20260716'));
      expect(apply, contains('pg874_ramp_role_backup_20260716'));
      expect(apply, contains('pg874_ramp_semantic_backup_20260716'));
      expect(apply, contains('pg874_ramp_post_semantic_20260716'));
      expect(apply, contains("f.tag='ramp'"));
      expect(apply, contains("r.role='ramp'"));
      expect(apply, contains('land_search_without_battlefield_acceleration'));
      expect(apply, contains('role_confidence=d.role_confidence'));
      expect(apply, contains('explanation_reason=d.explanation_reason'));
      expect(apply, isNot(contains('INSERT INTO public.card_function_tags')));
      expect(apply, isNot(contains('INSERT INTO public.card_role_scores')));
      expect(
        apply,
        isNot(contains('INSERT INTO public.card_semantic_tags_v2')),
      );
      expect(apply, isNot(contains('card_battle_rules')));
      expect(apply, isNot(contains('deck_cards')));
    });

    test('rollback restores all exact snapshots with original hashes', () {
      final rollback = _read('_rollback.sql');
      expect(rollback, contains('function restore differs from snapshot'));
      expect(rollback, contains('role restore differs from snapshot'));
      expect(rollback, contains('semantic restore differs from snapshot'));
      expect(rollback, contains('hc<>3092'));
      expect(rollback, contains('rc<>3124'));
      expect(rollback, contains('sc<>3246'));
      expect(rollback, contains('jc<>3246'));
    });
  });
}
