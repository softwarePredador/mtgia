\pset pager off
\set ON_ERROR_STOP on

BEGIN;

DO $$
DECLARE
  v_backup_rows integer;
BEGIN
  SELECT COUNT(*)
  INTO v_backup_rows
  FROM manaloom_deploy_audit.pg021_global_attack_rule_scope_20260621_043814;

  IF v_backup_rows <> 3 THEN
    RAISE EXCEPTION 'PG021 rollback requires exactly 3 backup rows, found %', v_backup_rows;
  END IF;
END $$;

UPDATE card_battle_rules cbr
SET
  card_id = (backup.payload->>'card_id')::uuid,
  card_name = backup.payload->>'card_name',
  effect_json = backup.payload->'effect_json',
  deck_role_json = backup.payload->'deck_role_json',
  source = backup.payload->>'source',
  confidence = (backup.payload->>'confidence')::double precision,
  review_status = backup.payload->>'review_status',
  execution_status = backup.payload->>'execution_status',
  rule_version = (backup.payload->>'rule_version')::integer,
  oracle_hash = backup.payload->>'oracle_hash',
  notes = backup.payload->>'notes',
  reviewed_by = backup.payload->>'reviewed_by',
  reviewed_at = NULLIF(backup.payload->>'reviewed_at', '')::timestamptz,
  updated_at = now(),
  last_seen_at = NULLIF(backup.payload->>'last_seen_at', '')::timestamptz
FROM manaloom_deploy_audit.pg021_global_attack_rule_scope_20260621_043814 backup
WHERE cbr.normalized_name = backup.normalized_name
  AND cbr.logical_rule_key = backup.logical_rule_key;

COMMIT;

SELECT
  'pg021_global_attack_rule_scope_rollback' AS check_name,
  normalized_name,
  logical_rule_key,
  effect_json,
  notes
FROM card_battle_rules
WHERE (normalized_name, logical_rule_key) IN (
  ('silent arbiter', 'battle_rule_v1:6f6089b73fb8f7f9aee20cacb64fffc7'),
  ('magus of the moat', 'battle_rule_v1:439de5be33887bbce5dde1cfb367774a'),
  ('ensnaring bridge', 'battle_rule_v1:1ea5840419f4343c05a661e79d6829d5')
)
ORDER BY normalized_name;
