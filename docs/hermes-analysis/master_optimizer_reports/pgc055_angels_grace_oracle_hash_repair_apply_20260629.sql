BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

DO $$
BEGIN
  IF to_regclass('manaloom_deploy_audit.pgc055_angels_grace_oracle_hash_repair_20260629') IS NOT NULL THEN
    RAISE EXCEPTION 'PGC055 backup table already exists';
  END IF;
END $$;

CREATE TABLE manaloom_deploy_audit.pgc055_angels_grace_oracle_hash_repair_20260629 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name = 'angel''s grace'
  AND logical_rule_key = 'battle_rule_v1:2833836fd4d943d3e02d1cfa2d284227';

DO $$
DECLARE
  updated_count integer;
BEGIN
  WITH expected AS (
    SELECT
      'angel''s grace'::text AS normalized_name,
      'battle_rule_v1:2833836fd4d943d3e02d1cfa2d284227'::text AS logical_rule_key,
      '627c4ce7adf5be44b93e2b850159e5d9'::text AS expected_oracle_hash,
      md5(coalesce(c.oracle_text, '')) AS computed_oracle_hash,
      $json${
        "battle_model_scope": "split_second_cannot_lose_opponents_cannot_win_damage_life_floor_v1",
        "opponents_cant_win_this_turn": true,
        "oracle_runtime_scope": "cannot_lose_opponents_cannot_win_damage_life_floor_split_second_annotation",
        "split_second": true
      }$json$::jsonb AS effect_patch
    FROM public.cards c
    WHERE lower(c.name) = 'angel''s grace'
  )
  UPDATE public.card_battle_rules r
  SET
    oracle_hash = expected.expected_oracle_hash,
    effect_json = coalesce(r.effect_json, '{}'::jsonb) || expected.effect_patch,
    notes = concat_ws(
      E'\n',
      nullif(r.notes, ''),
      'PGC055: restored Angel''s Grace oracle_hash and runtime metadata after current PG -> Hermes sync drift.'
    ),
    updated_at = now(),
    last_seen_at = now()
  FROM expected
  WHERE r.normalized_name = expected.normalized_name
    AND r.logical_rule_key = expected.logical_rule_key
    AND expected.computed_oracle_hash = expected.expected_oracle_hash;

  GET DIAGNOSTICS updated_count = ROW_COUNT;
  IF updated_count <> 1 THEN
    RAISE EXCEPTION 'PGC055 expected to update 1 Angel''s Grace row, updated %', updated_count;
  END IF;
END $$;

COMMIT;
