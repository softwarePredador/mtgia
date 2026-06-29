BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

DO $$
BEGIN
  IF to_regclass('manaloom_deploy_audit.pgc056_pinnacle_monk_mdfc_land_face_20260629') IS NOT NULL THEN
    RAISE EXCEPTION 'PGC056 backup table already exists';
  END IF;
END $$;

CREATE TABLE manaloom_deploy_audit.pgc056_pinnacle_monk_mdfc_land_face_20260629 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name = 'pinnacle monk // mystic peak'
  AND logical_rule_key = 'battle_rule_v1:bcde63b5e56f2b9f20af6384bc70ad5d';

DO $$
DECLARE
  updated_count integer;
BEGIN
  UPDATE public.card_battle_rules r
  SET
    effect_json = r.effect_json || $json${
      "back_face_land_status": "runtime_executor_v1",
      "battle_model_scope": "front_creature_prowess_etb_return_instant_or_sorcery_graveyard_to_hand_mdfc_red_land_life_payment_runtime_v1",
      "oracle_runtime_scope": "front_creature_etb_return_instant_or_sorcery_and_mystic_peak_red_land_pay_three_life_etb_runtime_v1",
      "mdfc_land_face": {
        "name": "Mystic Peak",
        "effect": "land",
        "type_line": "Land",
        "produces": "R",
        "mana_produced": 1,
        "enters_tapped_unless_pay_life": 3,
        "enters_tapped_unless_pay_life_status": "runtime_executor_v1",
        "battle_model_scope": "mystic_peak_red_land_pay_three_life_or_enter_tapped_runtime_v1"
      }
    }$json$::jsonb,
    rule_version = greatest(r.rule_version + 1, 3),
    reviewed_by = 'codex-pgc056',
    reviewed_at = now(),
    updated_at = now(),
    last_seen_at = now(),
    notes = concat_ws(
      E'\n',
      nullif(r.notes, ''),
      'PGC056: promoted Pinnacle Monk // Mystic Peak MDFC land face from annotation_only to runtime_executor_v1 after Scryfall/XMage audit.'
    )
  WHERE r.normalized_name = 'pinnacle monk // mystic peak'
    AND r.logical_rule_key = 'battle_rule_v1:bcde63b5e56f2b9f20af6384bc70ad5d'
    AND r.review_status = 'verified'
    AND r.execution_status = 'auto'
    AND r.oracle_hash = 'aa1967461796c715e0c5e0b4d741f249';

  GET DIAGNOSTICS updated_count = ROW_COUNT;
  IF updated_count <> 1 THEN
    RAISE EXCEPTION 'PGC056 expected to update 1 Pinnacle Monk row, updated %', updated_count;
  END IF;
END $$;

COMMIT;
