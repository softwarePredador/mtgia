BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE manaloom_deploy_audit.pg750b_trusted_rule_oracle_hash_backfill_new_server_20260711 AS
SELECT
  cbr.*,
  md5(coalesce(c.oracle_text, '')) AS expected_oracle_hash,
  now() AS backed_up_at
FROM card_battle_rules cbr
JOIN cards c ON c.id = cbr.card_id
WHERE cbr.execution_status = 'auto'
  AND cbr.review_status = 'verified'
  AND (cbr.oracle_hash IS NULL OR btrim(cbr.oracle_hash) = '')
  AND btrim(coalesce(c.oracle_text, '')) <> '';

WITH updated AS (
  UPDATE card_battle_rules cbr
  SET
    oracle_hash = md5(coalesce(c.oracle_text, '')),
    updated_at = now()
  FROM cards c
  WHERE c.id = cbr.card_id
    AND cbr.execution_status = 'auto'
    AND cbr.review_status = 'verified'
    AND (cbr.oracle_hash IS NULL OR btrim(cbr.oracle_hash) = '')
    AND btrim(coalesce(c.oracle_text, '')) <> ''
  RETURNING cbr.card_id, cbr.normalized_name, cbr.logical_rule_key
)
SELECT count(*) AS oracle_hash_rows_backfilled
FROM updated;

COMMIT;
