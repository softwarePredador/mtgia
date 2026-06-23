\pset pager off

BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

DO $$
BEGIN
  IF to_regclass('manaloom_deploy_audit.pg083_runtime_hash_restore_20260623_083050') IS NOT NULL THEN
    RAISE EXCEPTION 'PG083 runtime hash restore backup table already exists';
  END IF;
END $$;

CREATE TEMP TABLE pg083_runtime_hash_targets(
  normalized_name text,
  card_name text,
  logical_rule_key text,
  expected_oracle_hash text
);

INSERT INTO pg083_runtime_hash_targets(normalized_name, card_name, logical_rule_key, expected_oracle_hash)
VALUES
  ('fellwar stone', 'Fellwar Stone', 'battle_rule_v1:3906ffa3cbf7d3437d68e44e13e10bba', 'd63befc8ac40d9a38732f9b5c1a7414a'),
  ('mana vault', 'Mana Vault', 'battle_rule_v1:5a2533694ffd19223d3cde1e25d258ff', '35e3fd94c8453c0e326033af49ae18c8'),
  ('mox amber', 'Mox Amber', 'battle_rule_v1:972703914ee50acd7a4e6f529fea1adf', 'e47b40cf2afc4c9ceac6bf91815da706'),
  ('talisman of conviction', 'Talisman of Conviction', 'battle_rule_v1:02133e513da5ea98ac74d32d39b16470', 'd49ceec937367a344a9f0948eea4f8f2'),
  ('seething song', 'Seething Song', 'battle_rule_v1:3eb15dc581c6b913158f9b63c023f3d7', 'ccd492289c6f1c14c8fb7a248d7bbf32');

CREATE TABLE manaloom_deploy_audit.pg083_runtime_hash_restore_20260623_083050 AS
SELECT cbr.*
FROM card_battle_rules cbr
JOIN pg083_runtime_hash_targets t
  ON t.normalized_name = cbr.normalized_name
 AND t.logical_rule_key = cbr.logical_rule_key;

DO $$
DECLARE
  v_target integer;
  v_oracle integer;
  v_missing integer;
  v_trusted integer;
BEGIN
  SELECT
    count(*),
    count(*) FILTER (WHERE md5(coalesce(c.oracle_text, '')) = t.expected_oracle_hash),
    count(*) FILTER (WHERE cbr.oracle_hash IS NULL OR cbr.oracle_hash = ''),
    count(*) FILTER (WHERE cbr.review_status IN ('verified', 'active') AND cbr.execution_status = 'auto')
  INTO v_target, v_oracle, v_missing, v_trusted
  FROM pg083_runtime_hash_targets t
  JOIN card_battle_rules cbr
    ON cbr.normalized_name = t.normalized_name
   AND cbr.logical_rule_key = t.logical_rule_key
  JOIN cards c
    ON c.id = cbr.card_id;

  IF v_target <> 5 THEN
    RAISE EXCEPTION 'PG083 precondition failed: expected 5 target rows, got %', v_target;
  END IF;
  IF v_oracle <> 5 THEN
    RAISE EXCEPTION 'PG083 precondition failed: expected 5 current oracle hash matches, got %', v_oracle;
  END IF;
  IF v_missing <> 5 THEN
    RAISE EXCEPTION 'PG083 precondition failed: expected 5 missing hashes, got %', v_missing;
  END IF;
  IF v_trusted <> 5 THEN
    RAISE EXCEPTION 'PG083 precondition failed: expected 5 trusted auto rows, got %', v_trusted;
  END IF;
END $$;

UPDATE card_battle_rules cbr
SET
  oracle_hash = t.expected_oracle_hash,
  rule_version = greatest(cbr.rule_version, 2),
  reviewed_by = 'codex-auditor',
  reviewed_at = now(),
  updated_at = now(),
  last_seen_at = now(),
  notes = concat_ws(E'\n', nullif(cbr.notes, ''), 'PG083: restored oracle_hash provenance for existing tested runtime rule; effect_json/deck_role_json unchanged.')
FROM pg083_runtime_hash_targets t
WHERE cbr.normalized_name = t.normalized_name
  AND cbr.logical_rule_key = t.logical_rule_key;

COMMIT;
