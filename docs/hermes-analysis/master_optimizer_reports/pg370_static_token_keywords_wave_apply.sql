BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE manaloom_deploy_audit.pg370_static_token_keywords_wave_20260702_102950 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('advent of the wurm', 'call the cavalry', 'call to the feast', 'jungleborn pioneer', 'knight watch', 'paladin of the bloodstained', 'queen''s commission', 'sworn companions')
   OR normalized_name LIKE 'advent of the wurm // %'
   OR normalized_name LIKE 'call the cavalry // %'
   OR normalized_name LIKE 'call to the feast // %'
   OR normalized_name LIKE 'jungleborn pioneer // %'
   OR normalized_name LIKE 'knight watch // %'
   OR normalized_name LIKE 'paladin of the bloodstained // %'
   OR normalized_name LIKE 'queen''s commission // %'
   OR normalized_name LIKE 'sworn companions // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('advent of the wurm', 'Advent of the Wurm', 'ff8e375ff6d722cb33ba0a79a4670dfc', 'battle_rule_v1:15ad6cde4eeec225c78c40aa1bae3eef', '{"ability_kind":"one_shot","battle_model_scope":"xmage_fixed_create_creature_tokens_spell_v1","effect":"token_maker","token_colors":["G"],"token_count":1,"token_description":"5/5 green Wurm creature token with trample","token_keywords":["trample"],"token_name":"Wurm Token","token_power":5,"token_subtype":"Wurm","token_toughness":5,"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"WurmWithTrampleToken"}'::jsonb, '{"category":"wincon","effect":"token_maker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AdventOfTheWurm translated into ManaLoom runtime scope xmage_fixed_create_creature_tokens_spell_v1. This row is package-ready only because the source signature is a narrow fixed spell-resolution creature-token maker with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('call the cavalry', 'Call the Cavalry', '32d68e2d062d46dece64180695886a79', 'battle_rule_v1:2bc1e95fd40f9c279ad684f5fddb9d2a', '{"ability_kind":"one_shot","battle_model_scope":"xmage_fixed_create_creature_tokens_spell_v1","effect":"token_maker","token_colors":["W"],"token_count":2,"token_description":"2/2 white Knight creature token with vigilance","token_keywords":["vigilance"],"token_name":"Knight Token","token_power":2,"token_subtype":"Knight","token_toughness":2,"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"KnightToken"}'::jsonb, '{"category":"wincon","effect":"token_maker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CallTheCavalry translated into ManaLoom runtime scope xmage_fixed_create_creature_tokens_spell_v1. This row is package-ready only because the source signature is a narrow fixed spell-resolution creature-token maker with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('call to the feast', 'Call to the Feast', '202f9814c0be3f31b4ecbd95ebdbe93f', 'battle_rule_v1:f4c11b865d09547623884f1b1100610c', '{"ability_kind":"one_shot","battle_model_scope":"xmage_fixed_create_creature_tokens_spell_v1","effect":"token_maker","token_colors":["W"],"token_count":3,"token_description":"1/1 white Vampire creature token with lifelink","token_keywords":["lifelink"],"token_name":"Vampire Token","token_power":1,"token_subtype":"Vampire","token_toughness":1,"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"IxalanVampireToken"}'::jsonb, '{"category":"wincon","effect":"token_maker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CallToTheFeast translated into ManaLoom runtime scope xmage_fixed_create_creature_tokens_spell_v1. This row is package-ready only because the source signature is a narrow fixed spell-resolution creature-token maker with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('jungleborn pioneer', 'Jungleborn Pioneer', '437a069274542fcc917c0ebd3f090a6a', 'battle_rule_v1:cef3e05a99c1ea3e0ae4d8f83d61174c', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_create_tokens_v1","effect":"creature","etb_token_colors":["U"],"etb_token_count":1,"etb_token_keywords":["hexproof"],"etb_token_name":"Merfolk Token","etb_token_power":1,"etb_token_subtype":"Merfolk","etb_token_toughness":1,"token_description":"1/1 blue Merfolk creature token with hexproof","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"MerfolkHexproofToken"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class JunglebornPioneer translated into ManaLoom runtime scope xmage_creature_etb_create_tokens_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('knight watch', 'Knight Watch', '32d68e2d062d46dece64180695886a79', 'battle_rule_v1:2bc1e95fd40f9c279ad684f5fddb9d2a', '{"ability_kind":"one_shot","battle_model_scope":"xmage_fixed_create_creature_tokens_spell_v1","effect":"token_maker","token_colors":["W"],"token_count":2,"token_description":"2/2 white Knight creature token with vigilance","token_keywords":["vigilance"],"token_name":"Knight Token","token_power":2,"token_subtype":"Knight","token_toughness":2,"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"KnightToken"}'::jsonb, '{"category":"wincon","effect":"token_maker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class KnightWatch translated into ManaLoom runtime scope xmage_fixed_create_creature_tokens_spell_v1. This row is package-ready only because the source signature is a narrow fixed spell-resolution creature-token maker with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('paladin of the bloodstained', 'Paladin of the Bloodstained', '89c3a916361a14ceb4973cf23a14180d', 'battle_rule_v1:594b1605e5f877db26cc8325c3338ed6', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_create_tokens_v1","effect":"creature","etb_token_colors":["W"],"etb_token_count":1,"etb_token_keywords":["lifelink"],"etb_token_name":"Vampire Token","etb_token_power":1,"etb_token_subtype":"Vampire","etb_token_toughness":1,"token_description":"1/1 white Vampire creature token with lifelink","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"IxalanVampireToken"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PaladinOfTheBloodstained translated into ManaLoom runtime scope xmage_creature_etb_create_tokens_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('queen''s commission', 'Queen''s Commission', '83272aece045b20eeef2cd70f2d7b80a', 'battle_rule_v1:2df5942a4afe369ac6448ff6cba57f94', '{"ability_kind":"one_shot","battle_model_scope":"xmage_fixed_create_creature_tokens_spell_v1","effect":"token_maker","token_colors":["W"],"token_count":2,"token_description":"1/1 white Vampire creature token with lifelink","token_keywords":["lifelink"],"token_name":"Vampire Token","token_power":1,"token_subtype":"Vampire","token_toughness":1,"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"IxalanVampireToken"}'::jsonb, '{"category":"wincon","effect":"token_maker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class QueensCommission translated into ManaLoom runtime scope xmage_fixed_create_creature_tokens_spell_v1. This row is package-ready only because the source signature is a narrow fixed spell-resolution creature-token maker with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('sworn companions', 'Sworn Companions', '11963923899b828dbcd5021a17b50537', 'battle_rule_v1:b095a7a51e9f9e5f82be474acc85c2e7', '{"ability_kind":"one_shot","battle_model_scope":"xmage_fixed_create_creature_tokens_spell_v1","effect":"token_maker","token_colors":["W"],"token_count":2,"token_description":"1/1 white Soldier creature token with lifelink","token_keywords":["lifelink"],"token_name":"Soldier Token","token_power":1,"token_subtype":"Soldier","token_toughness":1,"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"SoldierLifelinkToken"}'::jsonb, '{"category":"wincon","effect":"token_maker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SwornCompanions translated into ManaLoom runtime scope xmage_fixed_create_creature_tokens_spell_v1. This row is package-ready only because the source signature is a narrow fixed spell-resolution creature-token maker with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('advent of the wurm', 'Advent of the Wurm', 'ff8e375ff6d722cb33ba0a79a4670dfc', 'battle_rule_v1:15ad6cde4eeec225c78c40aa1bae3eef', '{"ability_kind":"one_shot","battle_model_scope":"xmage_fixed_create_creature_tokens_spell_v1","effect":"token_maker","token_colors":["G"],"token_count":1,"token_description":"5/5 green Wurm creature token with trample","token_keywords":["trample"],"token_name":"Wurm Token","token_power":5,"token_subtype":"Wurm","token_toughness":5,"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"WurmWithTrampleToken"}'::jsonb, '{"category":"wincon","effect":"token_maker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AdventOfTheWurm translated into ManaLoom runtime scope xmage_fixed_create_creature_tokens_spell_v1. This row is package-ready only because the source signature is a narrow fixed spell-resolution creature-token maker with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('call the cavalry', 'Call the Cavalry', '32d68e2d062d46dece64180695886a79', 'battle_rule_v1:2bc1e95fd40f9c279ad684f5fddb9d2a', '{"ability_kind":"one_shot","battle_model_scope":"xmage_fixed_create_creature_tokens_spell_v1","effect":"token_maker","token_colors":["W"],"token_count":2,"token_description":"2/2 white Knight creature token with vigilance","token_keywords":["vigilance"],"token_name":"Knight Token","token_power":2,"token_subtype":"Knight","token_toughness":2,"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"KnightToken"}'::jsonb, '{"category":"wincon","effect":"token_maker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CallTheCavalry translated into ManaLoom runtime scope xmage_fixed_create_creature_tokens_spell_v1. This row is package-ready only because the source signature is a narrow fixed spell-resolution creature-token maker with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('call to the feast', 'Call to the Feast', '202f9814c0be3f31b4ecbd95ebdbe93f', 'battle_rule_v1:f4c11b865d09547623884f1b1100610c', '{"ability_kind":"one_shot","battle_model_scope":"xmage_fixed_create_creature_tokens_spell_v1","effect":"token_maker","token_colors":["W"],"token_count":3,"token_description":"1/1 white Vampire creature token with lifelink","token_keywords":["lifelink"],"token_name":"Vampire Token","token_power":1,"token_subtype":"Vampire","token_toughness":1,"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"IxalanVampireToken"}'::jsonb, '{"category":"wincon","effect":"token_maker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CallToTheFeast translated into ManaLoom runtime scope xmage_fixed_create_creature_tokens_spell_v1. This row is package-ready only because the source signature is a narrow fixed spell-resolution creature-token maker with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('jungleborn pioneer', 'Jungleborn Pioneer', '437a069274542fcc917c0ebd3f090a6a', 'battle_rule_v1:cef3e05a99c1ea3e0ae4d8f83d61174c', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_create_tokens_v1","effect":"creature","etb_token_colors":["U"],"etb_token_count":1,"etb_token_keywords":["hexproof"],"etb_token_name":"Merfolk Token","etb_token_power":1,"etb_token_subtype":"Merfolk","etb_token_toughness":1,"token_description":"1/1 blue Merfolk creature token with hexproof","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"MerfolkHexproofToken"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class JunglebornPioneer translated into ManaLoom runtime scope xmage_creature_etb_create_tokens_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('knight watch', 'Knight Watch', '32d68e2d062d46dece64180695886a79', 'battle_rule_v1:2bc1e95fd40f9c279ad684f5fddb9d2a', '{"ability_kind":"one_shot","battle_model_scope":"xmage_fixed_create_creature_tokens_spell_v1","effect":"token_maker","token_colors":["W"],"token_count":2,"token_description":"2/2 white Knight creature token with vigilance","token_keywords":["vigilance"],"token_name":"Knight Token","token_power":2,"token_subtype":"Knight","token_toughness":2,"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"KnightToken"}'::jsonb, '{"category":"wincon","effect":"token_maker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class KnightWatch translated into ManaLoom runtime scope xmage_fixed_create_creature_tokens_spell_v1. This row is package-ready only because the source signature is a narrow fixed spell-resolution creature-token maker with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('paladin of the bloodstained', 'Paladin of the Bloodstained', '89c3a916361a14ceb4973cf23a14180d', 'battle_rule_v1:594b1605e5f877db26cc8325c3338ed6', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_create_tokens_v1","effect":"creature","etb_token_colors":["W"],"etb_token_count":1,"etb_token_keywords":["lifelink"],"etb_token_name":"Vampire Token","etb_token_power":1,"etb_token_subtype":"Vampire","etb_token_toughness":1,"token_description":"1/1 white Vampire creature token with lifelink","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"IxalanVampireToken"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PaladinOfTheBloodstained translated into ManaLoom runtime scope xmage_creature_etb_create_tokens_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('queen''s commission', 'Queen''s Commission', '83272aece045b20eeef2cd70f2d7b80a', 'battle_rule_v1:2df5942a4afe369ac6448ff6cba57f94', '{"ability_kind":"one_shot","battle_model_scope":"xmage_fixed_create_creature_tokens_spell_v1","effect":"token_maker","token_colors":["W"],"token_count":2,"token_description":"1/1 white Vampire creature token with lifelink","token_keywords":["lifelink"],"token_name":"Vampire Token","token_power":1,"token_subtype":"Vampire","token_toughness":1,"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"IxalanVampireToken"}'::jsonb, '{"category":"wincon","effect":"token_maker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class QueensCommission translated into ManaLoom runtime scope xmage_fixed_create_creature_tokens_spell_v1. This row is package-ready only because the source signature is a narrow fixed spell-resolution creature-token maker with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('sworn companions', 'Sworn Companions', '11963923899b828dbcd5021a17b50537', 'battle_rule_v1:b095a7a51e9f9e5f82be474acc85c2e7', '{"ability_kind":"one_shot","battle_model_scope":"xmage_fixed_create_creature_tokens_spell_v1","effect":"token_maker","token_colors":["W"],"token_count":2,"token_description":"1/1 white Soldier creature token with lifelink","token_keywords":["lifelink"],"token_name":"Soldier Token","token_power":1,"token_subtype":"Soldier","token_toughness":1,"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"SoldierLifelinkToken"}'::jsonb, '{"category":"wincon","effect":"token_maker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SwornCompanions translated into ManaLoom runtime scope xmage_fixed_create_creature_tokens_spell_v1. This row is package-ready only because the source signature is a narrow fixed spell-resolution creature-token maker with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('advent of the wurm', 'Advent of the Wurm', 'ff8e375ff6d722cb33ba0a79a4670dfc', 'battle_rule_v1:15ad6cde4eeec225c78c40aa1bae3eef', '{"ability_kind":"one_shot","battle_model_scope":"xmage_fixed_create_creature_tokens_spell_v1","effect":"token_maker","token_colors":["G"],"token_count":1,"token_description":"5/5 green Wurm creature token with trample","token_keywords":["trample"],"token_name":"Wurm Token","token_power":5,"token_subtype":"Wurm","token_toughness":5,"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"WurmWithTrampleToken"}'::jsonb, '{"category":"wincon","effect":"token_maker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AdventOfTheWurm translated into ManaLoom runtime scope xmage_fixed_create_creature_tokens_spell_v1. This row is package-ready only because the source signature is a narrow fixed spell-resolution creature-token maker with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('call the cavalry', 'Call the Cavalry', '32d68e2d062d46dece64180695886a79', 'battle_rule_v1:2bc1e95fd40f9c279ad684f5fddb9d2a', '{"ability_kind":"one_shot","battle_model_scope":"xmage_fixed_create_creature_tokens_spell_v1","effect":"token_maker","token_colors":["W"],"token_count":2,"token_description":"2/2 white Knight creature token with vigilance","token_keywords":["vigilance"],"token_name":"Knight Token","token_power":2,"token_subtype":"Knight","token_toughness":2,"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"KnightToken"}'::jsonb, '{"category":"wincon","effect":"token_maker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CallTheCavalry translated into ManaLoom runtime scope xmage_fixed_create_creature_tokens_spell_v1. This row is package-ready only because the source signature is a narrow fixed spell-resolution creature-token maker with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('call to the feast', 'Call to the Feast', '202f9814c0be3f31b4ecbd95ebdbe93f', 'battle_rule_v1:f4c11b865d09547623884f1b1100610c', '{"ability_kind":"one_shot","battle_model_scope":"xmage_fixed_create_creature_tokens_spell_v1","effect":"token_maker","token_colors":["W"],"token_count":3,"token_description":"1/1 white Vampire creature token with lifelink","token_keywords":["lifelink"],"token_name":"Vampire Token","token_power":1,"token_subtype":"Vampire","token_toughness":1,"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"IxalanVampireToken"}'::jsonb, '{"category":"wincon","effect":"token_maker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CallToTheFeast translated into ManaLoom runtime scope xmage_fixed_create_creature_tokens_spell_v1. This row is package-ready only because the source signature is a narrow fixed spell-resolution creature-token maker with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('jungleborn pioneer', 'Jungleborn Pioneer', '437a069274542fcc917c0ebd3f090a6a', 'battle_rule_v1:cef3e05a99c1ea3e0ae4d8f83d61174c', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_create_tokens_v1","effect":"creature","etb_token_colors":["U"],"etb_token_count":1,"etb_token_keywords":["hexproof"],"etb_token_name":"Merfolk Token","etb_token_power":1,"etb_token_subtype":"Merfolk","etb_token_toughness":1,"token_description":"1/1 blue Merfolk creature token with hexproof","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"MerfolkHexproofToken"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class JunglebornPioneer translated into ManaLoom runtime scope xmage_creature_etb_create_tokens_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('knight watch', 'Knight Watch', '32d68e2d062d46dece64180695886a79', 'battle_rule_v1:2bc1e95fd40f9c279ad684f5fddb9d2a', '{"ability_kind":"one_shot","battle_model_scope":"xmage_fixed_create_creature_tokens_spell_v1","effect":"token_maker","token_colors":["W"],"token_count":2,"token_description":"2/2 white Knight creature token with vigilance","token_keywords":["vigilance"],"token_name":"Knight Token","token_power":2,"token_subtype":"Knight","token_toughness":2,"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"KnightToken"}'::jsonb, '{"category":"wincon","effect":"token_maker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class KnightWatch translated into ManaLoom runtime scope xmage_fixed_create_creature_tokens_spell_v1. This row is package-ready only because the source signature is a narrow fixed spell-resolution creature-token maker with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('paladin of the bloodstained', 'Paladin of the Bloodstained', '89c3a916361a14ceb4973cf23a14180d', 'battle_rule_v1:594b1605e5f877db26cc8325c3338ed6', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_create_tokens_v1","effect":"creature","etb_token_colors":["W"],"etb_token_count":1,"etb_token_keywords":["lifelink"],"etb_token_name":"Vampire Token","etb_token_power":1,"etb_token_subtype":"Vampire","etb_token_toughness":1,"token_description":"1/1 white Vampire creature token with lifelink","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"IxalanVampireToken"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PaladinOfTheBloodstained translated into ManaLoom runtime scope xmage_creature_etb_create_tokens_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('queen''s commission', 'Queen''s Commission', '83272aece045b20eeef2cd70f2d7b80a', 'battle_rule_v1:2df5942a4afe369ac6448ff6cba57f94', '{"ability_kind":"one_shot","battle_model_scope":"xmage_fixed_create_creature_tokens_spell_v1","effect":"token_maker","token_colors":["W"],"token_count":2,"token_description":"1/1 white Vampire creature token with lifelink","token_keywords":["lifelink"],"token_name":"Vampire Token","token_power":1,"token_subtype":"Vampire","token_toughness":1,"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"IxalanVampireToken"}'::jsonb, '{"category":"wincon","effect":"token_maker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class QueensCommission translated into ManaLoom runtime scope xmage_fixed_create_creature_tokens_spell_v1. This row is package-ready only because the source signature is a narrow fixed spell-resolution creature-token maker with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('sworn companions', 'Sworn Companions', '11963923899b828dbcd5021a17b50537', 'battle_rule_v1:b095a7a51e9f9e5f82be474acc85c2e7', '{"ability_kind":"one_shot","battle_model_scope":"xmage_fixed_create_creature_tokens_spell_v1","effect":"token_maker","token_colors":["W"],"token_count":2,"token_description":"1/1 white Soldier creature token with lifelink","token_keywords":["lifelink"],"token_name":"Soldier Token","token_power":1,"token_subtype":"Soldier","token_toughness":1,"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"SoldierLifelinkToken"}'::jsonb, '{"category":"wincon","effect":"token_maker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SwornCompanions translated into ManaLoom runtime scope xmage_fixed_create_creature_tokens_spell_v1. This row is package-ready only because the source signature is a narrow fixed spell-resolution creature-token maker with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
