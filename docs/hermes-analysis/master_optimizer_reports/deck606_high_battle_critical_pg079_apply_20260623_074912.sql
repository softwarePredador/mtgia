BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

DO $$
BEGIN
  IF to_regclass('manaloom_deploy_audit.pg079_deck606_high_battle_critical_20260623_074912') IS NOT NULL THEN
    RAISE EXCEPTION 'PG079 deck606 high battle-critical backup table already exists';
  END IF;
END $$;

CREATE TEMP TABLE pg079_deck606_high_targets(
  normalized_name text,
  logical_rule_key text,
  expected_oracle_hash text,
  expected_scope text
);

INSERT INTO pg079_deck606_high_targets(normalized_name, logical_rule_key, expected_oracle_hash, expected_scope)
VALUES
  ('flare of duplication', 'battle_rule_v1:b82bbb548dab138fa0700cb4cf905617', '3b1f1bcd5e69cb1f5f306e83345b2a1f', 'copy_target_instant_or_sorcery_stack_spell_alt_cost_annotation_v1'),
  ('powerbalance', 'battle_rule_v1:e35051e9c60b94a84ac9b71c11c7fc4b', '8cbde54a4e2e1464a5deb5171928e203', 'opponent_spell_reveal_top_same_mana_value_free_cast_v1'),
  ('reforge the soul', 'battle_rule_v1:90b82cfc81ff726ac0fc96a1b220f263', '041645992d04029f74855292bb1459f4', 'each_player_discard_hand_draw_seven_miracle_annotation_v1'),
  ('rise of the eldrazi', 'battle_rule_v1:57d155e410ca3cc6a96e14ed50f524d4', '6cad51822d2ad0e019c29770033c7d21', 'uncounterable_destroy_target_permanent_target_player_draw_four_extra_turn_exile_v1'),
  ('rite of the dragoncaller', 'battle_rule_v1:b23bca3229a81d65750cf9c453c7943d', '9308f0eadf924f7ea0c8ea2463224c9a', 'instant_sorcery_cast_create_5_5_flying_dragon_v1'),
  ('storm herd', 'battle_rule_v1:b041641dc875caa7987253389dc52839', '25e798eec6b64f1ae52d3af1ca8597dd', 'life_total_flying_pegasus_token_maker_v1'),
  ('witch enchanter // witch-blessed meadow', 'battle_rule_v1:5768b971f1ab4f2d4d9b8bd6a768c132', 'cd5355a1a3cd44df9237726d9e3006c5', 'creature_etb_destroy_opponent_artifact_or_enchantment_v1');

CREATE TABLE manaloom_deploy_audit.pg079_deck606_high_battle_critical_20260623_074912 AS
SELECT now() AS backed_up_at, to_jsonb(cbr) AS payload
FROM card_battle_rules cbr
WHERE cbr.normalized_name IN (SELECT normalized_name FROM pg079_deck606_high_targets);

DO $$
DECLARE
  v_target integer;
  v_oracle integer;
  v_trusted integer;
  v_shadow integer;
BEGIN
  SELECT
    count(*),
    count(*) FILTER (WHERE md5(coalesce(c.oracle_text, '')) = t.expected_oracle_hash),
    count(*) FILTER (WHERE cbr.source = 'curated' AND cbr.review_status IN ('active', 'verified') AND cbr.execution_status = 'auto')
  INTO v_target, v_oracle, v_trusted
  FROM pg079_deck606_high_targets t
  JOIN card_battle_rules cbr
    ON cbr.normalized_name = t.normalized_name
   AND cbr.logical_rule_key = t.logical_rule_key
  JOIN cards c
    ON c.id = cbr.card_id;

  SELECT count(*)
  INTO v_shadow
  FROM card_battle_rules cbr
  WHERE cbr.normalized_name IN (SELECT normalized_name FROM pg079_deck606_high_targets)
    AND NOT EXISTS (
      SELECT 1
      FROM pg079_deck606_high_targets t
      WHERE t.normalized_name = cbr.normalized_name
        AND t.logical_rule_key = cbr.logical_rule_key
    )
    AND cbr.execution_status <> 'disabled';

  IF v_target <> 7 THEN
    RAISE EXCEPTION 'PG079 precondition failed: expected 7 target rows, got %', v_target;
  END IF;
  IF v_oracle <> 7 THEN
    RAISE EXCEPTION 'PG079 precondition failed: expected 7 current oracle hashes, got %', v_oracle;
  END IF;
  IF v_trusted <> 7 THEN
    RAISE EXCEPTION 'PG079 precondition failed: expected 7 trusted curated auto rows, got %', v_trusted;
  END IF;
  IF v_shadow <> 7 THEN
    RAISE EXCEPTION 'PG079 precondition failed: expected 7 non-disabled shadow rows, got %', v_shadow;
  END IF;
