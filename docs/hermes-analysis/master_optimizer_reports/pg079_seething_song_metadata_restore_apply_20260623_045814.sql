BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

DO $$
BEGIN
  IF to_regclass('manaloom_deploy_audit.pg079_seething_song_metadata_restore_20260623_045814') IS NOT NULL THEN
    RAISE EXCEPTION 'PG079 Seething Song metadata restore backup table already exists';
  END IF;
END $$;

CREATE TABLE manaloom_deploy_audit.pg079_seething_song_metadata_restore_20260623_045814 AS
SELECT now() AS backed_up_at, to_jsonb(cbr) AS payload
FROM card_battle_rules cbr
WHERE cbr.normalized_name = 'seething song'
  AND cbr.logical_rule_key = 'battle_rule_v1:3eb15dc581c6b913158f9b63c023f3d7';

DO $$
DECLARE
  v_target integer;
BEGIN
  SELECT count(*)
  INTO v_target
  FROM card_battle_rules cbr
  JOIN cards c ON c.id = cbr.card_id
  WHERE cbr.normalized_name = 'seething song'
    AND cbr.logical_rule_key = 'battle_rule_v1:3eb15dc581c6b913158f9b63c023f3d7'
    AND cbr.review_status = 'verified'
    AND cbr.execution_status = 'auto'
    AND cbr.oracle_hash = md5(coalesce(c.oracle_text, ''));

  IF v_target <> 1 THEN
    RAISE EXCEPTION 'PG079 Seething Song precondition failed: expected one verified auto hash-matched target row, got %', v_target;
  END IF;
END $$;

DO $$
DECLARE
  v_updated integer;
BEGIN
  WITH updated AS (
    UPDATE card_battle_rules cbr
    SET
      effect_json = cbr.effect_json
        || '{"mana_color_status":"abstracted_to_generic_pool_runtime","oracle_runtime_scope":"single_shot_red_ritual_runtime_generic_pool_color_annotation","pg058_l3b_simple_red_ritual_family":"deck6_simple_red_rituals"}'::jsonb,
      reviewed_by = 'codex-auditor',
      reviewed_at = now(),
      updated_at = now(),
      last_seen_at = now(),
      notes = concat_ws(
        E'\n',
        nullif(cbr.notes, ''),
        'PG079 addendum: restored Seething Song PG058 simple-red-ritual metadata required by runtime provenance tests. No deck composition change.'
      )
    WHERE cbr.normalized_name = 'seething song'
      AND cbr.logical_rule_key = 'battle_rule_v1:3eb15dc581c6b913158f9b63c023f3d7'
    RETURNING 1
  )
  SELECT count(*) INTO v_updated FROM updated;

  IF v_updated <> 1 THEN
    RAISE EXCEPTION 'PG079 Seething Song metadata update failed: expected 1 updated row, got %', v_updated;
  END IF;
END $$;

COMMIT;
