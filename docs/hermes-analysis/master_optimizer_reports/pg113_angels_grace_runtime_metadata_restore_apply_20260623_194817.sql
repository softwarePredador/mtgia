\pset pager off

BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

DO $$
BEGIN
  IF to_regclass('manaloom_deploy_audit.pg113_angels_grace_runtime_metadata_restore_20260623_194817') IS NOT NULL THEN
    RAISE EXCEPTION 'PG113 abort: backup table already exists';
  END IF;
END $$;

CREATE TABLE manaloom_deploy_audit.pg113_angels_grace_runtime_metadata_restore_20260623_194817 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name = 'angel''s grace'
  AND logical_rule_key = 'battle_rule_v1:2833836fd4d943d3e02d1cfa2d284227';

DO $$
DECLARE
  v_target integer;
  v_card_hash integer;
  v_deficient integer;
BEGIN
  SELECT
    count(*),
    count(*) FILTER (WHERE md5(coalesce(c.oracle_text, '')) = '627c4ce7adf5be44b93e2b850159e5d9'),
    count(*) FILTER (
      WHERE nullif(r.oracle_hash, '') IS NULL
         OR r.effect_json->>'battle_model_scope' IS DISTINCT FROM 'split_second_cannot_lose_opponents_cannot_win_damage_life_floor_v1'
         OR r.effect_json->>'oracle_runtime_scope' IS DISTINCT FROM 'cannot_lose_opponents_cannot_win_damage_life_floor_split_second_annotation'
         OR r.effect_json->>'split_second' IS DISTINCT FROM 'true'
         OR r.effect_json->>'opponents_cant_win_this_turn' IS DISTINCT FROM 'true'
    )
  INTO v_target, v_card_hash, v_deficient
  FROM public.card_battle_rules r
  JOIN public.cards c ON lower(c.name) = r.normalized_name
  WHERE r.normalized_name = 'angel''s grace'
    AND r.logical_rule_key = 'battle_rule_v1:2833836fd4d943d3e02d1cfa2d284227'
    AND r.review_status = 'verified'
    AND r.execution_status = 'auto'
    AND r.source = 'curated'
    AND r.effect_json->>'effect' = 'cannot_lose_turn'
    AND (r.effect_json->>'life_floor_on_damage')::numeric = 1;

  IF v_target <> 1 THEN
    RAISE EXCEPTION 'PG113 abort: expected 1 trusted Angel''s Grace target, got %', v_target;
  END IF;
  IF v_card_hash <> 1 THEN
    RAISE EXCEPTION 'PG113 abort: expected current Angel''s Grace card oracle hash, got %', v_card_hash;
  END IF;
  IF v_deficient <> 1 THEN
    RAISE EXCEPTION 'PG113 abort: expected 1 metadata-deficient row, got %', v_deficient;
  END IF;
END $$;

WITH patched AS (
  UPDATE public.card_battle_rules r
  SET
    oracle_hash = '627c4ce7adf5be44b93e2b850159e5d9',
    confidence = 0.970,
    effect_json = coalesce(r.effect_json, '{}'::jsonb) || jsonb_build_object(
      'battle_model_scope', 'split_second_cannot_lose_opponents_cannot_win_damage_life_floor_v1',
      'oracle_runtime_scope', 'cannot_lose_opponents_cannot_win_damage_life_floor_split_second_annotation',
      'split_second', true,
      'opponents_cant_win_this_turn', true,
      'life_floor_on_damage', 1,
      'instant', true,
      'cmc', 1,
      'effect', 'cannot_lose_turn'
    ),
    rule_version = greatest(r.rule_version, 2),
    reviewed_by = 'codex-pg113',
    reviewed_at = now(),
    updated_at = now(),
    last_seen_at = now(),
    notes = concat_ws(E'\n', nullif(r.notes, ''), 'PG113: restored Angel''s Grace oracle_hash/runtime metadata after PG112 full-suite attempt exposed PG086 drift; no executor, deck_cards, or deck composition change.')
  WHERE r.normalized_name = 'angel''s grace'
    AND r.logical_rule_key = 'battle_rule_v1:2833836fd4d943d3e02d1cfa2d284227'
    AND r.review_status = 'verified'
    AND r.execution_status = 'auto'
    AND r.source = 'curated'
  RETURNING r.*
)
SELECT count(*) AS patched_rows
FROM patched;

COMMIT;
