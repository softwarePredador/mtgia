BEGIN;

DELETE FROM card_battle_rules
WHERE normalized_name IN ('scroll rack', 'smothering tithe');

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
  payload->>'normalized_name',
  payload->>'logical_rule_key',
  NULLIF(payload->>'card_id', '')::uuid,
  payload->>'card_name',
  COALESCE(payload->'effect_json', '{}'::jsonb),
  COALESCE(payload->'deck_role_json', '{}'::jsonb),
  payload->>'source',
  NULLIF(payload->>'confidence', '')::numeric,
  payload->>'review_status',
  payload->>'execution_status',
  NULLIF(payload->>'rule_version', '')::integer,
  payload->>'oracle_hash',
  payload->>'notes',
  payload->>'reviewed_by',
  NULLIF(payload->>'reviewed_at', '')::timestamptz,
  COALESCE(NULLIF(payload->>'created_at', '')::timestamptz, now()),
  COALESCE(NULLIF(payload->>'updated_at', '')::timestamptz, now()),
  NULLIF(payload->>'last_seen_at', '')::timestamptz
FROM manaloom_deploy_audit.pg065_shared_engine_rules_20260623_031553
ON CONFLICT (normalized_name, logical_rule_key) DO UPDATE SET
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
  created_at = excluded.created_at,
  updated_at = excluded.updated_at,
  last_seen_at = excluded.last_seen_at;

COMMIT;
