BEGIN;

WITH restored AS (
  UPDATE card_battle_rules br
     SET oracle_hash = b.old_oracle_hash,
         notes = b.old_notes,
         updated_at = b.old_updated_at
    FROM manaloom_deploy_audit.pg700_active_oracle_hash_backfill_new_server_20260709 b
   WHERE br.card_id = b.card_id
     AND br.logical_rule_key = b.logical_rule_key
  RETURNING br.card_name, br.normalized_name, br.logical_rule_key
)
SELECT count(*) AS restored_rows FROM restored;

COMMIT;
