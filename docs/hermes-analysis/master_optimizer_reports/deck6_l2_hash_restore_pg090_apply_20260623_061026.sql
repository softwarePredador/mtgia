BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

DO $$
BEGIN
  IF to_regclass('manaloom_deploy_audit.pg090_deck6_l2_hash_restore_20260623_061026') IS NOT NULL THEN
    RAISE EXCEPTION 'backup table manaloom_deploy_audit.pg090_deck6_l2_hash_restore_20260623_061026 already exists';
  END IF;
END $$;

CREATE TEMP TABLE pg090_deck6_l2_hash_target (
  normalized_name text,
  logical_rule_key text,
  expected_oracle_hash text
);

INSERT INTO pg090_deck6_l2_hash_target VALUES
  ('scroll rack', 'battle_rule_v1:3b58ff16a7eb52fb05c1bd8517225cd2', '8133928f03d5a5a77f2beecfcbd09e30'),
  ('silence', 'battle_rule_v1:74b210b77b004a677906e0216d44e445', 'a0ca3c09a7db091c435ab31adb9c1780'),
  ('fellwar stone', 'battle_rule_v1:3906ffa3cbf7d3437d68e44e13e10bba', 'd63befc8ac40d9a38732f9b5c1a7414a'),
  ('mana vault', 'battle_rule_v1:5a2533694ffd19223d3cde1e25d258ff', '35e3fd94c8453c0e326033af49ae18c8'),
  ('mox amber', 'battle_rule_v1:972703914ee50acd7a4e6f529fea1adf', 'e47b40cf2afc4c9ceac6bf91815da706'),
  ('seething song', 'battle_rule_v1:3eb15dc581c6b913158f9b63c023f3d7', 'ccd492289c6f1c14c8fb7a248d7bbf32'),
  ('talisman of conviction', 'battle_rule_v1:02133e513da5ea98ac74d32d39b16470', 'd49ceec937367a344a9f0948eea4f8f2'),
  ('unexpected windfall', 'battle_rule_v1:f9f98ea1925518eea7a7c94c21ef2dc4', '9c4fbe06104051a2e8b1d295d307b26a'),
  ('valakut awakening // valakut stoneforge', 'battle_rule_v1:6e1f3b876822abafe1de47610f46858d', '22b42fcc181b7aed71f78b2e1e51e887');

DO $$
DECLARE
  target_count integer;
  hash_match_count integer;
  trusted_count integer;
  missing_hash_count integer;
  scoped_count integer;
BEGIN
  SELECT count(*) INTO target_count FROM pg090_deck6_l2_hash_target;

  SELECT count(*) INTO hash_match_count
  FROM pg090_deck6_l2_hash_target t
  JOIN cards c ON lower(c.name) = t.normalized_name
  WHERE md5(coalesce(c.oracle_text, '')) = t.expected_oracle_hash;

  SELECT count(*) INTO trusted_count
  FROM pg090_deck6_l2_hash_target t
  JOIN card_battle_rules r
    ON r.normalized_name = t.normalized_name
   AND r.logical_rule_key = t.logical_rule_key
  WHERE r.execution_status = 'auto'
    AND r.review_status IN ('active', 'verified');

  SELECT count(*) INTO missing_hash_count
  FROM pg090_deck6_l2_hash_target t
  JOIN card_battle_rules r
    ON r.normalized_name = t.normalized_name
   AND r.logical_rule_key = t.logical_rule_key
  WHERE r.oracle_hash IS NULL;

  SELECT count(*) INTO scoped_count
  FROM pg090_deck6_l2_hash_target t
  JOIN card_battle_rules r
    ON r.normalized_name = t.normalized_name
   AND r.logical_rule_key = t.logical_rule_key
  WHERE r.effect_json ? 'battle_model_scope';

  IF target_count <> 9 OR hash_match_count <> 9 OR trusted_count <> 9 OR missing_hash_count <> 9 OR scoped_count <> 9 THEN
    RAISE EXCEPTION 'PG090 precondition failed target=% hash_match=% trusted=% missing_hash=% scoped=%',
      target_count, hash_match_count, trusted_count, missing_hash_count, scoped_count;
  END IF;
END $$;

CREATE TABLE manaloom_deploy_audit.pg090_deck6_l2_hash_restore_20260623_061026 AS
SELECT r.*
FROM card_battle_rules r
JOIN pg090_deck6_l2_hash_target t
  ON r.normalized_name = t.normalized_name
 AND r.logical_rule_key = t.logical_rule_key;

UPDATE card_battle_rules r
SET
  oracle_hash = t.expected_oracle_hash,
  rule_version = greatest(coalesce(r.rule_version, 1), 2),
  reviewed_by = 'codex-pg090',
  reviewed_at = now(),
  updated_at = now(),
  notes = concat_ws(E'\n', nullif(r.notes, ''), 'PG090 2026-06-23: Deck 6 L2 hash-only restore from raw oracle_text md5 after PostgreSQL-source sync exposed missing oracle_hash; no semantic/runtime change.')
FROM pg090_deck6_l2_hash_target t
WHERE r.normalized_name = t.normalized_name
  AND r.logical_rule_key = t.logical_rule_key;

COMMIT;
