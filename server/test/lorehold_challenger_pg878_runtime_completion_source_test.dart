import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:test/test.dart';

const _reportPrefix =
    '../docs/hermes-analysis/master_optimizer_reports/'
    'pg878_lorehold_challenger_runtime_completion_20260716';
const _runtimePath =
    '../docs/hermes-analysis/manaloom-knowledge/scripts/'
    'battle_analyst_v9.py';
const _focusedTestPath =
    '../docs/hermes-analysis/manaloom-knowledge/scripts/'
    'test_priority_lorehold_card_runtime.py';
const _packageDocPath =
    '../docs/hermes-analysis/'
    'PG878_LOREHOLD_CHALLENGER_RUNTIME_COMPLETION_2026-07-16.md';

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

Map<String, dynamic> _birgiEffect() =>
    jsonDecode(r'''
{"ability_kind":"triggered_and_activated_modal_dfc","back_face":{"activated_discard_count":1,"activated_discard_exile_top_count":2,"cmc":5,"mana_cost":"{4}{R}","name":"Harnfel, Horn of Bounty","oracle_text":"Discard a card: Exile the top two cards of your library. You may play those cards this turn.","play_exiled_until":"end_of_turn","runtime_status":"runtime_executor_v1","type_line":"Legendary Artifact"},"back_face_harnfel_discard_exile_two_play_this_turn":true,"back_face_runtime_status":"runtime_executor_v1","back_face_status":"runtime_executor_v1","battle_model_scope":"birgi_harnfel_modal_faces_exact_v1","boast_twice_each_turn":true,"boast_twice_status":"annotation_only","cmc":3.0,"effect":"ramp_engine","front_face_mana_cost":"{2}{R}","front_face_name":"Birgi, God of Storytelling","is_creature_permanent":true,"mana_persists_steps":true,"modal_dfc":true,"oracle_runtime_scope":"birgi_front_spell_cast_red_mana_and_harnfel_back_discard_exile_two_play_this_turn_exact_v1","power":3,"produces":"R","spell_cast_add_mana":1,"spell_cast_mana_color":"R","toughness":3,"trigger":"spell_cast"}
''')
        as Map<String, dynamic>;

Map<String, dynamic> _birgiRole() =>
    jsonDecode(r'''
{"category":"ramp","effect":"ramp_engine","functions":["spell_cast_mana_engine","modal_back_face_impulse_play"],"subtype":"spell_cast_mana_and_impulse_play_modal_engine"}
''')
        as Map<String, dynamic>;

Map<String, dynamic> _breachEffect() =>
    jsonDecode(r'''
{"battle_model_scope":"underworld_breach_escape_and_end_step_sacrifice_exact_v1","cmc":2.0,"effect":"passive","end_step_sacrifice_status":"runtime_executor_v1","escape_additional_cost_exile_other_graveyard_cards":3,"escape_can_be_repeated":true,"escape_cost_model":"printed_mana_cost_plus_exile_three_other_cards","escape_grant_status":"runtime_executor_v1","escape_requires_nonland":true,"escape_requires_printed_mana_cost":true,"escape_uses_normal_cast_pipeline":true,"grants_escape_to_nonland_cards_in_graveyard":true,"is_enchantment_permanent":true,"oracle_runtime_scope":"nonland_graveyard_escape_printed_mana_cost_exile_three_other_and_beginning_end_step_sacrifice_exact_v1","sacrifice_at_beginning_of_end_step":true}
''')
        as Map<String, dynamic>;

Map<String, dynamic> _breachRole() =>
    jsonDecode(r'''
{"category":"recursion","effect":"passive","functions":["escape_grant","graveyard_cast_permission","end_step_sacrifice"],"runtime_modes":["passive_enchantment","graveyard_cast_permission","beginning_end_step_trigger"]}
''')
        as Map<String, dynamic>;

