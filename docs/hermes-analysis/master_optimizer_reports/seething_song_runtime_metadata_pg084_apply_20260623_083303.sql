\pset pager off

BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

DO $$
BEGIN
  IF to_regclass('manaloom_deploy_audit.pg084_seething_song_runtime_metadata_20260623_083303') IS NOT NULL THEN
    RAISE EXCEPTION 'PG084 Seething Song metadata backup table already exists';
  END IF;
END $$;

CREATE TABLE manaloom_deploy_audit.pg084_seething_song_runtime_metadata_20260623_083303 AS
SELECT *
FROM card_battle_rules
WHERE normalized_name = 'seething song'
  AND logical_rule_key = 'battle_rule_v1:3eb15dc581c6b913158f9b63c023f3d7';

DO $$
DECLARE
  v_target integer;
  v_hash integer;
  v_missing integer;
BEGIN
  SELECT
    count(*),
    count(*) FILTER (WHERE cbr.oracle_hash = 'ccd492289c6f1c14c8fb7a248d7bbf32'),
    count(*) FILTER (
      WHERE cbr.effect_json->>'mana_color_status' IS DISTINCT FROM 'abstracted_to_generic_pool_runtime'
         OR cbr.effect_json->>'oracle_runtime_scope' IS DISTINCT FROM 'single_shot_red_ritual_runtime_generic_pool_color_annotation'
         OR cbr.effect_json->>'pg058_l3b_simple_red_ritual_family' IS DISTINCT FROM 'deck6_simple_red_rituals'
    )
  INTO v_target, v_hash, v_missing
  FROM card_battle_rules cbr
  WHERE cbr.normalized_name = 'seething song'
    AND cbr.logical_rule_key = 'battle_rule_v1:3eb15dc581c6b913158f9b63c023f3d7'
    AND cbr.review_status = 'verified'
    AND cbr.execution_status = 'auto';

  IF v_target <> 1 THEN
    RAISE EXCEPTION 'PG084 precondition failed: expected 1 Seething Song target, got %', v_target;
  END IF;
  IF v_hash <> 1 THEN
    RAISE EXCEPTION 'PG084 precondition failed: expected current Seething Song oracle hash, got %', v_hash;
  END IF;
  IF v_missing <> 1 THEN
    RAISE EXCEPTION 'PG084 precondition failed: expected 1 metadata-deficient row, got %', v_missing;
  END IF;
END $$;

UPDATE card_battle_rules
SET
  effect_json = effect_json || jsonb_build_object(
    'mana_color_status', 'abstracted_to_generic_pool_runtime',
    'oracle_runtime_scope', 'single_shot_red_ritual_runtime_generic_pool_color_annotation',
    'pg058_l3b_simple_red_ritual_family', 'deck6_simple_red_rituals'
  ),
  rule_version = greatest(rule_version, 2),
  reviewed_by = 'codex-auditor',
  reviewed_at = now(),
  updated_at = now(),
  last_seen_at = now(),
  notes = concat_ws(E'\n', nullif(notes, ''), 'PG084: restored Seething Song red-mana runtime metadata after broad PG sync exposed missing mana_color_status/oracle_runtime_scope; no executor or deck change.')
WHERE normalized_name = 'seething song'
  AND logical_rule_key = 'battle_rule_v1:3eb15dc581c6b913158f9b63c023f3d7'
  AND review_status = 'verified'
  AND execution_status = 'auto';

COMMIT;
