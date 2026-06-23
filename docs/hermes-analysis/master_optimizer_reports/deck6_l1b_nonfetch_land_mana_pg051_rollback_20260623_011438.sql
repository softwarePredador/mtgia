-- PG051 Deck 6 L1B non-fetch land mana-source rollback.
-- Restores the 22 target card_battle_rules rows captured before apply.

BEGIN;

DELETE FROM card_battle_rules cbr
USING manaloom_deploy_audit.pg051_deck6_l1b_nonfetch_land_mana_20260623_011438 backup
WHERE cbr.normalized_name = backup.normalized_name
  AND cbr.logical_rule_key = backup.logical_rule_key;

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
FROM manaloom_deploy_audit.pg051_deck6_l1b_nonfetch_land_mana_20260623_011438;

COMMIT;
