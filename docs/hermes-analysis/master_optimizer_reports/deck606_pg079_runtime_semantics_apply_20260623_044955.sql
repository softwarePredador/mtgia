BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

DO $$
BEGIN
  IF to_regclass('manaloom_deploy_audit.pg079_deck606_runtime_semantics_20260623_044955') IS NOT NULL THEN
    RAISE EXCEPTION 'PG079 deck606 runtime semantics backup table already exists';
  END IF;
END $$;

CREATE TEMP TABLE pg079_target_rules(
  normalized_name text,
  logical_rule_key text,
  expected_effect_json jsonb,
  expected_deck_role_json jsonb,
  target_confidence numeric
);

INSERT INTO pg079_target_rules(normalized_name, logical_rule_key, expected_effect_json, expected_deck_role_json, target_confidence)
VALUES
  (
    'flare of duplication',
    'battle_rule_v1:b82bbb548dab138fa0700cb4cf905617',
    '{"cmc":3.0,"effect":"copy_spell","instant":true,"target":"instant_or_sorcery_on_stack","may_choose_new_targets":true,"alternative_cost_status":"sacrifice_nontoken_red_creature_annotation_only","battle_model_scope":"copy_target_instant_or_sorcery_stack_spell_alt_cost_annotation_v1"}'::jsonb,
    '{"effect":"copy_spell","timing":"instant","category":"engine"}'::jsonb,
    0.95
  ),
  (
    'powerbalance',
    'battle_rule_v1:e35051e9c60b94a84ac9b71c11c7fc4b',
    '{"cmc":2.0,"effect":"draw_engine","trigger":"opponent_spell","draw_on_enter":false,"powerbalance_topdeck_free_cast_same_mana_value":true,"topdeck_free_cast_resolution_status":"compact_cast_to_graveyard_no_nested_resolution_v1","battle_model_scope":"opponent_spell_reveal_top_same_mana_value_free_cast_v1"}'::jsonb,
    '{"effect":"topdeck_free_cast","trigger":"opponent_spell","category":"engine"}'::jsonb,
    0.90
  ),
  (
    'reforge the soul',
    'battle_rule_v1:90b82cfc81ff726ac0fc96a1b220f263',
    '{"cmc":5.0,"effect":"draw_cards","count":7,"wheel":true,"wheel_like":true,"miracle":"1R","battle_model_scope":"each_player_discard_hand_draw_seven_miracle_annotation_v1"}'::jsonb,
    '{"effect":"draw_cards","category":"draw"}'::jsonb,
    0.97
  ),
  (
    'rise of the eldrazi',
    'battle_rule_v1:57d155e410ca3cc6a96e14ed50f524d4',
    '{"cmc":12.0,"effect":"composite_resolution","uncounterable":true,"exiles_self":true,"_composite_rule_components":[{"effect":"remove_permanent","target":"nonland_permanent"},{"effect":"draw_cards","count":4},{"effect":"extra_turn","turns":1}],"battle_model_scope":"uncounterable_destroy_target_permanent_target_player_draw_four_extra_turn_exile_v1"}'::jsonb,
    '{"effect":"composite_resolution","category":"wincon"}'::jsonb,
    0.96
  ),
  (
    'rite of the dragoncaller',
    'battle_rule_v1:b23bca3229a81d65750cf9c453c7943d',
    '{"cmc":6.0,"effect":"token_maker","trigger":"instant_sorcery_cast","trigger_effect":"token_maker","token_count":1,"token_name":"Dragon Token","token_power":5,"token_toughness":5,"token_flying":true,"battle_model_scope":"instant_sorcery_cast_create_5_5_flying_dragon_v1"}'::jsonb,
    '{"effect":"token_maker","category":"wincon"}'::jsonb,
    0.95
  ),
  (
    'storm herd',
    'battle_rule_v1:b041641dc875caa7987253389dc52839',
    '{"cmc":10.0,"effect":"token_maker","token_count":"life_total","token_name":"Pegasus Token","token_power":1,"token_toughness":1,"token_flying":true,"battle_model_scope":"life_total_flying_pegasus_token_maker_v1"}'::jsonb,
    '{"effect":"token_maker","category":"wincon"}'::jsonb,
    0.96
  ),
  (
    'witch enchanter // witch-blessed meadow',
    'battle_rule_v1:5768b971f1ab4f2d4d9b8bd6a768c132',
    '{"cmc":4.0,"effect":"creature","is_creature_permanent":true,"etb_remove_target":"artifact_or_enchantment","target_controller":"opponent","battle_model_scope":"creature_etb_destroy_opponent_artifact_or_enchantment_v1"}'::jsonb,
    '{"effect":"etb_remove_artifact_or_enchantment","timing":"creature_etb","category":"removal"}'::jsonb,
    0.94
  );

CREATE TABLE manaloom_deploy_audit.pg079_deck606_runtime_semantics_20260623_044955 AS
SELECT now() AS backed_up_at, to_jsonb(cbr) AS payload
FROM card_battle_rules cbr
JOIN cards c ON c.id = cbr.card_id
WHERE (
    cbr.execution_status = 'auto'
    AND cbr.review_status IN ('active', 'verified')
    AND cbr.oracle_hash IS NULL
    AND cbr.effect_json ? 'battle_model_scope'
    AND c.oracle_text IS NOT NULL
  )
  OR cbr.normalized_name IN (SELECT normalized_name FROM pg079_target_rules);

