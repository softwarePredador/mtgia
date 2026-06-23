\pset pager off

CREATE TEMP TABLE pg079_target_rules(
  normalized_name text,
  logical_rule_key text,
  expected_effect_json jsonb,
  expected_deck_role_json jsonb
);

INSERT INTO pg079_target_rules(normalized_name, logical_rule_key, expected_effect_json, expected_deck_role_json)
VALUES
  ('flare of duplication','battle_rule_v1:b82bbb548dab138fa0700cb4cf905617','{"cmc":3.0,"effect":"copy_spell","instant":true,"target":"instant_or_sorcery_on_stack","may_choose_new_targets":true,"alternative_cost_status":"sacrifice_nontoken_red_creature_annotation_only","battle_model_scope":"copy_target_instant_or_sorcery_stack_spell_alt_cost_annotation_v1"}'::jsonb,'{"effect":"copy_spell","timing":"instant","category":"engine"}'::jsonb),
  ('powerbalance','battle_rule_v1:e35051e9c60b94a84ac9b71c11c7fc4b','{"cmc":2.0,"effect":"draw_engine","trigger":"opponent_spell","draw_on_enter":false,"powerbalance_topdeck_free_cast_same_mana_value":true,"topdeck_free_cast_resolution_status":"compact_cast_to_graveyard_no_nested_resolution_v1","battle_model_scope":"opponent_spell_reveal_top_same_mana_value_free_cast_v1"}'::jsonb,'{"effect":"topdeck_free_cast","trigger":"opponent_spell","category":"engine"}'::jsonb),
  ('reforge the soul','battle_rule_v1:90b82cfc81ff726ac0fc96a1b220f263','{"cmc":5.0,"effect":"draw_cards","count":7,"wheel":true,"wheel_like":true,"miracle":"1R","battle_model_scope":"each_player_discard_hand_draw_seven_miracle_annotation_v1"}'::jsonb,'{"effect":"draw_cards","category":"draw"}'::jsonb),
  ('rise of the eldrazi','battle_rule_v1:57d155e410ca3cc6a96e14ed50f524d4','{"cmc":12.0,"effect":"composite_resolution","uncounterable":true,"exiles_self":true,"_composite_rule_components":[{"effect":"remove_permanent","target":"nonland_permanent"},{"effect":"draw_cards","count":4},{"effect":"extra_turn","turns":1}],"battle_model_scope":"uncounterable_destroy_target_permanent_target_player_draw_four_extra_turn_exile_v1"}'::jsonb,'{"effect":"composite_resolution","category":"wincon"}'::jsonb),
  ('rite of the dragoncaller','battle_rule_v1:b23bca3229a81d65750cf9c453c7943d','{"cmc":6.0,"effect":"token_maker","trigger":"instant_sorcery_cast","trigger_effect":"token_maker","token_count":1,"token_name":"Dragon Token","token_power":5,"token_toughness":5,"token_flying":true,"battle_model_scope":"instant_sorcery_cast_create_5_5_flying_dragon_v1"}'::jsonb,'{"effect":"token_maker","category":"wincon"}'::jsonb),
  ('storm herd','battle_rule_v1:b041641dc875caa7987253389dc52839','{"cmc":10.0,"effect":"token_maker","token_count":"life_total","token_name":"Pegasus Token","token_power":1,"token_toughness":1,"token_flying":true,"battle_model_scope":"life_total_flying_pegasus_token_maker_v1"}'::jsonb,'{"effect":"token_maker","category":"wincon"}'::jsonb),
  ('witch enchanter // witch-blessed meadow','battle_rule_v1:5768b971f1ab4f2d4d9b8bd6a768c132','{"cmc":4.0,"effect":"creature","is_creature_permanent":true,"etb_remove_target":"artifact_or_enchantment","target_controller":"opponent","battle_model_scope":"creature_etb_destroy_opponent_artifact_or_enchantment_v1"}'::jsonb,'{"effect":"etb_remove_artifact_or_enchantment","timing":"creature_etb","category":"removal"}'::jsonb);

