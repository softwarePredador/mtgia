BEGIN;

DO $$
BEGIN
  IF to_regclass('manaloom_deploy_audit.pg091_deck607_token_maker_family_20260623_093259') IS NULL THEN
    RAISE EXCEPTION 'backup table manaloom_deploy_audit.pg091_deck607_token_maker_family_20260623_093259 not found';
  END IF;
END $$;

CREATE TEMP TABLE pg091_deck607_token_maker_backup AS
SELECT *
FROM manaloom_deploy_audit.pg091_deck607_token_maker_family_20260623_093259;

DELETE FROM card_battle_rules r
WHERE r.normalized_name IN (
    SELECT DISTINCT normalized_name FROM pg091_deck607_token_maker_backup
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
  b.normalized_name,
  b.card_id,
  b.card_name,
  b.effect_json,
  b.deck_role_json,
  b.source,
  b.confidence,
  b.review_status,
  b.rule_version,
  b.oracle_hash,
  b.notes,
  b.reviewed_by,
  b.reviewed_at,
  b.created_at,
  now(),
  b.last_seen_at,
  b.logical_rule_key,
  b.execution_status
FROM pg091_deck607_token_maker_backup b;

COMMIT;
