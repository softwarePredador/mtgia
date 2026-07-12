WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('the golden throne', 'The Golden Throne', '33a6eac65a90700967487d2482bae1e6', 'battle_rule_v1:109245c854877317216eb2c3c5c0e324', '{"ability_kind":"activated_mana","activation_requires_sacrifice_target":true,"activation_requires_tap":true,"activation_sacrifice_target":"creature","battle_model_scope":"xmage_target_sacrifice_mana_source_permanent_v1","effect":"ramp_permanent","is_mana_source":true,"loss_replacement_destination":"exile","loss_replacement_event":"lose_game","loss_replacement_life_total":1,"mana_activation_requires_sacrifice_target":true,"mana_activation_requires_tap":true,"mana_produced":3,"mana_source_contextual_only":true,"permanent_type":"artifact","produces":"WUBRG","replace_losing_game_exile_self_life_total_1":true,"xmage_ability_classes":["SimpleManaAbility","SimpleStaticAbility"],"xmage_auxiliary_ability_classes":[],"xmage_cost_class":"SacrificeTargetCost","xmage_effect_classes":["AddManaInAnyCombinationEffect","TheGoldenThroneEffect"],"xmage_mana_ability_classes":["SimpleManaAbility"],"xmage_unmodeled_effect_classes":[]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TheGoldenThrone translated into ManaLoom runtime scope xmage_target_sacrifice_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg847_golden_throne_new_server_20260712_215759) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
