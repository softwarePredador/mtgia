BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

DO $$
BEGIN
  IF to_regclass('manaloom_deploy_audit.pg075_deck6_seething_song_metadata_20260623_053046') IS NOT NULL THEN
    RAISE EXCEPTION 'PG075 backup table already exists';
  END IF;
END $$;

CREATE TABLE manaloom_deploy_audit.pg075_deck6_seething_song_metadata_20260623_053046 AS
SELECT now() AS backed_up_at, to_jsonb(cbr) AS payload
FROM card_battle_rules cbr
WHERE cbr.normalized_name = 'seething song'
  AND cbr.logical_rule_key = 'battle_rule_v1:3eb15dc581c6b913158f9b63c023f3d7';

DO $$
DECLARE
  v_rules integer;
BEGIN
  SELECT count(*)
  INTO v_rules
  FROM card_battle_rules cbr
  JOIN cards c ON c.id = cbr.card_id
  WHERE cbr.normalized_name = 'seething song'
    AND cbr.logical_rule_key = 'battle_rule_v1:3eb15dc581c6b913158f9b63c023f3d7'
    AND cbr.oracle_hash = md5(coalesce(c.oracle_text, ''))
    AND cbr.effect_json->>'battle_model_scope' = 'single_shot_red_ritual_v1';

  IF v_rules <> 1 THEN
    RAISE EXCEPTION 'PG075 precondition failed: expected current hashed Seething Song single-shot ritual row, got %', v_rules;
  END IF;
END $$;

UPDATE card_battle_rules
SET
  effect_json = effect_json || jsonb_build_object(
    'produces', 'R',
    'mana_color_status', 'abstracted_to_generic_pool_runtime'
  ),
  updated_at = now(),
  last_seen_at = now(),
  notes = concat_ws(
    E'\n',
    nullif(notes, ''),
    'PG075: restored Seething Song red-mana annotation metadata required by the ritual provenance harness; no executor semantic change.'
  )
WHERE normalized_name = 'seething song'
  AND logical_rule_key = 'battle_rule_v1:3eb15dc581c6b913158f9b63c023f3d7';

COMMIT;
