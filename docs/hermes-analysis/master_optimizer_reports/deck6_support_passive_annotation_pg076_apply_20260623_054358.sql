BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

DO $$
BEGIN
  IF to_regclass('manaloom_deploy_audit.pg076_deck6_support_passive_annotation_20260623_054358') IS NOT NULL THEN
    RAISE EXCEPTION 'Backup table manaloom_deploy_audit.pg076_deck6_support_passive_annotation_20260623_054358 already exists';
  END IF;
END $$;

CREATE TEMP TABLE pg076_target_patch AS
SELECT *
FROM (
  VALUES
    (
      'Drannith Magistrate',
      'battle_rule_v1:673c58ea36aeaf798d78aaaa10892e3e',
      '{"battle_model_scope":"static_nonhand_cast_restriction_annotation_creature_body_v1","oracle_runtime_scope":"creature_body_runtime_static_nonhand_cast_lock_annotation","static_ability_status":"annotation_only","opponents_cant_cast_from_nonhand_zones":true,"runtime_modeled_effect":"creature_body_only"}'::jsonb,
      '{"category":"stax","functions":["creature_body","static_cast_restriction"],"annotation_only":["opponents_cant_cast_from_nonhand_zones"]}'::jsonb,
      'PG076: added current oracle_hash and scoped static non-hand cast restriction annotation; runtime remains creature body only.'
    ),
    (
      'Giver of Runes',
      'battle_rule_v1:c2736795c0d2c41d771b8a87319618bc',
      '{"battle_model_scope":"creature_body_protection_activation_annotation_v1","oracle_runtime_scope":"creature_body_runtime_protection_activation_annotation","activated_protection_status":"annotation_only","tap_activation":true,"protection_target":"another_creature_you_control","protection_choices":["colorless","chosen_color"],"duration":"until_end_of_turn","runtime_modeled_effect":"creature_body_only"}'::jsonb,
      '{"category":"protection","functions":["creature_body","activated_protection"],"annotation_only":["protection_activation"]}'::jsonb,
      'PG076: added current oracle_hash and scoped protection activation annotation; runtime remains creature body only.'
    ),
    (
      'Mother of Runes',
      'battle_rule_v1:85d8c93e5ff3b531d4ab9217bd956948',
      '{"battle_model_scope":"creature_body_protection_activation_annotation_v1","oracle_runtime_scope":"creature_body_runtime_protection_activation_annotation","activated_protection_status":"annotation_only","tap_activation":true,"protection_target":"target_creature_you_control","protection_choices":["chosen_color"],"duration":"until_end_of_turn","runtime_modeled_effect":"creature_body_only"}'::jsonb,
      '{"category":"protection","functions":["creature_body","activated_protection"],"annotation_only":["protection_activation"]}'::jsonb,
      'PG076: added current oracle_hash and scoped protection activation annotation; runtime remains creature body only.'
    ),
    (
      'Professional Face-Breaker',
      'battle_rule_v1:3d154b436fcb6b4f290cdd0246d5def4',
      '{"battle_model_scope":"creature_body_menace_combat_damage_treasure_impulse_annotation_v1","oracle_runtime_scope":"creature_body_runtime_menace_treasure_impulse_annotation","combat_damage_treasure_trigger_status":"annotation_only","treasure_impulse_draw_status":"annotation_only","keywords":["menace"],"runtime_modeled_effect":"creature_body_only"}'::jsonb,
      '{"category":"ramp","functions":["creature_body","combat_damage_treasure_engine","treasure_impulse_draw"],"annotation_only":["combat_damage_treasure_trigger","treasure_impulse_draw"]}'::jsonb,
      'PG076: added current oracle_hash and scoped combat-damage Treasure/impulse annotations; runtime remains creature body only.'
    ),
    (
      'Ranger-Captain of Eos',
      'battle_rule_v1:b05b64c0734daafd9c6f24ea02b39495',
      '{"battle_model_scope":"creature_body_etb_small_creature_tutor_sacrifice_noncreature_silence_annotation_v1","oracle_runtime_scope":"creature_body_runtime_etb_tutor_sacrifice_silence_annotation","etb_tutor_status":"annotation_only","etb_tutor_target":"creature_mana_value_1_or_less","library_shuffle_status":"annotation_only","sacrifice_noncreature_silence_status":"annotation_only","runtime_modeled_effect":"creature_body_only"}'::jsonb,
      '{"category":"protection","functions":["creature_body","small_creature_tutor","noncreature_silence"],"annotation_only":["etb_tutor","sacrifice_noncreature_silence"]}'::jsonb,
      'PG076: added current oracle_hash and scoped ETB small-creature tutor plus sacrifice noncreature silence annotations; runtime remains creature body only.'
    ),
    (
      'Storm-Kiln Artist',
      'battle_rule_v1:128e222b4de1e6308d98743711b54985',
      '{"battle_model_scope":"creature_body_artifact_power_magecraft_treasure_annotation_v1","oracle_runtime_scope":"creature_body_runtime_artifact_power_magecraft_treasure_annotation","artifact_power_bonus_status":"annotation_only","magecraft_treasure_status":"annotation_only","magecraft_trigger":"cast_or_copy_instant_or_sorcery","runtime_modeled_effect":"creature_body_only"}'::jsonb,
      '{"category":"ramp","functions":["creature_body","artifact_power_bonus","magecraft_treasure_engine"],"annotation_only":["artifact_power_bonus","magecraft_treasure_trigger"]}'::jsonb,
      'PG076: added current oracle_hash and scoped artifact-power/magecraft Treasure annotations; runtime remains creature body only.'
    )
) AS t(card_name, logical_rule_key, effect_patch, deck_role_patch, note);

