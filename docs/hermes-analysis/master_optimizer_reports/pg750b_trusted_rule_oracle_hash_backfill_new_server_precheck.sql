WITH target_rows AS (
  SELECT
    cbr.card_id,
    cbr.normalized_name,
    cbr.card_name,
    cbr.logical_rule_key,
    cbr.oracle_hash AS current_oracle_hash,
    md5(coalesce(c.oracle_text, '')) AS expected_oracle_hash,
    c.oracle_text
  FROM card_battle_rules cbr
  JOIN cards c ON c.id = cbr.card_id
  WHERE cbr.execution_status = 'auto'
    AND cbr.review_status = 'verified'
    AND (cbr.oracle_hash IS NULL OR btrim(cbr.oracle_hash) = '')
)
SELECT
  count(*) AS safe_backfill_rows,
  count(*) FILTER (WHERE card_id IS NULL) AS missing_card_id_rows,
  count(*) FILTER (WHERE btrim(coalesce(oracle_text, '')) = '') AS missing_oracle_text_rows,
  count(DISTINCT normalized_name) AS distinct_normalized_names
FROM target_rows;

WITH target_rows AS (
  SELECT
    cbr.card_id,
    cbr.normalized_name,
    cbr.card_name,
    cbr.logical_rule_key,
    cbr.oracle_hash AS current_oracle_hash,
    md5(coalesce(c.oracle_text, '')) AS expected_oracle_hash,
    c.oracle_text
  FROM card_battle_rules cbr
  JOIN cards c ON c.id = cbr.card_id
  WHERE cbr.execution_status = 'auto'
    AND cbr.review_status = 'verified'
    AND (cbr.oracle_hash IS NULL OR btrim(cbr.oracle_hash) = '')
)
SELECT
  card_name,
  normalized_name,
  logical_rule_key,
  expected_oracle_hash
FROM target_rows
ORDER BY normalized_name, logical_rule_key;
