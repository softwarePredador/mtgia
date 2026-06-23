BEGIN;

CREATE TEMP TABLE pg090_rule_hash_scope_restore_target AS
SELECT normalized_name, logical_rule_key
FROM manaloom_deploy_audit.pg090_rule_hash_scope_restore_20260623_062000;

DELETE FROM card_battle_rules r
USING pg090_rule_hash_scope_restore_target t
WHERE r.normalized_name = t.normalized_name
  AND r.logical_rule_key = t.logical_rule_key;

INSERT INTO card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg090_rule_hash_scope_restore_20260623_062000;

COMMIT;
