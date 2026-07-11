WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('brass infiniscope', 'Brass Infiniscope', 'dec2186f7cf6f51fd45bdb65220eef81', 'battle_rule_v1:d2482d830daad814b7bd75e8fbc4d0c6', '{"ability_kind":"activated_mana","activation_requires_tap":true,"battle_model_scope":"xmage_simple_tap_mana_source_with_next_cast_x_trigger_v1","effect":"ramp_permanent","is_mana_source":true,"mana_activation_cast_trigger":{"duration":"end_of_turn","effects":[{"count":1,"effect":"draw_cards"},{"amount_source":"half_x_rounded_down","effect":"gain_life"}],"spell_filter":"x_mana_cost_spell","trigger_timing":"next_matching_cast"},"mana_activation_requires_tap":true,"mana_produced":2,"permanent_type":"artifact","produced_mana_symbols":["C","C"],"produces":"C","source_mana_cost":"{4}","source_type_line":"Artifact","xmage_ability_classes":["CastNextSpellDelayedTriggeredAbility","SimpleManaAbility"],"xmage_auxiliary_ability_classes":["CastNextSpellDelayedTriggeredAbility"],"xmage_effect_classes":["BrassInfiniscopeDelayedEffect","BrassInfiniscopeManaEffect","ManaEffect","OneShotEffect"],"xmage_mana_ability_classes":["SimpleManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BrassInfiniscope translated into ManaLoom runtime scope xmage_simple_tap_mana_source_with_next_cast_x_trigger_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg758_next_cast_x_trigger_new_server_nex_20260711_111840) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
