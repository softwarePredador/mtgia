WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('gilanra, caller of wirewood', 'Gilanra, Caller of Wirewood', '2bea3dade1f9f92d10a0dfb71801c5e8', 'battle_rule_v1:fecd3cc5b5678dac55f2dbc16d7d883e', '{"ability_kind":"activated_mana","activation_requires_tap":true,"battle_model_scope":"xmage_simple_tap_mana_source_with_mana_spent_cast_trigger_v1","conditional_mana_modes_status":"runtime_executor_v1","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"mana_spent_cast_trigger":{"effects":[{"count":1,"effect":"draw_cards"}],"mana_value_gte":6,"spell_filter":"mana_value_gte"},"permanent_type":"creature","produced_mana_symbols":["G"],"produces":"G","xmage_ability_classes":["BasicManaAbility","GreenManaAbility","ManaSpentDelayedTriggeredAbility","PartnerAbility"],"xmage_auxiliary_ability_classes":["BasicManaAbility","ManaSpentDelayedTriggeredAbility","PartnerAbility"],"xmage_effect_classes":["CreateDelayedTriggeredAbilityEffect","DrawCardSourceControllerEffect"],"xmage_mana_ability_classes":["GreenManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GilanraCallerOfWirewood translated into ManaLoom runtime scope xmage_simple_tap_mana_source_with_mana_spent_cast_trigger_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('lapis orb of dragonkind', 'Lapis Orb of Dragonkind', '3f0548e0ec530c46558c3517ae0bab50', 'battle_rule_v1:305beef99118ac78d750a3a1e4d4eca0', '{"ability_kind":"activated_mana","activation_requires_tap":true,"battle_model_scope":"xmage_simple_tap_mana_source_with_mana_spent_cast_trigger_v1","conditional_mana_modes_status":"runtime_executor_v1","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"mana_spent_cast_trigger":{"effects":[{"count":2,"effect":"scry"}],"spell_filter":"dragon_creature_spell"},"permanent_type":"artifact","produced_mana_symbols":["U"],"produces":"U","xmage_ability_classes":["BasicManaAbility","BlueManaAbility","ManaSpentDelayedTriggeredAbility"],"xmage_auxiliary_ability_classes":["BasicManaAbility","ManaSpentDelayedTriggeredAbility"],"xmage_effect_classes":["CreateDelayedTriggeredAbilityEffect","ScryEffect"],"xmage_mana_ability_classes":["BlueManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class LapisOrbOfDragonkind translated into ManaLoom runtime scope xmage_simple_tap_mana_source_with_mana_spent_cast_trigger_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('scaled nurturer', 'Scaled Nurturer', 'a91a2e5526969ab5f1997f8f9ae8e03b', 'battle_rule_v1:e6474bc6e59aeffc724328786ec793c7', '{"ability_kind":"activated_mana","activation_requires_tap":true,"battle_model_scope":"xmage_simple_tap_mana_source_with_mana_spent_cast_trigger_v1","conditional_mana_modes_status":"runtime_executor_v1","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"mana_spent_cast_trigger":{"effects":[{"amount":2,"effect":"gain_life"}],"spell_filter":"dragon_creature_spell"},"permanent_type":"creature","produced_mana_symbols":["G"],"produces":"G","xmage_ability_classes":["BasicManaAbility","GreenManaAbility","ManaSpentDelayedTriggeredAbility"],"xmage_auxiliary_ability_classes":["BasicManaAbility","ManaSpentDelayedTriggeredAbility"],"xmage_effect_classes":["CreateDelayedTriggeredAbilityEffect","GainLifeEffect"],"xmage_mana_ability_classes":["GreenManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ScaledNurturer translated into ManaLoom runtime scope xmage_simple_tap_mana_source_with_mana_spent_cast_trigger_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg757_mana_spent_cast_trigger_new_server_20260711_105415) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
