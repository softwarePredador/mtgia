-- PG061 Deck 6 L3B simple red rituals metadata confirmation rollback.

BEGIN;

DO $$
BEGIN
  IF to_regclass('manaloom_deploy_audit.pg061_deck6_l3b_simple_red_rituals_metadata_20260623_022418') IS NULL THEN
    RAISE EXCEPTION 'Backup table manaloom_deploy_audit.pg061_deck6_l3b_simple_red_rituals_metadata_20260623_022418 does not exist';
  END IF;
END $$;

DELETE FROM card_battle_rules
WHERE normalized_name IN ('rite of flame', 'seething song');

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
FROM manaloom_deploy_audit.pg061_deck6_l3b_simple_red_rituals_metadata_20260623_022418;

COMMIT;