WITH target_rows AS (
  SELECT
    t.normalized_name,
    t.logical_rule_key,
    c.name,
    md5(coalesce(c.oracle_text, '')) AS expected_oracle_hash,
    cbr.source,
    cbr.review_status,
    cbr.execution_status,
    cbr.confidence,
    cbr.rule_version,
    cbr.oracle_hash,
    cbr.effect_json,
    cbr.deck_role_json,
    t.expected_effect_json,
    t.expected_deck_role_json
  FROM pg079_target_rules t
  JOIN card_battle_rules cbr
    ON cbr.normalized_name = t.normalized_name
   AND cbr.logical_rule_key = t.logical_rule_key
  JOIN cards c
    ON c.id = cbr.card_id
),
scoped_missing_hash AS (
  SELECT cbr.*
  FROM card_battle_rules cbr
  JOIN cards c ON c.id = cbr.card_id
  WHERE cbr.execution_status = 'auto'
    AND cbr.review_status IN ('active', 'verified')
    AND cbr.oracle_hash IS NULL
    AND cbr.effect_json ? 'battle_model_scope'
    AND c.oracle_text IS NOT NULL
)
SELECT
  (SELECT count(*) FROM pg079_target_rules) AS expected_target_rules,
  count(*) AS target_rule_rows,
  count(*) FILTER (WHERE oracle_hash = expected_oracle_hash) AS target_hash_match_rows,
  count(*) FILTER (WHERE oracle_hash IS NULL) AS target_missing_hash_rows,
  count(*) FILTER (WHERE effect_json ? 'battle_model_scope') AS target_scoped_rows,
  count(*) FILTER (
    WHERE
      (
        normalized_name = 'flare of duplication'
        AND effect_json->>'effect' = 'copy_spell'
        AND effect_json->>'target' = 'instant_or_sorcery_on_stack'
        AND effect_json->>'battle_model_scope' = 'copy_target_instant_or_sorcery_stack_spell_alt_cost_annotation_v1'
      )
      OR (
        normalized_name = 'powerbalance'
        AND effect_json->>'effect' = 'draw_engine'
        AND effect_json->>'trigger' = 'opponent_spell'
        AND (effect_json->>'powerbalance_topdeck_free_cast_same_mana_value')::boolean IS TRUE
        AND effect_json->>'battle_model_scope' = 'opponent_spell_reveal_top_same_mana_value_free_cast_v1'
      )
      OR (
        normalized_name = 'reforge the soul'
        AND effect_json->>'effect' = 'draw_cards'
        AND (effect_json->>'count')::integer = 7
        AND effect_json->>'battle_model_scope' = 'each_player_discard_hand_draw_seven_miracle_annotation_v1'
      )
      OR (
        normalized_name = 'rise of the eldrazi'
        AND effect_json->>'effect' = 'composite_resolution'
        AND effect_json ? '_composite_rule_components'
        AND effect_json->>'battle_model_scope' = 'uncounterable_destroy_target_permanent_target_player_draw_four_extra_turn_exile_v1'
      )
      OR (
        normalized_name = 'rite of the dragoncaller'
        AND effect_json->>'effect' = 'token_maker'
        AND effect_json->>'trigger' = 'instant_sorcery_cast'
        AND (effect_json->>'token_power')::integer = 5
        AND effect_json->>'battle_model_scope' = 'instant_sorcery_cast_create_5_5_flying_dragon_v1'
      )
      OR (
        normalized_name = 'storm herd'
        AND effect_json->>'effect' = 'token_maker'
        AND effect_json->>'token_count' = 'life_total'
        AND (effect_json->>'token_flying')::boolean IS TRUE
        AND effect_json->>'battle_model_scope' = 'life_total_flying_pegasus_token_maker_v1'
      )
      OR (
        normalized_name = 'witch enchanter // witch-blessed meadow'
        AND effect_json->>'effect' = 'creature'
        AND effect_json->>'etb_remove_target' = 'artifact_or_enchantment'
        AND effect_json->>'battle_model_scope' = 'creature_etb_destroy_opponent_artifact_or_enchantment_v1'
      )
  ) AS target_required_semantic_fields_rows,
  count(*) FILTER (WHERE review_status = 'verified' AND execution_status = 'auto') AS target_verified_auto_rows,
  (SELECT count(*) FROM scoped_missing_hash) AS scoped_trusted_auto_missing_hash_rows,
  (SELECT count(*) FROM manaloom_deploy_audit.pg079_deck606_runtime_semantics_20260623_044955) AS backup_rows
FROM target_rows;

SELECT
  c.name,
  c.type_line,
  c.mana_cost,
  c.cmc,
  cbr.logical_rule_key,
  cbr.review_status,
  cbr.execution_status,
  cbr.confidence,
  cbr.rule_version,
  cbr.oracle_hash,
  md5(coalesce(c.oracle_text, '')) AS expected_oracle_hash,
  cbr.effect_json->>'effect' AS effect,
  cbr.effect_json->>'battle_model_scope' AS battle_model_scope,
  cbr.effect_json
FROM pg079_target_rules t
JOIN card_battle_rules cbr
  ON cbr.normalized_name = t.normalized_name
 AND cbr.logical_rule_key = t.logical_rule_key
JOIN cards c
  ON c.id = cbr.card_id
ORDER BY c.name;
