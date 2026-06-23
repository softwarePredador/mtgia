-- PG059 Deck 6 L2 hash-only regression repair apply.
-- Expected precheck:
--   deck_target_cards=7
--   target_runtime_rows=8
--   target_runtime_missing_hash_rows=8
--   target_runtime_hash_mismatch_rows=0
--   target_runtime_live_hash_mismatch_rows=0
--   target_runtime_bad_effect_rows=0
--   target_runtime_bad_scope_rows=0
--   backup_candidate_rows=23
--   target_deck_cards_missing=0

BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

DO $$
BEGIN
  IF to_regclass('manaloom_deploy_audit.pg059_deck6_l2_hash_regression_repair_20260623_021840') IS NOT NULL THEN
    RAISE EXCEPTION 'Backup table manaloom_deploy_audit.pg059_deck6_l2_hash_regression_repair_20260623_021840 already exists';
  END IF;
END $$;

CREATE TABLE manaloom_deploy_audit.pg059_deck6_l2_hash_regression_repair_20260623_021840 AS
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
SELECT cbr.*
FROM card_battle_rules cbr
WHERE cbr.card_id IN (SELECT card_id FROM deck_target_cards);

DO $$
DECLARE
  v_backup_rows integer;
  v_missing_hash_rows integer;
BEGIN
  SELECT count(*) INTO v_backup_rows
  FROM manaloom_deploy_audit.pg059_deck6_l2_hash_regression_repair_20260623_021840;

  SELECT count(*) INTO v_missing_hash_rows
  FROM card_battle_rules cbr
  WHERE cbr.logical_rule_key IN (
    'battle_rule_v1:3906ffa3cbf7d3437d68e44e13e10bba',
    'battle_rule_v1:5a2533694ffd19223d3cde1e25d258ff',
    'battle_rule_v1:972703914ee50acd7a4e6f529fea1adf',
    'battle_rule_v1:3eb15dc581c6b913158f9b63c023f3d7',
    'battle_rule_v1:74b210b77b004a677906e0216d44e445',
    'battle_rule_v1:02133e513da5ea98ac74d32d39b16470',
    'battle_rule_v1:245b8d2627720fadfd7a30464d07605a',
    'battle_rule_v1:6e1f3b876822abafe1de47610f46858d'
  )
    AND cbr.source = 'curated'
    AND cbr.review_status IN ('active', 'verified')
    AND cbr.execution_status = 'auto'
    AND coalesce(cbr.oracle_hash, '') = '';

  IF v_backup_rows <> 23 OR v_missing_hash_rows <> 8 THEN
    RAISE EXCEPTION 'PG059 precondition failed: backup_rows=%, missing_hash_rows=% expected 23/8',
      v_backup_rows, v_missing_hash_rows;
  END IF;
END $$;

WITH updates(logical_rule_key, expected_hash) AS (
  VALUES
    ('battle_rule_v1:3906ffa3cbf7d3437d68e44e13e10bba', 'd63befc8ac40d9a38732f9b5c1a7414a'),
    ('battle_rule_v1:5a2533694ffd19223d3cde1e25d258ff', '35e3fd94c8453c0e326033af49ae18c8'),
    ('battle_rule_v1:972703914ee50acd7a4e6f529fea1adf', 'e47b40cf2afc4c9ceac6bf91815da706'),
    ('battle_rule_v1:3eb15dc581c6b913158f9b63c023f3d7', 'ccd492289c6f1c14c8fb7a248d7bbf32'),
    ('battle_rule_v1:74b210b77b004a677906e0216d44e445', 'a0ca3c09a7db091c435ab31adb9c1780'),
    ('battle_rule_v1:02133e513da5ea98ac74d32d39b16470', 'd49ceec937367a344a9f0948eea4f8f2'),
    ('battle_rule_v1:245b8d2627720fadfd7a30464d07605a', '22b42fcc181b7aed71f78b2e1e51e887'),
    ('battle_rule_v1:6e1f3b876822abafe1de47610f46858d', '22b42fcc181b7aed71f78b2e1e51e887')
)
UPDATE card_battle_rules cbr
SET
  oracle_hash = updates.expected_hash,
  reviewed_by = 'codex_pg059',
  reviewed_at = now(),
  updated_at = now(),
  last_seen_at = now(),
  notes = concat_ws(
    E'\n',
    nullif(cbr.notes, ''),
    'PG059 2026-06-23: Deck 6 L2 hash-only regression repair. Restored oracle_hash from current PostgreSQL cards.oracle_text for already-specific trusted runtime rule; no effect_json/executor/deck change.'
  )