DO $$
DECLARE
  v_targets integer;
  v_target_oracle integer;
  v_target_missing_hash integer;
  v_target_hash_match integer;
  v_target_scoped integer;
  v_scoped_missing_hash integer;
BEGIN
  SELECT
    count(*),
    count(*) FILTER (WHERE c.oracle_text IS NOT NULL),
    count(*) FILTER (WHERE cbr.oracle_hash IS NULL),
    count(*) FILTER (WHERE cbr.oracle_hash = md5(coalesce(c.oracle_text, ''))),
    count(*) FILTER (WHERE cbr.effect_json ? 'battle_model_scope')
  INTO v_targets, v_target_oracle, v_target_missing_hash, v_target_hash_match, v_target_scoped
  FROM pg079_target_rules t
  JOIN card_battle_rules cbr
    ON cbr.normalized_name = t.normalized_name
   AND cbr.logical_rule_key = t.logical_rule_key
  JOIN cards c
    ON c.id = cbr.card_id
  WHERE cbr.source = 'curated'
    AND cbr.execution_status = 'auto'
    AND cbr.review_status IN ('active', 'verified');

  SELECT count(*)
  INTO v_scoped_missing_hash
  FROM card_battle_rules cbr
  JOIN cards c ON c.id = cbr.card_id
  WHERE cbr.execution_status = 'auto'
    AND cbr.review_status IN ('active', 'verified')
    AND cbr.oracle_hash IS NULL
    AND cbr.effect_json ? 'battle_model_scope'
    AND c.oracle_text IS NOT NULL;

  IF v_targets <> 7 THEN
    RAISE EXCEPTION 'PG079 target precondition failed: expected 7 trusted target rules, got %', v_targets;
  END IF;
  IF v_target_oracle <> 7 THEN
    RAISE EXCEPTION 'PG079 target precondition failed: expected 7 target oracle texts, got %', v_target_oracle;
  END IF;
  IF v_target_scoped <> 7 THEN
    RAISE EXCEPTION 'PG079 target precondition failed: expected 7 scoped target rules, got %', v_target_scoped;
  END IF;
  IF v_target_missing_hash NOT IN (0, 7) THEN
    RAISE EXCEPTION 'PG079 target precondition failed: expected 0 or 7 missing target hashes depending on prior concurrent target apply, got %', v_target_missing_hash;
  END IF;
  IF v_target_missing_hash = 0 AND v_target_hash_match <> 7 THEN
    RAISE EXCEPTION 'PG079 target precondition failed: expected 7 target hash matches when target hashes are already present, got %', v_target_hash_match;
  END IF;
  IF v_scoped_missing_hash <> 97 THEN
    RAISE EXCEPTION 'PG079 hash precondition failed: expected 97 scoped trusted rows missing hash, got %', v_scoped_missing_hash;
  END IF;
END $$;

DO $$
DECLARE
  v_updated integer;
BEGIN
  WITH updated AS (
    UPDATE card_battle_rules cbr
    SET
      oracle_hash = md5(coalesce(c.oracle_text, '')),
      reviewed_by = 'codex-auditor',
      reviewed_at = now(),
      updated_at = now(),
      last_seen_at = now(),
      notes = concat_ws(
        E'\n',
        nullif(cbr.notes, ''),
        'PG079: restored missing oracle_hash provenance for an already scoped trusted executable rule. No effect_json, deck_role_json, or deck composition change.'
      )
    FROM cards c
    WHERE c.id = cbr.card_id
      AND cbr.execution_status = 'auto'
      AND cbr.review_status IN ('active', 'verified')
      AND cbr.oracle_hash IS NULL
      AND cbr.effect_json ? 'battle_model_scope'
      AND c.oracle_text IS NOT NULL
    RETURNING 1
  )
  SELECT count(*) INTO v_updated FROM updated;

  IF v_updated <> 97 THEN
    RAISE EXCEPTION 'PG079 scoped hash restore failed: expected 97 updated rows, got %', v_updated;
  END IF;
END $$;

DO $$
DECLARE
  v_updated integer;
BEGIN
  WITH updated AS (
    UPDATE card_battle_rules cbr
    SET
      effect_json = t.expected_effect_json,
      deck_role_json = t.expected_deck_role_json,
      oracle_hash = md5(coalesce(c.oracle_text, '')),
      confidence = t.target_confidence,
      review_status = 'verified',
      execution_status = 'auto',
      rule_version = cbr.rule_version + 1,
      reviewed_by = 'codex-auditor',
      reviewed_at = now(),
      updated_at = now(),
      last_seen_at = now(),
      notes = concat_ws(
        E'\n',
        nullif(cbr.notes, ''),
        'PG079: filled missing deck606 high battle-critical runtime semantics after focused executor tests. This branch is used only when target semantics were not already present before this apply.'
      )
    FROM pg079_target_rules t, cards c
    WHERE cbr.normalized_name = t.normalized_name
      AND cbr.logical_rule_key = t.logical_rule_key
      AND c.id = cbr.card_id
      AND (
        cbr.oracle_hash IS NULL
        OR NOT (cbr.effect_json ? 'battle_model_scope')
      )
    RETURNING 1
  )
  SELECT count(*) INTO v_updated FROM updated;

  IF v_updated NOT IN (0, 7) THEN
    RAISE EXCEPTION 'PG079 target semantic update failed: expected 0 already-present or 7 updated rows, got %', v_updated;
  END IF;
END $$;

COMMIT;
