\pset pager off
\set ON_ERROR_STOP on

BEGIN;

DO $$
BEGIN
  IF to_regclass('manaloom_deploy_audit.pg017_arcane_epiphany_20260621_004200') IS NULL THEN
    RAISE EXCEPTION 'PG017 rollback backup table is missing';
  END IF;
END $$;

DELETE FROM card_battle_rules
WHERE lower(card_name) = 'arcane epiphany'
  AND logical_rule_key = 'battle_rule_v1:3e12c38dd6d41a47079fbdefee08b3bd';

DELETE FROM card_function_tags
WHERE lower(card_name) = 'arcane epiphany'
  AND tag = 'draw'
  AND source = 'card_battle_rules_v1';

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
  (payload->>'confidence')::numeric,
  payload->>'review_status',
  COALESCE(payload->>'execution_status', 'auto'),
  COALESCE((payload->>'rule_version')::int, 1),
  payload->>'oracle_hash',
  payload->>'notes',
  payload->>'reviewed_by',
  NULLIF(payload->>'reviewed_at', '')::timestamptz,
  COALESCE(NULLIF(payload->>'created_at', '')::timestamptz, now()),
  COALESCE(NULLIF(payload->>'updated_at', '')::timestamptz, now()),
  NULLIF(payload->>'last_seen_at', '')::timestamptz
FROM manaloom_deploy_audit.pg017_arcane_epiphany_20260621_004200
WHERE section = 'card_battle_rules'
ON CONFLICT (normalized_name, logical_rule_key)
DO UPDATE SET
  card_id = EXCLUDED.card_id,
  card_name = EXCLUDED.card_name,
  effect_json = EXCLUDED.effect_json,
  deck_role_json = EXCLUDED.deck_role_json,
  source = EXCLUDED.source,
  confidence = EXCLUDED.confidence,
  review_status = EXCLUDED.review_status,
  execution_status = EXCLUDED.execution_status,
  rule_version = EXCLUDED.rule_version,
  oracle_hash = EXCLUDED.oracle_hash,
  notes = EXCLUDED.notes,
  reviewed_by = EXCLUDED.reviewed_by,
  reviewed_at = EXCLUDED.reviewed_at,
  updated_at = EXCLUDED.updated_at,
  last_seen_at = EXCLUDED.last_seen_at;

INSERT INTO card_function_tags (
  card_id,
  card_name,
  tag,
  confidence,
  source,
  evidence,
  updated_at
)
SELECT
  NULLIF(payload->>'card_id', '')::uuid,
  payload->>'card_name',
  payload->>'tag',
  (payload->>'confidence')::numeric,
  payload->>'source',
  payload->>'evidence',
  COALESCE(NULLIF(payload->>'updated_at', '')::timestamptz, now())
FROM manaloom_deploy_audit.pg017_arcane_epiphany_20260621_004200
WHERE section = 'card_function_tags'
ON CONFLICT (card_id, tag, source)
DO UPDATE SET
  card_name = EXCLUDED.card_name,
  confidence = EXCLUDED.confidence,
  evidence = EXCLUDED.evidence,
  updated_at = EXCLUDED.updated_at;

COMMIT;
