BEGIN;

WITH backup AS (
  SELECT payload
  FROM manaloom_deploy_audit.pg079_deck606_high_battle_critical_20260623_074912
)
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
  payload->>'normalized_name',
  NULLIF(payload->>'card_id', '')::uuid,
  payload->>'card_name',
  (payload->'effect_json')::jsonb,
  (payload->'deck_role_json')::jsonb,
  payload->>'source',
  (payload->>'confidence')::numeric,
  payload->>'review_status',
  (payload->>'rule_version')::integer,
  payload->>'oracle_hash',
  payload->>'notes',
  payload->>'reviewed_by',
  NULLIF(payload->>'reviewed_at', '')::timestamptz,
  NULLIF(payload->>'created_at', '')::timestamptz,
  NULLIF(payload->>'updated_at', '')::timestamptz,
  NULLIF(payload->>'last_seen_at', '')::timestamptz,
  payload->>'logical_rule_key',
  payload->>'execution_status'
FROM backup
ON CONFLICT (normalized_name, logical_rule_key) DO UPDATE
SET
  card_id = excluded.card_id,
  card_name = excluded.card_name,
  effect_json = excluded.effect_json,
  deck_role_json = excluded.deck_role_json,
  source = excluded.source,
  confidence = excluded.confidence,
  review_status = excluded.review_status,
  rule_version = excluded.rule_version,
  oracle_hash = excluded.oracle_hash,
  notes = excluded.notes,
  reviewed_by = excluded.reviewed_by,
  reviewed_at = excluded.reviewed_at,
  created_at = excluded.created_at,
  updated_at = excluded.updated_at,
  last_seen_at = excluded.last_seen_at,
  execution_status = excluded.execution_status;

COMMIT;
