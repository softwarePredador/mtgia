BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

DO $$
BEGIN
  IF to_regclass('manaloom_deploy_audit.pg072_deck6_l6_interaction_removal_counter_20260623_045642') IS NOT NULL THEN
    RAISE EXCEPTION 'PG072 backup table already exists';
  END IF;
END $$;

CREATE TABLE manaloom_deploy_audit.pg072_deck6_l6_interaction_removal_counter_20260623_045642 AS
SELECT now() AS backed_up_at, to_jsonb(cbr) AS payload
FROM card_battle_rules cbr
WHERE cbr.normalized_name IN ('get lost', 'pyroblast');

DO $$
DECLARE
  v_cards integer;
  v_rules integer;
  v_specific integer;
BEGIN
  SELECT count(*)
  INTO v_cards
  FROM cards c
  WHERE (
      c.name = 'Get Lost'
      AND md5(coalesce(c.oracle_text, '')) = '6b6517e1b5b60db5cf6bbcd991dbc1ec'
    )
    OR (
      c.name = 'Pyroblast'
      AND md5(coalesce(c.oracle_text, '')) = 'ecf9ad1f393a664f16867aab8a6edf77'
    );

  SELECT count(*)
  INTO v_rules
  FROM card_battle_rules
  WHERE normalized_name IN ('get lost', 'pyroblast');

  SELECT count(*)
  INTO v_specific
  FROM card_battle_rules
  WHERE (normalized_name = 'get lost'
      AND logical_rule_key = 'battle_rule_v1:8e7da3df51386d58c857a596433f73ea')
    OR (normalized_name = 'pyroblast'
      AND logical_rule_key = 'battle_rule_v1:141ff57f44bc4c229393f05f7daf667c');

  IF v_cards <> 2 THEN
    RAISE EXCEPTION 'PG072 precondition failed: expected 2 target cards with current oracle hashes, got %', v_cards;
  END IF;
  IF v_rules <> 4 THEN
    RAISE EXCEPTION 'PG072 precondition failed: expected 4 target rules, got %', v_rules;
  END IF;
  IF v_specific <> 2 THEN
    RAISE EXCEPTION 'PG072 precondition failed: expected 2 existing curated runtime rows, got %', v_specific;
  END IF;
END $$;

UPDATE card_battle_rules
SET
  oracle_hash = '6b6517e1b5b60db5cf6bbcd991dbc1ec',
  effect_json = effect_json || jsonb_build_object(
    'effect', 'remove_permanent',
    'instant', true,
    'target', 'creature_enchantment_or_planeswalker',
    'map_tokens_created', 2,
    'battle_model_scope', 'destroy_creature_enchantment_planeswalker_create_two_map_tokens_v1',
    'oracle_runtime_scope', 'destroy_target_creature_enchantment_or_planeswalker_then_controller_creates_two_map_tokens_v1',
    'map_token_activation_status', 'annotation_only_explore_activation_not_autorun'
  ),
  deck_role_json = deck_role_json || jsonb_build_object(
    'effect', 'remove_permanent',
    'category', 'interaction',
    'target_types', jsonb_build_array('creature', 'enchantment', 'planeswalker'),
    'compensation_tokens', 'two_map_tokens'
  ),
  confidence = 0.970,
  rule_version = greatest(rule_version, 2),
  reviewed_by = 'codex-auditor',
  reviewed_at = now(),
  updated_at = now(),
  last_seen_at = now(),
  notes = concat_ws(
    E'\n',
    nullif(notes, ''),
    'PG072: expanded Get Lost from creature-only removal to creature/enchantment/planeswalker removal and modeled two Map compensation tokens; Map activation/explore remains annotation-only.'
  )
WHERE normalized_name = 'get lost'
  AND logical_rule_key = 'battle_rule_v1:8e7da3df51386d58c857a596433f73ea';

UPDATE card_battle_rules
SET
  oracle_hash = 'ecf9ad1f393a664f16867aab8a6edf77',
  effect_json = effect_json || jsonb_build_object(
    'effect', 'counter',
    'instant', true,
    'target', 'blue_spell',
    'requires_blue_target', true,
    'available_modes', jsonb_build_array('counter_target_blue_spell_runtime', 'destroy_target_blue_permanent_annotation_only'),
    'battle_model_scope', 'blue_spell_counter_runtime_destroy_blue_permanent_annotation_v1',
    'oracle_runtime_scope', 'choose_counter_blue_spell_runtime_destroy_blue_permanent_annotation_v1',
    'destroy_blue_permanent_status', 'annotation_only_no_proactive_blue_permanent_mode_executor'
  ),
  deck_role_json = deck_role_json || jsonb_build_object(
    'effect', 'counter',
    'category', 'interaction',
    'target', 'blue_spell',
    'color_hate', 'blue'
  ),
  confidence = 0.970,
  rule_version = greatest(rule_version, 2),
  reviewed_by = 'codex-auditor',
  reviewed_at = now(),
  updated_at = now(),
  last_seen_at = now(),
  notes = concat_ws(
    E'\n',
    nullif(notes, ''),
    'PG072: scoped Pyroblast counter mode to blue spells only; destroy-blue-permanent mode is retained as annotation-only until proactive blue-permanent mode selection exists.'
  )
WHERE normalized_name = 'pyroblast'
  AND logical_rule_key = 'battle_rule_v1:141ff57f44bc4c229393f05f7daf667c';

UPDATE card_battle_rules
SET
  review_status = 'deprecated',
  execution_status = 'disabled',
  updated_at = now(),
  last_seen_at = now(),
  notes = concat_ws(
    E'\n',
    nullif(notes, ''),
    'PG072: disabled superseded generated review-only row after scoped blue-target counter validation.'
  )
WHERE normalized_name = 'pyroblast'
  AND logical_rule_key = 'battle_rule_v1:d47cbde8d1dc5678060e25ea1b620a82';

COMMIT;
