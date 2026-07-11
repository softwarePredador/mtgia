WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('jade orb of dragonkind', 'Jade Orb of Dragonkind', '2d345b86529babf2506f565d73423e14', 'battle_rule_v1:51a37d7c66aa9aa722f06dc526f5267d', '{"ability_kind":"activated_mana","activation_requires_tap":true,"battle_model_scope":"xmage_simple_tap_mana_source_with_mana_spent_cast_trigger_v1","conditional_mana_modes_status":"runtime_executor_v1","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"mana_spent_cast_trigger":{"effects":[{"counter_count":1,"counter_type":"+1/+1","duration":"until_next_turn","effect":"enter_with_counter_and_gain_keyword","keyword":"hexproof"}],"spell_filter":"dragon_creature_spell"},"permanent_type":"artifact","produced_mana_symbols":["G"],"produces":"G","xmage_ability_classes":["BasicManaAbility","GreenManaAbility","HexproofAbility","ManaSpentDelayedTriggeredAbility"],"xmage_auxiliary_ability_classes":["BasicManaAbility","HexproofAbility","ManaSpentDelayedTriggeredAbility"],"xmage_effect_classes":["CreateDelayedTriggeredAbilityEffect","GainAbilityTargetEffect","JadeOrbAdditionalCounterEffect","JadeOrbGainHexproofEffect"],"xmage_mana_ability_classes":["GreenManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class JadeOrbOfDragonkind translated into ManaLoom runtime scope xmage_simple_tap_mana_source_with_mana_spent_cast_trigger_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg764_jade_orb_new_server_jade_orb_mana_20260711_132543) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
