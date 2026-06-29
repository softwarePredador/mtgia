BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

DO $$
BEGIN
  IF to_regclass('manaloom_deploy_audit.pgc059_deck607_active_nonland_oracle_hash_backfill_20260629') IS NOT NULL THEN
    RAISE EXCEPTION 'PGC059 backup table already exists';
  END IF;
END $$;

CREATE TABLE manaloom_deploy_audit.pgc059_deck607_active_nonland_oracle_hash_backfill_20260629 AS
WITH expected(normalized_name, logical_rule_key, expected_oracle_hash) AS (
  VALUES
    ('fellwar stone', 'battle_rule_v1:3906ffa3cbf7d3437d68e44e13e10bba', 'd63befc8ac40d9a38732f9b5c1a7414a'),
    ('library of leng', 'battle_rule_v1:b6491cf6f7d7df9a3fb0d91abd3d31c3', '575aef3cc2523831e440ea7dcd55fa6e'),
    ('scroll rack', 'battle_rule_v1:3b58ff16a7eb52fb05c1bd8517225cd2', '8133928f03d5a5a77f2beecfcbd09e30'),
    ('talisman of conviction', 'battle_rule_v1:02133e513da5ea98ac74d32d39b16470', 'd49ceec937367a344a9f0948eea4f8f2'),
    ('unexpected windfall', 'battle_rule_v1:f9f98ea1925518eea7a7c94c21ef2dc4', '9c4fbe06104051a2e8b1d295d307b26a')
)
SELECT r.*
FROM public.card_battle_rules r
JOIN expected e
  ON r.normalized_name = e.normalized_name
 AND r.logical_rule_key = e.logical_rule_key;

DO $$
DECLARE
  updated_count integer;
BEGIN
  WITH expected(normalized_name, logical_rule_key, expected_oracle_hash) AS (
    VALUES
      ('fellwar stone', 'battle_rule_v1:3906ffa3cbf7d3437d68e44e13e10bba', 'd63befc8ac40d9a38732f9b5c1a7414a'),
      ('library of leng', 'battle_rule_v1:b6491cf6f7d7df9a3fb0d91abd3d31c3', '575aef3cc2523831e440ea7dcd55fa6e'),
      ('scroll rack', 'battle_rule_v1:3b58ff16a7eb52fb05c1bd8517225cd2', '8133928f03d5a5a77f2beecfcbd09e30'),
      ('talisman of conviction', 'battle_rule_v1:02133e513da5ea98ac74d32d39b16470', 'd49ceec937367a344a9f0948eea4f8f2'),
      ('unexpected windfall', 'battle_rule_v1:f9f98ea1925518eea7a7c94c21ef2dc4', '9c4fbe06104051a2e8b1d295d307b26a')
  ),
  checked AS (
    SELECT
      e.normalized_name,
      e.logical_rule_key,
      e.expected_oracle_hash
    FROM expected e
    JOIN public.card_battle_rules r
      ON r.normalized_name = e.normalized_name
     AND r.logical_rule_key = e.logical_rule_key
    JOIN public.cards c
      ON c.id = r.card_id
    WHERE md5(coalesce(c.oracle_text, '')) = e.expected_oracle_hash
      AND r.review_status IN ('verified', 'active')
      AND r.execution_status IN ('auto', 'executable')
      AND r.rule_version >= 2
  )
  UPDATE public.card_battle_rules r
  SET
    oracle_hash = checked.expected_oracle_hash,
    notes = concat_ws(
      E'\n',
      nullif(r.notes, ''),
      'PGC059: filled deck 607 active nonland oracle_hash from md5(cards.oracle_text); behavior unchanged.'
    ),
    updated_at = now(),
    last_seen_at = now()
  FROM checked
  WHERE r.normalized_name = checked.normalized_name
    AND r.logical_rule_key = checked.logical_rule_key;

  GET DIAGNOSTICS updated_count = ROW_COUNT;
  IF updated_count <> 5 THEN
    RAISE EXCEPTION 'PGC059 expected to update 5 active deck 607 nonland rows, updated %', updated_count;
  END IF;
END $$;

COMMIT;
