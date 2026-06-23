BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE manaloom_deploy_audit.pg067_seething_song_runtime_metadata_20260623_032307 AS
SELECT now() AS backed_up_at, to_jsonb(cbr) AS payload
FROM card_battle_rules cbr
WHERE cbr.normalized_name = 'seething song'
  AND cbr.logical_rule_key = 'battle_rule_v1:3eb15dc581c6b913158f9b63c023f3d7';

DO $$
DECLARE
  v_bad integer;
BEGIN
  SELECT count(*)
  INTO v_bad
  FROM cards c
  JOIN card_battle_rules cbr ON cbr.card_id = c.id
  WHERE cbr.normalized_name = 'seething song'
    AND cbr.logical_rule_key = 'battle_rule_v1:3eb15dc581c6b913158f9b63c023f3d7'
    AND (
      md5(coalesce(c.oracle_text, '')) IS DISTINCT FROM 'ccd492289c6f1c14c8fb7a248d7bbf32'
      OR cbr.oracle_hash IS DISTINCT FROM 'ccd492289c6f1c14c8fb7a248d7bbf32'
      OR cbr.review_status NOT IN ('verified', 'active')
      OR cbr.execution_status NOT IN ('auto', 'executable')
      OR cbr.effect_json->>'effect' IS DISTINCT FROM 'ramp_ritual'
      OR cbr.effect_json->>'battle_model_scope' IS DISTINCT FROM 'single_shot_red_ritual_v1'
    );

  IF v_bad <> 0 THEN
    RAISE EXCEPTION 'PG067 precondition failed for Seething Song runtime row: bad=%', v_bad;
  END IF;
END $$;

UPDATE card_battle_rules
SET
  effect_json = effect_json || jsonb_build_object(
    'mana_color_status', 'abstracted_to_generic_pool_runtime'
  ),
  rule_version = greatest(rule_version, 2),
  reviewed_by = coalesce(reviewed_by, 'codex-auditor'),
  reviewed_at = coalesce(reviewed_at, now()),
  updated_at = now(),
  last_seen_at = now(),
  notes = concat_ws(
    E'\n',
    nullif(notes, ''),
    'PG067: recorded runtime color abstraction for Seething Song; replay adds one-shot mana to the generic pool while preserving oracle produces=R metadata.'
  )
WHERE normalized_name = 'seething song'
  AND logical_rule_key = 'battle_rule_v1:3eb15dc581c6b913158f9b63c023f3d7';

COMMIT;
