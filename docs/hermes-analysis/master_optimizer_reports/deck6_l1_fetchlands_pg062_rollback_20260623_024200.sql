-- PG062 Deck 6 L1 fetchland cleanup rollback.
-- Restores all target card_battle_rules rows captured before PG062.

BEGIN;

DO $$
BEGIN
  IF to_regclass('manaloom_deploy_audit.pg062_deck6_l1_fetchlands_20260623_024200') IS NULL THEN
    RAISE EXCEPTION 'Backup table manaloom_deploy_audit.pg062_deck6_l1_fetchlands_20260623_024200 does not exist';
  END IF;
END $$;

WITH target_names(card_name) AS (
  VALUES
    ('Arid Mesa'),
    ('Bloodstained Mire'),
    ('Flooded Strand'),
    ('Marsh Flats'),
    ('Prismatic Vista'),
    ('Scalding Tarn'),
    ('Windswept Heath'),
    ('Wooded Foothills')
),
target_cards AS (
  SELECT c.id AS card_id
  FROM target_names tn
  JOIN cards c
    ON lower(c.name) = lower(tn.card_name)
  JOIN deck_cards dc
    ON dc.card_id = c.id
   AND dc.deck_id = '528c877f-f829-4207-95e6-73981776c323'::uuid
)
DELETE FROM card_battle_rules cbr
USING target_cards tc
WHERE cbr.card_id = tc.card_id;

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
FROM manaloom_deploy_audit.pg062_deck6_l1_fetchlands_20260623_024200;

COMMIT;
