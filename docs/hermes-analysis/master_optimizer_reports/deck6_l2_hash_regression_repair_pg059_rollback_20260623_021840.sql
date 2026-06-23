-- PG059 Deck 6 L2 hash-only regression repair rollback.
-- Restores all card_battle_rules rows captured before PG059.

BEGIN;

DO $$
BEGIN
  IF to_regclass('manaloom_deploy_audit.pg059_deck6_l2_hash_regression_repair_20260623_021840') IS NULL THEN
    RAISE EXCEPTION 'Backup table manaloom_deploy_audit.pg059_deck6_l2_hash_regression_repair_20260623_021840 does not exist';
  END IF;
END $$;

WITH deck_target_cards AS (
  SELECT c.id AS card_id
  FROM deck_cards dc
  JOIN cards c ON c.id = dc.card_id
  WHERE dc.deck_id = '528c877f-f829-4207-95e6-73981776c323'::uuid
    AND c.name IN (
      'Fellwar Stone',
      'Mana Vault',
      'Mox Amber',
      'Seething Song',
      'Silence',
      'Talisman of Conviction',
      'Valakut Awakening // Valakut Stoneforge'
    )
)
DELETE FROM card_battle_rules cbr
USING deck_target_cards dt
WHERE cbr.card_id = dt.card_id;

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
FROM manaloom_deploy_audit.pg059_deck6_l2_hash_regression_repair_20260623_021840;

COMMIT;
