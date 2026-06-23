BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

DO $$
BEGIN
  IF to_regclass('manaloom_deploy_audit.pg073_pg058_seething_song_metadata_restore_20260623_052954') IS NOT NULL THEN
    RAISE EXCEPTION 'PG073 PG058 Seething Song metadata restore backup table already exists';
  END IF;
END $$;

CREATE TABLE manaloom_deploy_audit.pg073_pg058_seething_song_metadata_restore_20260623_052954 AS
SELECT now() AS backed_up_at, to_jsonb(cbr) AS payload
FROM card_battle_rules cbr
WHERE cbr.normalized_name = 'seething song'
  AND cbr.logical_rule_key = 'battle_rule_v1:3eb15dc581c6b913158f9b63c023f3d7';

DO $$
DECLARE
  v_card integer;
  v_rule integer;
  v_missing_metadata integer;
BEGIN
  SELECT count(*)
  INTO v_card
  FROM cards
  WHERE name = 'Seething Song'
    AND md5(coalesce(oracle_text, '')) = 'ccd492289c6f1c14c8fb7a248d7bbf32';

  SELECT count(*)
  INTO v_rule
  FROM card_battle_rules
  WHERE normalized_name = 'seething song'
    AND logical_rule_key = 'battle_rule_v1:3eb15dc581c6b913158f9b63c023f3d7'
    AND execution_status = 'auto'
    AND oracle_hash = 'ccd492289c6f1c14c8fb7a248d7bbf32';

  SELECT count(*)
  INTO v_missing_metadata
  FROM card_battle_rules
  WHERE normalized_name = 'seething song'
    AND logical_rule_key = 'battle_rule_v1:3eb15dc581c6b913158f9b63c023f3d7'
    AND execution_status = 'auto'
    AND (
      effect_json->>'mana_color_status' IS DISTINCT FROM 'abstracted_to_generic_pool_runtime'
      OR effect_json->>'oracle_runtime_scope' IS DISTINCT FROM 'single_shot_red_ritual_runtime_generic_pool_color_annotation'
      OR effect_json->>'pg058_l3b_simple_red_ritual_family' IS DISTINCT FROM 'deck6_simple_red_rituals'
    );

  IF v_card <> 1 THEN
    RAISE EXCEPTION 'PG073 PG058 Seething Song metadata restore precondition failed: expected 1 target card with current oracle hash, got %', v_card;
  END IF;
  IF v_rule <> 1 THEN
    RAISE EXCEPTION 'PG073 PG058 Seething Song metadata restore precondition failed: expected 1 target runtime row with current oracle hash, got %', v_rule;
  END IF;
  IF v_missing_metadata <> 1 THEN
    RAISE EXCEPTION 'PG073 PG058 Seething Song metadata restore precondition failed: expected 1 metadata-deficient row, got %', v_missing_metadata;
  END IF;
END $$;

UPDATE card_battle_rules
SET
  effect_json = coalesce(effect_json, '{}'::jsonb) || jsonb_build_object(
    'effect', 'ramp_ritual',
    'instant', true,
    'produces', 'R',
    'mana_produced', 5,
    'battle_model_scope', 'single_shot_red_ritual_v1',
    'mana_color_status', 'abstracted_to_generic_pool_runtime',
    'oracle_runtime_scope', 'single_shot_red_ritual_runtime_generic_pool_color_annotation',
    'pg058_l3b_simple_red_ritual_family', 'deck6_simple_red_rituals'
  ),
  reviewed_by = 'codex-auditor',
  reviewed_at = now(),
  updated_at = now(),
  last_seen_at = now(),
  notes = concat_ws(
    E'\n',
    nullif(notes, ''),
    'PG073 addendum: restored PG058/PG061/PG067 Seething Song runtime metadata after broad PG sync exposed mana_color_status/oracle_runtime_scope regression; no executor or deck change.'
  )
WHERE normalized_name = 'seething song'
  AND logical_rule_key = 'battle_rule_v1:3eb15dc581c6b913158f9b63c023f3d7'
  AND execution_status = 'auto';

COMMIT;