Map<String, dynamic> _vaultEffect() =>
    jsonDecode(r'''
{"ability_kind":"static_triggered_and_activated_mana","activation_requires_tap":true,"battle_model_scope":"mana_vault_exact_untap_draw_damage_mana_v1","cmc":1.0,"does_not_untap_in_untap_step":true,"does_not_untap_normally":true,"draw_step_damage_status":"runtime_executor_v1","effect":"ramp_permanent","is_mana_source":true,"mana_ability_requires_tap":true,"mana_ability_status":"runtime_executor_v1","mana_activation_requires_tap":true,"mana_produced":3,"mana_vault_runtime_status":"runtime_executor_v1","oracle_runtime_scope":"no_normal_untap_optional_upkeep_pay_four_draw_step_tapped_damage_one_tap_add_three_colorless_exact_v1","permanent_type":"artifact","produced_mana_symbols":["C","C","C"],"produces":"C","source_mana_cost":"{1}","source_type_line":"Artifact","tapped_draw_step_damage":1,"untap_step_restriction_status":"runtime_executor_v1","upkeep_optional_untap_cost_generic":4,"upkeep_optional_untap_status":"runtime_executor_v1","xmage_ability_classes":["BeginningOfDrawTriggeredAbility","BeginningOfUpkeepTriggeredAbility","SimpleManaAbility","SimpleStaticAbility"],"xmage_condition_classes":["SourceTappedCondition"],"xmage_cost_classes":["GenericManaCost","TapSourceCost"],"xmage_effect_classes":["DamageControllerEffect","DontUntapInControllersUntapStepSourceEffect","UntapSourceEffect"],"xmage_filter_classes":[],"xmage_mana_ability_classes":["SimpleManaAbility"],"xmage_target_classes":[]}
''')
        as Map<String, dynamic>;

