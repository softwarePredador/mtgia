WITH backup AS (
  SELECT * FROM manaloom_deploy_audit.pg700_active_oracle_hash_backfill_new_server_20260709
),
joined AS (
  SELECT
    br.card_name,
    br.normalized_name,
    br.logical_rule_key,
    br.oracle_hash,
    b.new_oracle_hash
  FROM backup b
  JOIN card_battle_rules br
    ON br.card_id = b.card_id
   AND br.logical_rule_key = b.logical_rule_key
)
SELECT
  count(*) AS checked_rows,
  count(*) FILTER (WHERE oracle_hash = new_oracle_hash) AS rows_with_expected_hash,
  count(*) FILTER (WHERE nullif(oracle_hash, '') IS NULL) AS rows_still_missing_hash
FROM joined;

SELECT
  count(*) AS remaining_trusted_auto_missing_oracle_hash_rows
FROM card_battle_rules
WHERE review_status IN ('verified', 'active')
  AND execution_status = 'auto'
  AND nullif(oracle_hash, '') IS NULL;
