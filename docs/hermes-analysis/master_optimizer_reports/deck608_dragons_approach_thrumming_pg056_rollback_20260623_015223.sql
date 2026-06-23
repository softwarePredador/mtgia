-- PG056 Deck 608 Dragon's Approach / Thrumming Stone rollback.

BEGIN;

WITH backup_keys AS (
  SELECT normalized_name, logical_rule_key
  FROM manaloom_deploy_audit.pg056_deck608_dragons_approach_thrumming_20260623_015223
)
DELETE FROM card_battle_rules cbr
USING backup_keys bk
WHERE cbr.normalized_name = bk.normalized_name
  AND cbr.logical_rule_key = bk.logical_rule_key;

INSERT INTO card_battle_rules (
  normalized_name,
  logical_rule_key,
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
  execution_status
)
SELECT
  normalized_name,
  logical_rule_key,
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
  execution_status
FROM manaloom_deploy_audit.pg056_deck608_dragons_approach_thrumming_20260623_015223;

COMMIT;
