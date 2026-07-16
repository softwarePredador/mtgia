import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:test/test.dart';

const _reportPrefix =
    '../docs/hermes-analysis/master_optimizer_reports/'
    'pg879_flashback_exact_runtime_and_cmc_20260716';
const _packageDocPath =
    '../docs/hermes-analysis/'
    'PG879_FLASHBACK_EXACT_RUNTIME_AND_CMC_2026-07-16.md';
const _runtimePath =
    '../docs/hermes-analysis/manaloom-knowledge/scripts/'
    'battle_analyst_v9.py';
const _runtimeTestPath =
    '../docs/hermes-analysis/manaloom-knowledge/scripts/'
    'test_flashback_exact_runtime.py';

String _sql(String suffix) => File('$_reportPrefix$suffix').readAsStringSync();

dynamic _stable(dynamic value) {
  if (value is Map) {
    final keys = value.keys.map((key) => key.toString()).toList()..sort();
    return LinkedHashMap<String, dynamic>.fromEntries(
      keys.map((key) => MapEntry(key, _stable(value[key]))),
    );
  }
  if (value is List) return value.map(_stable).toList();
  return value;
}

dynamic _firstPresent(Iterable<dynamic> values) {
  for (final value in values) {
    if (value != null &&
        value != '' &&
        value != const [] &&
        value != const {}) {
      return value;
    }
  }
  return null;
}

String _logicalRuleKey(
  Map<String, dynamic> effect,
  Map<String, dynamic> deckRole,
) {
  final payload = <String, dynamic>{
    'effect': effect,
    'deck_role': deckRole,
    'face_name': _firstPresent([effect['face_name'], deckRole['face_name']]),
    'face_index': _firstPresent([effect['face_index'], deckRole['face_index']]),
    'variant_kind': _firstPresent([
      effect['variant_kind'],
      deckRole['variant_kind'],
    ]),
    'ability_kind': _firstPresent([
      effect['ability_kind'],
      deckRole['ability_kind'],
    ]),
    'timing_window': _firstPresent([
      effect['timing_window'],
      deckRole['timing_window'],
    ]),
    'source_zone': _firstPresent([
      effect['source_zone'],
      deckRole['source_zone'],
    ]),
  };
  final digest = sha256.convert(utf8.encode(jsonEncode(_stable(payload))));
  return 'battle_rule_v1:${digest.toString().substring(0, 32)}';
}

Map<String, dynamic> _effect() =>
    jsonDecode(r'''
{"ability_kind":"one_shot_targeted_continuous_permission","battle_model_scope":"target_instant_sorcery_graveyard_gains_mana_cost_flashback_until_eot_v1","cmc":1.0,"duration":"until_end_of_turn","effect":"graveyard_flashback_grant","flashback_cast_status":"runtime_executor_v1","flashback_cost_source":"target_printed_mana_cost","flashback_exile_on_leave_stack":true,"flashback_exile_status":"runtime_executor_v1","flashback_grant_status":"runtime_executor_v1","flashback_uses_normal_cast_pipeline":true,"grants_flashback_to":"target_instant_or_sorcery","instant":true,"oracle_runtime_scope":"target_one_own_graveyard_instant_sorcery_grant_printed_cost_flashback_until_eot_exile_after_stack_exact_v1","sorcery":false,"source_mana_cost":"{R}","source_type_line":"Instant","target":"instant_or_sorcery_card_in_your_graveyard","target_constraints":{"card_types":["instant","sorcery"],"controller_scope":"self","zone":"graveyard"},"target_controller":"self","target_count":1,"target_count_max":1,"target_count_min":1,"target_declared_on_cast":true,"target_legality_rechecked_on_resolution":true,"target_zone":"graveyard","targeted_flashback_grant":true,"xmage_ability_classes":[],"xmage_condition_classes":[],"xmage_cost_classes":[],"xmage_duration":"EndOfTurn","xmage_effect_classes":["GainFlashbackTargetEffect"],"xmage_filter_classes":[],"xmage_filter_constants":["StaticFilters.FILTER_CARD_INSTANT_OR_SORCERY"],"xmage_granted_ability_class":"FlashbackAbility","xmage_granted_ability_cost_source":"card.getManaCost()","xmage_target_classes":["TargetCardInYourGraveyard"]}
''')
        as Map<String, dynamic>;

Map<String, dynamic> _deckRole() =>
    jsonDecode(r'''
{"category":"engine","effect":"graveyard_flashback_grant","functions":["targeted_graveyard_cast_permission","flashback_alternative_cost","flashback_stack_exile_replacement"],"subtype":"targeted_flashback_grant","target":"instant_or_sorcery_card_in_your_graveyard","timing":"instant"}
''')
        as Map<String, dynamic>;

