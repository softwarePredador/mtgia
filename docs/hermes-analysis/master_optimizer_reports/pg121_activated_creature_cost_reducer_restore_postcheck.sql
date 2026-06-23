WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes) AS (
  VALUES
    ('training grounds', 'Training Grounds', 'abdaacd48d9c93d70dd49ee28fcc8ffc', 'battle_rule_v1:c85c546552beeb0bd02a75cede7d3773', '{"ability_kind":"static","applies_to_controller":"source_controller","battle_model_scope":"static_activated_ability_cost_reduction_variant_v1","cost_reduction_applies_to":"activated_abilities_of_creatures_you_control","cost_reduction_generic":2,"cost_reduction_minimum_total_mana":1,"effect":"static_cost_reduction"}'::jsonb, '{"category":"support","effect":"static_cost_reduction","subtype":"cost_reducer","timing":"static"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class TrainingGrounds mapped to family static_cost_reducer; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('biomancer''s familiar', 'Biomancer''s Familiar', 'd46c913f1a4b75d8c3310602ed48ba5c', 'battle_rule_v1:c85c546552beeb0bd02a75cede7d3773', '{"ability_kind":"static","applies_to_controller":"source_controller","battle_model_scope":"static_activated_ability_cost_reduction_variant_v1","cost_reduction_applies_to":"activated_abilities_of_creatures_you_control","cost_reduction_generic":2,"cost_reduction_minimum_total_mana":1,"effect":"static_cost_reduction"}'::jsonb, '{"category":"support","effect":"static_cost_reduction","subtype":"cost_reducer","timing":"static"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class BiomancersFamiliar mapped to family static_cost_reducer; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
    ON r.normalized_name = p.normalized_name
   AND r.logical_rule_key = p.logical_rule_key
)
SELECT
  p.card_name,
  p.normalized_name,
  p.logical_rule_key,
  count(r.*) FILTER (WHERE r.logical_rule_key = p.logical_rule_key) AS promoted_rule_rows,
  count(r.*) FILTER (WHERE r.review_status = 'verified' AND r.execution_status = 'auto') AS promoted_verified_auto_rows,
  count(r.*) FILTER (WHERE r.oracle_hash = p.oracle_hash) AS promoted_oracle_hash_rows,
  (SELECT count(*) FROM manaloom_deploy_audit.pg121_activated_creature_cost_reducer_restore_20260623_2) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
