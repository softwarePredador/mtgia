BEGIN;

DO $$
DECLARE
  v_backup_exists boolean;
  v_bad integer;
BEGIN
  SELECT to_regclass('manaloom_deploy_audit.pg070_deck6_l2_hash_only_runtime_rules_20260623_011859') IS NOT NULL
  INTO v_backup_exists;

  IF NOT v_backup_exists THEN
    RAISE EXCEPTION 'PG070 addendum precondition failed: backup table is missing';
  END IF;

  SELECT count(*)
  INTO v_bad
  FROM card_battle_rules
  WHERE normalized_name = 'seething song'
    AND logical_rule_key = 'battle_rule_v1:3eb15dc581c6b913158f9b63c023f3d7'
    AND (
      oracle_hash IS DISTINCT FROM 'ccd492289c6f1c14c8fb7a248d7bbf32'
      OR effect_json->>'effect' IS DISTINCT FROM 'ramp_ritual'
      OR effect_json->>'battle_model_scope' IS DISTINCT FROM 'single_shot_red_ritual_v1'
    );

  IF v_bad <> 0 THEN
    RAISE EXCEPTION 'PG070 addendum precondition failed: Seething Song runtime row not in expected hash/scope state';
  END IF;
END $$;

UPDATE card_battle_rules
SET
  effect_json = effect_json || jsonb_build_object(
    'mana_color_status', 'abstracted_to_generic_pool_runtime',
    'oracle_runtime_scope', 'single_shot_red_ritual_runtime_generic_pool_color_annotation',
    'pg058_l3b_simple_red_ritual_family', 'deck6_simple_red_rituals'
  ),
  updated_at = now(),
  last_seen_at = now(),
  notes = concat_ws(
    E'\n',
    nullif(notes, ''),
    'PG070 addendum: restored PG058/PG059 Seething Song red-mana metadata after hash-only cleanup exposed the missing runtime annotation.'
  )
WHERE normalized_name = 'seething song'
  AND logical_rule_key = 'battle_rule_v1:3eb15dc581c6b913158f9b63c023f3d7';

COMMIT;