Map<String, dynamic> _vaultRole() =>
    jsonDecode(r'''
{"category":"ramp","effect":"ramp_permanent","functions":["fast_mana","optional_upkeep_untap","tapped_draw_step_damage"],"subtype":"fast_mana_with_untap_and_damage_runtime"}
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

void main() {
  group('PG878 Lorehold challenger runtime completion', () {
    test('canonical logical keys match all three exact semantics', () {
      expect(
        _logicalRuleKey(_birgiEffect(), _birgiRole()),
        'battle_rule_v1:e27d00eff7b686d7c8aab1426c621635',
      );
      expect(
        _logicalRuleKey(_breachEffect(), _breachRole()),
        'battle_rule_v1:a38468ecbf8f6ff1512b3b52674a3d0c',
      );
      expect(
        _logicalRuleKey(_vaultEffect(), _vaultRole()),
        'battle_rule_v1:d43496777c4b1e36b1c9a5111133acf4',
      );
    });

    test('precheck and postcheck are read only and exact-state gated', () {
      final precheck = _sql('_precheck.sql');
      final postcheck = _sql('_postcheck.sql');
      _expectReadOnly(precheck);
      _expectReadOnly(postcheck);

      expect(precheck, contains('PG878_PRECHECK_PASS'));
      expect(precheck, contains("v_count <> 11"));
      expect(precheck, contains("v_live <> 5"));
      expect(precheck, contains('6edced874860dcadd35256813d3160a1'));
      expect(precheck, contains('d047e689c2f3bea43ff9a0179114f12b'));
      expect(precheck, contains('3ff2fb6259e01b96bbb8a932931f9c8a'));
      expect(postcheck, contains('PG878_POSTCHECK_PASS'));
      expect(postcheck, contains('v_total <> 14'));
      expect(postcheck, contains('v_exact <> 3'));
      expect(postcheck, contains('exact post snapshot drift'));
    });

    test(
      'apply mutates only battle rules and snapshots full pre/post state',
      () {
        final apply = _sql('_apply.sql');
        expect(apply, startsWith('-- MUTATING.'));
        expect(apply, contains('LOCK TABLE public.cards IN SHARE MODE'));
        expect(
          apply,
          contains(
            'LOCK TABLE public.card_battle_rules IN SHARE ROW EXCLUSIVE MODE',
          ),
        );
        for (final snapshot in [
          'pg878_lorehold_runtime_cards_pre_20260716',
          'pg878_lorehold_runtime_rules_pre_20260716',
          'pg878_lorehold_runtime_proposal_20260716',
          'pg878_lorehold_runtime_rules_post_20260716',
        ]) {
          expect(apply, contains(snapshot));
        }
        expect(apply, contains('expected 5 competing rows updated'));
        expect(apply, contains('expected 3 exact rows inserted'));
        expect(apply, contains('historical disabled rows changed'));
        expect(apply, contains('target cards changed'));
        expect(apply, contains('INSERT INTO public.card_battle_rules'));
        expect(apply, contains('UPDATE public.card_battle_rules'));

        for (final table in [
          'cards',
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
      },
    );

    test(
      'proposal removes partial Breach and Vault semantics without overclaiming boast',
      () {
        final apply = _sql('_apply.sql');
        expect(apply, contains('birgi_harnfel_modal_faces_exact_v1'));
        expect(
          apply,
          contains('underworld_breach_escape_and_end_step_sacrifice_exact_v1'),
        );
        expect(apply, contains('mana_vault_exact_untap_draw_damage_mana_v1'));
        expect(apply, contains('"back_face_status":"runtime_executor_v1"'));
        expect(apply, contains('"escape_grant_status":"runtime_executor_v1"'));
        expect(
          apply,
          contains('"end_step_sacrifice_status":"runtime_executor_v1"'),
        );
        expect(apply, contains('"tapped_draw_step_damage":1'));
        expect(
          apply,
          contains('"ability_kind":"static_triggered_and_activated_mana"'),
        );
        expect(apply, contains('"produced_mana_symbols":["C","C","C"]'));
        expect(apply, contains('"activation_requires_tap":true'));
        expect(apply, contains('"mana_activation_requires_tap":true'));
        expect(
          apply,
          contains('"untap_step_restriction_status":"runtime_executor_v1"'),
        );
        expect(apply, contains('"xmage_target_classes":[]'));
        expect(apply, contains('"xmage_filter_classes":[]'));
        expect(apply, isNot(contains('tapped_upkeep_damage')));
        expect(apply, contains('"boast_twice_status":"annotation_only"'));
      },
    );

    test(
      'rollback is exact-poststate gated and restores the full 11-row prestate',
      () {
        final rollback = _sql('_rollback.sql');
        expect(rollback, startsWith('-- MUTATING ROLLBACK.'));
        expect(rollback, contains('exact poststate drifted'));
        expect(rollback, contains('expected 14 target rows deleted'));
        expect(rollback, contains('expected 11 rows restored'));
        expect(rollback, contains('restored prestate differs'));
        expect(rollback, contains('restored row set differs'));
        expect(rollback, contains('6edced874860dcadd35256813d3160a1'));
        expect(
          rollback,
          contains(
            'INSERT INTO public.card_battle_rules\n  SELECT *\n  FROM '
            'manaloom_deploy_audit.pg878_lorehold_runtime_rules_pre_20260716',
          ),
        );
        expect(rollback, isNot(contains('UPDATE public.cards')));
        expect(rollback, isNot(contains('DELETE FROM public.cards')));
      },
    );

    test('native runtime and focused tests cover every promoted executor', () {
      final runtime = File(_runtimePath).readAsStringSync();
      final focusedTests = File(_focusedTestPath).readAsStringSync();
      final doc = File(_packageDocPath).readAsStringSync();

      for (final token in [
        'def cast_harnfel_back_face_from_hand(',
        'def activate_harnfel_horn_of_bounty(',
        'def cast_harnfel_permission_card_from_exile(',
        'def underworld_breach_escape_source(',
        'def process_underworld_breach_end_step_sacrifices(',
        'def process_mana_vault_upkeep_optional_untap(',
        'def process_mana_vault_draw_step_damage(',
        'def record_mana_source_activation(',
        'mana_vault_mana_activated',
      ]) {
        expect(
          runtime,
          contains(token),
          reason: 'missing runtime token $token',
        );
      }

      for (final testName in [
        'test_harnfel_back_face_casts_for_five_and_resolves_as_artifact',
        'test_harnfel_exiled_counter_uses_real_priority_target',
        'test_harnfel_exiled_instant_uses_empty_end_step_priority_before_expiry',
        'test_underworld_breach_escape_pays_mana_and_exiles_exactly_three_other_cards',
        'test_underworld_breach_escaped_counter_uses_real_stack_target',
        'test_mana_vault_initial_refresh_emits_one_provenanced_activation_event',
        'test_mana_vault_draw_trigger_waits_until_after_draw_and_rechecks_tapped',
      ]) {
        expect(
          focusedTests,
          contains(testName),
          reason: 'missing focused test $testName',
        );
      }

      for (final digest in [
        '9cb100723cd36ca66a89724ead11e57c423e987688cde10479ebfda65d430e37',
        '99de025b840d7fb4f2875e4ba76a7fbfb6a8c0ab34d19f00251ff6b578fe36c1',
        '139e81625a2a030bcf80e613ede72b7bde7693c22c72b9900798aa4ab939e571',
      ]) {
        expect(doc, contains(digest));
      }
      expect(
        doc,
        contains('applied, postchecked, synchronized to Hermes, and contract-audited'),
      );
    });
  });
}
