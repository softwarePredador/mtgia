\pset pager off
\set ON_ERROR_STOP on

BEGIN;

DO $$
BEGIN
  IF to_regclass('manaloom_deploy_audit.pg029_blasphemous_act_battle_rule_20260622_192517') IS NULL THEN
    RAISE EXCEPTION 'PG029 rollback backup table is missing';
  END IF;
END $$;

DELETE FROM card_battle_rules
WHERE normalized_name = 'blasphemous act'
  AND (
    logical_rule_key = 'battle_rule_v1:56271789d639ef390213dbc90059e4d2'
    OR logical_rule_key IN (
      SELECT split_part(key, '|', 2)
      FROM manaloom_deploy_audit.pg029_blasphemous_act_battle_rule_20260622_192517
      WHERE section = 'card_battle_rules'
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
FROM manaloom_deploy_audit.pg029_blasphemous_act_battle_rule_20260622_192517
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

SELECT
  'pg029_rollback_result' AS check_name,
  card_name,
  logical_rule_key,
  effect_json,
  source,
  confidence,
  review_status,
  execution_status,
  oracle_hash
FROM card_battle_rules
WHERE normalized_name = 'blasphemous act'
ORDER BY source, review_status, execution_status, logical_rule_key;

COMMIT;
