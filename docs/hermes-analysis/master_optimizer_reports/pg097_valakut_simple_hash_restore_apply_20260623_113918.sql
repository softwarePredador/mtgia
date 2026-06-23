BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE manaloom_deploy_audit.pg097_valakut_simple_hash_restore_20260623_113918 AS
SELECT
  r.*,
  md5(COALESCE(c.oracle_text, '')) AS card_oracle_hash,
  CURRENT_TIMESTAMP AS backed_up_at
FROM card_battle_rules r
JOIN cards c ON c.id = r.card_id
WHERE r.normalized_name = 'valakut awakening'
  AND r.logical_rule_key = 'battle_rule_v1:245b8d2627720fadfd7a30464d07605a';

WITH updated AS (
  UPDATE card_battle_rules r
  SET
    oracle_hash = '22b42fcc181b7aed71f78b2e1e51e887',
    review_status = 'active',
    execution_status = 'auto',
    updated_at = CURRENT_TIMESTAMP,
    last_seen_at = CURRENT_TIMESTAMP
  FROM cards c
  WHERE c.id = r.card_id
    AND r.normalized_name = 'valakut awakening'
    AND r.logical_rule_key = 'battle_rule_v1:245b8d2627720fadfd7a30464d07605a'
    AND md5(COALESCE(c.oracle_text, '')) = '22b42fcc181b7aed71f78b2e1e51e887'
  RETURNING r.normalized_name, r.logical_rule_key, r.oracle_hash, r.review_status, r.execution_status
)
SELECT count(*) AS updated_rows
FROM updated;

COMMIT;
