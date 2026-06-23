BEGIN;

DO $$
BEGIN
  IF to_regclass('manaloom_deploy_audit.pg087_deck606_remaining_semantic_20260623_085349') IS NULL THEN
    RAISE EXCEPTION 'missing backup table manaloom_deploy_audit.pg087_deck606_remaining_semantic_20260623_085349';
  END IF;
END $$;

WITH target_cards AS (
  SELECT DISTINCT card_id
  FROM manaloom_deploy_audit.pg087_deck606_remaining_semantic_20260623_085349
)
DELETE FROM card_battle_rules r
USING target_cards t
WHERE r.card_id = t.card_id;

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
FROM manaloom_deploy_audit.pg087_deck606_remaining_semantic_20260623_085349;

COMMIT;
