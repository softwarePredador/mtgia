WITH backup_rows AS (
  SELECT
    b.card_id,
    b.normalized_name,
    b.logical_rule_key,
    b.source
  FROM card_battle_rules_backup_pg814_hash_new_server b
), checked AS (
  SELECT
    c.name AS card_name,
    r.normalized_name,
    r.logical_rule_key,
    r.oracle_hash,
    md5(c.oracle_text) AS expected_oracle_hash
  FROM backup_rows b
  JOIN card_battle_rules r
    ON r.card_id = b.card_id
   AND COALESCE(r.normalized_name, '') = COALESCE(b.normalized_name, '')
   AND COALESCE(r.logical_rule_key, '') = COALESCE(b.logical_rule_key, '')
   AND COALESCE(r.source, '') = COALESCE(b.source, '')
  JOIN cards c ON c.id = r.card_id
)
SELECT
  count(*) AS checked_rows,
  count(*) FILTER (WHERE oracle_hash = expected_oracle_hash) AS matching_hash_rows,
  count(*) FILTER (WHERE COALESCE(BTRIM(oracle_hash), '') = '') AS still_missing_hash_rows
FROM checked;

SELECT
  count(*) AS remaining_verified_auto_missing_oracle_hash
FROM card_battle_rules r
JOIN cards c ON c.id = r.card_id
WHERE r.review_status = 'verified'
  AND r.execution_status = 'auto'
  AND COALESCE(BTRIM(r.oracle_hash), '') = ''
  AND NULLIF(BTRIM(c.oracle_text), '') IS NOT NULL;
