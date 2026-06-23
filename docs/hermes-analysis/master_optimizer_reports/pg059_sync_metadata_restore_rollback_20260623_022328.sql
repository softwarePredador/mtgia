-- PG059 sync metadata restore rollback.
-- Restores target rows captured before PG059.

BEGIN;

WITH backup_keys AS (
  SELECT normalized_name, logical_rule_key
  FROM manaloom_deploy_audit.pg059_sync_metadata_restore_20260623_022328
)
DELETE FROM card_battle_rules cbr
USING backup_keys bk
WHERE cbr.normalized_name = bk.normalized_name
  AND cbr.logical_rule_key = bk.logical_rule_key;

INSERT INTO card_battle_rules (
  normalized_name,
  card_id,
  card_name,
  effect_json,
  deck_role_json,
  source,
  confidence,
  review_status,
  rule_version,
  oracle_hash,
  notes,
  reviewed_by,
  reviewed_at,
  created_at,
  updated_at,
  last_seen_at,
  logical_rule_key,
  execution_status
)
SELECT
  normalized_name,
  card_id,
  card_name,
  effect_json,
  deck_role_json,
  source,
  confidence,
  review_status,
  rule_version,
  oracle_hash,
  notes,
  reviewed_by,
  reviewed_at,
  created_at,
  updated_at,
  last_seen_at,
  logical_rule_key,
  execution_status
FROM manaloom_deploy_audit.pg059_sync_metadata_restore_20260623_022328;

COMMIT;
