WITH target_card AS (
  SELECT id, name, md5(coalesce(oracle_text, '')) AS oracle_hash
  FROM public.cards
  WHERE lower(name) = 'pearl medallion'
),
rule_rows AS (
  SELECT *
  FROM public.card_battle_rules
  WHERE normalized_name = 'pearl medallion'
),
backup_rows AS (
  SELECT count(*) AS count
  FROM manaloom_deploy_audit.pg108_pearl_medallion_static_cost_reducer_20260623_170353
)
SELECT
  (SELECT count(*) FROM target_card) AS target_card_rows,
  (SELECT count(*) FROM target_card WHERE oracle_hash = '77f7f449ee56143d6b63814fecd37176') AS card_oracle_hash_match_rows,
  (SELECT count(*) FROM rule_rows WHERE logical_rule_key = 'battle_rule_v1:0d857d5b176cc91065a4754f5824ebf2') AS promoted_rule_rows,
  (SELECT count(*) FROM rule_rows WHERE logical_rule_key = 'battle_rule_v1:0d857d5b176cc91065a4754f5824ebf2' AND review_status = 'verified' AND execution_status = 'auto') AS promoted_verified_auto_rows,
  (SELECT count(*) FROM rule_rows WHERE logical_rule_key = 'battle_rule_v1:0d857d5b176cc91065a4754f5824ebf2' AND oracle_hash = '77f7f449ee56143d6b63814fecd37176') AS promoted_oracle_hash_rows,
  (SELECT count(*) FROM rule_rows WHERE logical_rule_key = 'battle_rule_v1:0d857d5b176cc91065a4754f5824ebf2' AND effect_json->>'effect' = 'static_cost_reduction') AS promoted_expected_effect_rows,
  (SELECT count(*) FROM rule_rows WHERE logical_rule_key = 'battle_rule_v1:0d857d5b176cc91065a4754f5824ebf2' AND deck_role_json->>'category' = 'support') AS promoted_support_category_rows,
  (SELECT count(*) FROM rule_rows WHERE logical_rule_key <> 'battle_rule_v1:0d857d5b176cc91065a4754f5824ebf2' AND review_status NOT IN ('deprecated', 'rejected') AND execution_status <> 'disabled') AS active_shadow_rows,
  (SELECT count(*) FROM rule_rows WHERE logical_rule_key <> 'battle_rule_v1:0d857d5b176cc91065a4754f5824ebf2' AND review_status IN ('verified', 'active') AND execution_status IN ('auto', 'executable') AND effect_json->>'effect' = 'ramp_permanent') AS active_rows_still_claiming_ramp_permanent,
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
WHERE normalized_name = 'pearl medallion'
ORDER BY logical_rule_key;
