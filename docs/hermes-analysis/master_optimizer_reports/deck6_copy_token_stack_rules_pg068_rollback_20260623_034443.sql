-- PG068 deck6 copy/token-copy stack rules rollback.
-- Restores all target card_battle_rules rows captured before PG068.

\pset pager off
\set ON_ERROR_STOP on

BEGIN;

DO $$
BEGIN
  IF to_regclass('manaloom_deploy_audit.pg068_deck6_copy_token_stack_rules_20260623_034443') IS NULL THEN
    RAISE EXCEPTION 'Backup table manaloom_deploy_audit.pg068_deck6_copy_token_stack_rules_20260623_034443 does not exist';
  END IF;
END $$;

DELETE FROM card_battle_rules
WHERE normalized_name IN (
  'dualcaster mage',
  'reiterate',
  'heat shimmer',
  'twinflame',
  'molten duplication'
);

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
FROM manaloom_deploy_audit.pg068_deck6_copy_token_stack_rules_20260623_034443;

COMMIT;
