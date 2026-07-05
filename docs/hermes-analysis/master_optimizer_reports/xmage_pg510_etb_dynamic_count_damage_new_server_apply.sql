BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg510_xmage_pg510_etb_dynamic_count_dama_20260705_141441 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('basalt ravager', 'explosive prodigy', 'firefist adept', 'gruesome scourger', 'kessig malcontents', 'outrage shaman', 'thundering sparkmage', 'volley veteran')
   OR normalized_name LIKE 'basalt ravager // %'
   OR normalized_name LIKE 'explosive prodigy // %'
   OR normalized_name LIKE 'firefist adept // %'
   OR normalized_name LIKE 'gruesome scourger // %'
   OR normalized_name LIKE 'kessig malcontents // %'
   OR normalized_name LIKE 'outrage shaman // %'
   OR normalized_name LIKE 'thundering sparkmage // %'
   OR normalized_name LIKE 'volley veteran // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('basalt ravager', 'Basalt Ravager', 'cac67c66affc0628f40c1811b0873ae9', 'battle_rule_v1:f2ae1e68342721c6d1e6f939f7a083b5', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_dynamic_count_damage_target_v1","damage_amount_source":"greatest_shared_creature_type_count","damage_base_amount":0,"damage_per_count":1,"effect":"creature","etb_damage_amount":0,"etb_damage_target":"any_target","etb_dynamic_damage":true,"target":"any_target","target_constraints":{"scope":"any_target"},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"any_target"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BasaltRavager translated into ManaLoom runtime scope xmage_creature_etb_dynamic_count_damage_target_v1. This row is package-ready only because the source signature is a narrow creature ETB dynamic battlefield-count damage trigger with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('explosive prodigy', 'Explosive Prodigy', '1e447151ab8aa3df1306d5d1db6c8fa0', 'battle_rule_v1:1282c6f503ecc1b764fb82ec1ca73ef2', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_dynamic_count_damage_target_v1","damage_amount_source":"colors_among_permanents_you_control","damage_base_amount":0,"damage_per_count":1,"effect":"creature","etb_damage_amount":0,"etb_damage_target":"creature","etb_dynamic_damage":true,"target":"creature","target_constraints":{"card_types":["creature"],"controller_scope":"opponent"},"target_controller":"opponent","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ExplosiveProdigy translated into ManaLoom runtime scope xmage_creature_etb_dynamic_count_damage_target_v1. This row is package-ready only because the source signature is a narrow creature ETB dynamic battlefield-count damage trigger with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('firefist adept', 'Firefist Adept', '2dbcc9991de1570f0ae1eed570d9250e', 'battle_rule_v1:0d910538c746d80f8fafe09e19cf67d2', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_dynamic_count_damage_target_v1","battlefield_count_scope":"controller_battlefield","battlefield_count_subtypes":["wizard"],"damage_amount_source":"battlefield_permanent_count","damage_base_amount":0,"damage_per_count":1,"effect":"creature","etb_damage_amount":0,"etb_damage_target":"creature","etb_dynamic_damage":true,"target":"creature","target_constraints":{"card_types":["creature"],"controller_scope":"opponent"},"target_controller":"opponent","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FirefistAdept translated into ManaLoom runtime scope xmage_creature_etb_dynamic_count_damage_target_v1. This row is package-ready only because the source signature is a narrow creature ETB dynamic battlefield-count damage trigger with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('gruesome scourger', 'Gruesome Scourger', 'dcb48cabe9a66fe7a9ed1da0092575ef', 'battle_rule_v1:4caec1a33ceadbea7dfb82ef563888ea', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_dynamic_count_damage_target_v1","battlefield_count_card_types":["creature"],"battlefield_count_scope":"controller_battlefield","damage_amount_source":"battlefield_permanent_count","damage_base_amount":0,"damage_per_count":1,"effect":"creature","etb_damage_amount":0,"etb_damage_target":"opponent_or_planeswalker","etb_dynamic_damage":true,"target":"opponent_or_planeswalker","target_constraints":{"scope":"opponent_or_planeswalker"},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"opponent_or_planeswalker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GruesomeScourger translated into ManaLoom runtime scope xmage_creature_etb_dynamic_count_damage_target_v1. This row is package-ready only because the source signature is a narrow creature ETB dynamic battlefield-count damage trigger with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('kessig malcontents', 'Kessig Malcontents', '8620d16e48cf01bf3f08cad8b985b752', 'battle_rule_v1:12df6f8c33b63f99bcc89c6b6444dedc', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_dynamic_count_damage_target_v1","battlefield_count_scope":"controller_battlefield","battlefield_count_subtypes":["human"],"damage_amount_source":"battlefield_permanent_count","damage_base_amount":0,"damage_per_count":1,"effect":"creature","etb_damage_amount":0,"etb_damage_target":"player_or_planeswalker","etb_dynamic_damage":true,"target":"player_or_planeswalker","target_constraints":{"scope":"player_or_planeswalker"},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"player_or_planeswalker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class KessigMalcontents translated into ManaLoom runtime scope xmage_creature_etb_dynamic_count_damage_target_v1. This row is package-ready only because the source signature is a narrow creature ETB dynamic battlefield-count damage trigger with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('outrage shaman', 'Outrage Shaman', '6573f249c0ad49ee7c5fa5f88b7daf8c', 'battle_rule_v1:ef46a599a0428bf700b4e8d908835d77', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_dynamic_count_damage_target_v1","damage_amount_source":"controlled_permanents_mana_symbol_count","damage_base_amount":0,"damage_per_count":1,"effect":"creature","etb_damage_amount":0,"etb_damage_target":"creature","etb_dynamic_damage":true,"mana_symbol_count_color":"R","target":"creature","target_constraints":{"card_types":["creature"]},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class OutrageShaman translated into ManaLoom runtime scope xmage_creature_etb_dynamic_count_damage_target_v1. This row is package-ready only because the source signature is a narrow creature ETB dynamic battlefield-count damage trigger with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('thundering sparkmage', 'Thundering Sparkmage', 'caa6744bfdfeabfa57bd621cf6dbc15c', 'battle_rule_v1:dce4d2fc86d58bf503032bc12e78c447', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_dynamic_count_damage_target_v1","damage_amount_source":"party_count","damage_base_amount":0,"damage_per_count":1,"effect":"creature","etb_damage_amount":0,"etb_damage_target":"creature_or_planeswalker","etb_dynamic_damage":true,"target":"creature_or_planeswalker","target_constraints":{"card_types":["creature","planeswalker"]},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature_or_planeswalker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ThunderingSparkmage translated into ManaLoom runtime scope xmage_creature_etb_dynamic_count_damage_target_v1. This row is package-ready only because the source signature is a narrow creature ETB dynamic battlefield-count damage trigger with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('volley veteran', 'Volley Veteran', 'da37d347529c9a3813d5db00dd9a8ef9', 'battle_rule_v1:4bba8c2ade6fc9360d9fecb24654d190', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_dynamic_count_damage_target_v1","battlefield_count_scope":"controller_battlefield","battlefield_count_subtypes":["goblin"],"damage_amount_source":"battlefield_permanent_count","damage_base_amount":0,"damage_per_count":1,"effect":"creature","etb_damage_amount":0,"etb_damage_target":"creature","etb_dynamic_damage":true,"target":"creature","target_constraints":{"card_types":["creature"],"controller_scope":"opponent"},"target_controller":"opponent","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class VolleyVeteran translated into ManaLoom runtime scope xmage_creature_etb_dynamic_count_damage_target_v1. This row is package-ready only because the source signature is a narrow creature ETB dynamic battlefield-count damage trigger with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('basalt ravager', 'Basalt Ravager', 'cac67c66affc0628f40c1811b0873ae9', 'battle_rule_v1:f2ae1e68342721c6d1e6f939f7a083b5', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_dynamic_count_damage_target_v1","damage_amount_source":"greatest_shared_creature_type_count","damage_base_amount":0,"damage_per_count":1,"effect":"creature","etb_damage_amount":0,"etb_damage_target":"any_target","etb_dynamic_damage":true,"target":"any_target","target_constraints":{"scope":"any_target"},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"any_target"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BasaltRavager translated into ManaLoom runtime scope xmage_creature_etb_dynamic_count_damage_target_v1. This row is package-ready only because the source signature is a narrow creature ETB dynamic battlefield-count damage trigger with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('explosive prodigy', 'Explosive Prodigy', '1e447151ab8aa3df1306d5d1db6c8fa0', 'battle_rule_v1:1282c6f503ecc1b764fb82ec1ca73ef2', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_dynamic_count_damage_target_v1","damage_amount_source":"colors_among_permanents_you_control","damage_base_amount":0,"damage_per_count":1,"effect":"creature","etb_damage_amount":0,"etb_damage_target":"creature","etb_dynamic_damage":true,"target":"creature","target_constraints":{"card_types":["creature"],"controller_scope":"opponent"},"target_controller":"opponent","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ExplosiveProdigy translated into ManaLoom runtime scope xmage_creature_etb_dynamic_count_damage_target_v1. This row is package-ready only because the source signature is a narrow creature ETB dynamic battlefield-count damage trigger with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('firefist adept', 'Firefist Adept', '2dbcc9991de1570f0ae1eed570d9250e', 'battle_rule_v1:0d910538c746d80f8fafe09e19cf67d2', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_dynamic_count_damage_target_v1","battlefield_count_scope":"controller_battlefield","battlefield_count_subtypes":["wizard"],"damage_amount_source":"battlefield_permanent_count","damage_base_amount":0,"damage_per_count":1,"effect":"creature","etb_damage_amount":0,"etb_damage_target":"creature","etb_dynamic_damage":true,"target":"creature","target_constraints":{"card_types":["creature"],"controller_scope":"opponent"},"target_controller":"opponent","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FirefistAdept translated into ManaLoom runtime scope xmage_creature_etb_dynamic_count_damage_target_v1. This row is package-ready only because the source signature is a narrow creature ETB dynamic battlefield-count damage trigger with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('gruesome scourger', 'Gruesome Scourger', 'dcb48cabe9a66fe7a9ed1da0092575ef', 'battle_rule_v1:4caec1a33ceadbea7dfb82ef563888ea', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_dynamic_count_damage_target_v1","battlefield_count_card_types":["creature"],"battlefield_count_scope":"controller_battlefield","damage_amount_source":"battlefield_permanent_count","damage_base_amount":0,"damage_per_count":1,"effect":"creature","etb_damage_amount":0,"etb_damage_target":"opponent_or_planeswalker","etb_dynamic_damage":true,"target":"opponent_or_planeswalker","target_constraints":{"scope":"opponent_or_planeswalker"},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"opponent_or_planeswalker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GruesomeScourger translated into ManaLoom runtime scope xmage_creature_etb_dynamic_count_damage_target_v1. This row is package-ready only because the source signature is a narrow creature ETB dynamic battlefield-count damage trigger with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('kessig malcontents', 'Kessig Malcontents', '8620d16e48cf01bf3f08cad8b985b752', 'battle_rule_v1:12df6f8c33b63f99bcc89c6b6444dedc', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_dynamic_count_damage_target_v1","battlefield_count_scope":"controller_battlefield","battlefield_count_subtypes":["human"],"damage_amount_source":"battlefield_permanent_count","damage_base_amount":0,"damage_per_count":1,"effect":"creature","etb_damage_amount":0,"etb_damage_target":"player_or_planeswalker","etb_dynamic_damage":true,"target":"player_or_planeswalker","target_constraints":{"scope":"player_or_planeswalker"},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"player_or_planeswalker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class KessigMalcontents translated into ManaLoom runtime scope xmage_creature_etb_dynamic_count_damage_target_v1. This row is package-ready only because the source signature is a narrow creature ETB dynamic battlefield-count damage trigger with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('outrage shaman', 'Outrage Shaman', '6573f249c0ad49ee7c5fa5f88b7daf8c', 'battle_rule_v1:ef46a599a0428bf700b4e8d908835d77', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_dynamic_count_damage_target_v1","damage_amount_source":"controlled_permanents_mana_symbol_count","damage_base_amount":0,"damage_per_count":1,"effect":"creature","etb_damage_amount":0,"etb_damage_target":"creature","etb_dynamic_damage":true,"mana_symbol_count_color":"R","target":"creature","target_constraints":{"card_types":["creature"]},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class OutrageShaman translated into ManaLoom runtime scope xmage_creature_etb_dynamic_count_damage_target_v1. This row is package-ready only because the source signature is a narrow creature ETB dynamic battlefield-count damage trigger with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('thundering sparkmage', 'Thundering Sparkmage', 'caa6744bfdfeabfa57bd621cf6dbc15c', 'battle_rule_v1:dce4d2fc86d58bf503032bc12e78c447', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_dynamic_count_damage_target_v1","damage_amount_source":"party_count","damage_base_amount":0,"damage_per_count":1,"effect":"creature","etb_damage_amount":0,"etb_damage_target":"creature_or_planeswalker","etb_dynamic_damage":true,"target":"creature_or_planeswalker","target_constraints":{"card_types":["creature","planeswalker"]},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature_or_planeswalker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ThunderingSparkmage translated into ManaLoom runtime scope xmage_creature_etb_dynamic_count_damage_target_v1. This row is package-ready only because the source signature is a narrow creature ETB dynamic battlefield-count damage trigger with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('volley veteran', 'Volley Veteran', 'da37d347529c9a3813d5db00dd9a8ef9', 'battle_rule_v1:4bba8c2ade6fc9360d9fecb24654d190', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_dynamic_count_damage_target_v1","battlefield_count_scope":"controller_battlefield","battlefield_count_subtypes":["goblin"],"damage_amount_source":"battlefield_permanent_count","damage_base_amount":0,"damage_per_count":1,"effect":"creature","etb_damage_amount":0,"etb_damage_target":"creature","etb_dynamic_damage":true,"target":"creature","target_constraints":{"card_types":["creature"],"controller_scope":"opponent"},"target_controller":"opponent","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class VolleyVeteran translated into ManaLoom runtime scope xmage_creature_etb_dynamic_count_damage_target_v1. This row is package-ready only because the source signature is a narrow creature ETB dynamic battlefield-count damage trigger with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('basalt ravager', 'Basalt Ravager', 'cac67c66affc0628f40c1811b0873ae9', 'battle_rule_v1:f2ae1e68342721c6d1e6f939f7a083b5', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_dynamic_count_damage_target_v1","damage_amount_source":"greatest_shared_creature_type_count","damage_base_amount":0,"damage_per_count":1,"effect":"creature","etb_damage_amount":0,"etb_damage_target":"any_target","etb_dynamic_damage":true,"target":"any_target","target_constraints":{"scope":"any_target"},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"any_target"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BasaltRavager translated into ManaLoom runtime scope xmage_creature_etb_dynamic_count_damage_target_v1. This row is package-ready only because the source signature is a narrow creature ETB dynamic battlefield-count damage trigger with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('explosive prodigy', 'Explosive Prodigy', '1e447151ab8aa3df1306d5d1db6c8fa0', 'battle_rule_v1:1282c6f503ecc1b764fb82ec1ca73ef2', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_dynamic_count_damage_target_v1","damage_amount_source":"colors_among_permanents_you_control","damage_base_amount":0,"damage_per_count":1,"effect":"creature","etb_damage_amount":0,"etb_damage_target":"creature","etb_dynamic_damage":true,"target":"creature","target_constraints":{"card_types":["creature"],"controller_scope":"opponent"},"target_controller":"opponent","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ExplosiveProdigy translated into ManaLoom runtime scope xmage_creature_etb_dynamic_count_damage_target_v1. This row is package-ready only because the source signature is a narrow creature ETB dynamic battlefield-count damage trigger with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('firefist adept', 'Firefist Adept', '2dbcc9991de1570f0ae1eed570d9250e', 'battle_rule_v1:0d910538c746d80f8fafe09e19cf67d2', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_dynamic_count_damage_target_v1","battlefield_count_scope":"controller_battlefield","battlefield_count_subtypes":["wizard"],"damage_amount_source":"battlefield_permanent_count","damage_base_amount":0,"damage_per_count":1,"effect":"creature","etb_damage_amount":0,"etb_damage_target":"creature","etb_dynamic_damage":true,"target":"creature","target_constraints":{"card_types":["creature"],"controller_scope":"opponent"},"target_controller":"opponent","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FirefistAdept translated into ManaLoom runtime scope xmage_creature_etb_dynamic_count_damage_target_v1. This row is package-ready only because the source signature is a narrow creature ETB dynamic battlefield-count damage trigger with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('gruesome scourger', 'Gruesome Scourger', 'dcb48cabe9a66fe7a9ed1da0092575ef', 'battle_rule_v1:4caec1a33ceadbea7dfb82ef563888ea', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_dynamic_count_damage_target_v1","battlefield_count_card_types":["creature"],"battlefield_count_scope":"controller_battlefield","damage_amount_source":"battlefield_permanent_count","damage_base_amount":0,"damage_per_count":1,"effect":"creature","etb_damage_amount":0,"etb_damage_target":"opponent_or_planeswalker","etb_dynamic_damage":true,"target":"opponent_or_planeswalker","target_constraints":{"scope":"opponent_or_planeswalker"},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"opponent_or_planeswalker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GruesomeScourger translated into ManaLoom runtime scope xmage_creature_etb_dynamic_count_damage_target_v1. This row is package-ready only because the source signature is a narrow creature ETB dynamic battlefield-count damage trigger with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('kessig malcontents', 'Kessig Malcontents', '8620d16e48cf01bf3f08cad8b985b752', 'battle_rule_v1:12df6f8c33b63f99bcc89c6b6444dedc', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_dynamic_count_damage_target_v1","battlefield_count_scope":"controller_battlefield","battlefield_count_subtypes":["human"],"damage_amount_source":"battlefield_permanent_count","damage_base_amount":0,"damage_per_count":1,"effect":"creature","etb_damage_amount":0,"etb_damage_target":"player_or_planeswalker","etb_dynamic_damage":true,"target":"player_or_planeswalker","target_constraints":{"scope":"player_or_planeswalker"},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"player_or_planeswalker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class KessigMalcontents translated into ManaLoom runtime scope xmage_creature_etb_dynamic_count_damage_target_v1. This row is package-ready only because the source signature is a narrow creature ETB dynamic battlefield-count damage trigger with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('outrage shaman', 'Outrage Shaman', '6573f249c0ad49ee7c5fa5f88b7daf8c', 'battle_rule_v1:ef46a599a0428bf700b4e8d908835d77', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_dynamic_count_damage_target_v1","damage_amount_source":"controlled_permanents_mana_symbol_count","damage_base_amount":0,"damage_per_count":1,"effect":"creature","etb_damage_amount":0,"etb_damage_target":"creature","etb_dynamic_damage":true,"mana_symbol_count_color":"R","target":"creature","target_constraints":{"card_types":["creature"]},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class OutrageShaman translated into ManaLoom runtime scope xmage_creature_etb_dynamic_count_damage_target_v1. This row is package-ready only because the source signature is a narrow creature ETB dynamic battlefield-count damage trigger with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('thundering sparkmage', 'Thundering Sparkmage', 'caa6744bfdfeabfa57bd621cf6dbc15c', 'battle_rule_v1:dce4d2fc86d58bf503032bc12e78c447', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_dynamic_count_damage_target_v1","damage_amount_source":"party_count","damage_base_amount":0,"damage_per_count":1,"effect":"creature","etb_damage_amount":0,"etb_damage_target":"creature_or_planeswalker","etb_dynamic_damage":true,"target":"creature_or_planeswalker","target_constraints":{"card_types":["creature","planeswalker"]},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature_or_planeswalker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ThunderingSparkmage translated into ManaLoom runtime scope xmage_creature_etb_dynamic_count_damage_target_v1. This row is package-ready only because the source signature is a narrow creature ETB dynamic battlefield-count damage trigger with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('volley veteran', 'Volley Veteran', 'da37d347529c9a3813d5db00dd9a8ef9', 'battle_rule_v1:4bba8c2ade6fc9360d9fecb24654d190', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_dynamic_count_damage_target_v1","battlefield_count_scope":"controller_battlefield","battlefield_count_subtypes":["goblin"],"damage_amount_source":"battlefield_permanent_count","damage_base_amount":0,"damage_per_count":1,"effect":"creature","etb_damage_amount":0,"etb_damage_target":"creature","etb_dynamic_damage":true,"target":"creature","target_constraints":{"card_types":["creature"],"controller_scope":"opponent"},"target_controller":"opponent","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class VolleyVeteran translated into ManaLoom runtime scope xmage_creature_etb_dynamic_count_damage_target_v1. This row is package-ready only because the source signature is a narrow creature ETB dynamic battlefield-count damage trigger with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
