BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg674_boost_all_draw_new_server_boost_al_20260708_221124 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('bewildering blizzard', 'blinding spray', 'hydrolash')
   OR normalized_name LIKE 'bewildering blizzard // %'
   OR normalized_name LIKE 'blinding spray // %'
   OR normalized_name LIKE 'hydrolash // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('bewildering blizzard', 'Bewildering Blizzard', 'e3919b8158fa4ca767ebc87280c1b444', 'battle_rule_v1:20b9a31934f0273e2c7c04e71556d751', '{"_composite_rule_components":[{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":3,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"},{"battle_model_scope":"xmage_fixed_boost_all_or_opponents_creatures_until_eot_spell_v1","compose_on_resolution":true,"duration":"until_end_of_turn","effect":"global_stat_modifier_until_eot","power_boost":-3,"power_delta":-3,"target":"opponents_creatures","target_constraints":{"card_types":["creature"],"controller":"opponents"},"target_controller":"opponents","toughness_boost":0,"toughness_delta":0,"xmage_effect_class":"BoostAllEffect"}],"battle_model_scope":"xmage_fixed_boost_all_or_opponents_creatures_until_eot_draw_card_spell_v1","count":3,"draw_count":3,"effect":"composite_resolution","instant":true,"power_boost":-3,"power_delta":-3,"resolution_order":"draw_then_boost","sorcery":false,"target":"opponents_creatures","target_constraints":{"card_types":["creature"],"controller":"opponents"},"target_controller":"opponents","toughness_boost":0,"toughness_delta":0,"xmage_effect_classes":["BoostAllEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"opponents_creatures","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BewilderingBlizzard translated into ManaLoom runtime scope xmage_fixed_boost_all_or_opponents_creatures_until_eot_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow fixed all/opponents/filtered-creature boost plus draw-card spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('blinding spray', 'Blinding Spray', '6d5bb5f069b8abded312db6dce1fa30a', 'battle_rule_v1:dc28e66e63622544aa582d3021171e9a', '{"_composite_rule_components":[{"battle_model_scope":"xmage_fixed_boost_all_or_opponents_creatures_until_eot_spell_v1","compose_on_resolution":true,"duration":"until_end_of_turn","effect":"global_stat_modifier_until_eot","power_boost":-4,"power_delta":-4,"target":"opponents_creatures","target_constraints":{"card_types":["creature"],"controller":"opponents"},"target_controller":"opponents","toughness_boost":0,"toughness_delta":0,"xmage_effect_class":"BoostAllEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_fixed_boost_all_or_opponents_creatures_until_eot_draw_card_spell_v1","count":1,"draw_count":1,"effect":"composite_resolution","instant":true,"power_boost":-4,"power_delta":-4,"resolution_order":"boost_then_draw","sorcery":false,"target":"opponents_creatures","target_constraints":{"card_types":["creature"],"controller":"opponents"},"target_controller":"opponents","toughness_boost":0,"toughness_delta":0,"xmage_effect_classes":["BoostAllEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"opponents_creatures","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BlindingSpray translated into ManaLoom runtime scope xmage_fixed_boost_all_or_opponents_creatures_until_eot_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow fixed all/opponents/filtered-creature boost plus draw-card spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('hydrolash', 'Hydrolash', '3a690e555ed48a9dc42db087954023f2', 'battle_rule_v1:c31ef85a2a29d1a155ad6938c698a707', '{"_composite_rule_components":[{"battle_model_scope":"xmage_fixed_boost_filtered_creatures_until_eot_spell_v1","compose_on_resolution":true,"creature_filter":{"combat_state":"attacking"},"duration":"until_end_of_turn","effect":"global_stat_modifier_until_eot","power_boost":-2,"power_delta":-2,"target":"attacking_creatures","target_constraints":{"card_types":["creature"],"creature_filter":{"combat_state":"attacking"}},"target_controller":"all","toughness_boost":0,"toughness_delta":0,"xmage_effect_class":"BoostAllEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_fixed_boost_all_or_opponents_creatures_until_eot_draw_card_spell_v1","count":1,"creature_filter":{"combat_state":"attacking"},"draw_count":1,"effect":"composite_resolution","instant":true,"power_boost":-2,"power_delta":-2,"resolution_order":"boost_then_draw","sorcery":false,"target":"attacking_creatures","target_constraints":{"card_types":["creature"],"creature_filter":{"combat_state":"attacking"}},"target_controller":"all","toughness_boost":0,"toughness_delta":0,"xmage_effect_classes":["BoostAllEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"attacking_creatures","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Hydrolash translated into ManaLoom runtime scope xmage_fixed_boost_all_or_opponents_creatures_until_eot_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow fixed all/opponents/filtered-creature boost plus draw-card spell with focused runtime coverage.', 'deprecate_nonmatching_rows')
),
  counts AS (
    SELECT
      p.card_name,
      p.normalized_name,
      p.oracle_hash,
      count(c.id) AS target_card_rows,
      min(c.id::text)::uuid AS canonical_card_id
    FROM proposed p
    LEFT JOIN public.cards c
      ON (
           lower(c.name) = p.normalized_name
           OR split_part(lower(c.name), ' // ', 1) = p.normalized_name
         )
     AND md5(coalesce(c.oracle_text, '')) = p.oracle_hash
    GROUP BY p.card_name, p.normalized_name, p.oracle_hash
  )
  SELECT jsonb_agg(counts ORDER BY card_name)
    INTO v_missing
  FROM counts
  WHERE target_card_rows < 1;

  IF v_missing IS NOT NULL THEN
    RAISE EXCEPTION 'XMage batch package abort: expected at least one Oracle-hash-matched card row for every proposed card: %', v_missing;
  END IF;
END $$;

WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('bewildering blizzard', 'Bewildering Blizzard', 'e3919b8158fa4ca767ebc87280c1b444', 'battle_rule_v1:20b9a31934f0273e2c7c04e71556d751', '{"_composite_rule_components":[{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":3,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"},{"battle_model_scope":"xmage_fixed_boost_all_or_opponents_creatures_until_eot_spell_v1","compose_on_resolution":true,"duration":"until_end_of_turn","effect":"global_stat_modifier_until_eot","power_boost":-3,"power_delta":-3,"target":"opponents_creatures","target_constraints":{"card_types":["creature"],"controller":"opponents"},"target_controller":"opponents","toughness_boost":0,"toughness_delta":0,"xmage_effect_class":"BoostAllEffect"}],"battle_model_scope":"xmage_fixed_boost_all_or_opponents_creatures_until_eot_draw_card_spell_v1","count":3,"draw_count":3,"effect":"composite_resolution","instant":true,"power_boost":-3,"power_delta":-3,"resolution_order":"draw_then_boost","sorcery":false,"target":"opponents_creatures","target_constraints":{"card_types":["creature"],"controller":"opponents"},"target_controller":"opponents","toughness_boost":0,"toughness_delta":0,"xmage_effect_classes":["BoostAllEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"opponents_creatures","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BewilderingBlizzard translated into ManaLoom runtime scope xmage_fixed_boost_all_or_opponents_creatures_until_eot_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow fixed all/opponents/filtered-creature boost plus draw-card spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('blinding spray', 'Blinding Spray', '6d5bb5f069b8abded312db6dce1fa30a', 'battle_rule_v1:dc28e66e63622544aa582d3021171e9a', '{"_composite_rule_components":[{"battle_model_scope":"xmage_fixed_boost_all_or_opponents_creatures_until_eot_spell_v1","compose_on_resolution":true,"duration":"until_end_of_turn","effect":"global_stat_modifier_until_eot","power_boost":-4,"power_delta":-4,"target":"opponents_creatures","target_constraints":{"card_types":["creature"],"controller":"opponents"},"target_controller":"opponents","toughness_boost":0,"toughness_delta":0,"xmage_effect_class":"BoostAllEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_fixed_boost_all_or_opponents_creatures_until_eot_draw_card_spell_v1","count":1,"draw_count":1,"effect":"composite_resolution","instant":true,"power_boost":-4,"power_delta":-4,"resolution_order":"boost_then_draw","sorcery":false,"target":"opponents_creatures","target_constraints":{"card_types":["creature"],"controller":"opponents"},"target_controller":"opponents","toughness_boost":0,"toughness_delta":0,"xmage_effect_classes":["BoostAllEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"opponents_creatures","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BlindingSpray translated into ManaLoom runtime scope xmage_fixed_boost_all_or_opponents_creatures_until_eot_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow fixed all/opponents/filtered-creature boost plus draw-card spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('hydrolash', 'Hydrolash', '3a690e555ed48a9dc42db087954023f2', 'battle_rule_v1:c31ef85a2a29d1a155ad6938c698a707', '{"_composite_rule_components":[{"battle_model_scope":"xmage_fixed_boost_filtered_creatures_until_eot_spell_v1","compose_on_resolution":true,"creature_filter":{"combat_state":"attacking"},"duration":"until_end_of_turn","effect":"global_stat_modifier_until_eot","power_boost":-2,"power_delta":-2,"target":"attacking_creatures","target_constraints":{"card_types":["creature"],"creature_filter":{"combat_state":"attacking"}},"target_controller":"all","toughness_boost":0,"toughness_delta":0,"xmage_effect_class":"BoostAllEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_fixed_boost_all_or_opponents_creatures_until_eot_draw_card_spell_v1","count":1,"creature_filter":{"combat_state":"attacking"},"draw_count":1,"effect":"composite_resolution","instant":true,"power_boost":-2,"power_delta":-2,"resolution_order":"boost_then_draw","sorcery":false,"target":"attacking_creatures","target_constraints":{"card_types":["creature"],"creature_filter":{"combat_state":"attacking"}},"target_controller":"all","toughness_boost":0,"toughness_delta":0,"xmage_effect_classes":["BoostAllEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"attacking_creatures","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Hydrolash translated into ManaLoom runtime scope xmage_fixed_boost_all_or_opponents_creatures_until_eot_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow fixed all/opponents/filtered-creature boost plus draw-card spell with focused runtime coverage.', 'deprecate_nonmatching_rows')
),
deprecated AS (
  UPDATE public.card_battle_rules r
  SET
    review_status = 'deprecated',
    execution_status = 'disabled',
    updated_at = now(),
    notes = concat_ws(E'\n', nullif(r.notes, ''), 'XMage batch package: deprecated stale shadow before curated batch rule upsert.')
  FROM proposed p
  WHERE (
        r.normalized_name = p.normalized_name
        OR r.normalized_name LIKE p.normalized_name || ' // %'
      )
    AND p.shadow_handling <> 'preserve_existing_rows'
    AND r.logical_rule_key <> p.logical_rule_key
  RETURNING r.*
)
SELECT count(*) AS deprecated_shadow_rows FROM deprecated;

WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('bewildering blizzard', 'Bewildering Blizzard', 'e3919b8158fa4ca767ebc87280c1b444', 'battle_rule_v1:20b9a31934f0273e2c7c04e71556d751', '{"_composite_rule_components":[{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":3,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"},{"battle_model_scope":"xmage_fixed_boost_all_or_opponents_creatures_until_eot_spell_v1","compose_on_resolution":true,"duration":"until_end_of_turn","effect":"global_stat_modifier_until_eot","power_boost":-3,"power_delta":-3,"target":"opponents_creatures","target_constraints":{"card_types":["creature"],"controller":"opponents"},"target_controller":"opponents","toughness_boost":0,"toughness_delta":0,"xmage_effect_class":"BoostAllEffect"}],"battle_model_scope":"xmage_fixed_boost_all_or_opponents_creatures_until_eot_draw_card_spell_v1","count":3,"draw_count":3,"effect":"composite_resolution","instant":true,"power_boost":-3,"power_delta":-3,"resolution_order":"draw_then_boost","sorcery":false,"target":"opponents_creatures","target_constraints":{"card_types":["creature"],"controller":"opponents"},"target_controller":"opponents","toughness_boost":0,"toughness_delta":0,"xmage_effect_classes":["BoostAllEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"opponents_creatures","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BewilderingBlizzard translated into ManaLoom runtime scope xmage_fixed_boost_all_or_opponents_creatures_until_eot_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow fixed all/opponents/filtered-creature boost plus draw-card spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('blinding spray', 'Blinding Spray', '6d5bb5f069b8abded312db6dce1fa30a', 'battle_rule_v1:dc28e66e63622544aa582d3021171e9a', '{"_composite_rule_components":[{"battle_model_scope":"xmage_fixed_boost_all_or_opponents_creatures_until_eot_spell_v1","compose_on_resolution":true,"duration":"until_end_of_turn","effect":"global_stat_modifier_until_eot","power_boost":-4,"power_delta":-4,"target":"opponents_creatures","target_constraints":{"card_types":["creature"],"controller":"opponents"},"target_controller":"opponents","toughness_boost":0,"toughness_delta":0,"xmage_effect_class":"BoostAllEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_fixed_boost_all_or_opponents_creatures_until_eot_draw_card_spell_v1","count":1,"draw_count":1,"effect":"composite_resolution","instant":true,"power_boost":-4,"power_delta":-4,"resolution_order":"boost_then_draw","sorcery":false,"target":"opponents_creatures","target_constraints":{"card_types":["creature"],"controller":"opponents"},"target_controller":"opponents","toughness_boost":0,"toughness_delta":0,"xmage_effect_classes":["BoostAllEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"opponents_creatures","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BlindingSpray translated into ManaLoom runtime scope xmage_fixed_boost_all_or_opponents_creatures_until_eot_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow fixed all/opponents/filtered-creature boost plus draw-card spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('hydrolash', 'Hydrolash', '3a690e555ed48a9dc42db087954023f2', 'battle_rule_v1:c31ef85a2a29d1a155ad6938c698a707', '{"_composite_rule_components":[{"battle_model_scope":"xmage_fixed_boost_filtered_creatures_until_eot_spell_v1","compose_on_resolution":true,"creature_filter":{"combat_state":"attacking"},"duration":"until_end_of_turn","effect":"global_stat_modifier_until_eot","power_boost":-2,"power_delta":-2,"target":"attacking_creatures","target_constraints":{"card_types":["creature"],"creature_filter":{"combat_state":"attacking"}},"target_controller":"all","toughness_boost":0,"toughness_delta":0,"xmage_effect_class":"BoostAllEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_fixed_boost_all_or_opponents_creatures_until_eot_draw_card_spell_v1","count":1,"creature_filter":{"combat_state":"attacking"},"draw_count":1,"effect":"composite_resolution","instant":true,"power_boost":-2,"power_delta":-2,"resolution_order":"boost_then_draw","sorcery":false,"target":"attacking_creatures","target_constraints":{"card_types":["creature"],"creature_filter":{"combat_state":"attacking"}},"target_controller":"all","toughness_boost":0,"toughness_delta":0,"xmage_effect_classes":["BoostAllEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"attacking_creatures","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Hydrolash translated into ManaLoom runtime scope xmage_fixed_boost_all_or_opponents_creatures_until_eot_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow fixed all/opponents/filtered-creature boost plus draw-card spell with focused runtime coverage.', 'deprecate_nonmatching_rows')
),
matched_cards AS (
  SELECT
    p.normalized_name,
    p.card_name,
    p.oracle_hash,
    c.id AS card_id,
    c.name AS db_card_name
  FROM proposed p
  JOIN public.cards c
    ON (
         lower(c.name) = p.normalized_name
         OR split_part(lower(c.name), ' // ', 1) = p.normalized_name
       )
   AND md5(coalesce(c.oracle_text, '')) = p.oracle_hash
),
canonical_target_cards AS (
  SELECT
    p.*,
    min(m.card_id::text)::uuid AS card_id,
    min(m.db_card_name) AS db_card_name
  FROM proposed p
  JOIN matched_cards m
    USING (normalized_name, card_name, oracle_hash)
  GROUP BY
    p.normalized_name,
    p.card_name,
    p.oracle_hash,
    p.logical_rule_key,
    p.effect_json,
    p.deck_role_json,
    p.source,
    p.confidence,
    p.review_status,
    p.execution_status,
    p.notes,
    p.shadow_handling
),
upserted AS (
  INSERT INTO public.card_battle_rules (
    normalized_name,
    card_id,
    card_name,
    effect_json,
    deck_role_json,
    source,
    confidence,
    review_status,
    rule_version,
    oracle_hash,
    notes,
    reviewed_by,
    reviewed_at,
    created_at,
    updated_at,
    last_seen_at,
    logical_rule_key,
    execution_status
  )
  SELECT
    normalized_name,
    card_id,
    db_card_name,
    effect_json,
    deck_role_json,
    source,
    confidence,
    review_status,
    2,
    oracle_hash,
    notes,
    'codex-xmage-batch',
    now(),
    now(),
    now(),
    now(),
    logical_rule_key,
    execution_status
  FROM canonical_target_cards
  ON CONFLICT (normalized_name, logical_rule_key) DO UPDATE
  SET
    card_id = EXCLUDED.card_id,
    card_name = EXCLUDED.card_name,
    effect_json = EXCLUDED.effect_json,
    deck_role_json = EXCLUDED.deck_role_json,
    source = EXCLUDED.source,
    confidence = EXCLUDED.confidence,
    review_status = EXCLUDED.review_status,
    rule_version = EXCLUDED.rule_version,
    oracle_hash = EXCLUDED.oracle_hash,
    notes = EXCLUDED.notes,
    reviewed_by = EXCLUDED.reviewed_by,
    reviewed_at = EXCLUDED.reviewed_at,
    updated_at = EXCLUDED.updated_at,
    last_seen_at = EXCLUDED.last_seen_at,
    execution_status = EXCLUDED.execution_status
  RETURNING *
)
SELECT count(*) AS upserted_rows FROM upserted;

COMMIT;
