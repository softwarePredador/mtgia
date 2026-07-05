BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg534_multi_tokens_new_server_20260705_223815 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('bestial menace', 'forbidden friendship', 'mascot exhibition')
   OR normalized_name LIKE 'bestial menace // %'
   OR normalized_name LIKE 'forbidden friendship // %'
   OR normalized_name LIKE 'mascot exhibition // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('bestial menace', 'Bestial Menace', '776667960e301f39134e382444e0d528', 'battle_rule_v1:7bd0274870194298d04700a6cfdd764e', '{"_composite_rule_components":[{"ability_kind":"one_shot","battle_model_scope":"xmage_fixed_create_creature_tokens_spell_v1","compose_on_resolution":true,"effect":"token_maker","token_colors":["G"],"token_count":1,"token_description":"1/1 green Snake creature token","token_name":"Snake Token","token_power":1,"token_subtype":"Snake","token_toughness":1,"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"SnakeToken"},{"ability_kind":"one_shot","battle_model_scope":"xmage_fixed_create_creature_tokens_spell_v1","compose_on_resolution":true,"effect":"token_maker","token_colors":["G"],"token_count":1,"token_description":"2/2 green Wolf creature token","token_name":"Wolf Token","token_power":2,"token_subtype":"Wolf","token_toughness":2,"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"WolfToken"},{"ability_kind":"one_shot","battle_model_scope":"xmage_fixed_create_creature_tokens_spell_v1","compose_on_resolution":true,"effect":"token_maker","token_colors":["G"],"token_count":1,"token_description":"3/3 green Elephant creature token","token_name":"Elephant Token","token_power":3,"token_subtype":"Elephant","token_toughness":3,"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"ElephantToken"}],"ability_kind":"one_shot","battle_model_scope":"xmage_multi_create_creature_tokens_spell_v1","effect":"composite_resolution","token_component_count":3,"token_total_count":3,"xmage_effect_class":"CreateTokenEffect","xmage_token_classes":["SnakeToken","WolfToken","ElephantToken"]}'::jsonb, '{"category":"wincon","effect":"composite_resolution","subtype":"token_suite"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BestialMenace translated into ManaLoom runtime scope xmage_multi_create_creature_tokens_spell_v1. This row is package-ready only because the source signature is a narrow fixed spell-resolution multi-creature-token maker with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('forbidden friendship', 'Forbidden Friendship', '153c16e01b9313ee675ec174b8232ed6', 'battle_rule_v1:d389d66da23728fa4e8d296036357ec2', '{"_composite_rule_components":[{"ability_kind":"one_shot","battle_model_scope":"xmage_fixed_create_creature_tokens_spell_v1","compose_on_resolution":true,"effect":"token_maker","token_colors":["R"],"token_count":1,"token_description":"1/1 red Dinosaur creature token with haste","token_haste":true,"token_keywords":["haste"],"token_name":"Dinosaur Token","token_power":1,"token_subtype":"Dinosaur","token_toughness":1,"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"DinosaurHasteToken"},{"ability_kind":"one_shot","battle_model_scope":"xmage_fixed_create_creature_tokens_spell_v1","compose_on_resolution":true,"effect":"token_maker","token_colors":["W"],"token_count":1,"token_description":"1/1 white Human Soldier creature token","token_name":"Human Soldier Token","token_power":1,"token_subtype":"Human Soldier","token_toughness":1,"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"HumanSoldierToken"}],"ability_kind":"one_shot","battle_model_scope":"xmage_multi_create_creature_tokens_spell_v1","effect":"composite_resolution","token_component_count":2,"token_total_count":2,"xmage_effect_class":"CreateTokenEffect","xmage_token_classes":["DinosaurHasteToken","HumanSoldierToken"]}'::jsonb, '{"category":"wincon","effect":"composite_resolution","subtype":"token_suite"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ForbiddenFriendship translated into ManaLoom runtime scope xmage_multi_create_creature_tokens_spell_v1. This row is package-ready only because the source signature is a narrow fixed spell-resolution multi-creature-token maker with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('mascot exhibition', 'Mascot Exhibition', 'ade5d3577a9263f1ce4504a5f6adf502', 'battle_rule_v1:e3cb683bd2371654f0aa9d57b630e774', '{"_composite_rule_components":[{"ability_kind":"one_shot","battle_model_scope":"xmage_fixed_create_creature_tokens_spell_v1","compose_on_resolution":true,"effect":"token_maker","token_colors":["W","B"],"token_count":1,"token_description":"2/1 white and black Inkling creature token with flying","token_flying":true,"token_keywords":["flying"],"token_name":"Inkling Token","token_power":2,"token_subtype":"Inkling","token_toughness":1,"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"InklingToken"},{"ability_kind":"one_shot","battle_model_scope":"xmage_fixed_create_creature_tokens_spell_v1","compose_on_resolution":true,"effect":"token_maker","token_colors":["W","R"],"token_count":1,"token_description":"3/2 red and white Spirit creature token","token_name":"Spirit Token","token_power":3,"token_subtype":"Spirit","token_toughness":2,"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"Spirit32Token"},{"ability_kind":"one_shot","battle_model_scope":"xmage_fixed_create_creature_tokens_spell_v1","compose_on_resolution":true,"effect":"token_maker","token_colors":["U","R"],"token_count":1,"token_description":"4/4 blue and red Elemental creature token","token_name":"Elemental Token","token_power":4,"token_subtype":"Elemental","token_toughness":4,"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"Elemental44Token"}],"ability_kind":"one_shot","battle_model_scope":"xmage_multi_create_creature_tokens_spell_v1","effect":"composite_resolution","token_component_count":3,"token_total_count":3,"xmage_effect_class":"CreateTokenEffect","xmage_token_classes":["InklingToken","Spirit32Token","Elemental44Token"]}'::jsonb, '{"category":"wincon","effect":"composite_resolution","subtype":"token_suite"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MascotExhibition translated into ManaLoom runtime scope xmage_multi_create_creature_tokens_spell_v1. This row is package-ready only because the source signature is a narrow fixed spell-resolution multi-creature-token maker with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('bestial menace', 'Bestial Menace', '776667960e301f39134e382444e0d528', 'battle_rule_v1:7bd0274870194298d04700a6cfdd764e', '{"_composite_rule_components":[{"ability_kind":"one_shot","battle_model_scope":"xmage_fixed_create_creature_tokens_spell_v1","compose_on_resolution":true,"effect":"token_maker","token_colors":["G"],"token_count":1,"token_description":"1/1 green Snake creature token","token_name":"Snake Token","token_power":1,"token_subtype":"Snake","token_toughness":1,"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"SnakeToken"},{"ability_kind":"one_shot","battle_model_scope":"xmage_fixed_create_creature_tokens_spell_v1","compose_on_resolution":true,"effect":"token_maker","token_colors":["G"],"token_count":1,"token_description":"2/2 green Wolf creature token","token_name":"Wolf Token","token_power":2,"token_subtype":"Wolf","token_toughness":2,"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"WolfToken"},{"ability_kind":"one_shot","battle_model_scope":"xmage_fixed_create_creature_tokens_spell_v1","compose_on_resolution":true,"effect":"token_maker","token_colors":["G"],"token_count":1,"token_description":"3/3 green Elephant creature token","token_name":"Elephant Token","token_power":3,"token_subtype":"Elephant","token_toughness":3,"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"ElephantToken"}],"ability_kind":"one_shot","battle_model_scope":"xmage_multi_create_creature_tokens_spell_v1","effect":"composite_resolution","token_component_count":3,"token_total_count":3,"xmage_effect_class":"CreateTokenEffect","xmage_token_classes":["SnakeToken","WolfToken","ElephantToken"]}'::jsonb, '{"category":"wincon","effect":"composite_resolution","subtype":"token_suite"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BestialMenace translated into ManaLoom runtime scope xmage_multi_create_creature_tokens_spell_v1. This row is package-ready only because the source signature is a narrow fixed spell-resolution multi-creature-token maker with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('forbidden friendship', 'Forbidden Friendship', '153c16e01b9313ee675ec174b8232ed6', 'battle_rule_v1:d389d66da23728fa4e8d296036357ec2', '{"_composite_rule_components":[{"ability_kind":"one_shot","battle_model_scope":"xmage_fixed_create_creature_tokens_spell_v1","compose_on_resolution":true,"effect":"token_maker","token_colors":["R"],"token_count":1,"token_description":"1/1 red Dinosaur creature token with haste","token_haste":true,"token_keywords":["haste"],"token_name":"Dinosaur Token","token_power":1,"token_subtype":"Dinosaur","token_toughness":1,"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"DinosaurHasteToken"},{"ability_kind":"one_shot","battle_model_scope":"xmage_fixed_create_creature_tokens_spell_v1","compose_on_resolution":true,"effect":"token_maker","token_colors":["W"],"token_count":1,"token_description":"1/1 white Human Soldier creature token","token_name":"Human Soldier Token","token_power":1,"token_subtype":"Human Soldier","token_toughness":1,"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"HumanSoldierToken"}],"ability_kind":"one_shot","battle_model_scope":"xmage_multi_create_creature_tokens_spell_v1","effect":"composite_resolution","token_component_count":2,"token_total_count":2,"xmage_effect_class":"CreateTokenEffect","xmage_token_classes":["DinosaurHasteToken","HumanSoldierToken"]}'::jsonb, '{"category":"wincon","effect":"composite_resolution","subtype":"token_suite"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ForbiddenFriendship translated into ManaLoom runtime scope xmage_multi_create_creature_tokens_spell_v1. This row is package-ready only because the source signature is a narrow fixed spell-resolution multi-creature-token maker with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('mascot exhibition', 'Mascot Exhibition', 'ade5d3577a9263f1ce4504a5f6adf502', 'battle_rule_v1:e3cb683bd2371654f0aa9d57b630e774', '{"_composite_rule_components":[{"ability_kind":"one_shot","battle_model_scope":"xmage_fixed_create_creature_tokens_spell_v1","compose_on_resolution":true,"effect":"token_maker","token_colors":["W","B"],"token_count":1,"token_description":"2/1 white and black Inkling creature token with flying","token_flying":true,"token_keywords":["flying"],"token_name":"Inkling Token","token_power":2,"token_subtype":"Inkling","token_toughness":1,"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"InklingToken"},{"ability_kind":"one_shot","battle_model_scope":"xmage_fixed_create_creature_tokens_spell_v1","compose_on_resolution":true,"effect":"token_maker","token_colors":["W","R"],"token_count":1,"token_description":"3/2 red and white Spirit creature token","token_name":"Spirit Token","token_power":3,"token_subtype":"Spirit","token_toughness":2,"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"Spirit32Token"},{"ability_kind":"one_shot","battle_model_scope":"xmage_fixed_create_creature_tokens_spell_v1","compose_on_resolution":true,"effect":"token_maker","token_colors":["U","R"],"token_count":1,"token_description":"4/4 blue and red Elemental creature token","token_name":"Elemental Token","token_power":4,"token_subtype":"Elemental","token_toughness":4,"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"Elemental44Token"}],"ability_kind":"one_shot","battle_model_scope":"xmage_multi_create_creature_tokens_spell_v1","effect":"composite_resolution","token_component_count":3,"token_total_count":3,"xmage_effect_class":"CreateTokenEffect","xmage_token_classes":["InklingToken","Spirit32Token","Elemental44Token"]}'::jsonb, '{"category":"wincon","effect":"composite_resolution","subtype":"token_suite"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MascotExhibition translated into ManaLoom runtime scope xmage_multi_create_creature_tokens_spell_v1. This row is package-ready only because the source signature is a narrow fixed spell-resolution multi-creature-token maker with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('bestial menace', 'Bestial Menace', '776667960e301f39134e382444e0d528', 'battle_rule_v1:7bd0274870194298d04700a6cfdd764e', '{"_composite_rule_components":[{"ability_kind":"one_shot","battle_model_scope":"xmage_fixed_create_creature_tokens_spell_v1","compose_on_resolution":true,"effect":"token_maker","token_colors":["G"],"token_count":1,"token_description":"1/1 green Snake creature token","token_name":"Snake Token","token_power":1,"token_subtype":"Snake","token_toughness":1,"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"SnakeToken"},{"ability_kind":"one_shot","battle_model_scope":"xmage_fixed_create_creature_tokens_spell_v1","compose_on_resolution":true,"effect":"token_maker","token_colors":["G"],"token_count":1,"token_description":"2/2 green Wolf creature token","token_name":"Wolf Token","token_power":2,"token_subtype":"Wolf","token_toughness":2,"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"WolfToken"},{"ability_kind":"one_shot","battle_model_scope":"xmage_fixed_create_creature_tokens_spell_v1","compose_on_resolution":true,"effect":"token_maker","token_colors":["G"],"token_count":1,"token_description":"3/3 green Elephant creature token","token_name":"Elephant Token","token_power":3,"token_subtype":"Elephant","token_toughness":3,"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"ElephantToken"}],"ability_kind":"one_shot","battle_model_scope":"xmage_multi_create_creature_tokens_spell_v1","effect":"composite_resolution","token_component_count":3,"token_total_count":3,"xmage_effect_class":"CreateTokenEffect","xmage_token_classes":["SnakeToken","WolfToken","ElephantToken"]}'::jsonb, '{"category":"wincon","effect":"composite_resolution","subtype":"token_suite"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BestialMenace translated into ManaLoom runtime scope xmage_multi_create_creature_tokens_spell_v1. This row is package-ready only because the source signature is a narrow fixed spell-resolution multi-creature-token maker with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('forbidden friendship', 'Forbidden Friendship', '153c16e01b9313ee675ec174b8232ed6', 'battle_rule_v1:d389d66da23728fa4e8d296036357ec2', '{"_composite_rule_components":[{"ability_kind":"one_shot","battle_model_scope":"xmage_fixed_create_creature_tokens_spell_v1","compose_on_resolution":true,"effect":"token_maker","token_colors":["R"],"token_count":1,"token_description":"1/1 red Dinosaur creature token with haste","token_haste":true,"token_keywords":["haste"],"token_name":"Dinosaur Token","token_power":1,"token_subtype":"Dinosaur","token_toughness":1,"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"DinosaurHasteToken"},{"ability_kind":"one_shot","battle_model_scope":"xmage_fixed_create_creature_tokens_spell_v1","compose_on_resolution":true,"effect":"token_maker","token_colors":["W"],"token_count":1,"token_description":"1/1 white Human Soldier creature token","token_name":"Human Soldier Token","token_power":1,"token_subtype":"Human Soldier","token_toughness":1,"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"HumanSoldierToken"}],"ability_kind":"one_shot","battle_model_scope":"xmage_multi_create_creature_tokens_spell_v1","effect":"composite_resolution","token_component_count":2,"token_total_count":2,"xmage_effect_class":"CreateTokenEffect","xmage_token_classes":["DinosaurHasteToken","HumanSoldierToken"]}'::jsonb, '{"category":"wincon","effect":"composite_resolution","subtype":"token_suite"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ForbiddenFriendship translated into ManaLoom runtime scope xmage_multi_create_creature_tokens_spell_v1. This row is package-ready only because the source signature is a narrow fixed spell-resolution multi-creature-token maker with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('mascot exhibition', 'Mascot Exhibition', 'ade5d3577a9263f1ce4504a5f6adf502', 'battle_rule_v1:e3cb683bd2371654f0aa9d57b630e774', '{"_composite_rule_components":[{"ability_kind":"one_shot","battle_model_scope":"xmage_fixed_create_creature_tokens_spell_v1","compose_on_resolution":true,"effect":"token_maker","token_colors":["W","B"],"token_count":1,"token_description":"2/1 white and black Inkling creature token with flying","token_flying":true,"token_keywords":["flying"],"token_name":"Inkling Token","token_power":2,"token_subtype":"Inkling","token_toughness":1,"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"InklingToken"},{"ability_kind":"one_shot","battle_model_scope":"xmage_fixed_create_creature_tokens_spell_v1","compose_on_resolution":true,"effect":"token_maker","token_colors":["W","R"],"token_count":1,"token_description":"3/2 red and white Spirit creature token","token_name":"Spirit Token","token_power":3,"token_subtype":"Spirit","token_toughness":2,"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"Spirit32Token"},{"ability_kind":"one_shot","battle_model_scope":"xmage_fixed_create_creature_tokens_spell_v1","compose_on_resolution":true,"effect":"token_maker","token_colors":["U","R"],"token_count":1,"token_description":"4/4 blue and red Elemental creature token","token_name":"Elemental Token","token_power":4,"token_subtype":"Elemental","token_toughness":4,"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"Elemental44Token"}],"ability_kind":"one_shot","battle_model_scope":"xmage_multi_create_creature_tokens_spell_v1","effect":"composite_resolution","token_component_count":3,"token_total_count":3,"xmage_effect_class":"CreateTokenEffect","xmage_token_classes":["InklingToken","Spirit32Token","Elemental44Token"]}'::jsonb, '{"category":"wincon","effect":"composite_resolution","subtype":"token_suite"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MascotExhibition translated into ManaLoom runtime scope xmage_multi_create_creature_tokens_spell_v1. This row is package-ready only because the source signature is a narrow fixed spell-resolution multi-creature-token maker with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
