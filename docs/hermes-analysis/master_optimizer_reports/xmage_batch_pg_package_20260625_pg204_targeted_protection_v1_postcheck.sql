WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes) AS (
  VALUES
    ('gods willing', 'Gods Willing', '745771d02a8a4d49bf5823457be81f09', 'battle_rule_v1:55c7847be59181f29da7aa82c5667a30', '{"ability_kind":"one_shot","battle_model_scope":"target_creature_you_control_protection_from_chosen_color_until_eot_v1","effect":"grant_protection_from_chosen_color","instant":true,"protection_color_choice":"contextual_best_source_color","protection_from_chosen_color_until_eot":true,"target":"creature_you_control","target_controller":"own"}'::jsonb, '{"category":"protection","effect":"grant_protection","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class GodsWilling mapped to family targeted_protection; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('sejiri shelter // sejiri glacier', 'Sejiri Shelter // Sejiri Glacier', 'e43013ce9cf0dbab47befb40e3c5c1ba', 'battle_rule_v1:55c7847be59181f29da7aa82c5667a30', '{"ability_kind":"one_shot","battle_model_scope":"target_creature_you_control_protection_from_chosen_color_until_eot_v1","effect":"grant_protection_from_chosen_color","instant":true,"protection_color_choice":"contextual_best_source_color","protection_from_chosen_color_until_eot":true,"target":"creature_you_control","target_controller":"own"}'::jsonb, '{"category":"protection","effect":"grant_protection","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class SejiriShelter mapped to family targeted_protection; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg204_targeted_protection_20260625_051947) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
