BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg845_conditional_activated_draw_new_ser_20260712_211331 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('endless atlas', 'falkenrath pit fighter', 'fool''s tome', 'ragamuffyn', 'tapestry of the ages')
   OR normalized_name LIKE 'endless atlas // %'
   OR normalized_name LIKE 'falkenrath pit fighter // %'
   OR normalized_name LIKE 'fool''s tome // %'
   OR normalized_name LIKE 'ragamuffyn // %'
   OR normalized_name LIKE 'tapestry of the ages // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('endless atlas', 'Endless Atlas', 'db628c828e9ac8519d479ef2f8ef58fd', 'battle_rule_v1:2d9432282c7d81378eaa782c1af6f921', '{"ability_kind":"activated","activated_draw":true,"activated_draw_count":1,"activated_effect":"draw_cards","activation_condition":"controller_controls_lands_same_name_gte","activation_condition_land_same_name_threshold":3,"activation_condition_status":"runtime_executor_v1","activation_cost_colors":[],"activation_cost_generic":2,"activation_cost_mana":"{2}","activation_requires_sacrifice":false,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_draw_v1","count":1,"effect":"draw_engine","permanent_type":"artifact","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"draw","effect":"draw_engine"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class EndlessAtlas translated into ManaLoom runtime scope xmage_permanent_simple_activated_draw_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated draw ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('falkenrath pit fighter', 'Falkenrath Pit Fighter', '47c0bbc6b3de23331823224dd0d3868c', 'battle_rule_v1:1135af3cd6d0b977ac182845987336f2', '{"ability_kind":"activated","activated_draw":true,"activated_draw_count":2,"activated_effect":"draw_cards","activation_condition":"opponent_lost_life_this_turn","activation_condition_opponent_life_lost_threshold":1,"activation_condition_status":"runtime_executor_v1","activation_cost_colors":["R"],"activation_cost_generic":1,"activation_cost_mana":"{1}{R}","activation_discard_count":1,"activation_discard_target":"any_card","activation_requires_discard_card":true,"activation_requires_sacrifice":false,"activation_requires_sacrifice_target":true,"activation_requires_tap":false,"activation_sacrifice_target":"vampire","battle_model_scope":"xmage_permanent_simple_activated_draw_v1","count":2,"effect":"draw_engine","permanent_type":"creature","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"draw","effect":"draw_engine"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FalkenrathPitFighter translated into ManaLoom runtime scope xmage_permanent_simple_activated_draw_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated draw ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('fool''s tome', 'Fool''s Tome', '49e29b58d3c5ddd4db576ed76e322551', 'battle_rule_v1:6c94429f211d447502f9c06ee33ef01e', '{"ability_kind":"activated","activated_draw":true,"activated_draw_count":1,"activated_effect":"draw_cards","activation_condition":"controller_has_no_cards_in_hand","activation_condition_status":"runtime_executor_v1","activation_cost_colors":[],"activation_cost_generic":2,"activation_cost_mana":"{2}","activation_requires_sacrifice":false,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_draw_v1","count":1,"effect":"draw_engine","permanent_type":"artifact","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"draw","effect":"draw_engine"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FoolsTome translated into ManaLoom runtime scope xmage_permanent_simple_activated_draw_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated draw ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('ragamuffyn', 'Ragamuffyn', 'd220bbe646cf679b6f263262bcd81eed', 'battle_rule_v1:8c887ae0a132334d87aac47b41d82096', '{"ability_kind":"activated","activated_draw":true,"activated_draw_count":1,"activated_effect":"draw_cards","activation_condition":"controller_has_no_cards_in_hand","activation_condition_status":"runtime_executor_v1","activation_cost_colors":[],"activation_cost_generic":0,"activation_cost_mana":"{0}","activation_requires_sacrifice":false,"activation_requires_sacrifice_target":true,"activation_requires_tap":true,"activation_sacrifice_target":"creature_or_land","battle_model_scope":"xmage_permanent_simple_activated_draw_v1","count":1,"effect":"draw_engine","permanent_type":"creature","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"draw","effect":"draw_engine"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Ragamuffyn translated into ManaLoom runtime scope xmage_permanent_simple_activated_draw_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated draw ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('tapestry of the ages', 'Tapestry of the Ages', 'd34211666b040792b018e60faedc4884', 'battle_rule_v1:e2fe8511410d4efad46dbd7288431d17', '{"ability_kind":"activated","activated_draw":true,"activated_draw_count":1,"activated_effect":"draw_cards","activation_condition":"controller_cast_noncreature_spell_this_turn","activation_condition_spell_count_threshold":1,"activation_condition_status":"runtime_executor_v1","activation_cost_colors":[],"activation_cost_generic":2,"activation_cost_mana":"{2}","activation_requires_sacrifice":false,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_draw_v1","count":1,"effect":"draw_engine","permanent_type":"artifact","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"draw","effect":"draw_engine"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TapestryOfTheAges translated into ManaLoom runtime scope xmage_permanent_simple_activated_draw_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated draw ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('endless atlas', 'Endless Atlas', 'db628c828e9ac8519d479ef2f8ef58fd', 'battle_rule_v1:2d9432282c7d81378eaa782c1af6f921', '{"ability_kind":"activated","activated_draw":true,"activated_draw_count":1,"activated_effect":"draw_cards","activation_condition":"controller_controls_lands_same_name_gte","activation_condition_land_same_name_threshold":3,"activation_condition_status":"runtime_executor_v1","activation_cost_colors":[],"activation_cost_generic":2,"activation_cost_mana":"{2}","activation_requires_sacrifice":false,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_draw_v1","count":1,"effect":"draw_engine","permanent_type":"artifact","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"draw","effect":"draw_engine"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class EndlessAtlas translated into ManaLoom runtime scope xmage_permanent_simple_activated_draw_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated draw ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('falkenrath pit fighter', 'Falkenrath Pit Fighter', '47c0bbc6b3de23331823224dd0d3868c', 'battle_rule_v1:1135af3cd6d0b977ac182845987336f2', '{"ability_kind":"activated","activated_draw":true,"activated_draw_count":2,"activated_effect":"draw_cards","activation_condition":"opponent_lost_life_this_turn","activation_condition_opponent_life_lost_threshold":1,"activation_condition_status":"runtime_executor_v1","activation_cost_colors":["R"],"activation_cost_generic":1,"activation_cost_mana":"{1}{R}","activation_discard_count":1,"activation_discard_target":"any_card","activation_requires_discard_card":true,"activation_requires_sacrifice":false,"activation_requires_sacrifice_target":true,"activation_requires_tap":false,"activation_sacrifice_target":"vampire","battle_model_scope":"xmage_permanent_simple_activated_draw_v1","count":2,"effect":"draw_engine","permanent_type":"creature","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"draw","effect":"draw_engine"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FalkenrathPitFighter translated into ManaLoom runtime scope xmage_permanent_simple_activated_draw_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated draw ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('fool''s tome', 'Fool''s Tome', '49e29b58d3c5ddd4db576ed76e322551', 'battle_rule_v1:6c94429f211d447502f9c06ee33ef01e', '{"ability_kind":"activated","activated_draw":true,"activated_draw_count":1,"activated_effect":"draw_cards","activation_condition":"controller_has_no_cards_in_hand","activation_condition_status":"runtime_executor_v1","activation_cost_colors":[],"activation_cost_generic":2,"activation_cost_mana":"{2}","activation_requires_sacrifice":false,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_draw_v1","count":1,"effect":"draw_engine","permanent_type":"artifact","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"draw","effect":"draw_engine"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FoolsTome translated into ManaLoom runtime scope xmage_permanent_simple_activated_draw_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated draw ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('ragamuffyn', 'Ragamuffyn', 'd220bbe646cf679b6f263262bcd81eed', 'battle_rule_v1:8c887ae0a132334d87aac47b41d82096', '{"ability_kind":"activated","activated_draw":true,"activated_draw_count":1,"activated_effect":"draw_cards","activation_condition":"controller_has_no_cards_in_hand","activation_condition_status":"runtime_executor_v1","activation_cost_colors":[],"activation_cost_generic":0,"activation_cost_mana":"{0}","activation_requires_sacrifice":false,"activation_requires_sacrifice_target":true,"activation_requires_tap":true,"activation_sacrifice_target":"creature_or_land","battle_model_scope":"xmage_permanent_simple_activated_draw_v1","count":1,"effect":"draw_engine","permanent_type":"creature","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"draw","effect":"draw_engine"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Ragamuffyn translated into ManaLoom runtime scope xmage_permanent_simple_activated_draw_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated draw ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('tapestry of the ages', 'Tapestry of the Ages', 'd34211666b040792b018e60faedc4884', 'battle_rule_v1:e2fe8511410d4efad46dbd7288431d17', '{"ability_kind":"activated","activated_draw":true,"activated_draw_count":1,"activated_effect":"draw_cards","activation_condition":"controller_cast_noncreature_spell_this_turn","activation_condition_spell_count_threshold":1,"activation_condition_status":"runtime_executor_v1","activation_cost_colors":[],"activation_cost_generic":2,"activation_cost_mana":"{2}","activation_requires_sacrifice":false,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_draw_v1","count":1,"effect":"draw_engine","permanent_type":"artifact","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"draw","effect":"draw_engine"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TapestryOfTheAges translated into ManaLoom runtime scope xmage_permanent_simple_activated_draw_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated draw ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('endless atlas', 'Endless Atlas', 'db628c828e9ac8519d479ef2f8ef58fd', 'battle_rule_v1:2d9432282c7d81378eaa782c1af6f921', '{"ability_kind":"activated","activated_draw":true,"activated_draw_count":1,"activated_effect":"draw_cards","activation_condition":"controller_controls_lands_same_name_gte","activation_condition_land_same_name_threshold":3,"activation_condition_status":"runtime_executor_v1","activation_cost_colors":[],"activation_cost_generic":2,"activation_cost_mana":"{2}","activation_requires_sacrifice":false,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_draw_v1","count":1,"effect":"draw_engine","permanent_type":"artifact","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"draw","effect":"draw_engine"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class EndlessAtlas translated into ManaLoom runtime scope xmage_permanent_simple_activated_draw_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated draw ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('falkenrath pit fighter', 'Falkenrath Pit Fighter', '47c0bbc6b3de23331823224dd0d3868c', 'battle_rule_v1:1135af3cd6d0b977ac182845987336f2', '{"ability_kind":"activated","activated_draw":true,"activated_draw_count":2,"activated_effect":"draw_cards","activation_condition":"opponent_lost_life_this_turn","activation_condition_opponent_life_lost_threshold":1,"activation_condition_status":"runtime_executor_v1","activation_cost_colors":["R"],"activation_cost_generic":1,"activation_cost_mana":"{1}{R}","activation_discard_count":1,"activation_discard_target":"any_card","activation_requires_discard_card":true,"activation_requires_sacrifice":false,"activation_requires_sacrifice_target":true,"activation_requires_tap":false,"activation_sacrifice_target":"vampire","battle_model_scope":"xmage_permanent_simple_activated_draw_v1","count":2,"effect":"draw_engine","permanent_type":"creature","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"draw","effect":"draw_engine"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FalkenrathPitFighter translated into ManaLoom runtime scope xmage_permanent_simple_activated_draw_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated draw ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('fool''s tome', 'Fool''s Tome', '49e29b58d3c5ddd4db576ed76e322551', 'battle_rule_v1:6c94429f211d447502f9c06ee33ef01e', '{"ability_kind":"activated","activated_draw":true,"activated_draw_count":1,"activated_effect":"draw_cards","activation_condition":"controller_has_no_cards_in_hand","activation_condition_status":"runtime_executor_v1","activation_cost_colors":[],"activation_cost_generic":2,"activation_cost_mana":"{2}","activation_requires_sacrifice":false,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_draw_v1","count":1,"effect":"draw_engine","permanent_type":"artifact","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"draw","effect":"draw_engine"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FoolsTome translated into ManaLoom runtime scope xmage_permanent_simple_activated_draw_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated draw ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('ragamuffyn', 'Ragamuffyn', 'd220bbe646cf679b6f263262bcd81eed', 'battle_rule_v1:8c887ae0a132334d87aac47b41d82096', '{"ability_kind":"activated","activated_draw":true,"activated_draw_count":1,"activated_effect":"draw_cards","activation_condition":"controller_has_no_cards_in_hand","activation_condition_status":"runtime_executor_v1","activation_cost_colors":[],"activation_cost_generic":0,"activation_cost_mana":"{0}","activation_requires_sacrifice":false,"activation_requires_sacrifice_target":true,"activation_requires_tap":true,"activation_sacrifice_target":"creature_or_land","battle_model_scope":"xmage_permanent_simple_activated_draw_v1","count":1,"effect":"draw_engine","permanent_type":"creature","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"draw","effect":"draw_engine"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Ragamuffyn translated into ManaLoom runtime scope xmage_permanent_simple_activated_draw_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated draw ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('tapestry of the ages', 'Tapestry of the Ages', 'd34211666b040792b018e60faedc4884', 'battle_rule_v1:e2fe8511410d4efad46dbd7288431d17', '{"ability_kind":"activated","activated_draw":true,"activated_draw_count":1,"activated_effect":"draw_cards","activation_condition":"controller_cast_noncreature_spell_this_turn","activation_condition_spell_count_threshold":1,"activation_condition_status":"runtime_executor_v1","activation_cost_colors":[],"activation_cost_generic":2,"activation_cost_mana":"{2}","activation_requires_sacrifice":false,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_draw_v1","count":1,"effect":"draw_engine","permanent_type":"artifact","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"draw","effect":"draw_engine"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TapestryOfTheAges translated into ManaLoom runtime scope xmage_permanent_simple_activated_draw_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated draw ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
