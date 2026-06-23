WITH target_card AS (
  SELECT id, name, md5(coalesce(oracle_text, '')) AS oracle_hash
  FROM public.cards
  WHERE lower(name) = 'the scarlet witch'
),
rule_rows AS (
  SELECT *
  FROM public.card_battle_rules
  WHERE normalized_name = 'the scarlet witch'
),
backup_rows AS (
  SELECT count(*) AS count
  FROM manaloom_deploy_audit.pg110_the_scarlet_witch_static_cost_reducer_20260623_150416
)
SELECT
  (SELECT count(*) FROM target_card) AS target_card_rows,
  (SELECT count(*) FROM target_card WHERE oracle_hash = '6129fda2f5ae1f8edad5a2f2e77d05c2') AS card_oracle_hash_match_rows,
  (SELECT count(*) FROM rule_rows WHERE logical_rule_key = 'battle_rule_v1:0b23c5f26d2bc884b7f506cdd9d422fc') AS promoted_rule_rows,
  (SELECT count(*) FROM rule_rows WHERE logical_rule_key = 'battle_rule_v1:0b23c5f26d2bc884b7f506cdd9d422fc' AND review_status = 'verified' AND execution_status = 'auto') AS promoted_verified_auto_rows,
  (SELECT count(*) FROM rule_rows WHERE logical_rule_key = 'battle_rule_v1:0b23c5f26d2bc884b7f506cdd9d422fc' AND oracle_hash = '6129fda2f5ae1f8edad5a2f2e77d05c2') AS promoted_oracle_hash_rows,
  (SELECT count(*) FROM rule_rows WHERE logical_rule_key = 'battle_rule_v1:0b23c5f26d2bc884b7f506cdd9d422fc' AND effect_json->>'effect' = 'static_cost_reduction') AS promoted_expected_effect_rows,
  (SELECT count(*) FROM rule_rows WHERE logical_rule_key = 'battle_rule_v1:0b23c5f26d2bc884b7f506cdd9d422fc' AND effect_json->>'cost_reduction_amount_source' = 'source_power') AS promoted_source_power_rows,
  (SELECT count(*) FROM rule_rows WHERE logical_rule_key = 'battle_rule_v1:0b23c5f26d2bc884b7f506cdd9d422fc' AND (effect_json->>'minimum_mana_value')::integer = 4) AS promoted_minimum_mana_value_rows,
  (SELECT count(*) FROM rule_rows WHERE logical_rule_key <> 'battle_rule_v1:0b23c5f26d2bc884b7f506cdd9d422fc' AND review_status NOT IN ('deprecated', 'rejected') AND execution_status <> 'disabled') AS active_shadow_rows,
  (SELECT count(*) FROM rule_rows WHERE review_status IN ('verified', 'active') AND execution_status IN ('auto', 'executable') AND coalesce(oracle_hash, '') = '') AS trusted_missing_oracle_hash_rows,
  (SELECT count FROM backup_rows) AS backup_rows;

SELECT
  normalized_name,
  card_name,
  logical_rule_key,
  source,
  review_status,
  execution_status,
  confidence,
  rule_version,
  oracle_hash,
  effect_json,
  deck_role_json,
  notes
FROM public.card_battle_rules
WHERE normalized_name = 'the scarlet witch'
ORDER BY logical_rule_key;
