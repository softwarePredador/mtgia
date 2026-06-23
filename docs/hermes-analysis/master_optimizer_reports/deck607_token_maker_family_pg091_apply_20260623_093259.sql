BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

DO $$
BEGIN
  IF to_regclass('manaloom_deploy_audit.pg091_deck607_token_maker_family_20260623_093259') IS NOT NULL THEN
    RAISE EXCEPTION 'backup table manaloom_deploy_audit.pg091_deck607_token_maker_family_20260623_093259 already exists';
  END IF;
END $$;

CREATE TEMP TABLE pg091_deck607_token_maker_target AS
SELECT
  'Furygale Flocking'::text AS name,
  'furygale flocking'::text AS normalized_name,
  'battle_rule_v1:8efd14e0d2f631b8e9f0205cf6030f39'::text AS promote_from_key,
  'battle_rule_v1:63b66f50aad09aa5669ac693b2fca7e5'::text AS expected_logical_rule_key,
  '8946b0e85c8430c6105ea70c7fb2724a'::text AS expected_oracle_hash,
  'per_opponent_two_3_3_flying_hasty_elemental_tokens_v1'::text AS expected_scope,
  jsonb_build_object(
    'cmc', 10.0,
    'effect', 'token_maker',
    'token_count_per_opponent', 2,
    'token_name', 'Elemental Token',
    'token_subtype', 'Elemental',
    'token_colors', jsonb_build_array('U', 'R'),
    'token_power', 3,
    'token_toughness', 3,
    'token_flying', true,
    'token_haste', true,
    'cost_reduction_status', 'annotation_only',
    'cost_reduction_per_instant_sorcery_in_graveyard', 1,
    'attack_each_opponent_this_turn_status', 'annotation_only',
    'battle_model_scope', 'per_opponent_two_3_3_flying_hasty_elemental_tokens_v1',
    'oracle_runtime_scope', 'per_opponent_two_3_3_flying_hasty_elemental_tokens_cost_reduction_attack_annotation_v1'
  ) AS effect_json,
  jsonb_build_object(
    'effect', 'token_maker',
    'category', 'wincon',
    'timing', 'sorcery',
    'functions', jsonb_build_array('create_creature_tokens', 'graveyard_cost_reduction_annotation'),
    'runtime_modes', jsonb_build_array('token_count_per_opponent', 'creature_token_creation')
  ) AS deck_role_json,
  0.95::numeric AS confidence
UNION ALL
SELECT
  'Prismari Pianist',
  'prismari pianist',
  'battle_rule_v1:8efd14e0d2f631b8e9f0205cf6030f39',
  'battle_rule_v1:0288989021534a6f036968f62361f634',
  '1594ae692e3095e544f3cd3430d43e86',
  'instant_sorcery_cast_create_1_or_3_1_1_elementals_by_spell_mv_v1',
  jsonb_build_object(
    'cmc', 3.0,
    'effect', 'token_maker',
    'trigger', 'instant_sorcery_cast',
    'trigger_effect', 'token_maker',
    'trigger_token_count', 1,
    'trigger_token_count_if_spell_cmc_at_least', 5,
    'trigger_token_count_at_or_above_threshold', 3,
    'token_name', 'Elemental Token',
    'token_subtype', 'Elemental',
    'token_colors', jsonb_build_array('U', 'R'),
    'token_power', 1,
    'token_toughness', 1,
    'battle_model_scope', 'instant_sorcery_cast_create_1_or_3_1_1_elementals_by_spell_mv_v1',
    'oracle_runtime_scope', 'instant_sorcery_spell_cast_trigger_create_elementals_by_spell_mana_value_v1'
  ),
  jsonb_build_object(
    'effect', 'token_maker',
    'category', 'wincon',
    'timing', 'triggered_permanent',
    'functions', jsonb_build_array('instant_sorcery_spell_cast_token_trigger'),
    'runtime_modes', jsonb_build_array('triggered_token_creation', 'spell_mana_value_threshold')
  ),
  0.95::numeric
UNION ALL
SELECT
  'Tempt with Bunnies',
  'tempt with bunnies',
  'battle_rule_v1:030b2f3e0f549a462c3c8ea429877980',
  'battle_rule_v1:ac96c7799172699f5d7b6b0dc5e4aa80',
  '201f6c7234bfef550f3d497e736f0d7a',
  'tempting_offer_base_draw_one_component_v1',
  jsonb_build_object(
    'cmc', 3.0,
    'effect', 'draw_cards',
    'count', 1,
    'compose_on_resolution', true,
    'tempting_offer_default', 'opponents_decline',
    'tempting_offer_opponent_choice_status', 'annotation_only',
    'battle_model_scope', 'tempting_offer_base_draw_one_component_v1',
    'oracle_runtime_scope', 'tempting_offer_base_draw_one_opponent_choice_annotation_v1'
  ),
  jsonb_build_object(
    'effect', 'draw_cards',
    'category', 'draw',
    'timing', 'sorcery',
    'functions', jsonb_build_array('draw_one_base', 'tempting_offer_annotation'),
    'runtime_modes', jsonb_build_array('compose_on_resolution')
  ),
  0.92::numeric
