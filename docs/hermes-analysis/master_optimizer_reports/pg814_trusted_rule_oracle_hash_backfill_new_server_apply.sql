BEGIN;

DROP TABLE IF EXISTS card_battle_rules_backup_pg814_hash_new_server;

CREATE TABLE card_battle_rules_backup_pg814_hash_new_server AS
SELECT r.*
FROM card_battle_rules r
JOIN cards c ON c.id = r.card_id
WHERE r.review_status = 'verified'
  AND r.execution_status = 'auto'
  AND COALESCE(BTRIM(r.oracle_hash), '') = ''
  AND NULLIF(BTRIM(c.oracle_text), '') IS NOT NULL;

WITH updated AS (
  UPDATE card_battle_rules r
  SET oracle_hash = md5(c.oracle_text),
      updated_at = NOW()
  FROM cards c
  WHERE c.id = r.card_id
    AND r.review_status = 'verified'
    AND r.execution_status = 'auto'
    AND COALESCE(BTRIM(r.oracle_hash), '') = ''
    AND NULLIF(BTRIM(c.oracle_text), '') IS NOT NULL
  RETURNING r.card_id, r.card_name, r.normalized_name, r.logical_rule_key, r.oracle_hash
)
SELECT
  (SELECT count(*) FROM card_battle_rules_backup_pg814_hash_new_server) AS backup_rows,
  count(*) AS updated_rows
FROM updated;

COMMIT;
