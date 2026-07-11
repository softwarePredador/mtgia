BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

DROP TABLE IF EXISTS manaloom_deploy_audit.pg732b_trusted_rule_oracle_hash_backfill_new_server_20260711;

CREATE TABLE manaloom_deploy_audit.pg732b_trusted_rule_oracle_hash_backfill_new_server_20260711 AS
SELECT
  br.normalized_name,
  br.card_name,
  br.logical_rule_key,
  br.oracle_hash AS old_oracle_hash,
  br.notes AS old_notes,
  br.updated_at AS old_updated_at,
  md5(c.oracle_text) AS new_oracle_hash,
  NOW() AS backed_up_at
FROM card_battle_rules br
JOIN cards c ON c.id = br.card_id
WHERE br.execution_status = 'auto'
  AND br.review_status IN ('verified', 'active')
  AND COALESCE(br.oracle_hash, '') = ''
  AND COALESCE(BTRIM(c.oracle_text), '') <> '';

WITH target AS (
  SELECT
    br.normalized_name,
    br.logical_rule_key,
    md5(c.oracle_text) AS new_oracle_hash
  FROM card_battle_rules br
  JOIN cards c ON c.id = br.card_id
  WHERE br.execution_status = 'auto'
    AND br.review_status IN ('verified', 'active')
    AND COALESCE(br.oracle_hash, '') = ''
    AND COALESCE(BTRIM(c.oracle_text), '') <> ''
),
updated AS (
  UPDATE card_battle_rules br
  SET
    oracle_hash = target.new_oracle_hash,
    updated_at = NOW(),
    notes = CONCAT_WS(' | ', NULLIF(br.notes, ''), 'pg732b trusted_rule_oracle_hash_backfill_new_server')
  FROM target
  WHERE br.normalized_name = target.normalized_name
    AND br.logical_rule_key = target.logical_rule_key
  RETURNING br.normalized_name, br.logical_rule_key
)
SELECT COUNT(*) AS oracle_hash_rows_backfilled
FROM updated;

COMMIT;
