BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

DO $$
BEGIN
  IF to_regclass('manaloom_deploy_audit.pg087_deck606_remaining_semantic_20260623_085349') IS NOT NULL THEN
    RAISE EXCEPTION 'backup table manaloom_deploy_audit.pg087_deck606_remaining_semantic_20260623_085349 already exists';
  END IF;
END $$;

CREATE TEMP TABLE pg087_deck606_remaining_semantic_target AS
SELECT
  'Hexing Squelcher'::text AS name,
  'hexing squelcher'::text AS normalized_name,
  'battle_rule_v1:c6587e309bfd402ee1b98b4848abc6d3'::text AS expected_logical_rule_key,
  'ed00818e6ca804b7d1a3ef47c29277ea'::text AS expected_oracle_hash,
  'creature_body_uncounterable_ward_static_counter_protection_annotations_v1'::text AS expected_scope,
  jsonb_build_object(
    'cmc', 2.0,
    'effect', 'creature',
    'power', 2,
    'toughness', 2,
    'is_creature_permanent', true,
    'uncounterable', true,
    'spells_you_control_cant_be_countered', true,
    'spells_you_control_cant_be_countered_status', 'runtime_counter_target_filter',
    'ward_pay_life', 2,
    'ward_pay_life_status', 'annotation_only',
    'other_creatures_you_control_ward_pay_life', 2,
    'other_creatures_ward_status', 'annotation_only',
    'battle_model_scope', 'creature_body_uncounterable_ward_static_counter_protection_annotations_v1',
    'oracle_runtime_scope', 'self_uncounterable_and_controller_spell_counter_shield_runtime_ward_pay_life_annotation_v1'
  ) AS effect_json,
  jsonb_build_object(
    'effect', 'creature',
    'category', 'protection',
    'functions', jsonb_build_array('creature_body', 'self_uncounterable', 'controller_spell_counter_shield', 'ward_static'),
    'runtime_modes', jsonb_build_array('creature_body', 'self_uncounterable_counter_filter', 'controller_spell_counter_filter'),
    'annotation_modes', jsonb_build_array('ward_pay_life', 'other_creatures_ward_pay_life')
  ) AS deck_role_json
UNION ALL
SELECT
  'Ragavan, Nimble Pilferer',
  'ragavan, nimble pilferer',
  'battle_rule_v1:3e0569d6bae4ed8b6e6e4289ea75084e',
  'e337b9515b6984af8a1572db48f47eec',
  'creature_body_haste_combat_damage_treasure_impulse_dash_annotations_v1',
  jsonb_build_object(
    'cmc', 1.0,
    'effect', 'creature',
    'power', 2,
    'toughness', 1,
    'is_creature_permanent', true,
    'keywords', jsonb_build_array('haste'),
    'haste', true,
    'combat_damage_treasure_count', 1,
    'combat_damage_treasure_trigger_status', 'annotation_only',
    'combat_damage_exile_top_opponent_library_status', 'annotation_only',
    'temporary_cast_permission_status', 'annotation_only',
    'dash_cost', '{1}{R}',
    'dash_status', 'annotation_only',
    'runtime_modeled_effect', 'creature_body_haste_only',
    'battle_model_scope', 'creature_body_haste_combat_damage_treasure_impulse_dash_annotations_v1',
    'oracle_runtime_scope', 'creature_body_haste_runtime_combat_damage_treasure_impulse_dash_annotations_v1'
  ),
  jsonb_build_object(
    'effect', 'creature',
    'category', 'ramp',
    'functions', jsonb_build_array('creature_body', 'haste_attacker', 'combat_damage_treasure_engine', 'temporary_cast_permission', 'dash'),
    'runtime_modes', jsonb_build_array('creature_body', 'haste'),
    'annotation_modes', jsonb_build_array('combat_damage_treasure_trigger', 'exile_top_card_temporary_cast_permission', 'dash')
  )
UNION ALL
SELECT
  'Skyclave Apparition',
  'skyclave apparition',
  'battle_rule_v1:4f29c7a4bbe21a160f28452406153846',
  '4d0c162906712b2c428b754ad2f0b3a0',
  'creature_etb_exile_nonland_nontoken_mv_lte4_leave_illusion_annotation_v1',
  jsonb_build_object(
    'cmc', 3.0,
    'effect', 'creature',
    'power', 2,
    'toughness', 2,
    'is_creature_permanent', true,
    'etb_remove_effect', 'remove_permanent',
    'etb_remove_target', 'nonland_permanent',
    'target_controller', 'opponent',
    'target_mana_value_max', 4,
    'target_nontoken', true,
    'exile_target', true,
    'leave_battlefield_illusion_token_status', 'annotation_only',
    'illusion_token_power_toughness_equal_exiled_mana_value', true,
    'battle_model_scope', 'creature_etb_exile_nonland_nontoken_mv_lte4_leave_illusion_annotation_v1',
    'oracle_runtime_scope', 'creature_body_etb_exile_nonland_nontoken_mv_lte4_runtime_leave_token_annotation_v1'
  ),
  jsonb_build_object(
    'effect', 'creature',
    'category', 'removal',
    'functions', jsonb_build_array('creature_body', 'etb_exile_nonland_nontoken_permanent_mv_lte4', 'leave_battlefield_illusion_token'),
    'runtime_modes', jsonb_build_array('creature_body', 'etb_exile_nonland_nontoken_permanent_mv_lte4'),
    'annotation_modes', jsonb_build_array('leave_battlefield_illusion_token')
  )
