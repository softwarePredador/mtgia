WITH target_card AS (
  SELECT id, name, md5(coalesce(oracle_text, '')) AS oracle_hash
  FROM public.cards
  WHERE lower(name) = 'the scarlet witch'
),
rule_rows AS (
  SELECT *
  FROM public.card_battle_rules
  WHERE normalized_name = 'the scarlet witch'
)
SELECT
  (SELECT count(*) FROM target_card) AS target_card_rows,
  (SELECT count(*) FROM target_card WHERE oracle_hash = '6129fda2f5ae1f8edad5a2f2e77d05c2') AS card_oracle_hash_match_rows,
  (SELECT count(*) FROM rule_rows) AS existing_rule_rows,
  (SELECT count(*) FROM rule_rows WHERE logical_rule_key = 'battle_rule_v1:0b23c5f26d2bc884b7f506cdd9d422fc') AS expected_rule_rows_before,
  (SELECT count(*) FROM rule_rows WHERE review_status IN ('verified', 'active') AND execution_status IN ('auto', 'executable')) AS trusted_rule_rows_before,
  (SELECT count(*) FROM rule_rows WHERE effect_json->>'effect' = 'static_cost_reduction' AND review_status NOT IN ('deprecated', 'rejected') AND execution_status <> 'disabled') AS active_static_cost_reduction_rows_before,
  (SELECT count(*) FROM rule_rows WHERE logical_rule_key <> 'battle_rule_v1:0b23c5f26d2bc884b7f506cdd9d422fc' AND review_status NOT IN ('deprecated', 'rejected') AND execution_status <> 'disabled') AS would_deprecate_shadow_rows,
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
WHERE normalized_name = 'the scarlet witch'
ORDER BY logical_rule_key;
