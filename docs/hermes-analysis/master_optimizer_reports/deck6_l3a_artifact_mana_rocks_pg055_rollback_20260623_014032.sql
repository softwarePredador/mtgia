-- PG055 Deck 6 L3A artifact mana-rock family rollback.
-- Restores card_battle_rules rows captured before PG055.

BEGIN;

WITH target_names(name) AS (
  VALUES
    ('Arcane Signet'),
    ('Boros Signet'),
    ('Fellwar Stone'),
    ('Mana Vault'),
    ('Mox Amber'),
    ('Sol Ring'),
    ('Talisman of Conviction')
),
deck_target AS (
  SELECT lower(c.name) AS normalized_name
  FROM deck_cards dc
  JOIN cards c ON c.id = dc.card_id
  JOIN target_names tn ON tn.name = c.name
  WHERE dc.deck_id = '528c877f-f829-4207-95e6-73981776c323'::uuid
)
DELETE FROM card_battle_rules cbr
USING deck_target dt
WHERE cbr.normalized_name = dt.normalized_name;

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
FROM manaloom_deploy_audit.pg055_deck6_l3a_artifact_mana_rocks_20260623_014032;

COMMIT;
