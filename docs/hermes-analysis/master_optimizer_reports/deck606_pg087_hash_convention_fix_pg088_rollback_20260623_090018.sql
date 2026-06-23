\pset pager off

BEGIN;

UPDATE card_battle_rules cbr
SET
  oracle_hash = b.oracle_hash,
  reviewed_by = b.reviewed_by,
  reviewed_at = b.reviewed_at,
  updated_at = now(),
  last_seen_at = b.last_seen_at,
  notes = b.notes
FROM manaloom_deploy_audit.pg088_deck606_pg087_hash_convention_fix_20260623_090018 b
WHERE cbr.normalized_name = b.normalized_name
  AND cbr.logical_rule_key = b.logical_rule_key;

COMMIT;
