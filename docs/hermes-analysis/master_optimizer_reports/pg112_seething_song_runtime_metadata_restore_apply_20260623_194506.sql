\pset pager off

BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

DO $$
BEGIN
  IF to_regclass('manaloom_deploy_audit.pg112_seething_song_runtime_metadata_restore_20260623_194506') IS NOT NULL THEN
    RAISE EXCEPTION 'PG112 abort: backup table already exists';
  END IF;
END $$;

CREATE TABLE manaloom_deploy_audit.pg112_seething_song_runtime_metadata_restore_20260623_194506 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name = 'seething song'
  AND logical_rule_key = 'battle_rule_v1:3eb15dc581c6b913158f9b63c023f3d7';

DO $$
DECLARE
  v_target integer;
  v_card_hash integer;
  v_deficient integer;
BEGIN
  SELECT
    count(*),
    count(*) FILTER (WHERE md5(coalesce(c.oracle_text, '')) = 'ccd492289c6f1c14c8fb7a248d7bbf32'),
    count(*) FILTER (
      WHERE nullif(r.oracle_hash, '') IS NULL
         OR r.effect_json->>'mana_color_status' IS DISTINCT FROM 'abstracted_to_generic_pool_runtime'
         OR r.effect_json->>'oracle_runtime_scope' IS DISTINCT FROM 'single_shot_red_ritual_runtime_generic_pool_color_annotation'
         OR r.effect_json->>'pg058_l3b_simple_red_ritual_family' IS DISTINCT FROM 'deck6_simple_red_rituals'
    )
  INTO v_target, v_card_hash, v_deficient
  FROM public.card_battle_rules r
  JOIN public.cards c ON lower(c.name) = r.normalized_name
  WHERE r.normalized_name = 'seething song'
    AND r.logical_rule_key = 'battle_rule_v1:3eb15dc581c6b913158f9b63c023f3d7'
    AND r.review_status = 'verified'
    AND r.execution_status = 'auto'
    AND r.source = 'curated'
    AND r.effect_json->>'effect' = 'ramp_ritual'
    AND r.effect_json->>'battle_model_scope' = 'single_shot_red_ritual_v1'
    AND r.effect_json->>'produces' = 'R'
    AND (r.effect_json->>'mana_produced')::numeric = 5;

  IF v_target <> 1 THEN
    RAISE EXCEPTION 'PG112 abort: expected 1 trusted Seething Song target, got %', v_target;
  END IF;
  IF v_card_hash <> 1 THEN
    RAISE EXCEPTION 'PG112 abort: expected current Seething Song card oracle hash, got %', v_card_hash;
  END IF;
  IF v_deficient <> 1 THEN
    RAISE EXCEPTION 'PG112 abort: expected 1 metadata-deficient row, got %', v_deficient;
  END IF;
END $$;

WITH patched AS (
  UPDATE public.card_battle_rules r
  SET
    oracle_hash = 'ccd492289c6f1c14c8fb7a248d7bbf32',
    effect_json = coalesce(r.effect_json, '{}'::jsonb) || jsonb_build_object(
      'mana_color_status', 'abstracted_to_generic_pool_runtime',
      'oracle_runtime_scope', 'single_shot_red_ritual_runtime_generic_pool_color_annotation',
      'pg058_l3b_simple_red_ritual_family', 'deck6_simple_red_rituals'
    ),
    rule_version = greatest(r.rule_version, 2),
    reviewed_by = 'codex-pg112',
    reviewed_at = now(),
    updated_at = now(),
    last_seen_at = now(),
    notes = concat_ws(E'\n', nullif(r.notes, ''), 'PG112: restored Seething Song red-mana runtime metadata and oracle_hash after PG111 full-suite attempt exposed PG058 drift; no executor, deck_cards, or deck composition change.')
  WHERE r.normalized_name = 'seething song'
    AND r.logical_rule_key = 'battle_rule_v1:3eb15dc581c6b913158f9b63c023f3d7'
    AND r.review_status = 'verified'
    AND r.execution_status = 'auto'
    AND r.source = 'curated'
  RETURNING r.*
)
SELECT count(*) AS patched_rows
FROM patched;

COMMIT;