END $$;

UPDATE card_battle_rules
SET
  oracle_hash = '3b1f1bcd5e69cb1f5f306e83345b2a1f',
  effect_json = jsonb_build_object(
    'effect', 'copy_spell',
    'cmc', 3.0,
    'instant', true,
    'target', 'instant_or_sorcery_on_stack',
    'requires_stack_target', true,
    'may_choose_new_targets', true,
    'alternative_cost_status', 'sacrifice_nontoken_red_creature_annotation_only',
    'battle_model_scope', 'copy_target_instant_or_sorcery_stack_spell_alt_cost_annotation_v1',
    'oracle_runtime_scope', 'copy_target_instant_or_sorcery_spell_stack_copy_runtime_alt_cost_not_dynamic_v1'
  ),
  deck_role_json = jsonb_build_object(
    'effect', 'copy_spell',
    'category', 'engine',
    'timing', 'instant',
    'runtime_modes', jsonb_build_array('copy_target_instant_or_sorcery_on_stack'),
    'annotation_modes', jsonb_build_array('alternative_sacrifice_cost')
  ),
  confidence = 0.970,
  review_status = 'verified',
  execution_status = 'auto',
  rule_version = greatest(rule_version, 2),
  reviewed_by = 'codex-auditor',
  reviewed_at = now(),
  updated_at = now(),
  last_seen_at = now(),
  notes = concat_ws(E'\n', nullif(notes, ''), 'PG079: oracle-specific Flare of Duplication stack-copy model. Dynamic alternative sacrifice cost remains annotation-only.')
WHERE normalized_name = 'flare of duplication'
  AND logical_rule_key = 'battle_rule_v1:b82bbb548dab138fa0700cb4cf905617';

UPDATE card_battle_rules
SET
  oracle_hash = '8cbde54a4e2e1464a5deb5171928e203',
  effect_json = jsonb_build_object(
    'effect', 'draw_engine',
    'cmc', 2.0,
    'trigger', 'opponent_spell',
    'draw_on_enter', false,
    'powerbalance_topdeck_free_cast_same_mana_value', true,
    'battle_model_scope', 'opponent_spell_reveal_top_same_mana_value_free_cast_v1',
    'oracle_runtime_scope', 'opponent_spell_reveal_top_library_cast_same_mana_value_without_paying_mana_cost_compact_v1'
  ),
  deck_role_json = jsonb_build_object(
    'effect', 'draw_engine',
    'category', 'engine',
    'functions', jsonb_build_array('topdeck_reveal', 'conditional_free_cast'),
    'runtime_modes', jsonb_build_array('opponent_spell_same_mana_value_top_card_free_cast')
  ),
  confidence = 0.970,
  review_status = 'verified',
  execution_status = 'auto',
  rule_version = greatest(rule_version, 2),
  reviewed_by = 'codex-auditor',
  reviewed_at = now(),
  updated_at = now(),
  last_seen_at = now(),
  notes = concat_ws(E'\n', nullif(notes, ''), 'PG079: replaces generic draw-engine handling with Powerbalance same-mana-value topdeck free-cast compact runtime. No draw-on-enter.')
WHERE normalized_name = 'powerbalance'
  AND logical_rule_key = 'battle_rule_v1:e35051e9c60b94a84ac9b71c11c7fc4b';

UPDATE card_battle_rules
SET
  oracle_hash = '041645992d04029f74855292bb1459f4',
  effect_json = jsonb_build_object(
    'effect', 'draw_cards',
    'count', 7,
    'wheel', true,
    'each_player', true,
    'miracle', '1R',
    'battle_model_scope', 'each_player_discard_hand_draw_seven_miracle_annotation_v1',
    'oracle_runtime_scope', 'each_player_discard_hand_draw_seven_runtime_miracle_cost_annotation_v1'
  ),
  deck_role_json = jsonb_build_object(
    'effect', 'draw_cards',
    'category', 'draw',
    'functions', jsonb_build_array('wheel', 'refill'),
    'annotation_modes', jsonb_build_array('miracle_cost')
  ),
  confidence = 0.970,
  review_status = 'verified',
  execution_status = 'auto',
  rule_version = greatest(rule_version, 2),
  reviewed_by = 'codex-auditor',
  reviewed_at = now(),
  updated_at = now(),
  last_seen_at = now(),
  notes = concat_ws(E'\n', nullif(notes, ''), 'PG079: scopes Reforge the Soul as each-player discard hand then draw seven. Miracle cost is annotation/provenance; runtime miracle windows remain handled by existing Lorehold draw hooks.')
WHERE normalized_name = 'reforge the soul'
  AND logical_rule_key = 'battle_rule_v1:90b82cfc81ff726ac0fc96a1b220f263';

