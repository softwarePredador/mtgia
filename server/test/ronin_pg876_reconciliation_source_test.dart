import 'dart:io';

import 'package:test/test.dart';

const _prefix =
    '../docs/hermes-analysis/master_optimizer_reports/'
    'pg876_ronin_ramp_reconciliation_20260716';
const _uuid = '115df6db-5280-4223-921b-dc4f591841f2';
const _preFunctionSha =
    '83d684394dda226d06f4afb55fbb32b150b2d3780aa3856cc339c45abbf03381';
const _postFunctionSha =
    '9fe4dcd49d1940beb9d517c7f970814a98197f6fd8548a5d2e28a577cc1f3b01';
const _postRoleSha =
    'cb9a07b13db7249c50d9fb03769668d8f200531694390d81a7d32c507fbb558a';

String _read(String suffix) => File('$_prefix$suffix').readAsStringSync();

void _expectOnlyRoninUuid(String sql) {
  final uuids =
      RegExp(
        r'\b[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\b',
        caseSensitive: false,
      ).allMatches(sql).map((match) => match.group(0)!.toLowerCase()).toSet();
  expect(uuids, {_uuid});
}

void _expectNoSemanticMutation(String sql) {
  expect(sql, isNot(contains('DELETE FROM public.card_semantic_tags_v2')));
  expect(sql, isNot(contains('UPDATE public.card_semantic_tags_v2')));
  expect(sql, isNot(contains('INSERT INTO public.card_semantic_tags_v2')));
}

void _expectNoOutOfScopeMutation(String sql) {
  for (final table in [
    'cards',
    'card_meta_insights',
    'edhrec_card_snapshots',
    'deck_cards',
    'decks',
    'card_legalities',
    'card_battle_rules',
    'commander_card_usage',
  ]) {
    expect(sql, isNot(contains('DELETE FROM public.$table')));
    expect(sql, isNot(contains('UPDATE public.$table')));
    expect(sql, isNot(contains('INSERT INTO public.$table')));
  }
}

void main() {
  group('PG876 Ronin reconciliation package', () {
    test('precheck and postcheck are read only, exact and semantic-empty', () {
      final precheck = _read('_precheck.sql');
      final postcheck = _read('_postcheck.sql');

      for (final sql in [precheck, postcheck]) {
        expect(sql, contains('BEGIN TRANSACTION READ ONLY'));
        expect(sql, contains('ROLLBACK;'));
        expect(sql, contains(_uuid));
        _expectOnlyRoninUuid(sql);
        expect(sql, contains("source = 'deterministic_heuristic_v1'"));
        expect(sql, contains('semantic_snapshot_count'));
        expect(sql, contains('semantic_snapshot_count = 0'));
        expect(sql, isNot(contains('CREATE TABLE')));
        expect(sql, isNot(contains('DELETE FROM public.')));
        expect(sql, isNot(contains('UPDATE public.')));
        expect(sql, isNot(contains('INSERT INTO public.')));
      }

      expect(precheck, contains('PG876_PRECHECK_PASS'));
      expect(precheck, contains('function_count = 1'));
      expect(precheck, contains('role_count = 0'));
      expect(precheck, contains(_preFunctionSha));
      expect(
        precheck,
        contains(
          '853b46a8324082709733e85a6486098aaf786cc73924cd7e85d6035b0105b3c8',
        ),
      );
      expect(postcheck, contains('PG876_POSTCHECK_PASS'));
      expect(postcheck, contains('function_count = 4'));
      expect(postcheck, contains('role_count = 3'));
      expect(postcheck, contains(_postFunctionSha));
      expect(postcheck, contains(_postRoleSha));
      expect(postcheck, contains('function_post_diff = 0'));
      expect(postcheck, contains('role_post_diff = 0'));
      expect(postcheck, contains('target_diff = 0'));
      expect(postcheck, contains('untouched_function_diff = 0'));
      expect(postcheck, contains('untouched_role_diff = 0'));
    });

    test('apply replaces only the exact heuristic function and role rows', () {
      final apply = _read('_apply.sql');

      expect(apply, startsWith('-- MUTATING.'));
      expect(apply, contains(_uuid));
      _expectOnlyRoninUuid(apply);
      expect(apply, contains("source = 'deterministic_heuristic_v1'"));
      for (final suffix in [
        'target',
        'function_backup',
        'role_backup',
        'function_untouched',
        'role_untouched',
        'function_post',
        'role_post',
      ]) {
        expect(
          apply,
          contains('pg876_ronin_${suffix}_20260716'),
          reason: 'missing audit snapshot $suffix',
        );
      }

      expect(apply, contains('DELETE FROM public.card_function_tags'));
      expect(apply, contains('DELETE FROM public.card_role_scores'));
      _expectNoSemanticMutation(apply);
      _expectNoOutOfScopeMutation(apply);

      expect(apply, contains("'ramp', 0.880"));
      expect(apply, contains("'removal', 0.830"));
      expect(apply, contains("'sacrifice', 0.800"));
      expect(apply, contains("'sacrifice_outlet', 0.800"));
      expect(apply, contains("'ramp', 63"));
      expect(apply, contains("'removal', 60"));
      expect(apply, contains("'sacrifice', 58"));
      expect(apply, contains('v_function_count <> 4'));
      expect(apply, contains('v_role_count <> 3'));
      expect(apply, contains(_preFunctionSha));
      expect(apply, contains(_postFunctionSha));
      expect(apply, contains(_postRoleSha));
    });

    test(
      'rollback guards poststate and restores exact empty-role prestate',
      () {
        final rollback = _read('_rollback.sql');

        expect(rollback, startsWith('-- MUTATING ROLLBACK.'));
        expect(rollback, contains(_uuid));
        _expectOnlyRoninUuid(rollback);
        expect(rollback, contains('current function poststate drifted'));
        expect(rollback, contains('current role poststate drifted'));
        expect(rollback, contains('a non-target source changed'));
        expect(rollback, contains('semantic snapshot appeared'));
        expect(rollback, contains('card or scoring input changed'));
        expect(rollback, contains('function restore differs'));
        expect(rollback, contains('role restore differs'));
        expect(rollback, contains('v_function_count <> 1'));
        expect(rollback, contains('v_role_count <> 0'));
        expect(rollback, contains(_preFunctionSha));
        _expectNoSemanticMutation(rollback);
        _expectNoOutOfScopeMutation(rollback);
      },
    );

    test('handoff records applied postcheck and no semantic snapshot', () {
      final handoff =
          File(
            '../docs/hermes-analysis/'
            'PG876_RONIN_RAMP_RECONCILIATION_2026-07-16.md',
          ).readAsStringSync();

      expect(handoff, contains('applied_and_postchecked'));
      expect(handoff, contains('PG876_PRECHECK_PASS'));
      expect(handoff, contains('PG876_POSTCHECK_PASS'));
      expect(handoff, contains('explicitly authorized apply committed'));
      expect(handoff, contains('semantic-v2 rows: `0`'));
      expect(handoff, contains('`121` cards'));
      expect(handoff, contains('deferred'));
    });
  });
}
