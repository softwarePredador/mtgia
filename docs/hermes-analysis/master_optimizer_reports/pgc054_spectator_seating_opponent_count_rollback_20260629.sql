-- PGC054 Spectator Seating opponent-count ETB runtime rollback.
-- Restores the exact card_battle_rules rows captured before apply.

BEGIN;

DO $$
DECLARE
  v_backup_rows integer;
BEGIN
  SELECT count(*) INTO v_backup_rows
  FROM manaloom_deploy_audit.pgc054_spectator_seating_opponent_count_20260629;
  IF v_backup_rows <> 2 THEN
    RAISE EXCEPTION 'PGC054 rollback guard failed: expected 2 backup rows, found %', v_backup_rows;
  END IF;
END $$;

DELETE FROM card_battle_rules
WHERE normalized_name = 'spectator seating';

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
FROM manaloom_deploy_audit.pgc054_spectator_seating_opponent_count_20260629;

COMMIT;
