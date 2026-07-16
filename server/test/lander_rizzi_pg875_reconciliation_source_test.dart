import 'dart:io';

import 'package:test/test.dart';

const _prefix =
    '../docs/hermes-analysis/master_optimizer_reports/'
    'pg875_lander_rizzi_reconciliation_20260716';
const _uuid = '1f10f7b7-a895-4a76-9d64-7751eced092e';

String _read(String suffix) => File('$_prefix$suffix').readAsStringSync();

void main() {
  group('PG875 Lander Rizzi reconciliation package', () {
    test('precheck and postcheck are read only and hash exact', () {
      final precheck = _read('_precheck.sql');
      final postcheck = _read('_postcheck.sql');

      for (final sql in [precheck, postcheck]) {
        expect(sql, contains('BEGIN TRANSACTION READ ONLY'));
        expect(sql, contains('ROLLBACK;'));
        expect(sql, isNot(contains('DELETE FROM public.')));
        expect(sql, isNot(contains('UPDATE public.')));
        expect(sql, isNot(contains('INSERT INTO public.')));
        expect(sql, isNot(contains('CREATE TABLE')));
      }

      expect(precheck, contains(_uuid));
      expect(precheck, contains('PG875_PRECHECK_PASS'));
      expect(precheck, contains('function_count = 11'));
      expect(precheck, contains('role_count = 4'));
      expect(precheck, contains('semantic_count = 1'));
      expect(
        precheck,
        contains(
          '940bfb92b0dd23af72999cff33de4dfd6de5cbb00581f0edb421c01609e7d2f7',
        ),
      );
      expect(postcheck, contains('PG875_POSTCHECK_PASS'));
      expect(postcheck, contains('function_count = 12'));
      expect(postcheck, contains('role_count = 5'));
      expect(postcheck, contains('function_post_diff = 0'));
      expect(postcheck, contains('untouched_function_diff = 0'));
      expect(postcheck, contains('target_input_diff = 0'));
    });

    test(
      'apply replaces only exact deterministic rows and snapshots all lanes',
      () {
        final apply = _read('_apply.sql');

        expect(apply, startsWith('-- MUTATING.'));
        expect(apply, contains(_uuid));
        for (final suffix in [
          'target',
          'function_backup',
          'role_backup',
          'semantic_backup',
          'function_untouched',
          'role_untouched',
          'semantic_untouched',
          'function_post',
          'role_post',
          'semantic_post',
        ]) {
          expect(
            apply,
            contains('pg875_lander_${suffix}_20260716'),
            reason: 'missing audit snapshot $suffix',
          );
        }

        expect(apply, contains('DELETE FROM public.card_function_tags'));
        expect(apply, contains('DELETE FROM public.card_role_scores'));
        expect(apply, contains('DELETE FROM public.card_semantic_tags_v2'));
        expect(apply, isNot(contains('DELETE FROM public.cards')));
        expect(apply, isNot(contains('DELETE FROM public.card_meta_insights')));
        expect(apply, isNot(contains('DELETE FROM public.deck_cards')));
        expect(apply, isNot(contains('DELETE FROM public.card_battle_rules')));
        expect(apply, isNot(contains('UPDATE public.cards')));
        expect(apply, isNot(contains('UPDATE public.card_meta_insights')));

        expect(apply, contains("'ramp', 0.880"));
        expect(apply, contains("'token_maker', 0.820"));
        expect(apply, contains("'token', 0.820"));
        expect(apply, contains("'sacrifice_outlet', 0.800"));
        expect(apply, contains("'sacrifice', 0.800"));
        expect(apply, contains("'artifact_synergy', 0.740"));
        expect(apply, contains("'payoff', 0.720"));
        expect(apply, contains("'ramp', 80"));
        expect(apply, contains("'token', 76"));
        expect(apply, contains("'sacrifice', 75"));
        expect(apply, contains("'artifact_synergy', 70"));
        expect(apply, contains("'payoff', 69"));
        expect(apply, contains("'triggered_engine'"));
        expect(apply, contains("'mana_acceleration_or_land_search'"));
        expect(
          apply,
          contains(
            'Code truth: the inferred ramp tag makes semantic enabler true.',
          ),
        );
        expect(apply, contains('v_function_count <> 12'));
        expect(apply, contains('v_role_count <> 5'));
        expect(apply, contains('v_semantic_count <> 1'));
      },
    );

    test('rollback requires exact poststate and restores exact backups', () {
      final rollback = _read('_rollback.sql');

      expect(rollback, startsWith('-- MUTATING ROLLBACK.'));
      expect(rollback, contains('current function poststate drifted'));
      expect(rollback, contains('current role poststate drifted'));
      expect(rollback, contains('current semantic poststate drifted'));
      expect(rollback, contains('a non-target source changed'));
      expect(rollback, contains('card or meta input changed'));
      expect(rollback, contains('function restore differs'));
      expect(rollback, contains('role restore differs'));
      expect(rollback, contains('semantic restore differs'));
      expect(rollback, contains('v_function_count <> 11'));
      expect(rollback, contains('v_role_count <> 4'));
      expect(rollback, contains('v_semantic_count <> 1'));
      expect(rollback, isNot(contains('DELETE FROM public.cards')));
      expect(
        rollback,
        isNot(contains('DELETE FROM public.card_meta_insights')),
      );
      expect(rollback, isNot(contains('DELETE FROM public.deck_cards')));
      expect(rollback, isNot(contains('DELETE FROM public.card_battle_rules')));
    });

    test(
      'handoff records applied validation and semantic enabler code truth',
      () {
        final readme =
            File(
              '../docs/hermes-analysis/'
              'PG875_LANDER_RIZZI_RECONCILIATION_2026-07-16.md',
            ).readAsStringSync();

        expect(readme, contains('applied_and_postchecked'));
        expect(readme, contains('`enabler=true` is intentional code truth'));
        expect(readme, contains('PG875_POSTCHECK_PASS'));
        expect(readme, contains('all `0`'));
      },
    );
  });
}
