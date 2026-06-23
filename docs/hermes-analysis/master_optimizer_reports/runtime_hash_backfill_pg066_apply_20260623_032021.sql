BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE manaloom_deploy_audit.pg066_runtime_hash_backfill_20260623_032021 AS
WITH expected(normalized_name, logical_rule_key) AS (
  VALUES
    ('silence', 'battle_rule_v1:74b210b77b004a677906e0216d44e445'),
    ('fellwar stone', 'battle_rule_v1:3906ffa3cbf7d3437d68e44e13e10bba'),
    ('mana vault', 'battle_rule_v1:5a2533694ffd19223d3cde1e25d258ff'),
    ('mox amber', 'battle_rule_v1:972703914ee50acd7a4e6f529fea1adf'),
    ('seething song', 'battle_rule_v1:3eb15dc581c6b913158f9b63c023f3d7'),
    ('talisman of conviction', 'battle_rule_v1:02133e513da5ea98ac74d32d39b16470'),
    ('valakut awakening', 'battle_rule_v1:245b8d2627720fadfd7a30464d07605a'),
    ('valakut awakening // valakut stoneforge', 'battle_rule_v1:6e1f3b876822abafe1de47610f46858d')
)
SELECT
  now() AS backed_up_at,
  to_jsonb(cbr) AS payload
FROM card_battle_rules cbr
JOIN expected e USING (normalized_name, logical_rule_key);

DO $$
DECLARE
  v_expected_count integer;
  v_bad_count integer;
BEGIN
  WITH expected(card_name, normalized_name, logical_rule_key, expected_oracle_hash) AS (
    VALUES
      ('Silence', 'silence', 'battle_rule_v1:74b210b77b004a677906e0216d44e445', 'a0ca3c09a7db091c435ab31adb9c1780'),
      ('Fellwar Stone', 'fellwar stone', 'battle_rule_v1:3906ffa3cbf7d3437d68e44e13e10bba', 'd63befc8ac40d9a38732f9b5c1a7414a'),
      ('Mana Vault', 'mana vault', 'battle_rule_v1:5a2533694ffd19223d3cde1e25d258ff', '35e3fd94c8453c0e326033af49ae18c8'),
      ('Mox Amber', 'mox amber', 'battle_rule_v1:972703914ee50acd7a4e6f529fea1adf', 'e47b40cf2afc4c9ceac6bf91815da706'),
      ('Seething Song', 'seething song', 'battle_rule_v1:3eb15dc581c6b913158f9b63c023f3d7', 'ccd492289c6f1c14c8fb7a248d7bbf32'),
      ('Talisman of Conviction', 'talisman of conviction', 'battle_rule_v1:02133e513da5ea98ac74d32d39b16470', 'd49ceec937367a344a9f0948eea4f8f2'),
      ('Valakut Awakening // Valakut Stoneforge', 'valakut awakening', 'battle_rule_v1:245b8d2627720fadfd7a30464d07605a', '22b42fcc181b7aed71f78b2e1e51e887'),
      ('Valakut Awakening // Valakut Stoneforge', 'valakut awakening // valakut stoneforge', 'battle_rule_v1:6e1f3b876822abafe1de47610f46858d', '22b42fcc181b7aed71f78b2e1e51e887')
  ),
  joined AS (
    SELECT e.*, c.id AS card_id, md5(coalesce(c.oracle_text, '')) AS target_oracle_hash, cbr.review_status, cbr.execution_status
    FROM expected e
    LEFT JOIN cards c ON lower(c.name) = lower(e.card_name)
    LEFT JOIN card_battle_rules cbr
      ON cbr.normalized_name = e.normalized_name
     AND cbr.logical_rule_key = e.logical_rule_key
  )
  SELECT
    count(*),
    count(*) FILTER (
      WHERE card_id IS NULL
         OR target_oracle_hash IS DISTINCT FROM expected_oracle_hash
         OR review_status NOT IN ('verified', 'active')
         OR execution_status NOT IN ('auto', 'executable')
    )
  INTO v_expected_count, v_bad_count
  FROM joined;

  IF v_expected_count <> 8 OR v_bad_count <> 0 THEN
    RAISE EXCEPTION 'PG066 precondition failed: expected=% bad=%', v_expected_count, v_bad_count;
  END IF;
END $$;

WITH expected(normalized_name, logical_rule_key, expected_oracle_hash) AS (
  VALUES
    ('silence', 'battle_rule_v1:74b210b77b004a677906e0216d44e445', 'a0ca3c09a7db091c435ab31adb9c1780'),
    ('fellwar stone', 'battle_rule_v1:3906ffa3cbf7d3437d68e44e13e10bba', 'd63befc8ac40d9a38732f9b5c1a7414a'),
    ('mana vault', 'battle_rule_v1:5a2533694ffd19223d3cde1e25d258ff', '35e3fd94c8453c0e326033af49ae18c8'),
    ('mox amber', 'battle_rule_v1:972703914ee50acd7a4e6f529fea1adf', 'e47b40cf2afc4c9ceac6bf91815da706'),
    ('seething song', 'battle_rule_v1:3eb15dc581c6b913158f9b63c023f3d7', 'ccd492289c6f1c14c8fb7a248d7bbf32'),
    ('talisman of conviction', 'battle_rule_v1:02133e513da5ea98ac74d32d39b16470', 'd49ceec937367a344a9f0948eea4f8f2'),
    ('valakut awakening', 'battle_rule_v1:245b8d2627720fadfd7a30464d07605a', '22b42fcc181b7aed71f78b2e1e51e887'),
    ('valakut awakening // valakut stoneforge', 'battle_rule_v1:6e1f3b876822abafe1de47610f46858d', '22b42fcc181b7aed71f78b2e1e51e887')
)
UPDATE card_battle_rules cbr
SET
  oracle_hash = expected.expected_oracle_hash,
  rule_version = greatest(cbr.rule_version, 2),
  reviewed_by = coalesce(cbr.reviewed_by, 'codex-auditor'),
  reviewed_at = coalesce(cbr.reviewed_at, now()),
  updated_at = now(),
  last_seen_at = now(),
  notes = concat_ws(
    E'\n',
    nullif(cbr.notes, ''),
    'PG066: backfilled oracle_hash from live cards.oracle_text after PG->SQLite sync exposed trusted runtime rows without persisted hash.'
  )
FROM expected
WHERE cbr.normalized_name = expected.normalized_name
  AND cbr.logical_rule_key = expected.logical_rule_key;

COMMIT;
