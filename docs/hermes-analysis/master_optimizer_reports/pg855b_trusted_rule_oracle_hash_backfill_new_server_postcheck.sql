\echo 'PG855B trusted rule oracle_hash backfill postcheck'

SELECT
  COUNT(*) AS rows_still_missing_oracle_hash,
  COUNT(DISTINCT br.card_id) AS cards_still_missing_oracle_hash
FROM card_battle_rules br
JOIN cards c ON c.id = br.card_id
WHERE br.source = 'curated'
  AND br.review_status = 'verified'
  AND br.execution_status = 'auto'
  AND COALESCE(BTRIM(br.oracle_hash), '') = ''
  AND COALESCE(BTRIM(c.oracle_text), '') <> '';

SELECT
  COUNT(*) AS backup_rows
FROM manaloom_deploy_audit.pg855b_trusted_rule_oracle_hash_backfill_new_server_20260713;
