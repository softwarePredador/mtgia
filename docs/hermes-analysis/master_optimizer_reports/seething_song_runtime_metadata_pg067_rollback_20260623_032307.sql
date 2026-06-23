BEGIN;

UPDATE card_battle_rules cbr
SET
  card_id = NULLIF(backup.payload->>'card_id', '')::uuid,
  card_name = backup.payload->>'card_name',
  effect_json = COALESCE(backup.payload->'effect_json', '{}'::jsonb),
  deck_role_json = COALESCE(backup.payload->'deck_role_json', '{}'::jsonb),
  source = backup.payload->>'source',
  confidence = NULLIF(backup.payload->>'confidence', '')::numeric,
  review_status = backup.payload->>'review_status',
  execution_status = backup.payload->>'execution_status',
  rule_version = NULLIF(backup.payload->>'rule_version', '')::integer,
  oracle_hash = backup.payload->>'oracle_hash',
  notes = backup.payload->>'notes',
  reviewed_by = backup.payload->>'reviewed_by',
  reviewed_at = NULLIF(backup.payload->>'reviewed_at', '')::timestamptz,
  updated_at = COALESCE(NULLIF(backup.payload->>'updated_at', '')::timestamptz, now()),
  last_seen_at = NULLIF(backup.payload->>'last_seen_at', '')::timestamptz
FROM manaloom_deploy_audit.pg067_seething_song_runtime_metadata_20260623_032307 backup
WHERE cbr.normalized_name = backup.payload->>'normalized_name'
  AND cbr.logical_rule_key = backup.payload->>'logical_rule_key';

COMMIT;