UNION ALL
SELECT
  'Underworld Breach',
  'underworld breach',
  'battle_rule_v1:3f9f5259b05245670ee19b357aa2e999',
  'a98ca5777789e48c44daff97999f2beb',
  'escape_grant_nonland_graveyard_end_step_sacrifice_annotation_v1',
  jsonb_build_object(
    'cmc', 2.0,
    'effect', 'passive',
    'is_enchantment_permanent', true,
    'grants_escape_to_nonland_cards_in_graveyard', true,
    'escape_grant_status', 'annotation_only',
    'escape_additional_cost_exile_other_graveyard_cards', 3,
    'escape_cost_model', 'mana_cost_plus_exile_three_other_cards',
    'end_step_sacrifice_status', 'annotation_only',
    'battle_model_scope', 'escape_grant_nonland_graveyard_end_step_sacrifice_annotation_v1',
    'oracle_runtime_scope', 'passive_enchantment_runtime_escape_and_end_step_sacrifice_annotations_v1'
  ),
  jsonb_build_object(
    'effect', 'passive',
    'category', 'recursion',
    'functions', jsonb_build_array('escape_grant', 'graveyard_cast_permission', 'end_step_sacrifice'),
    'runtime_modes', jsonb_build_array('passive_enchantment'),
    'annotation_modes', jsonb_build_array('escape_grant', 'escape_additional_cost', 'end_step_sacrifice')
  );

DO $$
DECLARE
  target_count integer;
  card_count integer;
  trusted_count integer;
  oracle_match_count integer;
  conflict_count integer;
BEGIN
  SELECT count(*) INTO target_count FROM pg087_deck606_remaining_semantic_target;

  SELECT count(*) INTO card_count
  FROM pg087_deck606_remaining_semantic_target t
  JOIN cards c ON lower(c.name) = t.normalized_name;

  SELECT count(*) INTO trusted_count
  FROM pg087_deck606_remaining_semantic_target t
  JOIN cards c ON lower(c.name) = t.normalized_name
  JOIN card_battle_rules r ON r.card_id = c.id
  WHERE r.source = 'curated'
    AND r.review_status = 'verified'
    AND r.execution_status = 'auto';

  SELECT count(*) INTO oracle_match_count
  FROM pg087_deck606_remaining_semantic_target t
  JOIN cards c ON lower(c.name) = t.normalized_name
  WHERE md5(coalesce(c.oracle_text, '')) = t.expected_oracle_hash;

  SELECT count(*) INTO conflict_count
  FROM card_battle_rules r
  JOIN pg087_deck606_remaining_semantic_target t
    ON r.logical_rule_key = t.expected_logical_rule_key
  WHERE lower(coalesce(r.card_name, r.normalized_name)) <> t.normalized_name;

  IF target_count <> 4 OR card_count <> 4 OR trusted_count <> 4 OR oracle_match_count <> 4 OR conflict_count <> 0 THEN
    RAISE EXCEPTION 'PG087 precondition failed target=% card=% trusted=% oracle_match=% conflicts=%',
      target_count, card_count, trusted_count, oracle_match_count, conflict_count;
  END IF;
END $$;

CREATE TABLE manaloom_deploy_audit.pg087_deck606_remaining_semantic_20260623_085349 AS
SELECT r.*
FROM card_battle_rules r
JOIN cards c ON c.id = r.card_id
JOIN pg087_deck606_remaining_semantic_target t ON lower(c.name) = t.normalized_name;

UPDATE card_battle_rules r
SET
  logical_rule_key = t.expected_logical_rule_key,
  oracle_hash = t.expected_oracle_hash,
  effect_json = t.effect_json,
  deck_role_json = t.deck_role_json,
  source = 'curated',
  confidence = 1.0,
  review_status = 'verified',
  execution_status = 'auto',
  rule_version = greatest(coalesce(r.rule_version, 1), 2),
  reviewed_by = 'codex-pg087',
  reviewed_at = now(),
  updated_at = now(),
  notes = concat_ws(E'\n', nullif(r.notes, ''), 'PG087 2026-06-23: Deck 606 remaining semantic specificity batch. Added card-specific oracle_hash, logical key, battle_model_scope, and explicit runtime-vs-annotation fields; no deck swap.')
FROM pg087_deck606_remaining_semantic_target t
JOIN cards c ON lower(c.name) = t.normalized_name
WHERE r.card_id = c.id
  AND r.source = 'curated'
  AND r.review_status = 'verified'
  AND r.execution_status = 'auto';

UPDATE card_battle_rules r
SET
  review_status = 'deprecated',
  execution_status = 'disabled',
  updated_at = now(),
  notes = concat_ws(E'\n', nullif(r.notes, ''), 'PG087 disabled: superseded generated/review-only shadow after card-specific trusted rule was validated.')
FROM pg087_deck606_remaining_semantic_target t
JOIN cards c ON lower(c.name) = t.normalized_name
WHERE r.card_id = c.id
  AND r.logical_rule_key <> t.expected_logical_rule_key
  AND (
    r.source = 'generated'
    OR r.review_status IN ('needs_review', 'review_only')
    OR r.execution_status = 'review_only'
  );

COMMIT;
