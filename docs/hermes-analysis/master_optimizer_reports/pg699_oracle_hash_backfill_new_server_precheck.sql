WITH target_rows AS (
  SELECT
    br.card_name,
    br.normalized_name,
    br.card_id,
    br.logical_rule_key,
    br.oracle_hash AS current_oracle_hash,
    md5(coalesce(c.oracle_text, '')) AS computed_oracle_hash,
    br.effect_json->>'battle_model_scope' AS battle_model_scope
  FROM card_battle_rules br
  JOIN cards c ON c.id = br.card_id
  WHERE br.review_status = 'verified'
    AND br.execution_status = 'auto'
    AND nullif(br.oracle_hash, '') IS NULL
    AND c.oracle_text IS NOT NULL
)
SELECT
  count(*) AS rows_to_backfill,
  count(DISTINCT card_id) AS distinct_cards,
  count(*) FILTER (WHERE computed_oracle_hash IS NOT NULL AND computed_oracle_hash <> '') AS rows_with_computed_hash
FROM target_rows;

WITH target_rows AS (
  SELECT
    br.card_name,
    br.normalized_name,
    br.card_id,
    br.logical_rule_key,
    br.oracle_hash AS current_oracle_hash,
    md5(coalesce(c.oracle_text, '')) AS computed_oracle_hash,
    br.effect_json->>'battle_model_scope' AS battle_model_scope
  FROM card_battle_rules br
  JOIN cards c ON c.id = br.card_id
  WHERE br.review_status = 'verified'
    AND br.execution_status = 'auto'
    AND nullif(br.oracle_hash, '') IS NULL
    AND c.oracle_text IS NOT NULL
)
SELECT
  card_name,
  normalized_name,
  logical_rule_key,
  battle_model_scope,
  computed_oracle_hash
FROM target_rows
ORDER BY card_name, logical_rule_key;
