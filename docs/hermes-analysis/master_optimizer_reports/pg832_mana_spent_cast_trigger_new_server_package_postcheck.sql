WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('animal attendant', 'Animal Attendant', '5ea6d292274988b43bf0bdfaec74dafa', 'battle_rule_v1:4809d748a08c9e5538cd61561e618545', '{"ability_kind":"activated_mana","activation_requires_tap":true,"battle_model_scope":"xmage_simple_tap_mana_source_with_mana_spent_cast_trigger_v1","conditional_mana_modes_status":"runtime_executor_v1","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"mana_spent_cast_trigger":{"effects":[{"counter_count":1,"counter_type":"+1/+1","effect":"enter_with_counter_and_gain_keyword"}],"spell_filter":"non_human_creature_spell"},"permanent_type":"creature","produces":"WUBRG","xmage_ability_classes":["AnyColorManaAbility"],"xmage_auxiliary_ability_classes":[],"xmage_effect_classes":["AddCounterEnteringCreatureEffect"],"xmage_mana_ability_classes":["AnyColorManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AnimalAttendant translated into ManaLoom runtime scope xmage_simple_tap_mana_source_with_mana_spent_cast_trigger_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('biophagus', 'Biophagus', '9b9202a6230df7731797234b9c491f69', 'battle_rule_v1:7de7daa7c43218a20cefab7989ffceb6', '{"ability_kind":"activated_mana","activation_requires_tap":true,"battle_model_scope":"xmage_simple_tap_mana_source_with_mana_spent_cast_trigger_v1","conditional_mana_modes_status":"runtime_executor_v1","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"mana_spent_cast_trigger":{"effects":[{"counter_count":1,"counter_type":"+1/+1","effect":"enter_with_counter_and_gain_keyword"}],"spell_filter":"creature_spell"},"permanent_type":"creature","produces":"WUBRG","xmage_ability_classes":["AnyColorManaAbility"],"xmage_auxiliary_ability_classes":[],"xmage_effect_classes":["AddCounterEnteringCreatureEffect"],"xmage_mana_ability_classes":["AnyColorManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Biophagus translated into ManaLoom runtime scope xmage_simple_tap_mana_source_with_mana_spent_cast_trigger_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('carnelian orb of dragonkind', 'Carnelian Orb of Dragonkind', '953552350488f1086f2784d8e61f93b3', 'battle_rule_v1:fedd234c13a6dc99dd2871de3a66046c', '{"ability_kind":"activated_mana","activation_requires_tap":true,"battle_model_scope":"xmage_simple_tap_mana_source_with_mana_spent_cast_trigger_v1","conditional_mana_modes_status":"runtime_executor_v1","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"mana_spent_cast_trigger":{"effects":[{"counter_count":0,"counter_type":"+1/+1","duration":"until_end_of_turn","effect":"enter_with_counter_and_gain_keyword","keyword":"haste"}],"spell_filter":"dragon_creature_spell"},"permanent_type":"artifact","produced_mana_symbols":["R"],"produces":"R","xmage_ability_classes":["HasteAbility","SimpleManaAbility"],"xmage_auxiliary_ability_classes":["HasteAbility"],"xmage_effect_classes":["BasicManaEffect","GainAbilityTargetEffect","ManaSpentOnSpellGainsAbilityEffect"],"xmage_mana_ability_classes":["SimpleManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CarnelianOrbOfDragonkind translated into ManaLoom runtime scope xmage_simple_tap_mana_source_with_mana_spent_cast_trigger_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows')
),
rule_rows AS (
  SELECT
    r.normalized_name,
    r.logical_rule_key,
    r.oracle_hash,
    r.review_status,
    r.execution_status
  FROM proposed p
  LEFT JOIN public.card_battle_rules r
    ON (
         r.normalized_name = p.normalized_name
         OR r.normalized_name LIKE p.normalized_name || ' // %'
       )
   AND r.logical_rule_key = p.logical_rule_key
)
SELECT
  p.card_name,
  p.normalized_name,
  p.logical_rule_key,
  count(r.*) FILTER (WHERE r.logical_rule_key = p.logical_rule_key) AS promoted_rule_rows,
  count(r.*) FILTER (WHERE r.review_status = 'verified' AND r.execution_status = 'auto') AS promoted_verified_auto_rows,
  count(r.*) FILTER (WHERE r.oracle_hash = p.oracle_hash) AS promoted_oracle_hash_rows,
  (SELECT count(*) FROM manaloom_deploy_audit.pg832_mana_spent_cast_trigger_new_server_20260712_130709) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
