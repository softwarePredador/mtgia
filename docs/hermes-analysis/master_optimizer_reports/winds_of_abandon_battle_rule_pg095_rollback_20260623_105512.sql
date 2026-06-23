\pset pager off
\set ON_ERROR_STOP on

BEGIN;

DO $$
BEGIN
  IF to_regclass('manaloom_deploy_audit.pg095_winds_of_abandon_battle_rule_20260623_105512') IS NULL THEN
    RAISE EXCEPTION 'PG095 rollback backup table is missing';
  END IF;
END $$;

DELETE FROM card_battle_rules
WHERE normalized_name = 'winds of abandon'
   OR lower(card_name) = 'winds of abandon';

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
FROM manaloom_deploy_audit.pg095_winds_of_abandon_battle_rule_20260623_105512;

COMMIT;
