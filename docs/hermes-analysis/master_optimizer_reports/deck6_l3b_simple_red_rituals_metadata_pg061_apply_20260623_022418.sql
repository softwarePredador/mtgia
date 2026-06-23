-- PG061 Deck 6 L3B simple red rituals metadata confirmation apply.
-- Current-state/idempotent repair after PG060 aborted before a durable backup
-- table existed. Backs up current rows and reasserts the desired metadata.

BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

DO $$
BEGIN
  IF to_regclass('manaloom_deploy_audit.pg061_deck6_l3b_simple_red_rituals_metadata_20260623_022418') IS NOT NULL THEN
    RAISE EXCEPTION 'Backup table manaloom_deploy_audit.pg061_deck6_l3b_simple_red_rituals_metadata_20260623_022418 already exists';
  END IF;
END $$;

CREATE TABLE manaloom_deploy_audit.pg061_deck6_l3b_simple_red_rituals_metadata_20260623_022418 AS
SELECT *
FROM card_battle_rules
WHERE normalized_name IN ('rite of flame', 'seething song');

DO $$
DECLARE
  v_backup_rows integer;
BEGIN
  SELECT count(*) INTO v_backup_rows
  FROM manaloom_deploy_audit.pg061_deck6_l3b_simple_red_rituals_metadata_20260623_022418;

  IF v_backup_rows <> 5 THEN
    RAISE EXCEPTION 'PG061 precondition failed: backup_rows=% expected 5', v_backup_rows;
  END IF;
END $$;

WITH target_runtime(
  normalized_name,
  logical_rule_key,
  expected_hash,
  expected_mana,
  expected_scope,
  expected_runtime_scope,
  expected_mana_color_status,
  sorcery_flag,
  instant_flag,
  graveyard_named_copy_scaling_status,
  singleton_commander_baseline
) AS (
  VALUES
    ('rite of flame', 'battle_rule_v1:b66dd96fa32c9822c798f16a83fa5518', '35a034ee45b092bc443cd5992d8793f4', 2, 'rite_of_flame_singleton_baseline_red_ritual_v1', 'single_shot_red_ritual_runtime_graveyard_copy_scaling_annotation_only', 'abstracted_to_generic_pool_runtime', true, NULL::boolean, 'annotation_only'::text, true),
    ('seething song', 'battle_rule_v1:3eb15dc581c6b913158f9b63c023f3d7', 'ccd492289c6f1c14c8fb7a248d7bbf32', 5, 'single_shot_red_ritual_v1', 'single_shot_red_ritual_runtime_generic_pool_color_annotation', 'abstracted_to_generic_pool_runtime', NULL::boolean, true, NULL::text, NULL::boolean)
)
UPDATE card_battle_rules cbr
SET
  oracle_hash = tr.expected_hash,
  effect_json = jsonb_strip_nulls(
    coalesce(cbr.effect_json, '{}'::jsonb)
    || jsonb_build_object(
      'effect', 'ramp_ritual',
      'produces', 'R',
      'mana_produced', tr.expected_mana,
      'battle_model_scope', tr.expected_scope,
      'oracle_runtime_scope', tr.expected_runtime_scope,
      'mana_color_status', tr.expected_mana_color_status,
      'sorcery', tr.sorcery_flag,
      'instant', tr.instant_flag,
      'graveyard_named_copy_scaling_status', tr.graveyard_named_copy_scaling_status,
      'singleton_commander_baseline', tr.singleton_commander_baseline,
      'pg058_l3b_simple_red_ritual_family', 'deck6_simple_red_rituals'
    )
  ),
  reviewed_by = 'codex_pg061',
  reviewed_at = now(),
  updated_at = now(),
  last_seen_at = now(),
  notes = concat_ws(
    E'\n',
    nullif(cbr.notes, ''),
    'PG061 2026-06-23: Current-state backup plus idempotent reassertion of Deck 6 L3B simple-red-ritual metadata after PG060 aborted before backup. No executor or deck change.'
  )
FROM target_runtime tr
WHERE cbr.normalized_name = tr.normalized_name
  AND cbr.logical_rule_key = tr.logical_rule_key
  AND cbr.source = 'curated'
  AND cbr.review_status IN ('active', 'verified')
  AND cbr.execution_status = 'auto';

COMMIT;