UPDATE card_battle_rules
SET
  oracle_hash = '6cad51822d2ad0e019c29770033c7d21',
  effect_json = jsonb_build_object(
    'effect', 'composite_resolution',
    'uncounterable', true,
    'exiles_self', true,
    '_composite_rule_components', jsonb_build_array(
      jsonb_build_object('effect', 'remove_permanent', 'target', 'nonland_permanent'),
      jsonb_build_object('effect', 'draw_cards', 'count', 4, 'target_player_status', 'controller_as_default_compact_target'),
      jsonb_build_object('effect', 'extra_turn', 'turns', 1)
    ),
    'battle_model_scope', 'uncounterable_destroy_target_permanent_target_player_draw_four_extra_turn_exile_v1',
    'oracle_runtime_scope', 'destroy_permanent_controller_draw_four_extra_turn_exile_self_compact_runtime_v1'
  ),
  deck_role_json = jsonb_build_object(
    'effect', 'composite_resolution',
    'category', 'wincon',
    'functions', jsonb_build_array('removal', 'draw', 'extra_turn'),
    'runtime_modes', jsonb_build_array('destroy_target_permanent', 'draw_four', 'extra_turn', 'exile_self')
  ),
  confidence = 0.960,
  review_status = 'verified',
  execution_status = 'auto',
  rule_version = greatest(rule_version, 2),
  reviewed_by = 'codex-auditor',
  reviewed_at = now(),
  updated_at = now(),
  last_seen_at = now(),
  notes = concat_ws(E'\n', nullif(notes, ''), 'PG079: promotes Rise of the Eldrazi from generic extra_turn to composite oracle-specific resolution: uncounterable, destroy target permanent, draw four, extra turn, exile self. Target-player draw uses controller-as-default compact target.')
WHERE normalized_name = 'rise of the eldrazi'
  AND logical_rule_key = 'battle_rule_v1:57d155e410ca3cc6a96e14ed50f524d4';

UPDATE card_battle_rules
SET
  oracle_hash = '9308f0eadf924f7ea0c8ea2463224c9a',
  effect_json = jsonb_build_object(
    'effect', 'token_maker',
    'cmc', 6.0,
    'trigger', 'instant_sorcery_cast',
    'trigger_effect', 'token_maker',
    'trigger_token_count', 1,
    'token_count', 1,
    'token_name', 'Dragon Token',
    'token_power', 5,
    'token_toughness', 5,
    'token_flying', true,
    'battle_model_scope', 'instant_sorcery_cast_create_5_5_flying_dragon_v1',
    'oracle_runtime_scope', 'enchantment_trigger_create_five_five_red_dragon_flying_on_instant_sorcery_cast_v1'
  ),
  deck_role_json = jsonb_build_object(
    'effect', 'token_maker',
    'category', 'wincon',
    'functions', jsonb_build_array('spell_cast_payoff', 'token_engine'),
    'runtime_modes', jsonb_build_array('instant_sorcery_cast_dragon_token')
  ),
  confidence = 0.970,
  review_status = 'verified',
  execution_status = 'auto',
  rule_version = greatest(rule_version, 2),
  reviewed_by = 'codex-auditor',
  reviewed_at = now(),
  updated_at = now(),
  last_seen_at = now(),
  notes = concat_ws(E'\n', nullif(notes, ''), 'PG079: Rite of the Dragoncaller now enters as an enchantment trigger source and creates one 5/5 flying Dragon token on later instant/sorcery casts.')
WHERE normalized_name = 'rite of the dragoncaller'
  AND logical_rule_key = 'battle_rule_v1:b23bca3229a81d65750cf9c453c7943d';

UPDATE card_battle_rules
SET
  oracle_hash = '25e798eec6b64f1ae52d3af1ca8597dd',
  effect_json = jsonb_build_object(
    'effect', 'token_maker',
    'cmc', 10.0,
    'token_count', 'life_total',
    'token_name', 'Pegasus Token',
    'token_power', 1,
    'token_toughness', 1,
    'token_flying', true,
    'battle_model_scope', 'life_total_flying_pegasus_token_maker_v1',
    'oracle_runtime_scope', 'create_x_one_one_white_pegasus_flying_where_x_is_life_total_v1'
  ),
  deck_role_json = jsonb_build_object(
    'effect', 'token_maker',
    'category', 'wincon',
    'functions', jsonb_build_array('wide_token_finisher'),
    'runtime_modes', jsonb_build_array('life_total_flying_pegasus_tokens')
  ),
  confidence = 0.970,
  review_status = 'verified',
  execution_status = 'auto',
  rule_version = greatest(rule_version, 2),
  reviewed_by = 'codex-auditor',
  reviewed_at = now(),
  updated_at = now(),
  last_seen_at = now(),
  notes = concat_ws(E'\n', nullif(notes, ''), 'PG079: Storm Herd now uses literal life total for 1/1 flying Pegasus token count; previous runtime halving bug fixed in executor.')
