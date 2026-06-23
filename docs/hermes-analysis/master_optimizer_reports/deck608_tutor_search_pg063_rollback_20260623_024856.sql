-- PG063 deck608 tutor/search package rollback.
-- Restores all target card_battle_rules rows captured before PG063.

BEGIN;

DO $$
BEGIN
  IF to_regclass('manaloom_deploy_audit.pg063_deck608_tutor_search_20260623_024856') IS NULL THEN
    RAISE EXCEPTION 'Backup table manaloom_deploy_audit.pg063_deck608_tutor_search_20260623_024856 does not exist';
  END IF;
END $$;

DELETE FROM card_battle_rules
WHERE normalized_name IN (
  'enlightened tutor',
  'idyllic tutor',
  'goblin engineer',
  'imperial recruiter'
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
FROM manaloom_deploy_audit.pg063_deck608_tutor_search_20260623_024856;

COMMIT;
