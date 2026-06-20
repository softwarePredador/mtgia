\echo 'PG-006 rollback - restore pre-apply execution_status rows and reopen migration 029'

BEGIN;

-- Restores row values, removes the PG-006 check constraint, and reopens
-- migration 029. This intentionally does not revert view definitions: current
-- backend source expects execution_status inside
-- card_intelligence_snapshot.battle_rules, and the column remains present.

WITH restored AS (
  UPDATE card_battle_rules AS cbr
  SET execution_status = backup.previous_execution_status
  FROM manaloom_deploy_audit.pg006_card_battle_rules_execution_status_20260620_0808 AS backup
  WHERE cbr.normalized_name = backup.normalized_name
    AND cbr.logical_rule_key = backup.logical_rule_key
  RETURNING 1
)
SELECT 'restored_rows' AS section, COUNT(*) AS rows
FROM restored;

ALTER TABLE card_battle_rules
DROP CONSTRAINT IF EXISTS chk_card_battle_rules_execution_status;

DELETE FROM schema_migrations
WHERE version = '029'
  AND name = 'add_card_battle_rules_execution_status';

COMMIT;
