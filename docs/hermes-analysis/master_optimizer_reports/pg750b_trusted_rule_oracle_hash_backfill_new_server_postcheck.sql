SELECT
  count(*) AS remaining_trusted_auto_missing_hash_rows
FROM card_battle_rules cbr
JOIN cards c ON c.id = cbr.card_id
WHERE cbr.execution_status = 'auto'
  AND cbr.review_status = 'verified'
  AND (cbr.oracle_hash IS NULL OR btrim(cbr.oracle_hash) = '')
  AND btrim(coalesce(c.oracle_text, '')) <> '';

SELECT
  count(*) AS backed_up_rows,
  count(*) FILTER (
    WHERE cbr.oracle_hash = backup.expected_oracle_hash
  ) AS matching_hash_rows
FROM manaloom_deploy_audit.pg750b_trusted_rule_oracle_hash_backfill_new_server_20260711 backup
JOIN card_battle_rules cbr
  ON cbr.card_id = backup.card_id
 AND cbr.logical_rule_key = backup.logical_rule_key
 AND cbr.normalized_name = backup.normalized_name;
