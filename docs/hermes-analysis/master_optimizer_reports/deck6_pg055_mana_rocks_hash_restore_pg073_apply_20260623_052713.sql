BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

DO $$
BEGIN
  IF to_regclass('manaloom_deploy_audit.pg073_pg055_mana_rocks_hash_restore_20260623_052713') IS NOT NULL THEN
    RAISE EXCEPTION 'PG073 PG055 mana rocks hash restore backup table already exists';
  END IF;
END $$;

CREATE TABLE manaloom_deploy_audit.pg073_pg055_mana_rocks_hash_restore_20260623_052713 AS
SELECT now() AS backed_up_at, to_jsonb(cbr) AS payload
FROM card_battle_rules cbr
WHERE (cbr.normalized_name, cbr.logical_rule_key) IN (
  ('fellwar stone', 'battle_rule_v1:3906ffa3cbf7d3437d68e44e13e10bba'),
  ('mana vault', 'battle_rule_v1:5a2533694ffd19223d3cde1e25d258ff'),
  ('mox amber', 'battle_rule_v1:972703914ee50acd7a4e6f529fea1adf'),
  ('talisman of conviction', 'battle_rule_v1:02133e513da5ea98ac74d32d39b16470')
);

DO $$
DECLARE
  v_cards integer;
  v_rules integer;
  v_missing_hash integer;
BEGIN
  WITH expected_cards(name, oracle_hash, logical_rule_key) AS (
    VALUES
      ('Fellwar Stone', 'd63befc8ac40d9a38732f9b5c1a7414a', 'battle_rule_v1:3906ffa3cbf7d3437d68e44e13e10bba'),
      ('Mana Vault', '35e3fd94c8453c0e326033af49ae18c8', 'battle_rule_v1:5a2533694ffd19223d3cde1e25d258ff'),
      ('Mox Amber', 'e47b40cf2afc4c9ceac6bf91815da706', 'battle_rule_v1:972703914ee50acd7a4e6f529fea1adf'),
      ('Talisman of Conviction', 'd49ceec937367a344a9f0948eea4f8f2', 'battle_rule_v1:02133e513da5ea98ac74d32d39b16470')
  )
  SELECT
    count(*) FILTER (WHERE md5(coalesce(c.oracle_text, '')) = e.oracle_hash),
    count(*) FILTER (WHERE r.logical_rule_key = e.logical_rule_key),
    count(*) FILTER (WHERE r.logical_rule_key = e.logical_rule_key AND coalesce(r.oracle_hash, '') = '')
  INTO v_cards, v_rules, v_missing_hash
  FROM expected_cards e
  LEFT JOIN cards c ON c.name = e.name
  LEFT JOIN card_battle_rules r ON r.normalized_name = lower(e.name)
    AND r.logical_rule_key = e.logical_rule_key
    AND r.execution_status = 'auto';

  IF v_cards <> 4 THEN
    RAISE EXCEPTION 'PG073 PG055 mana rocks hash restore precondition failed: expected 4 target cards with current oracle hashes, got %', v_cards;
  END IF;
  IF v_rules <> 4 THEN
    RAISE EXCEPTION 'PG073 PG055 mana rocks hash restore precondition failed: expected 4 target runtime rules, got %', v_rules;
  END IF;
  IF v_missing_hash <> 4 THEN
    RAISE EXCEPTION 'PG073 PG055 mana rocks hash restore precondition failed: expected 4 missing hashes, got %', v_missing_hash;
  END IF;
END $$;

UPDATE card_battle_rules
SET
  oracle_hash = CASE normalized_name
    WHEN 'fellwar stone' THEN 'd63befc8ac40d9a38732f9b5c1a7414a'
    WHEN 'mana vault' THEN '35e3fd94c8453c0e326033af49ae18c8'
    WHEN 'mox amber' THEN 'e47b40cf2afc4c9ceac6bf91815da706'
    WHEN 'talisman of conviction' THEN 'd49ceec937367a344a9f0948eea4f8f2'
  END,
  reviewed_by = 'codex-auditor',
  reviewed_at = now(),
  updated_at = now(),
  last_seen_at = now(),
  notes = concat_ws(
    E'\n',
    nullif(notes, ''),
    'PG073 addendum: restored oracle_hash required by the PG055 artifact mana rock runtime provenance gate after broad PG sync exposed missing hash metadata; no effect_json semantic change.'
  )
WHERE (normalized_name, logical_rule_key) IN (
  ('fellwar stone', 'battle_rule_v1:3906ffa3cbf7d3437d68e44e13e10bba'),
  ('mana vault', 'battle_rule_v1:5a2533694ffd19223d3cde1e25d258ff'),
  ('mox amber', 'battle_rule_v1:972703914ee50acd7a4e6f529fea1adf'),
  ('talisman of conviction', 'battle_rule_v1:02133e513da5ea98ac74d32d39b16470')
)
AND execution_status = 'auto';

COMMIT;
