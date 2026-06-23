BEGIN;

INSERT INTO card_battle_rules (
  normalized_name,
  logical_rule_key,
  card_id,
  card_name,
  effect_json,
  deck_role_json,
  source,
  confidence,
  review_status,
  execution_status,
  rule_version,
  oracle_hash,
  notes,
  reviewed_by,
  reviewed_at,
  created_at,
  updated_at,
  last_seen_at
)
SELECT
  backup.payload->>'normalized_name',
  backup.payload->>'logical_rule_key',
  NULLIF(backup.payload->>'card_id', '')::uuid,
  backup.payload->>'card_name',
  COALESCE(backup.payload->'effect_json', '{}'::jsonb),
  COALESCE(backup.payload->'deck_role_json', '{}'::jsonb),
  backup.payload->>'source',
  NULLIF(backup.payload->>'confidence', '')::numeric,
  backup.payload->>'review_status',
  backup.payload->>'execution_status',
  NULLIF(backup.payload->>'rule_version', '')::integer,
  backup.payload->>'oracle_hash',
  backup.payload->>'notes',
  backup.payload->>'reviewed_by',
  NULLIF(backup.payload->>'reviewed_at', '')::timestamptz,
  COALESCE(NULLIF(backup.payload->>'created_at', '')::timestamptz, now()),
  COALESCE(NULLIF(backup.payload->>'updated_at', '')::timestamptz, now()),
  NULLIF(backup.payload->>'last_seen_at', '')::timestamptz
FROM manaloom_deploy_audit.pg078_deck606_l2_hash_scope_restore_20260623_063535 backup
ON CONFLICT (normalized_name, logical_rule_key) DO UPDATE
SET
  card_id = excluded.card_id,
  card_name = excluded.card_name,
  effect_json = excluded.effect_json,
  deck_role_json = excluded.deck_role_json,
  source = excluded.source,
  confidence = excluded.confidence,
  review_status = excluded.review_status,
  execution_status = excluded.execution_status,
  rule_version = excluded.rule_version,
  oracle_hash = excluded.oracle_hash,
  notes = excluded.notes,
  reviewed_by = excluded.reviewed_by,
  reviewed_at = excluded.reviewed_at,
  updated_at = excluded.updated_at,
  last_seen_at = excluded.last_seen_at;

COMMIT;