void _expectReadOnly(String sql) {
  expect(sql, contains('BEGIN TRANSACTION READ ONLY'));
  expect(sql, contains('ROLLBACK;'));
  expect(sql, isNot(contains('UPDATE public.')));
  expect(sql, isNot(contains('INSERT INTO public.')));
  expect(sql, isNot(contains('DELETE FROM public.')));
  expect(sql, isNot(contains('CREATE TABLE')));
}

Set<String> _mutatedPublicTables(String sql) {
  final mutation = RegExp(
    r'\b(?:UPDATE|INSERT\s+INTO|DELETE\s+FROM)\s+public\.([a-z_]+)',
    caseSensitive: false,
  );
  return mutation
      .allMatches(sql)
      .map((match) => match.group(1)!.toLowerCase())
      .toSet();
}

void main() {
  group('PG879 Flashback exact runtime and CMC package', () {
    test('canonical effect and role produce the sealed logical key', () {
      final effect = _effect();
      final role = _deckRole();

      expect(
        _logicalRuleKey(effect, role),
        'battle_rule_v1:f5b21163180f3254fa6b288d5ab0a95b',
      );
      expect(effect['target_count'], 1);
      expect(effect['target_zone'], 'graveyard');
      expect(effect['target_controller'], 'self');
      expect(effect['flashback_cost_source'], 'target_printed_mana_cost');
      expect(effect['flashback_exile_on_leave_stack'], isTrue);
      expect(effect['flashback_uses_normal_cast_pipeline'], isTrue);
      expect(role['category'], 'engine');
      expect(
        role['functions'],
        containsAll([
          'targeted_graveyard_cast_permission',
          'flashback_alternative_cost',
          'flashback_stack_exile_replacement',
        ]),
      );
    });

    test('precheck and postcheck are read only and hash gated', () {
      final precheck = _sql('_precheck.sql');
      final postcheck = _sql('_postcheck.sql');
      _expectReadOnly(precheck);
      _expectReadOnly(postcheck);

      for (final sql in [precheck, postcheck]) {
        expect(sql, contains('03ef6ea64392bacd6db316eefe8c3896'));
        expect(sql, contains('22b9db71b43ac3cecf079dc716272d24'));
        expect(sql, contains('1a7fac705bdac60ec3c062960daecff6'));
      }
      expect(precheck, contains('a5ac34f8c716be13f6ea72aea4ef39a2'));
      expect(precheck, contains('368225ebe6470d5da54dbfbb31d733b2'));
      expect(precheck, contains('v_live <> 2'));
      expect(precheck, contains('PG879_PRECHECK_PASS'));
      expect(postcheck, contains('5b3d349754c594360b6315db018b0f96'));
      expect(postcheck, contains('v_total <> 3'));
      expect(postcheck, contains('v_exact <> 1'));
      expect(postcheck, contains('v_disabled <> 2'));
      expect(postcheck, contains('PG879_POSTCHECK_PASS'));
      expect(postcheck, contains('exact card post snapshot drift'));
      expect(postcheck, contains('exact rule post snapshot drift'));
    });

    test('apply is atomic, locked, fully snapshotted, and two-table only', () {
      final apply = _sql('_apply.sql');
      expect(apply, startsWith('-- MUTATING.'));
      expect(apply, contains('BEGIN;'));
      expect(apply, contains('COMMIT;'));
      expect(
        apply,
        contains('LOCK TABLE public.cards IN SHARE ROW EXCLUSIVE MODE'),
      );
      expect(
        apply,
        contains(
          'LOCK TABLE public.card_battle_rules IN SHARE ROW EXCLUSIVE MODE',
        ),
      );
      expect(_mutatedPublicTables(apply), {'cards', 'card_battle_rules'});

      for (final snapshot in [
        'pg879_flashback_cards_pre_20260716',
        'pg879_flashback_rules_pre_20260716',
        'pg879_flashback_proposal_20260716',
        'pg879_flashback_cards_post_20260716',
        'pg879_flashback_rules_post_20260716',
      ]) {
        expect(apply, contains(snapshot));
      }

      expect(apply, contains('UPDATE public.cards\n  SET cmc = 1.0'));
      expect(apply, contains('AND cmc = 0.0'));
      expect(apply, contains('expected exactly 1 cards.cmc update'));
      expect(apply, contains('expected exactly 2 live rules disabled'));
      expect(apply, contains('expected exactly 1 exact rule inserted'));
      expect(apply, contains('cards changed outside cmc 0.0 -> 1.0'));
      expect(apply, contains('exact card post snapshot diff'));
      expect(apply, contains('exact rule post snapshot diff'));
      expect(apply, contains('PG879_APPLY_COMMITTED'));

      for (final table in [
        'card_function_tags',
        'card_role_scores',
        'card_semantic_tags_v2',
        'deck_cards',
        'decks',
        'commander_card_usage',
      ]) {
        expect(apply, isNot(contains('UPDATE public.$table')));
        expect(apply, isNot(contains('INSERT INTO public.$table')));
        expect(apply, isNot(contains('DELETE FROM public.$table')));
      }
    });

    test('proposal is one exact verified auto row and disables broad rows', () {
      final apply = _sql('_apply.sql');
      final effect = _effect();
      final role = _deckRole();

      expect(apply, contains(jsonEncode(effect)));
      expect(apply, contains(jsonEncode(role)));
      expect(apply, contains("'curated'::text"));
      expect(apply, contains('0.98::numeric'));
      expect(apply, contains("'verified'::text"));
      expect(apply, contains("'auto'::text"));
      expect(apply, contains('3::integer'));
      expect(apply, contains("review_status = 'deprecated'"));
      expect(apply, contains("execution_status = 'disabled'"));
      expect(
        apply,
        contains(
          'PG879: disabled superseded broad recursion row before exact '
          'targeted flashback runtime promotion.',
        ),
      );
    });

    test(
      'rollback requires exact poststate and restores both full prestates',
      () {
        final rollback = _sql('_rollback.sql');
        expect(rollback, startsWith('-- MUTATING ROLLBACK.'));
        expect(_mutatedPublicTables(rollback), {'cards', 'card_battle_rules'});
        expect(rollback, contains('exact card poststate drifted'));
        expect(rollback, contains('exact rule poststate drifted'));
        expect(
          rollback,
          contains('expected exactly 3 poststate rules deleted'),
        );
        expect(
          rollback,
          contains('expected exactly 2 prestate rules restored'),
        );
        expect(rollback, contains('expected exactly 1 cards.cmc restore'));
        expect(rollback, contains('SET cmc = b.cmc'));
        expect(rollback, contains('c.cmc = 1.0'));
        expect(rollback, contains('b.cmc = 0.0'));
        expect(rollback, contains('a5ac34f8c716be13f6ea72aea4ef39a2'));
        expect(rollback, contains('368225ebe6470d5da54dbfbb31d733b2'));
        expect(rollback, contains('restored card row set differs'));
        expect(rollback, contains('restored rule row set differs'));
        expect(rollback, contains('PG879_ROLLBACK_COMMITTED'));
      },
    );

    test('runtime and package evidence cover the exact Flashback lifecycle', () {
      final runtime = File(_runtimePath).readAsStringSync();
      final runtimeTests = File(_runtimeTestPath).readAsStringSync();
      final doc = File(_packageDocPath).readAsStringSync();

      for (final token in [
        'FLASHBACK_TARGET_GRANT_EXACT_SCOPE',
        'def is_exact_flashback_target_grant(',
        'def prepare_declared_flashback_grant_target(',
        'def cast_flashback_spell_from_graveyard(',
        'def resolve_targeted_flashback_grant(',
        'flashback_countered',
        'flashback_permission_expired',
      ]) {
        expect(
          runtime,
          contains(token),
          reason: 'missing runtime token $token',
        );
      }

      for (final testName in [
        'test_oracle_normalization_routes_named_card_away_from_generic_recursion',
        'test_resolution_grants_only_declared_legal_target_at_printed_cost',
        'test_target_moved_before_resolution_is_illegal_and_gets_no_permission',
        'test_granted_cast_uses_normal_payment_pipeline_and_exiles_after_resolution',
        'test_granted_instant_exiles_when_countered_with_permission_provenance',
        'test_sorcery_timing_and_unused_permission_expiration_are_enforced',
      ]) {
        expect(
          runtimeTests,
          contains(testName),
          reason: 'missing focused test $testName',
        );
      }

      for (final digest in [
        '1fee8059282891aca6424a704e5f2c6bffaeecd97f440253c04a2ae8b504e12d',
        'a31c4c77af35bdd83e3e259a3d4546236e5017d4a9b037f92c309e2e8927beed',
        '6a3cea9f6a49b61f425bf267cc280a991d4d1315322b11059cd0604e0dd76e87',
        'd960ebf54f87db2baf2a23785c181bdfea863a60d493eb66707ba64becc77be9',
        '374eeaa08611b6b2db2fa3693325c8b50dad9b3b71dcbefd18e059c4403258f4',
      ]) {
        expect(doc, contains(digest));
      }
      expect(doc, contains('34d81ea4995ce15d7e1a788dc6d2a3595d35bcec'));
      expect(
        doc,
        contains('applied_postchecked_synced_and_contract_audited'),
      );
      expect(doc, contains('sync_pg_card_metadata_to_hermes.py'));
      expect(doc, contains('sync_battle_card_rules_pg.py'));
      expect(doc, contains('--apply-sqlite-from-pg'));
      expect(doc, contains('--only-card "Flashback"'));
    });
  });
}
