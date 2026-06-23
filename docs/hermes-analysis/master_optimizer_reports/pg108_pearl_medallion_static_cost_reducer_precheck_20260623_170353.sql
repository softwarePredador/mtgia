WITH target_card AS (
  SELECT id, name, md5(coalesce(oracle_text, '')) AS oracle_hash
  FROM public.cards
  WHERE lower(name) = 'pearl medallion'
),
rule_rows AS (
  SELECT *
  FROM public.card_battle_rules
  WHERE normalized_name = 'pearl medallion'
)
SELECT
  (SELECT count(*) FROM target_card) AS target_card_rows,
  (SELECT count(*) FROM target_card WHERE oracle_hash = '77f7f449ee56143d6b63814fecd37176') AS card_oracle_hash_match_rows,
  (SELECT count(*) FROM rule_rows) AS existing_rule_rows,
  (SELECT count(*) FROM rule_rows WHERE logical_rule_key = 'battle_rule_v1:0d857d5b176cc91065a4754f5824ebf2') AS expected_rule_rows_before,
  (SELECT count(*) FROM rule_rows WHERE review_status IN ('verified', 'active') AND execution_status IN ('auto', 'executable')) AS trusted_rule_rows_before,
  (SELECT count(*) FROM rule_rows WHERE effect_json->>'effect' = 'ramp_permanent' AND review_status NOT IN ('deprecated', 'rejected') AND execution_status <> 'disabled') AS active_ramp_shadow_rows_before,
  (SELECT count(*) FROM rule_rows WHERE logical_rule_key <> 'battle_rule_v1:0d857d5b176cc91065a4754f5824ebf2' AND review_status NOT IN ('deprecated', 'rejected') AND execution_status <> 'disabled') AS would_deprecate_shadow_rows,
  (SELECT count(*) FROM rule_rows WHERE coalesce(oracle_hash, '') = '') AS rows_missing_oracle_hash_before;

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
