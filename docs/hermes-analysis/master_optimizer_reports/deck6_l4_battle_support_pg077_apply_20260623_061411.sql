BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

DO $$
BEGIN
  IF to_regclass('manaloom_deploy_audit.pg077_deck6_l4_battle_support_20260623_061411') IS NOT NULL THEN
    RAISE EXCEPTION 'PG077 backup table already exists';
  END IF;
END $$;

CREATE TABLE manaloom_deploy_audit.pg077_deck6_l4_battle_support_20260623_061411 AS
SELECT now() AS backed_up_at, to_jsonb(cbr) AS payload
FROM card_battle_rules cbr
WHERE cbr.normalized_name IN ('jeska''s will', 'mizzix''s mastery');

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
      c.name = 'Jeska''s Will'
      AND md5(coalesce(c.oracle_text, '')) = 'e323893e6c38ee2d618b4f9c737fadee'
    )
    OR (
      c.name = 'Mizzix''s Mastery'
      AND md5(coalesce(c.oracle_text, '')) = '8b822f0c58e4ab4e91f9e4946e8c04e9'
    );

  SELECT count(*)
  INTO v_rules
  FROM card_battle_rules
  WHERE normalized_name IN ('jeska''s will', 'mizzix''s mastery');

  SELECT count(*)
  INTO v_specific
  FROM card_battle_rules
  WHERE (normalized_name = 'jeska''s will'
      AND logical_rule_key = 'battle_rule_v1:c8621a807cc65adc820a8b8189979f70')
    OR (normalized_name = 'mizzix''s mastery'
      AND logical_rule_key = 'battle_rule_v1:e44a8b8d0e4f8fc8e8a5ebd93a73194f');

  IF v_cards <> 2 THEN
    RAISE EXCEPTION 'PG077 precondition failed: expected 2 target cards with current oracle hashes, got %', v_cards;
  END IF;
  IF v_rules <> 4 THEN
    RAISE EXCEPTION 'PG077 precondition failed: expected 4 target rules, got %', v_rules;
  END IF;
  IF v_specific <> 2 THEN
    RAISE EXCEPTION 'PG077 precondition failed: expected 2 existing curated runtime rows, got %', v_specific;
  END IF;
END $$;

UPDATE card_battle_rules
SET
  oracle_hash = 'e323893e6c38ee2d618b4f9c737fadee',
  effect_json = jsonb_build_object(
    'effect', 'ramp_ritual',
    'produces', 'R',
    'mana_produced', 0,
    'mana_produced_from_target_opponent_hand_size', true,
    'target', 'opponent',
    'target_opponent_selection', 'largest_hand',
    'choose_both_if_control_commander', true,
    'impulse_exile_top_count', 3,
    'impulse_play_permission_status', 'exiled_play_permission_tracked_cast_from_exile_not_selected_by_ai',
    'sorcery', true,
    'battle_model_scope', 'choose_both_with_commander_red_by_target_opponent_hand_impulse_top_three_v1',
    'oracle_runtime_scope', 'commander_choose_both_add_red_by_target_opponent_hand_and_exile_top_three_permission_tracked_v1',
    'mana_color_status', 'red_pool_runtime'
  ),
  deck_role_json = jsonb_build_object(
    'effect', 'ramp_ritual',
    'category', 'ramp',
    'functions', jsonb_build_array('ritual', 'impulse_card_access'),
    'runtime_modes', jsonb_build_array('add_red_mana', 'impulse_exile_top_three')
  ),
  source = 'curated',
  confidence = 0.970,
  review_status = 'verified',
  execution_status = 'auto',
  rule_version = greatest(rule_version, 2),
  reviewed_by = 'codex-auditor',
  reviewed_at = now(),
  updated_at = now(),
  last_seen_at = now(),
  notes = concat_ws(
    E'\n',
    nullif(notes, ''),
    'PG077: promoted Jeska''s Will from fixed generic ritual to oracle-specific runtime. Runtime adds red mana equal to the selected living opponent hand size and, when the controller controls a commander, also exiles the top three cards with play permission tracked. Generic cast-from-exile selection is not yet enabled by AI.'
  )
WHERE normalized_name = 'jeska''s will'
  AND logical_rule_key = 'battle_rule_v1:c8621a807cc65adc820a8b8189979f70';

UPDATE card_battle_rules
SET
  oracle_hash = '8b822f0c58e4ab4e91f9e4946e8c04e9',
  effect_json = jsonb_build_object(
    'effect', 'overload_recursion',
    'target', 'instant_or_sorcery_graveyard',
    'overload_cost', '{5}{R}{R}{R}',
    'overload_min_targets', 2,
    'exiles_target_cards', true,
    'casts_copies_without_paying_mana', true,
    'exiles_self', true,
    'sorcery', true,
    'battle_model_scope', 'target_or_overload_graveyard_instant_sorcery_copy_cast_runtime_v1',
    'oracle_runtime_scope', 'normal_target_and_overload_each_graveyard_instant_sorcery_copy_cast_runtime_v1'
  ),
  deck_role_json = jsonb_build_object(
    'effect', 'overload_recursion',
    'category', 'wincon',
    'functions', jsonb_build_array('graveyard_spell_recursion', 'copy_cast', 'storm_payoff'),
    'runtime_modes', jsonb_build_array('target_graveyard_spell_copy', 'overload_all_graveyard_spells')
  ),
  source = 'curated',
  confidence = 0.970,
  review_status = 'verified',
  execution_status = 'auto',
  rule_version = greatest(rule_version, 2),
  reviewed_by = 'codex-auditor',
  reviewed_at = now(),
  updated_at = now(),
  last_seen_at = now(),
  notes = concat_ws(
    E'\n',
    nullif(notes, ''),
    'PG077: replaced Mizzix''s Mastery abstract graveyard-count damage proxy with runtime that exiles target/all instant-or-sorcery graveyard cards, creates copies, casts those copies without paying mana, and exiles Mizzix''s Mastery on resolution.'
  )
WHERE normalized_name = 'mizzix''s mastery'
  AND logical_rule_key = 'battle_rule_v1:e44a8b8d0e4f8fc8e8a5ebd93a73194f';

UPDATE card_battle_rules
SET
  review_status = 'deprecated',
  execution_status = 'disabled',
  updated_at = now(),
  last_seen_at = now(),
  notes = concat_ws(
    E'\n',
    nullif(notes, ''),
    'PG077: disabled superseded generated review-only row after scoped battle-support runtime validation.'
  )
WHERE normalized_name IN ('jeska''s will', 'mizzix''s mastery')
  AND logical_rule_key NOT IN (
    'battle_rule_v1:c8621a807cc65adc820a8b8189979f70',
    'battle_rule_v1:e44a8b8d0e4f8fc8e8a5ebd93a73194f'
  )
  AND review_status IN ('verified', 'active', 'needs_review')
  AND execution_status IN ('auto', 'executable', 'review_only');

COMMIT;
