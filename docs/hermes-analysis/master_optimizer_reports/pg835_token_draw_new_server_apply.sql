BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg835_token_draw_new_server_20260712_175702 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('glimmerburst', 'glittermonger', 'halo scarab', 'pirate''s prize')
   OR normalized_name LIKE 'glimmerburst // %'
   OR normalized_name LIKE 'glittermonger // %'
   OR normalized_name LIKE 'halo scarab // %'
   OR normalized_name LIKE 'pirate''s prize // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('glimmerburst', 'Glimmerburst', 'a25051234ee55b0b8079617746dc2868', 'battle_rule_v1:98b779eed4a072890e45c78d36bc47ce', '{"_composite_rule_components":[{"ability_kind":"one_shot","battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":2,"draw_count":2,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"},{"ability_kind":"one_shot","battle_model_scope":"xmage_fixed_create_creature_tokens_spell_v1","compose_on_resolution":true,"effect":"token_maker","token_colors":["W"],"token_count":1,"token_description":"1/1 white Glimmer enchantment creature token","token_name":"Glimmer Token","token_power":1,"token_subtype":"Glimmer","token_toughness":1,"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"GlimmerToken"}],"ability_kind":"one_shot","battle_model_scope":"xmage_fixed_create_creature_tokens_draw_cards_spell_v1","draw_count":2,"effect":"composite_resolution","resolution_order":"draw_then_create_tokens","token_colors":["W"],"token_count":1,"token_description":"1/1 white Glimmer enchantment creature token","token_name":"Glimmer Token","token_power":1,"token_subtype":"Glimmer","token_toughness":1,"xmage_effect_classes":["CreateTokenEffect","DrawCardSourceControllerEffect"],"xmage_token_class":"GlimmerToken"}'::jsonb, '{"category":"draw","effect":"composite_resolution"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Glimmerburst translated into ManaLoom runtime scope xmage_fixed_create_creature_tokens_draw_cards_spell_v1. This row is package-ready only because the source signature is a narrow fixed spell-resolution creature-token maker plus controller draw with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('glittermonger', 'Glittermonger', '5b4e50720f248f4efc602edf472eb667', 'battle_rule_v1:258e845f63060b52419d6034896b7655', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"token_maker","activation_cost_colors":[],"activation_cost_generic":0,"activation_cost_mana":"{0}","activation_requires_sacrifice":false,"activation_requires_tap":true,"artifact_tokens":true,"battle_model_scope":"xmage_permanent_simple_activated_create_token_v1","effect":"token_maker","token_activated_ability":"any_color_mana_self_sacrifice","token_activated_ability_status":"runtime_supported","token_activation_requires_sacrifice":true,"token_activation_requires_tap":true,"token_artifact_only":true,"token_count":1,"token_description":"Treasure token","token_is_mana_source":true,"token_mana_activation_requires_sacrifice":true,"token_mana_activation_requires_tap":true,"token_mana_produced":1,"token_mana_source_contextual_only":false,"token_name":"Treasure Token","token_produced_mana_symbols":["W","U","B","R","G"],"token_produces":"any_color","token_subtype":"Treasure","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"TreasureToken"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_create_token_v1","activated_create_token":true,"activated_effect":"token_maker","activation_cost_colors":[],"activation_cost_generic":0,"activation_cost_mana":"{0}","activation_requires_sacrifice":false,"activation_requires_tap":true,"artifact_tokens":true,"battle_model_scope":"xmage_permanent_simple_activated_create_token_v1","effect":"creature","token_activated_ability":"any_color_mana_self_sacrifice","token_activated_ability_status":"runtime_supported","token_activation_requires_sacrifice":true,"token_activation_requires_tap":true,"token_artifact_only":true,"token_count":1,"token_description":"Treasure token","token_is_mana_source":true,"token_mana_activation_requires_sacrifice":true,"token_mana_activation_requires_tap":true,"token_mana_produced":1,"token_mana_source_contextual_only":false,"token_name":"Treasure Token","token_produced_mana_symbols":["W","U","B","R","G"],"token_produces":"any_color","token_subtype":"Treasure","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"TreasureToken"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Glittermonger translated into ManaLoom runtime scope xmage_permanent_simple_activated_create_token_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated fixed creature-token ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('halo scarab', 'Halo Scarab', '2eb45603d56974326170f8c4ea703c63', 'battle_rule_v1:936a2b6b0a79421cb88b3e205d268b45', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"token_maker","activation_cost_colors":[],"activation_cost_generic":2,"activation_cost_mana":"{2}","activation_requires_exile_source_from_graveyard":true,"activation_requires_sacrifice":false,"activation_requires_tap":false,"activation_zone":"graveyard","artifact_tokens":true,"battle_model_scope":"xmage_graveyard_self_exile_activated_create_token_v1","effect":"token_maker","token_activated_ability":"any_color_mana_self_sacrifice","token_activated_ability_status":"runtime_supported","token_activation_requires_sacrifice":true,"token_activation_requires_tap":true,"token_artifact_only":true,"token_count":1,"token_description":"Treasure token","token_is_mana_source":true,"token_mana_activation_requires_sacrifice":true,"token_mana_activation_requires_tap":true,"token_mana_produced":1,"token_mana_source_contextual_only":false,"token_name":"Treasure Token","token_produced_mana_symbols":["W","U","B","R","G"],"token_produces":"any_color","token_subtype":"Treasure","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"TreasureToken"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_graveyard_self_exile_activated_create_token_v1","activated_create_token":true,"activated_effect":"token_maker","activation_cost_colors":[],"activation_cost_generic":2,"activation_cost_mana":"{2}","activation_requires_exile_source_from_graveyard":true,"activation_requires_sacrifice":false,"activation_requires_tap":false,"activation_zone":"graveyard","artifact_tokens":true,"battle_model_scope":"xmage_graveyard_self_exile_activated_create_token_v1","effect":"creature","token_activated_ability":"any_color_mana_self_sacrifice","token_activated_ability_status":"runtime_supported","token_activation_requires_sacrifice":true,"token_activation_requires_tap":true,"token_artifact_only":true,"token_count":1,"token_description":"Treasure token","token_is_mana_source":true,"token_mana_activation_requires_sacrifice":true,"token_mana_activation_requires_tap":true,"token_mana_produced":1,"token_mana_source_contextual_only":false,"token_name":"Treasure Token","token_produced_mana_symbols":["W","U","B","R","G"],"token_produces":"any_color","token_subtype":"Treasure","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"TreasureToken"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HaloScarab translated into ManaLoom runtime scope xmage_graveyard_self_exile_activated_create_token_v1. This row is package-ready only because the source signature is a narrow card with a graveyard self-exile activated fixed creature-token ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('pirate''s prize', 'Pirate''s Prize', '47b24fe1ccecb97beb2368d34a8b0be6', 'battle_rule_v1:9ebee39a8a5e2a280cfbca52a271bb7d', '{"_composite_rule_components":[{"ability_kind":"one_shot","battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":2,"draw_count":2,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"},{"ability_kind":"one_shot","artifact_tokens":true,"battle_model_scope":"xmage_fixed_create_creature_tokens_spell_v1","compose_on_resolution":true,"effect":"token_maker","token_activated_ability":"any_color_mana_self_sacrifice","token_activated_ability_status":"runtime_supported","token_activation_requires_sacrifice":true,"token_activation_requires_tap":true,"token_artifact_only":true,"token_count":1,"token_description":"Treasure token","token_is_mana_source":true,"token_mana_activation_requires_sacrifice":true,"token_mana_activation_requires_tap":true,"token_mana_produced":1,"token_mana_source_contextual_only":false,"token_name":"Treasure Token","token_produced_mana_symbols":["W","U","B","R","G"],"token_produces":"any_color","token_subtype":"Treasure","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"TreasureToken"}],"ability_kind":"one_shot","artifact_tokens":true,"battle_model_scope":"xmage_fixed_create_creature_tokens_draw_cards_spell_v1","draw_count":2,"effect":"composite_resolution","resolution_order":"draw_then_create_tokens","token_activated_ability":"any_color_mana_self_sacrifice","token_activated_ability_status":"runtime_supported","token_activation_requires_sacrifice":true,"token_activation_requires_tap":true,"token_artifact_only":true,"token_count":1,"token_description":"Treasure token","token_is_mana_source":true,"token_mana_activation_requires_sacrifice":true,"token_mana_activation_requires_tap":true,"token_mana_produced":1,"token_mana_source_contextual_only":false,"token_name":"Treasure Token","token_produced_mana_symbols":["W","U","B","R","G"],"token_produces":"any_color","token_subtype":"Treasure","xmage_effect_classes":["CreateTokenEffect","DrawCardSourceControllerEffect"],"xmage_token_class":"TreasureToken"}'::jsonb, '{"category":"draw","effect":"composite_resolution"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PiratesPrize translated into ManaLoom runtime scope xmage_fixed_create_creature_tokens_draw_cards_spell_v1. This row is package-ready only because the source signature is a narrow fixed spell-resolution creature-token maker plus controller draw with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('glimmerburst', 'Glimmerburst', 'a25051234ee55b0b8079617746dc2868', 'battle_rule_v1:98b779eed4a072890e45c78d36bc47ce', '{"_composite_rule_components":[{"ability_kind":"one_shot","battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":2,"draw_count":2,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"},{"ability_kind":"one_shot","battle_model_scope":"xmage_fixed_create_creature_tokens_spell_v1","compose_on_resolution":true,"effect":"token_maker","token_colors":["W"],"token_count":1,"token_description":"1/1 white Glimmer enchantment creature token","token_name":"Glimmer Token","token_power":1,"token_subtype":"Glimmer","token_toughness":1,"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"GlimmerToken"}],"ability_kind":"one_shot","battle_model_scope":"xmage_fixed_create_creature_tokens_draw_cards_spell_v1","draw_count":2,"effect":"composite_resolution","resolution_order":"draw_then_create_tokens","token_colors":["W"],"token_count":1,"token_description":"1/1 white Glimmer enchantment creature token","token_name":"Glimmer Token","token_power":1,"token_subtype":"Glimmer","token_toughness":1,"xmage_effect_classes":["CreateTokenEffect","DrawCardSourceControllerEffect"],"xmage_token_class":"GlimmerToken"}'::jsonb, '{"category":"draw","effect":"composite_resolution"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Glimmerburst translated into ManaLoom runtime scope xmage_fixed_create_creature_tokens_draw_cards_spell_v1. This row is package-ready only because the source signature is a narrow fixed spell-resolution creature-token maker plus controller draw with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('glittermonger', 'Glittermonger', '5b4e50720f248f4efc602edf472eb667', 'battle_rule_v1:258e845f63060b52419d6034896b7655', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"token_maker","activation_cost_colors":[],"activation_cost_generic":0,"activation_cost_mana":"{0}","activation_requires_sacrifice":false,"activation_requires_tap":true,"artifact_tokens":true,"battle_model_scope":"xmage_permanent_simple_activated_create_token_v1","effect":"token_maker","token_activated_ability":"any_color_mana_self_sacrifice","token_activated_ability_status":"runtime_supported","token_activation_requires_sacrifice":true,"token_activation_requires_tap":true,"token_artifact_only":true,"token_count":1,"token_description":"Treasure token","token_is_mana_source":true,"token_mana_activation_requires_sacrifice":true,"token_mana_activation_requires_tap":true,"token_mana_produced":1,"token_mana_source_contextual_only":false,"token_name":"Treasure Token","token_produced_mana_symbols":["W","U","B","R","G"],"token_produces":"any_color","token_subtype":"Treasure","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"TreasureToken"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_create_token_v1","activated_create_token":true,"activated_effect":"token_maker","activation_cost_colors":[],"activation_cost_generic":0,"activation_cost_mana":"{0}","activation_requires_sacrifice":false,"activation_requires_tap":true,"artifact_tokens":true,"battle_model_scope":"xmage_permanent_simple_activated_create_token_v1","effect":"creature","token_activated_ability":"any_color_mana_self_sacrifice","token_activated_ability_status":"runtime_supported","token_activation_requires_sacrifice":true,"token_activation_requires_tap":true,"token_artifact_only":true,"token_count":1,"token_description":"Treasure token","token_is_mana_source":true,"token_mana_activation_requires_sacrifice":true,"token_mana_activation_requires_tap":true,"token_mana_produced":1,"token_mana_source_contextual_only":false,"token_name":"Treasure Token","token_produced_mana_symbols":["W","U","B","R","G"],"token_produces":"any_color","token_subtype":"Treasure","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"TreasureToken"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Glittermonger translated into ManaLoom runtime scope xmage_permanent_simple_activated_create_token_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated fixed creature-token ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('halo scarab', 'Halo Scarab', '2eb45603d56974326170f8c4ea703c63', 'battle_rule_v1:936a2b6b0a79421cb88b3e205d268b45', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"token_maker","activation_cost_colors":[],"activation_cost_generic":2,"activation_cost_mana":"{2}","activation_requires_exile_source_from_graveyard":true,"activation_requires_sacrifice":false,"activation_requires_tap":false,"activation_zone":"graveyard","artifact_tokens":true,"battle_model_scope":"xmage_graveyard_self_exile_activated_create_token_v1","effect":"token_maker","token_activated_ability":"any_color_mana_self_sacrifice","token_activated_ability_status":"runtime_supported","token_activation_requires_sacrifice":true,"token_activation_requires_tap":true,"token_artifact_only":true,"token_count":1,"token_description":"Treasure token","token_is_mana_source":true,"token_mana_activation_requires_sacrifice":true,"token_mana_activation_requires_tap":true,"token_mana_produced":1,"token_mana_source_contextual_only":false,"token_name":"Treasure Token","token_produced_mana_symbols":["W","U","B","R","G"],"token_produces":"any_color","token_subtype":"Treasure","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"TreasureToken"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_graveyard_self_exile_activated_create_token_v1","activated_create_token":true,"activated_effect":"token_maker","activation_cost_colors":[],"activation_cost_generic":2,"activation_cost_mana":"{2}","activation_requires_exile_source_from_graveyard":true,"activation_requires_sacrifice":false,"activation_requires_tap":false,"activation_zone":"graveyard","artifact_tokens":true,"battle_model_scope":"xmage_graveyard_self_exile_activated_create_token_v1","effect":"creature","token_activated_ability":"any_color_mana_self_sacrifice","token_activated_ability_status":"runtime_supported","token_activation_requires_sacrifice":true,"token_activation_requires_tap":true,"token_artifact_only":true,"token_count":1,"token_description":"Treasure token","token_is_mana_source":true,"token_mana_activation_requires_sacrifice":true,"token_mana_activation_requires_tap":true,"token_mana_produced":1,"token_mana_source_contextual_only":false,"token_name":"Treasure Token","token_produced_mana_symbols":["W","U","B","R","G"],"token_produces":"any_color","token_subtype":"Treasure","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"TreasureToken"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HaloScarab translated into ManaLoom runtime scope xmage_graveyard_self_exile_activated_create_token_v1. This row is package-ready only because the source signature is a narrow card with a graveyard self-exile activated fixed creature-token ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('pirate''s prize', 'Pirate''s Prize', '47b24fe1ccecb97beb2368d34a8b0be6', 'battle_rule_v1:9ebee39a8a5e2a280cfbca52a271bb7d', '{"_composite_rule_components":[{"ability_kind":"one_shot","battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":2,"draw_count":2,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"},{"ability_kind":"one_shot","artifact_tokens":true,"battle_model_scope":"xmage_fixed_create_creature_tokens_spell_v1","compose_on_resolution":true,"effect":"token_maker","token_activated_ability":"any_color_mana_self_sacrifice","token_activated_ability_status":"runtime_supported","token_activation_requires_sacrifice":true,"token_activation_requires_tap":true,"token_artifact_only":true,"token_count":1,"token_description":"Treasure token","token_is_mana_source":true,"token_mana_activation_requires_sacrifice":true,"token_mana_activation_requires_tap":true,"token_mana_produced":1,"token_mana_source_contextual_only":false,"token_name":"Treasure Token","token_produced_mana_symbols":["W","U","B","R","G"],"token_produces":"any_color","token_subtype":"Treasure","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"TreasureToken"}],"ability_kind":"one_shot","artifact_tokens":true,"battle_model_scope":"xmage_fixed_create_creature_tokens_draw_cards_spell_v1","draw_count":2,"effect":"composite_resolution","resolution_order":"draw_then_create_tokens","token_activated_ability":"any_color_mana_self_sacrifice","token_activated_ability_status":"runtime_supported","token_activation_requires_sacrifice":true,"token_activation_requires_tap":true,"token_artifact_only":true,"token_count":1,"token_description":"Treasure token","token_is_mana_source":true,"token_mana_activation_requires_sacrifice":true,"token_mana_activation_requires_tap":true,"token_mana_produced":1,"token_mana_source_contextual_only":false,"token_name":"Treasure Token","token_produced_mana_symbols":["W","U","B","R","G"],"token_produces":"any_color","token_subtype":"Treasure","xmage_effect_classes":["CreateTokenEffect","DrawCardSourceControllerEffect"],"xmage_token_class":"TreasureToken"}'::jsonb, '{"category":"draw","effect":"composite_resolution"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PiratesPrize translated into ManaLoom runtime scope xmage_fixed_create_creature_tokens_draw_cards_spell_v1. This row is package-ready only because the source signature is a narrow fixed spell-resolution creature-token maker plus controller draw with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('glimmerburst', 'Glimmerburst', 'a25051234ee55b0b8079617746dc2868', 'battle_rule_v1:98b779eed4a072890e45c78d36bc47ce', '{"_composite_rule_components":[{"ability_kind":"one_shot","battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":2,"draw_count":2,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"},{"ability_kind":"one_shot","battle_model_scope":"xmage_fixed_create_creature_tokens_spell_v1","compose_on_resolution":true,"effect":"token_maker","token_colors":["W"],"token_count":1,"token_description":"1/1 white Glimmer enchantment creature token","token_name":"Glimmer Token","token_power":1,"token_subtype":"Glimmer","token_toughness":1,"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"GlimmerToken"}],"ability_kind":"one_shot","battle_model_scope":"xmage_fixed_create_creature_tokens_draw_cards_spell_v1","draw_count":2,"effect":"composite_resolution","resolution_order":"draw_then_create_tokens","token_colors":["W"],"token_count":1,"token_description":"1/1 white Glimmer enchantment creature token","token_name":"Glimmer Token","token_power":1,"token_subtype":"Glimmer","token_toughness":1,"xmage_effect_classes":["CreateTokenEffect","DrawCardSourceControllerEffect"],"xmage_token_class":"GlimmerToken"}'::jsonb, '{"category":"draw","effect":"composite_resolution"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Glimmerburst translated into ManaLoom runtime scope xmage_fixed_create_creature_tokens_draw_cards_spell_v1. This row is package-ready only because the source signature is a narrow fixed spell-resolution creature-token maker plus controller draw with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('glittermonger', 'Glittermonger', '5b4e50720f248f4efc602edf472eb667', 'battle_rule_v1:258e845f63060b52419d6034896b7655', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"token_maker","activation_cost_colors":[],"activation_cost_generic":0,"activation_cost_mana":"{0}","activation_requires_sacrifice":false,"activation_requires_tap":true,"artifact_tokens":true,"battle_model_scope":"xmage_permanent_simple_activated_create_token_v1","effect":"token_maker","token_activated_ability":"any_color_mana_self_sacrifice","token_activated_ability_status":"runtime_supported","token_activation_requires_sacrifice":true,"token_activation_requires_tap":true,"token_artifact_only":true,"token_count":1,"token_description":"Treasure token","token_is_mana_source":true,"token_mana_activation_requires_sacrifice":true,"token_mana_activation_requires_tap":true,"token_mana_produced":1,"token_mana_source_contextual_only":false,"token_name":"Treasure Token","token_produced_mana_symbols":["W","U","B","R","G"],"token_produces":"any_color","token_subtype":"Treasure","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"TreasureToken"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_create_token_v1","activated_create_token":true,"activated_effect":"token_maker","activation_cost_colors":[],"activation_cost_generic":0,"activation_cost_mana":"{0}","activation_requires_sacrifice":false,"activation_requires_tap":true,"artifact_tokens":true,"battle_model_scope":"xmage_permanent_simple_activated_create_token_v1","effect":"creature","token_activated_ability":"any_color_mana_self_sacrifice","token_activated_ability_status":"runtime_supported","token_activation_requires_sacrifice":true,"token_activation_requires_tap":true,"token_artifact_only":true,"token_count":1,"token_description":"Treasure token","token_is_mana_source":true,"token_mana_activation_requires_sacrifice":true,"token_mana_activation_requires_tap":true,"token_mana_produced":1,"token_mana_source_contextual_only":false,"token_name":"Treasure Token","token_produced_mana_symbols":["W","U","B","R","G"],"token_produces":"any_color","token_subtype":"Treasure","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"TreasureToken"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Glittermonger translated into ManaLoom runtime scope xmage_permanent_simple_activated_create_token_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated fixed creature-token ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('halo scarab', 'Halo Scarab', '2eb45603d56974326170f8c4ea703c63', 'battle_rule_v1:936a2b6b0a79421cb88b3e205d268b45', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"token_maker","activation_cost_colors":[],"activation_cost_generic":2,"activation_cost_mana":"{2}","activation_requires_exile_source_from_graveyard":true,"activation_requires_sacrifice":false,"activation_requires_tap":false,"activation_zone":"graveyard","artifact_tokens":true,"battle_model_scope":"xmage_graveyard_self_exile_activated_create_token_v1","effect":"token_maker","token_activated_ability":"any_color_mana_self_sacrifice","token_activated_ability_status":"runtime_supported","token_activation_requires_sacrifice":true,"token_activation_requires_tap":true,"token_artifact_only":true,"token_count":1,"token_description":"Treasure token","token_is_mana_source":true,"token_mana_activation_requires_sacrifice":true,"token_mana_activation_requires_tap":true,"token_mana_produced":1,"token_mana_source_contextual_only":false,"token_name":"Treasure Token","token_produced_mana_symbols":["W","U","B","R","G"],"token_produces":"any_color","token_subtype":"Treasure","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"TreasureToken"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_graveyard_self_exile_activated_create_token_v1","activated_create_token":true,"activated_effect":"token_maker","activation_cost_colors":[],"activation_cost_generic":2,"activation_cost_mana":"{2}","activation_requires_exile_source_from_graveyard":true,"activation_requires_sacrifice":false,"activation_requires_tap":false,"activation_zone":"graveyard","artifact_tokens":true,"battle_model_scope":"xmage_graveyard_self_exile_activated_create_token_v1","effect":"creature","token_activated_ability":"any_color_mana_self_sacrifice","token_activated_ability_status":"runtime_supported","token_activation_requires_sacrifice":true,"token_activation_requires_tap":true,"token_artifact_only":true,"token_count":1,"token_description":"Treasure token","token_is_mana_source":true,"token_mana_activation_requires_sacrifice":true,"token_mana_activation_requires_tap":true,"token_mana_produced":1,"token_mana_source_contextual_only":false,"token_name":"Treasure Token","token_produced_mana_symbols":["W","U","B","R","G"],"token_produces":"any_color","token_subtype":"Treasure","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"TreasureToken"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HaloScarab translated into ManaLoom runtime scope xmage_graveyard_self_exile_activated_create_token_v1. This row is package-ready only because the source signature is a narrow card with a graveyard self-exile activated fixed creature-token ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('pirate''s prize', 'Pirate''s Prize', '47b24fe1ccecb97beb2368d34a8b0be6', 'battle_rule_v1:9ebee39a8a5e2a280cfbca52a271bb7d', '{"_composite_rule_components":[{"ability_kind":"one_shot","battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":2,"draw_count":2,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"},{"ability_kind":"one_shot","artifact_tokens":true,"battle_model_scope":"xmage_fixed_create_creature_tokens_spell_v1","compose_on_resolution":true,"effect":"token_maker","token_activated_ability":"any_color_mana_self_sacrifice","token_activated_ability_status":"runtime_supported","token_activation_requires_sacrifice":true,"token_activation_requires_tap":true,"token_artifact_only":true,"token_count":1,"token_description":"Treasure token","token_is_mana_source":true,"token_mana_activation_requires_sacrifice":true,"token_mana_activation_requires_tap":true,"token_mana_produced":1,"token_mana_source_contextual_only":false,"token_name":"Treasure Token","token_produced_mana_symbols":["W","U","B","R","G"],"token_produces":"any_color","token_subtype":"Treasure","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"TreasureToken"}],"ability_kind":"one_shot","artifact_tokens":true,"battle_model_scope":"xmage_fixed_create_creature_tokens_draw_cards_spell_v1","draw_count":2,"effect":"composite_resolution","resolution_order":"draw_then_create_tokens","token_activated_ability":"any_color_mana_self_sacrifice","token_activated_ability_status":"runtime_supported","token_activation_requires_sacrifice":true,"token_activation_requires_tap":true,"token_artifact_only":true,"token_count":1,"token_description":"Treasure token","token_is_mana_source":true,"token_mana_activation_requires_sacrifice":true,"token_mana_activation_requires_tap":true,"token_mana_produced":1,"token_mana_source_contextual_only":false,"token_name":"Treasure Token","token_produced_mana_symbols":["W","U","B","R","G"],"token_produces":"any_color","token_subtype":"Treasure","xmage_effect_classes":["CreateTokenEffect","DrawCardSourceControllerEffect"],"xmage_token_class":"TreasureToken"}'::jsonb, '{"category":"draw","effect":"composite_resolution"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PiratesPrize translated into ManaLoom runtime scope xmage_fixed_create_creature_tokens_draw_cards_spell_v1. This row is package-ready only because the source signature is a narrow fixed spell-resolution creature-token maker plus controller draw with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
