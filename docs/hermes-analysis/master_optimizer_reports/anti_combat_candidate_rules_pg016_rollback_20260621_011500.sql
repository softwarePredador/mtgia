\pset pager off
\set ON_ERROR_STOP on

BEGIN;

DO $$
BEGIN
  IF to_regclass('manaloom_deploy_audit.pg016_anti_combat_rules_20260621_011500') IS NULL THEN
    RAISE EXCEPTION 'PG016 rollback backup table is missing';
  END IF;
END $$;

WITH pg016_keys(logical_rule_key) AS (
  VALUES
    ('battle_rule_v1:0b3adc33c3be375c3d4005b0082ff5c2'),
    ('battle_rule_v1:6932f0223ca41f0eedf724d55a9a858b'),
    ('battle_rule_v1:6f6089b73fb8f7f9aee20cacb64fffc7'),
    ('battle_rule_v1:1ea5840419f4343c05a661e79d6829d5'),
    ('battle_rule_v1:439de5be33887bbce5dde1cfb367774a')
)
DELETE FROM card_battle_rules cbr
USING pg016_keys
WHERE cbr.logical_rule_key = pg016_keys.logical_rule_key;

DELETE FROM card_battle_rules
WHERE (normalized_name || '|' || logical_rule_key) IN (
  SELECT key
  FROM manaloom_deploy_audit.pg016_anti_combat_rules_20260621_011500
  WHERE section = 'card_battle_rules'
);

DELETE FROM card_function_tags
WHERE lower(card_name) IN (
  'norn''s annex',
  'windborn muse',
  'silent arbiter',
  'ensnaring bridge',
  'magus of the moat'
)
  AND (
    (tag = 'protection' AND source = 'card_battle_rules_v1')
    OR (card_id::text || '|' || tag || '|' || source) IN (
      SELECT key
      FROM manaloom_deploy_audit.pg016_anti_combat_rules_20260621_011500
      WHERE section = 'card_function_tags'
    )
  );

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
FROM manaloom_deploy_audit.pg016_anti_combat_rules_20260621_011500
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
FROM manaloom_deploy_audit.pg016_anti_combat_rules_20260621_011500
WHERE section = 'card_function_tags'
ON CONFLICT (card_id, tag, source)
DO UPDATE SET
  card_name = EXCLUDED.card_name,
  confidence = EXCLUDED.confidence,
  evidence = EXCLUDED.evidence,
  updated_at = EXCLUDED.updated_at;

SELECT
  'pg016_rollback_rule_result' AS check_name,
  card_name,
  logical_rule_key,
  effect_json,
  deck_role_json,
  source,
  confidence,
  review_status,
  execution_status
FROM card_battle_rules
WHERE lower(card_name) IN (
  'norn''s annex',
  'windborn muse',
  'silent arbiter',
  'ensnaring bridge',
  'magus of the moat'
)
ORDER BY card_name, source, review_status, execution_status, logical_rule_key;

COMMIT;
