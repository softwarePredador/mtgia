BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg745_dynamic_token_count_new_server_dyn_20260711_064113 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('evangel of heliod', 'fresh meat', 'hallowed spiritkeeper', 'revenge of the rats', 'reverent hoplite', 'spider spawning', 'underworld hermit')
   OR normalized_name LIKE 'evangel of heliod // %'
   OR normalized_name LIKE 'fresh meat // %'
   OR normalized_name LIKE 'hallowed spiritkeeper // %'
   OR normalized_name LIKE 'revenge of the rats // %'
   OR normalized_name LIKE 'reverent hoplite // %'
   OR normalized_name LIKE 'spider spawning // %'
   OR normalized_name LIKE 'underworld hermit // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('evangel of heliod', 'Evangel of Heliod', '036d326bf50a3bec9d7791ca318f2c02', 'battle_rule_v1:5369f43f4ebb4611b222d350848442c4', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_create_tokens_v1","effect":"creature","etb_token_colors":["W"],"etb_token_count_source":"devotion_to_white","etb_token_name":"Soldier Token","etb_token_power":1,"etb_token_subtype":"Soldier","etb_token_toughness":1,"token_description":"1/1 white Soldier creature token","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"SoldierToken"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class EvangelOfHeliod translated into ManaLoom runtime scope xmage_creature_etb_create_tokens_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('fresh meat', 'Fresh Meat', 'b73bc66f5f1e43b16dadcd2da02c98d0', 'battle_rule_v1:ebc6caabca122273fd394e5d17899537', '{"ability_kind":"one_shot","battle_model_scope":"xmage_dynamic_count_create_creature_tokens_spell_v1","effect":"token_maker","token_colors":["G"],"token_count_source":"creatures_you_control_died_this_turn","token_description":"3/3 green Beast creature token","token_name":"Beast Token","token_power":3,"token_subtype":"Beast","token_toughness":3,"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"BeastToken"}'::jsonb, '{"category":"wincon","effect":"token_maker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FreshMeat translated into ManaLoom runtime scope xmage_dynamic_count_create_creature_tokens_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('hallowed spiritkeeper', 'Hallowed Spiritkeeper', '2c142ea165a6ce04487793441c32a16d', 'battle_rule_v1:1dc1ebcc43d6cda70b2c4d02dbefdaa3', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_create_tokens_v1","dies_token_colors":["W"],"dies_token_count_source":"controller_graveyard_creature_count","dies_token_flying":true,"dies_token_keywords":["flying"],"dies_token_name":"Spirit Token","dies_token_power":1,"dies_token_subtype":"Spirit","dies_token_toughness":1,"dies_trigger_effect":"token_maker","effect":"creature","keywords":["vigilance"],"token_description":"1/1 white Spirit creature token with flying","trigger":"dies","vigilance":true,"xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"SpiritWhiteToken"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HallowedSpiritkeeper translated into ManaLoom runtime scope xmage_creature_dies_create_tokens_v1. This row is package-ready only because the source signature is a narrow creature dies triggered fixed creature-token ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('revenge of the rats', 'Revenge of the Rats', 'b3a75311467c5352222fdfc6fca7b7bd', 'battle_rule_v1:ee9db175779e49a7daab32685760e37e', '{"ability_kind":"one_shot","battle_model_scope":"xmage_dynamic_count_create_creature_tokens_spell_v1","effect":"token_maker","flashback_cost":"{2}{B}{B}","flashback_status":"runtime_executor_v1","token_colors":["B"],"token_count_source":"controller_graveyard_creature_count","token_description":"1/1 black Rat creature token","token_name":"Rat Token","token_power":1,"token_subtype":"Rat","token_tapped":true,"token_toughness":1,"xmage_auxiliary_ability_classes":["FlashbackAbility"],"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"RatToken"}'::jsonb, '{"category":"wincon","effect":"token_maker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RevengeOfTheRats translated into ManaLoom runtime scope xmage_dynamic_count_create_creature_tokens_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('reverent hoplite', 'Reverent Hoplite', '8c8ea6c2ea65a8008a2a4c8e06f0179f', 'battle_rule_v1:7a522d8512326cec2db9f21d2bd12d96', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_create_tokens_v1","effect":"creature","etb_token_colors":["W"],"etb_token_count_source":"devotion_to_white","etb_token_name":"Human Soldier Token","etb_token_power":1,"etb_token_subtype":"Human Soldier","etb_token_toughness":1,"token_description":"1/1 white Human Soldier creature token","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"HumanSoldierToken"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ReverentHoplite translated into ManaLoom runtime scope xmage_creature_etb_create_tokens_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('spider spawning', 'Spider Spawning', 'd911b47c05e2ec72164f7b2c48162627', 'battle_rule_v1:4b857a2f074969cdb85c7eabacb7c73d', '{"ability_kind":"one_shot","battle_model_scope":"xmage_dynamic_count_create_creature_tokens_spell_v1","effect":"token_maker","flashback_cost":"{6}{B}","flashback_status":"runtime_executor_v1","token_colors":["G"],"token_count_source":"controller_graveyard_creature_count","token_description":"1/2 green Spider creature token with reach","token_keywords":["reach"],"token_name":"Spider Token","token_power":1,"token_subtype":"Spider","token_toughness":2,"xmage_auxiliary_ability_classes":["FlashbackAbility"],"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"SpiderToken"}'::jsonb, '{"category":"wincon","effect":"token_maker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SpiderSpawning translated into ManaLoom runtime scope xmage_dynamic_count_create_creature_tokens_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('underworld hermit', 'Underworld Hermit', '227054dbd6d2beac83b76e5457631d1f', 'battle_rule_v1:29c842654d32c86516e76abd5048a396', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_create_tokens_v1","effect":"creature","etb_token_colors":["G"],"etb_token_count_source":"devotion_to_black","etb_token_name":"Squirrel Token","etb_token_power":1,"etb_token_subtype":"Squirrel","etb_token_toughness":1,"token_description":"1/1 green Squirrel creature token","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"SquirrelToken"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class UnderworldHermit translated into ManaLoom runtime scope xmage_creature_etb_create_tokens_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('evangel of heliod', 'Evangel of Heliod', '036d326bf50a3bec9d7791ca318f2c02', 'battle_rule_v1:5369f43f4ebb4611b222d350848442c4', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_create_tokens_v1","effect":"creature","etb_token_colors":["W"],"etb_token_count_source":"devotion_to_white","etb_token_name":"Soldier Token","etb_token_power":1,"etb_token_subtype":"Soldier","etb_token_toughness":1,"token_description":"1/1 white Soldier creature token","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"SoldierToken"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class EvangelOfHeliod translated into ManaLoom runtime scope xmage_creature_etb_create_tokens_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('fresh meat', 'Fresh Meat', 'b73bc66f5f1e43b16dadcd2da02c98d0', 'battle_rule_v1:ebc6caabca122273fd394e5d17899537', '{"ability_kind":"one_shot","battle_model_scope":"xmage_dynamic_count_create_creature_tokens_spell_v1","effect":"token_maker","token_colors":["G"],"token_count_source":"creatures_you_control_died_this_turn","token_description":"3/3 green Beast creature token","token_name":"Beast Token","token_power":3,"token_subtype":"Beast","token_toughness":3,"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"BeastToken"}'::jsonb, '{"category":"wincon","effect":"token_maker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FreshMeat translated into ManaLoom runtime scope xmage_dynamic_count_create_creature_tokens_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('hallowed spiritkeeper', 'Hallowed Spiritkeeper', '2c142ea165a6ce04487793441c32a16d', 'battle_rule_v1:1dc1ebcc43d6cda70b2c4d02dbefdaa3', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_create_tokens_v1","dies_token_colors":["W"],"dies_token_count_source":"controller_graveyard_creature_count","dies_token_flying":true,"dies_token_keywords":["flying"],"dies_token_name":"Spirit Token","dies_token_power":1,"dies_token_subtype":"Spirit","dies_token_toughness":1,"dies_trigger_effect":"token_maker","effect":"creature","keywords":["vigilance"],"token_description":"1/1 white Spirit creature token with flying","trigger":"dies","vigilance":true,"xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"SpiritWhiteToken"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HallowedSpiritkeeper translated into ManaLoom runtime scope xmage_creature_dies_create_tokens_v1. This row is package-ready only because the source signature is a narrow creature dies triggered fixed creature-token ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('revenge of the rats', 'Revenge of the Rats', 'b3a75311467c5352222fdfc6fca7b7bd', 'battle_rule_v1:ee9db175779e49a7daab32685760e37e', '{"ability_kind":"one_shot","battle_model_scope":"xmage_dynamic_count_create_creature_tokens_spell_v1","effect":"token_maker","flashback_cost":"{2}{B}{B}","flashback_status":"runtime_executor_v1","token_colors":["B"],"token_count_source":"controller_graveyard_creature_count","token_description":"1/1 black Rat creature token","token_name":"Rat Token","token_power":1,"token_subtype":"Rat","token_tapped":true,"token_toughness":1,"xmage_auxiliary_ability_classes":["FlashbackAbility"],"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"RatToken"}'::jsonb, '{"category":"wincon","effect":"token_maker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RevengeOfTheRats translated into ManaLoom runtime scope xmage_dynamic_count_create_creature_tokens_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('reverent hoplite', 'Reverent Hoplite', '8c8ea6c2ea65a8008a2a4c8e06f0179f', 'battle_rule_v1:7a522d8512326cec2db9f21d2bd12d96', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_create_tokens_v1","effect":"creature","etb_token_colors":["W"],"etb_token_count_source":"devotion_to_white","etb_token_name":"Human Soldier Token","etb_token_power":1,"etb_token_subtype":"Human Soldier","etb_token_toughness":1,"token_description":"1/1 white Human Soldier creature token","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"HumanSoldierToken"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ReverentHoplite translated into ManaLoom runtime scope xmage_creature_etb_create_tokens_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('spider spawning', 'Spider Spawning', 'd911b47c05e2ec72164f7b2c48162627', 'battle_rule_v1:4b857a2f074969cdb85c7eabacb7c73d', '{"ability_kind":"one_shot","battle_model_scope":"xmage_dynamic_count_create_creature_tokens_spell_v1","effect":"token_maker","flashback_cost":"{6}{B}","flashback_status":"runtime_executor_v1","token_colors":["G"],"token_count_source":"controller_graveyard_creature_count","token_description":"1/2 green Spider creature token with reach","token_keywords":["reach"],"token_name":"Spider Token","token_power":1,"token_subtype":"Spider","token_toughness":2,"xmage_auxiliary_ability_classes":["FlashbackAbility"],"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"SpiderToken"}'::jsonb, '{"category":"wincon","effect":"token_maker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SpiderSpawning translated into ManaLoom runtime scope xmage_dynamic_count_create_creature_tokens_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('underworld hermit', 'Underworld Hermit', '227054dbd6d2beac83b76e5457631d1f', 'battle_rule_v1:29c842654d32c86516e76abd5048a396', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_create_tokens_v1","effect":"creature","etb_token_colors":["G"],"etb_token_count_source":"devotion_to_black","etb_token_name":"Squirrel Token","etb_token_power":1,"etb_token_subtype":"Squirrel","etb_token_toughness":1,"token_description":"1/1 green Squirrel creature token","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"SquirrelToken"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class UnderworldHermit translated into ManaLoom runtime scope xmage_creature_etb_create_tokens_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('evangel of heliod', 'Evangel of Heliod', '036d326bf50a3bec9d7791ca318f2c02', 'battle_rule_v1:5369f43f4ebb4611b222d350848442c4', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_create_tokens_v1","effect":"creature","etb_token_colors":["W"],"etb_token_count_source":"devotion_to_white","etb_token_name":"Soldier Token","etb_token_power":1,"etb_token_subtype":"Soldier","etb_token_toughness":1,"token_description":"1/1 white Soldier creature token","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"SoldierToken"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class EvangelOfHeliod translated into ManaLoom runtime scope xmage_creature_etb_create_tokens_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('fresh meat', 'Fresh Meat', 'b73bc66f5f1e43b16dadcd2da02c98d0', 'battle_rule_v1:ebc6caabca122273fd394e5d17899537', '{"ability_kind":"one_shot","battle_model_scope":"xmage_dynamic_count_create_creature_tokens_spell_v1","effect":"token_maker","token_colors":["G"],"token_count_source":"creatures_you_control_died_this_turn","token_description":"3/3 green Beast creature token","token_name":"Beast Token","token_power":3,"token_subtype":"Beast","token_toughness":3,"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"BeastToken"}'::jsonb, '{"category":"wincon","effect":"token_maker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FreshMeat translated into ManaLoom runtime scope xmage_dynamic_count_create_creature_tokens_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('hallowed spiritkeeper', 'Hallowed Spiritkeeper', '2c142ea165a6ce04487793441c32a16d', 'battle_rule_v1:1dc1ebcc43d6cda70b2c4d02dbefdaa3', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_create_tokens_v1","dies_token_colors":["W"],"dies_token_count_source":"controller_graveyard_creature_count","dies_token_flying":true,"dies_token_keywords":["flying"],"dies_token_name":"Spirit Token","dies_token_power":1,"dies_token_subtype":"Spirit","dies_token_toughness":1,"dies_trigger_effect":"token_maker","effect":"creature","keywords":["vigilance"],"token_description":"1/1 white Spirit creature token with flying","trigger":"dies","vigilance":true,"xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"SpiritWhiteToken"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HallowedSpiritkeeper translated into ManaLoom runtime scope xmage_creature_dies_create_tokens_v1. This row is package-ready only because the source signature is a narrow creature dies triggered fixed creature-token ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('revenge of the rats', 'Revenge of the Rats', 'b3a75311467c5352222fdfc6fca7b7bd', 'battle_rule_v1:ee9db175779e49a7daab32685760e37e', '{"ability_kind":"one_shot","battle_model_scope":"xmage_dynamic_count_create_creature_tokens_spell_v1","effect":"token_maker","flashback_cost":"{2}{B}{B}","flashback_status":"runtime_executor_v1","token_colors":["B"],"token_count_source":"controller_graveyard_creature_count","token_description":"1/1 black Rat creature token","token_name":"Rat Token","token_power":1,"token_subtype":"Rat","token_tapped":true,"token_toughness":1,"xmage_auxiliary_ability_classes":["FlashbackAbility"],"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"RatToken"}'::jsonb, '{"category":"wincon","effect":"token_maker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RevengeOfTheRats translated into ManaLoom runtime scope xmage_dynamic_count_create_creature_tokens_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('reverent hoplite', 'Reverent Hoplite', '8c8ea6c2ea65a8008a2a4c8e06f0179f', 'battle_rule_v1:7a522d8512326cec2db9f21d2bd12d96', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_create_tokens_v1","effect":"creature","etb_token_colors":["W"],"etb_token_count_source":"devotion_to_white","etb_token_name":"Human Soldier Token","etb_token_power":1,"etb_token_subtype":"Human Soldier","etb_token_toughness":1,"token_description":"1/1 white Human Soldier creature token","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"HumanSoldierToken"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ReverentHoplite translated into ManaLoom runtime scope xmage_creature_etb_create_tokens_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('spider spawning', 'Spider Spawning', 'd911b47c05e2ec72164f7b2c48162627', 'battle_rule_v1:4b857a2f074969cdb85c7eabacb7c73d', '{"ability_kind":"one_shot","battle_model_scope":"xmage_dynamic_count_create_creature_tokens_spell_v1","effect":"token_maker","flashback_cost":"{6}{B}","flashback_status":"runtime_executor_v1","token_colors":["G"],"token_count_source":"controller_graveyard_creature_count","token_description":"1/2 green Spider creature token with reach","token_keywords":["reach"],"token_name":"Spider Token","token_power":1,"token_subtype":"Spider","token_toughness":2,"xmage_auxiliary_ability_classes":["FlashbackAbility"],"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"SpiderToken"}'::jsonb, '{"category":"wincon","effect":"token_maker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SpiderSpawning translated into ManaLoom runtime scope xmage_dynamic_count_create_creature_tokens_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('underworld hermit', 'Underworld Hermit', '227054dbd6d2beac83b76e5457631d1f', 'battle_rule_v1:29c842654d32c86516e76abd5048a396', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_create_tokens_v1","effect":"creature","etb_token_colors":["G"],"etb_token_count_source":"devotion_to_black","etb_token_name":"Squirrel Token","etb_token_power":1,"etb_token_subtype":"Squirrel","etb_token_toughness":1,"token_description":"1/1 green Squirrel creature token","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"SquirrelToken"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class UnderworldHermit translated into ManaLoom runtime scope xmage_creature_etb_create_tokens_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