FROM updates
WHERE cbr.logical_rule_key = updates.logical_rule_key
  AND cbr.source = 'curated'
  AND cbr.review_status IN ('active', 'verified')
  AND cbr.execution_status = 'auto';

DO $$
DECLARE
  v_hashed_rows integer;
  v_missing_hash_rows integer;
BEGIN
  SELECT count(*) INTO v_hashed_rows
  FROM card_battle_rules cbr
  WHERE (
    cbr.logical_rule_key = 'battle_rule_v1:3906ffa3cbf7d3437d68e44e13e10bba'
    AND cbr.oracle_hash = 'd63befc8ac40d9a38732f9b5c1a7414a'
  ) OR (
    cbr.logical_rule_key = 'battle_rule_v1:5a2533694ffd19223d3cde1e25d258ff'
    AND cbr.oracle_hash = '35e3fd94c8453c0e326033af49ae18c8'
  ) OR (
    cbr.logical_rule_key = 'battle_rule_v1:972703914ee50acd7a4e6f529fea1adf'
    AND cbr.oracle_hash = 'e47b40cf2afc4c9ceac6bf91815da706'
  ) OR (
    cbr.logical_rule_key = 'battle_rule_v1:3eb15dc581c6b913158f9b63c023f3d7'
    AND cbr.oracle_hash = 'ccd492289c6f1c14c8fb7a248d7bbf32'
  ) OR (
    cbr.logical_rule_key = 'battle_rule_v1:74b210b77b004a677906e0216d44e445'
    AND cbr.oracle_hash = 'a0ca3c09a7db091c435ab31adb9c1780'
  ) OR (
    cbr.logical_rule_key = 'battle_rule_v1:02133e513da5ea98ac74d32d39b16470'
    AND cbr.oracle_hash = 'd49ceec937367a344a9f0948eea4f8f2'
  ) OR (
    cbr.logical_rule_key = 'battle_rule_v1:245b8d2627720fadfd7a30464d07605a'
    AND cbr.oracle_hash = '22b42fcc181b7aed71f78b2e1e51e887'
  ) OR (
    cbr.logical_rule_key = 'battle_rule_v1:6e1f3b876822abafe1de47610f46858d'
    AND cbr.oracle_hash = '22b42fcc181b7aed71f78b2e1e51e887'
  );

  SELECT count(*) INTO v_missing_hash_rows
  FROM card_battle_rules cbr
  WHERE cbr.logical_rule_key IN (
    'battle_rule_v1:3906ffa3cbf7d3437d68e44e13e10bba',
    'battle_rule_v1:5a2533694ffd19223d3cde1e25d258ff',
    'battle_rule_v1:972703914ee50acd7a4e6f529fea1adf',
    'battle_rule_v1:3eb15dc581c6b913158f9b63c023f3d7',
    'battle_rule_v1:74b210b77b004a677906e0216d44e445',
    'battle_rule_v1:02133e513da5ea98ac74d32d39b16470',
    'battle_rule_v1:245b8d2627720fadfd7a30464d07605a',
    'battle_rule_v1:6e1f3b876822abafe1de47610f46858d'
  )
    AND cbr.source = 'curated'
    AND cbr.review_status IN ('active', 'verified')
    AND cbr.execution_status = 'auto'
    AND coalesce(cbr.oracle_hash, '') = '';

  IF v_hashed_rows <> 8 OR v_missing_hash_rows <> 0 THEN
    RAISE EXCEPTION 'PG059 postcondition failed: hashed_rows=%, missing_hash_rows=% expected 8/0',
      v_hashed_rows, v_missing_hash_rows;
  END IF;
END $$;

COMMIT;