CREATE TABLE manaloom_deploy_audit.pg076_deck6_support_passive_annotation_20260623_054358 AS
SELECT cbr.*
FROM card_battle_rules cbr
JOIN cards c ON c.id = cbr.card_id
JOIN pg076_target_patch t ON t.card_name = c.name;

WITH patched AS (
  UPDATE card_battle_rules cbr
  SET
    oracle_hash = md5(coalesce(c.oracle_text, '')),
    effect_json = cbr.effect_json || t.effect_patch,
    deck_role_json = cbr.deck_role_json || t.deck_role_patch,
    confidence = GREATEST(cbr.confidence, 0.960),
    rule_version = GREATEST(cbr.rule_version, 2),
    notes = concat_ws(E'\n', nullif(cbr.notes, ''), t.note),
    reviewed_by = 'codex',
    reviewed_at = CURRENT_TIMESTAMP,
    updated_at = CURRENT_TIMESTAMP
  FROM cards c
  JOIN pg076_target_patch t ON t.card_name = c.name
  WHERE cbr.card_id = c.id
    AND cbr.logical_rule_key = t.logical_rule_key
  RETURNING cbr.normalized_name, cbr.logical_rule_key
)
SELECT count(*) AS curated_rows_patched FROM patched;

WITH disabled AS (
  UPDATE card_battle_rules cbr
  SET
    review_status = 'deprecated',
    execution_status = 'disabled',
    notes = concat_ws(
      E'\n',
      nullif(cbr.notes, ''),
      'PG076: disabled superseded generated review-only shadow row after curated oracle-specific annotation/provenance review.'
    ),
    reviewed_by = 'codex',
    reviewed_at = CURRENT_TIMESTAMP,
    updated_at = CURRENT_TIMESTAMP
  FROM cards c
  JOIN pg076_target_patch t ON t.card_name = c.name
  WHERE cbr.card_id = c.id
    AND cbr.logical_rule_key <> t.logical_rule_key
    AND cbr.source = 'generated'
    AND cbr.review_status = 'needs_review'
    AND cbr.execution_status = 'review_only'
  RETURNING cbr.normalized_name, cbr.logical_rule_key
)
SELECT count(*) AS generated_shadow_rows_disabled FROM disabled;

COMMIT;
