WITH remaining_missing AS (
  SELECT r.card_id, r.normalized_name, r.logical_rule_key
  FROM card_battle_rules r
  JOIN cards c ON c.id = r.card_id
  WHERE coalesce(r.oracle_hash, '') = ''
    AND coalesce(c.oracle_text, '') <> ''
    AND coalesce(r.execution_status, '') = 'auto'
    AND coalesce(r.review_status, '') IN ('verified', 'active')
),
backed_up AS (
  SELECT *
  FROM manaloom_deploy_audit.pg677b_trusted_oracle_hash_backfill_backup
  WHERE deploy_id = 'pg677b'
),
promoted AS (
  SELECT
    b.card_name,
    b.normalized_name,
    b.logical_rule_key,
    b.new_oracle_hash,
    r.oracle_hash,
    r.review_status,
    r.execution_status,
    r.source,
    r.rule_version
  FROM backed_up b
  JOIN card_battle_rules r
    ON r.card_id = b.card_id
   AND r.normalized_name = b.normalized_name
   AND r.logical_rule_key = b.logical_rule_key
)
SELECT
  (SELECT count(*) FROM backed_up) AS backed_up_rows,
  (SELECT count(*) FROM promoted WHERE oracle_hash = new_oracle_hash) AS rows_with_expected_hash,
  (SELECT count(*) FROM remaining_missing) AS remaining_trusted_executable_missing_oracle_hash;

WITH backed_up AS (
  SELECT *
  FROM manaloom_deploy_audit.pg677b_trusted_oracle_hash_backfill_backup
  WHERE deploy_id = 'pg677b'
),
promoted AS (
  SELECT
    b.card_name,
    b.normalized_name,
    b.logical_rule_key,
    b.new_oracle_hash,
    r.oracle_hash,
    r.review_status,
    r.execution_status,
    r.source,
    r.rule_version
  FROM backed_up b
  JOIN card_battle_rules r
    ON r.card_id = b.card_id
   AND r.normalized_name = b.normalized_name
   AND r.logical_rule_key = b.logical_rule_key
)
SELECT
  card_name,
  normalized_name,
  logical_rule_key,
  new_oracle_hash,
  oracle_hash,
  review_status,
  execution_status,
  source,
  rule_version
FROM promoted
ORDER BY card_name, normalized_name
LIMIT 80;