WHERE normalized_name = 'storm herd'
  AND logical_rule_key = 'battle_rule_v1:b041641dc875caa7987253389dc52839';

UPDATE card_battle_rules
SET
  oracle_hash = 'cd5355a1a3cd44df9237726d9e3006c5',
  effect_json = jsonb_build_object(
    'effect', 'creature',
    'cmc', 4.0,
    'etb_remove_target', 'artifact_or_enchantment',
    'etb_remove_effect', 'remove_permanent',
    'target_controller', 'opponent',
    'mdfc_land_face_status', 'annotation_only_not_selected_by_battle_ai',
    'battle_model_scope', 'creature_etb_destroy_opponent_artifact_or_enchantment_v1',
    'oracle_runtime_scope', 'front_face_creature_enters_destroy_target_artifact_or_enchantment_opponent_controls_v1'
  ),
  deck_role_json = jsonb_build_object(
    'effect', 'creature',
    'category', 'removal',
    'functions', jsonb_build_array('creature_body', 'artifact_enchantment_removal'),
    'runtime_modes', jsonb_build_array('etb_destroy_opponent_artifact_or_enchantment'),
    'annotation_modes', jsonb_build_array('mdfc_land_face')
  ),
  confidence = 0.970,
  review_status = 'verified',
  execution_status = 'auto',
  rule_version = greatest(rule_version, 2),
  reviewed_by = 'codex-auditor',
  reviewed_at = now(),
  updated_at = now(),
  last_seen_at = now(),
  notes = concat_ws(E'\n', nullif(notes, ''), 'PG079: Witch Enchanter front face is modeled as creature body plus ETB destroy target artifact/enchantment an opponent controls. MDFC land face remains annotation-only.')
WHERE normalized_name = 'witch enchanter // witch-blessed meadow'
  AND logical_rule_key = 'battle_rule_v1:5768b971f1ab4f2d4d9b8bd6a768c132';

UPDATE card_battle_rules cbr
SET
  review_status = 'deprecated',
  execution_status = 'disabled',
  updated_at = now(),
  last_seen_at = now(),
  notes = concat_ws(E'\n', nullif(cbr.notes, ''), 'PG079: disabled superseded generated/review shadow row after oracle-specific deck606 high battle-critical runtime model was promoted.')
WHERE cbr.normalized_name IN (SELECT normalized_name FROM pg079_deck606_high_targets)
  AND NOT EXISTS (
    SELECT 1
    FROM pg079_deck606_high_targets t
    WHERE t.normalized_name = cbr.normalized_name
      AND t.logical_rule_key = cbr.logical_rule_key
  )
  AND cbr.execution_status <> 'disabled';

DO $$
DECLARE
  v_hash integer;
  v_scope integer;
  v_shadow integer;
  v_backup integer;
BEGIN
  SELECT
    count(*) FILTER (WHERE cbr.oracle_hash = t.expected_oracle_hash),
    count(*) FILTER (WHERE cbr.effect_json->>'battle_model_scope' = t.expected_scope)
  INTO v_hash, v_scope
  FROM pg079_deck606_high_targets t
  JOIN card_battle_rules cbr
    ON cbr.normalized_name = t.normalized_name
   AND cbr.logical_rule_key = t.logical_rule_key;

  SELECT count(*)
  INTO v_shadow
  FROM card_battle_rules cbr
  WHERE cbr.normalized_name IN (SELECT normalized_name FROM pg079_deck606_high_targets)
    AND NOT EXISTS (
      SELECT 1
      FROM pg079_deck606_high_targets t
      WHERE t.normalized_name = cbr.normalized_name
        AND t.logical_rule_key = cbr.logical_rule_key
    )
    AND cbr.execution_status <> 'disabled';

  SELECT count(*) INTO v_backup
  FROM manaloom_deploy_audit.pg079_deck606_high_battle_critical_20260623_074912;

  IF v_hash <> 7 THEN
    RAISE EXCEPTION 'PG079 apply failed: expected 7 matching hashes, got %', v_hash;
  END IF;
  IF v_scope <> 7 THEN
    RAISE EXCEPTION 'PG079 apply failed: expected 7 matching scopes, got %', v_scope;
  END IF;
  IF v_shadow <> 0 THEN
    RAISE EXCEPTION 'PG079 apply failed: expected 0 non-disabled shadow rows, got %', v_shadow;
  END IF;
  IF v_backup <> 14 THEN
    RAISE EXCEPTION 'PG079 apply failed: expected 14 backup rows, got %', v_backup;
  END IF;
END $$;

COMMIT;
