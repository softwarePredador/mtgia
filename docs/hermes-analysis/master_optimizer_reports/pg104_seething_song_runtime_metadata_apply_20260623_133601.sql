BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE manaloom_deploy_audit.pg104_seething_song_runtime_metadata_20260623_133601 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name = 'seething song'
  AND logical_rule_key = 'battle_rule_v1:3eb15dc581c6b913158f9b63c023f3d7';

DO $$
DECLARE
  v_bad integer;
BEGIN
  SELECT count(*)
    INTO v_bad
  FROM public.card_battle_rules r
  JOIN public.cards c ON lower(c.name) = r.normalized_name
  WHERE r.normalized_name = 'seething song'
    AND r.logical_rule_key = 'battle_rule_v1:3eb15dc581c6b913158f9b63c023f3d7'
    AND (
      r.review_status <> 'verified'
      OR r.execution_status <> 'auto'
      OR r.source <> 'curated'
      OR (
        nullif(r.oracle_hash, '') IS NOT NULL
        AND r.oracle_hash <> 'ccd492289c6f1c14c8fb7a248d7bbf32'
      )
      OR md5(coalesce(c.oracle_text, '')) <> 'ccd492289c6f1c14c8fb7a248d7bbf32'
    );

  IF v_bad <> 0 THEN
    RAISE EXCEPTION 'PG104 abort: Seething Song trusted runtime row precondition failed, bad rows %', v_bad;
  END IF;
END $$;

WITH patched AS (
  UPDATE public.card_battle_rules r
  SET
    effect_json = r.effect_json || '{"mana_color_status":"abstracted_to_generic_pool_runtime","oracle_runtime_scope":"single_shot_red_ritual_runtime_generic_pool_color_annotation","pg058_l3b_simple_red_ritual_family":"deck6_simple_red_rituals"}'::jsonb,
    oracle_hash = 'ccd492289c6f1c14c8fb7a248d7bbf32',
    notes = concat_ws(
      E'\n',
      nullif(r.notes, ''),
      'PG104: restored Seething Song oracle_hash/runtime metadata after PG sync drift; semantic executor remains ramp_ritual/single_shot_red_ritual_v1.'
    ),
    reviewed_by = 'codex-pg104',
    reviewed_at = now(),
    updated_at = now(),
    last_seen_at = now()
  WHERE r.normalized_name = 'seething song'
    AND r.logical_rule_key = 'battle_rule_v1:3eb15dc581c6b913158f9b63c023f3d7'
  RETURNING r.*
)
SELECT count(*) AS patched_rows
FROM patched;

COMMIT;