UNION ALL
SELECT
  'Tempt with Bunnies',
  'tempt with bunnies',
  'battle_rule_v1:adf4845203520f2f668e196538e532f2',
  'battle_rule_v1:64814289c1def19e7cd5bb7462c4cf86',
  '201f6c7234bfef550f3d497e736f0d7a',
  'tempting_offer_base_create_1_1_white_rabbit_component_v1',
  jsonb_build_object(
    'cmc', 3.0,
    'effect', 'token_maker',
    'token_count', 1,
    'token_name', 'Rabbit Token',
    'token_subtype', 'Rabbit',
    'token_colors', jsonb_build_array('W'),
    'token_power', 1,
    'token_toughness', 1,
    'compose_on_resolution', true,
    'tempting_offer_default', 'opponents_decline',
    'tempting_offer_opponent_choice_status', 'annotation_only',
    'battle_model_scope', 'tempting_offer_base_create_1_1_white_rabbit_component_v1',
    'oracle_runtime_scope', 'tempting_offer_base_create_1_1_white_rabbit_opponent_choice_annotation_v1'
  ),
  jsonb_build_object(
    'effect', 'token_maker',
    'category', 'wincon',
    'timing', 'sorcery',
    'functions', jsonb_build_array('create_1_1_white_rabbit_base', 'tempting_offer_annotation'),
    'runtime_modes', jsonb_build_array('compose_on_resolution', 'creature_token_creation')
  ),
  0.92::numeric;

DO $$
DECLARE
  target_count integer;
  card_count integer;
  promotable_count integer;
  oracle_match_count integer;
  conflict_count integer;
BEGIN
  SELECT count(*) INTO target_count FROM pg091_deck607_token_maker_target;

  SELECT count(DISTINCT c.id) INTO card_count
  FROM pg091_deck607_token_maker_target t
  JOIN cards c ON lower(c.name) = t.normalized_name;

  SELECT count(*) INTO promotable_count
  FROM pg091_deck607_token_maker_target t
  JOIN card_battle_rules r
    ON r.normalized_name = t.normalized_name
   AND r.logical_rule_key = t.promote_from_key;

  SELECT count(*) INTO oracle_match_count
  FROM pg091_deck607_token_maker_target t
  JOIN cards c ON lower(c.name) = t.normalized_name
  WHERE md5(coalesce(c.oracle_text, '')) = t.expected_oracle_hash;

  SELECT count(*) INTO conflict_count
  FROM card_battle_rules r
  JOIN pg091_deck607_token_maker_target t
    ON r.logical_rule_key = t.expected_logical_rule_key
   AND r.normalized_name <> t.normalized_name;

  IF target_count <> 4 OR card_count <> 3 OR promotable_count <> 4 OR oracle_match_count <> 4 OR conflict_count <> 0 THEN
    RAISE EXCEPTION 'PG091 precondition failed target=% card=% promotable=% oracle_match=% conflicts=%',
      target_count, card_count, promotable_count, oracle_match_count, conflict_count;
  END IF;
END $$;

CREATE TABLE manaloom_deploy_audit.pg091_deck607_token_maker_family_20260623_093259 AS
SELECT DISTINCT r.*
FROM card_battle_rules r
JOIN pg091_deck607_token_maker_target t
  ON r.normalized_name = t.normalized_name;

UPDATE card_battle_rules r
SET
  logical_rule_key = t.expected_logical_rule_key,
  oracle_hash = t.expected_oracle_hash,
  effect_json = t.effect_json,
  deck_role_json = t.deck_role_json,
  source = 'curated',
  confidence = t.confidence,
  review_status = 'verified',
  execution_status = 'auto',
  rule_version = greatest(coalesce(r.rule_version, 1), 2),
  reviewed_by = 'codex-pg091',
  reviewed_at = now(),
  updated_at = now(),
  notes = concat_ws(E'\n', nullif(r.notes, ''), 'PG091 2026-06-23: deck 607 token-maker family. Promoted Oracle-specific token runtime with explicit annotation-only clauses; no deck swap.')
FROM pg091_deck607_token_maker_target t
WHERE r.normalized_name = t.normalized_name
  AND r.logical_rule_key = t.promote_from_key;

UPDATE card_battle_rules r
SET
  review_status = 'deprecated',
  execution_status = 'disabled',
  updated_at = now(),
  notes = concat_ws(E'\n', nullif(r.notes, ''), 'PG091 disabled: superseded generated/review-only token-maker shadow after card-specific family rule was validated.')
WHERE r.normalized_name IN (
    SELECT DISTINCT normalized_name FROM pg091_deck607_token_maker_target
  )
  AND r.logical_rule_key NOT IN (
    SELECT expected_logical_rule_key FROM pg091_deck607_token_maker_target
  )
  AND (
    r.source = 'generated'
    OR r.review_status IN ('needs_review', 'review_only')
    OR r.execution_status = 'review_only'
  );

COMMIT;
