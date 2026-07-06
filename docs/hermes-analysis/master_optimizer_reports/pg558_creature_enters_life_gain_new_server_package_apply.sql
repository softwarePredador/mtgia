BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg558_creature_enters_life_gain_new_serv_20260706_074911 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('ajani''s welcome', 'bogwater lumaret', 'essence warden', 'healer of the pride', 'hinterland sanctifier', 'impassioned orator', 'kor celebrant', 'soul warden', 'soul''s attendant')
   OR normalized_name LIKE 'ajani''s welcome // %'
   OR normalized_name LIKE 'bogwater lumaret // %'
   OR normalized_name LIKE 'essence warden // %'
   OR normalized_name LIKE 'healer of the pride // %'
   OR normalized_name LIKE 'hinterland sanctifier // %'
   OR normalized_name LIKE 'impassioned orator // %'
   OR normalized_name LIKE 'kor celebrant // %'
   OR normalized_name LIKE 'soul warden // %'
   OR normalized_name LIKE 'soul''s attendant // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('ajani''s welcome', 'Ajani''s Welcome', '6d09a37bd5c0505506c94b6f2d94a7a5', 'battle_rule_v1:089f3a0bad3917be07c2b3be1816798a', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_enters_life_gain_trigger_v1","effect":"enchantment","trigger":"creature_you_control_enters","trigger_another_creature_enters":false,"trigger_controller_scope":"self","trigger_effect":"gain_life","trigger_entering_card_types":["creature"],"trigger_gain_life":1,"trigger_optional":false,"xmage_ability_class":"EntersBattlefieldControlledTriggeredAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"enchantment"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AjanisWelcome translated into ManaLoom runtime scope xmage_creature_enters_life_gain_trigger_v1. This row is package-ready only because the source signature is a narrow permanent trigger when a creature enters and controller gains life with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('bogwater lumaret', 'Bogwater Lumaret', '4f1dcd5e34ac1dcc36285db8ea88fe55', 'battle_rule_v1:f7abc667a056e8f3a9e9f532c8e2d71b', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_enters_life_gain_trigger_v1","effect":"creature","trigger":"creature_you_control_enters","trigger_another_creature_enters":false,"trigger_controller_scope":"self","trigger_effect":"gain_life","trigger_entering_card_types":["creature"],"trigger_gain_life":1,"trigger_optional":false,"xmage_ability_class":"EntersBattlefieldThisOrAnotherTriggeredAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BogwaterLumaret translated into ManaLoom runtime scope xmage_creature_enters_life_gain_trigger_v1. This row is package-ready only because the source signature is a narrow permanent trigger when a creature enters and controller gains life with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('essence warden', 'Essence Warden', '541ce650961d6205c6983a80f0de26c8', 'battle_rule_v1:d872267cd94ffd18d01759dffea4b534', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_enters_life_gain_trigger_v1","effect":"creature","trigger":"creature_enters","trigger_another_creature_enters":true,"trigger_controller_scope":"any","trigger_effect":"gain_life","trigger_entering_card_types":["creature"],"trigger_gain_life":1,"trigger_optional":false,"xmage_ability_class":"EntersBattlefieldAllTriggeredAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class EssenceWarden translated into ManaLoom runtime scope xmage_creature_enters_life_gain_trigger_v1. This row is package-ready only because the source signature is a narrow permanent trigger when a creature enters and controller gains life with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('healer of the pride', 'Healer of the Pride', '1a8c83b7c87404d6374a48479a91191f', 'battle_rule_v1:633cd660f33c0fbfd62a2b44e3885178', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_enters_life_gain_trigger_v1","effect":"creature","trigger":"creature_you_control_enters","trigger_another_creature_enters":true,"trigger_controller_scope":"self","trigger_effect":"gain_life","trigger_entering_card_types":["creature"],"trigger_gain_life":2,"trigger_optional":false,"xmage_ability_class":"EntersBattlefieldControlledTriggeredAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HealerOfThePride translated into ManaLoom runtime scope xmage_creature_enters_life_gain_trigger_v1. This row is package-ready only because the source signature is a narrow permanent trigger when a creature enters and controller gains life with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('hinterland sanctifier', 'Hinterland Sanctifier', 'e7a0375eed54098f412273247b5f1092', 'battle_rule_v1:e8bfae58e56b3d8549356753d856f890', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_enters_life_gain_trigger_v1","effect":"creature","trigger":"creature_you_control_enters","trigger_another_creature_enters":true,"trigger_controller_scope":"self","trigger_effect":"gain_life","trigger_entering_card_types":["creature"],"trigger_gain_life":1,"trigger_optional":false,"xmage_ability_class":"EntersBattlefieldAllTriggeredAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HinterlandSanctifier translated into ManaLoom runtime scope xmage_creature_enters_life_gain_trigger_v1. This row is package-ready only because the source signature is a narrow permanent trigger when a creature enters and controller gains life with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('impassioned orator', 'Impassioned Orator', 'e7a0375eed54098f412273247b5f1092', 'battle_rule_v1:e7b144f63b6e37e3970f3ca0753d00f8', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_enters_life_gain_trigger_v1","effect":"creature","trigger":"creature_you_control_enters","trigger_another_creature_enters":true,"trigger_controller_scope":"self","trigger_effect":"gain_life","trigger_entering_card_types":["creature"],"trigger_gain_life":1,"trigger_optional":false,"xmage_ability_class":"EntersBattlefieldControlledTriggeredAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ImpassionedOrator translated into ManaLoom runtime scope xmage_creature_enters_life_gain_trigger_v1. This row is package-ready only because the source signature is a narrow permanent trigger when a creature enters and controller gains life with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('kor celebrant', 'Kor Celebrant', '4f1dcd5e34ac1dcc36285db8ea88fe55', 'battle_rule_v1:f7abc667a056e8f3a9e9f532c8e2d71b', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_enters_life_gain_trigger_v1","effect":"creature","trigger":"creature_you_control_enters","trigger_another_creature_enters":false,"trigger_controller_scope":"self","trigger_effect":"gain_life","trigger_entering_card_types":["creature"],"trigger_gain_life":1,"trigger_optional":false,"xmage_ability_class":"EntersBattlefieldThisOrAnotherTriggeredAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class KorCelebrant translated into ManaLoom runtime scope xmage_creature_enters_life_gain_trigger_v1. This row is package-ready only because the source signature is a narrow permanent trigger when a creature enters and controller gains life with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('soul warden', 'Soul Warden', '541ce650961d6205c6983a80f0de26c8', 'battle_rule_v1:d872267cd94ffd18d01759dffea4b534', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_enters_life_gain_trigger_v1","effect":"creature","trigger":"creature_enters","trigger_another_creature_enters":true,"trigger_controller_scope":"any","trigger_effect":"gain_life","trigger_entering_card_types":["creature"],"trigger_gain_life":1,"trigger_optional":false,"xmage_ability_class":"EntersBattlefieldAllTriggeredAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SoulWarden translated into ManaLoom runtime scope xmage_creature_enters_life_gain_trigger_v1. This row is package-ready only because the source signature is a narrow permanent trigger when a creature enters and controller gains life with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('soul''s attendant', 'Soul''s Attendant', '62c289d4ca14a9ac8ace7faa3460b6a6', 'battle_rule_v1:9a4743d4ac2cab2cf9ef969669b9606c', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_enters_life_gain_trigger_v1","effect":"creature","trigger":"creature_enters","trigger_another_creature_enters":true,"trigger_controller_scope":"any","trigger_effect":"gain_life","trigger_entering_card_types":["creature"],"trigger_gain_life":1,"trigger_optional":true,"xmage_ability_class":"EntersBattlefieldAllTriggeredAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SoulsAttendant translated into ManaLoom runtime scope xmage_creature_enters_life_gain_trigger_v1. This row is package-ready only because the source signature is a narrow permanent trigger when a creature enters and controller gains life with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('ajani''s welcome', 'Ajani''s Welcome', '6d09a37bd5c0505506c94b6f2d94a7a5', 'battle_rule_v1:089f3a0bad3917be07c2b3be1816798a', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_enters_life_gain_trigger_v1","effect":"enchantment","trigger":"creature_you_control_enters","trigger_another_creature_enters":false,"trigger_controller_scope":"self","trigger_effect":"gain_life","trigger_entering_card_types":["creature"],"trigger_gain_life":1,"trigger_optional":false,"xmage_ability_class":"EntersBattlefieldControlledTriggeredAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"enchantment"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AjanisWelcome translated into ManaLoom runtime scope xmage_creature_enters_life_gain_trigger_v1. This row is package-ready only because the source signature is a narrow permanent trigger when a creature enters and controller gains life with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('bogwater lumaret', 'Bogwater Lumaret', '4f1dcd5e34ac1dcc36285db8ea88fe55', 'battle_rule_v1:f7abc667a056e8f3a9e9f532c8e2d71b', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_enters_life_gain_trigger_v1","effect":"creature","trigger":"creature_you_control_enters","trigger_another_creature_enters":false,"trigger_controller_scope":"self","trigger_effect":"gain_life","trigger_entering_card_types":["creature"],"trigger_gain_life":1,"trigger_optional":false,"xmage_ability_class":"EntersBattlefieldThisOrAnotherTriggeredAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BogwaterLumaret translated into ManaLoom runtime scope xmage_creature_enters_life_gain_trigger_v1. This row is package-ready only because the source signature is a narrow permanent trigger when a creature enters and controller gains life with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('essence warden', 'Essence Warden', '541ce650961d6205c6983a80f0de26c8', 'battle_rule_v1:d872267cd94ffd18d01759dffea4b534', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_enters_life_gain_trigger_v1","effect":"creature","trigger":"creature_enters","trigger_another_creature_enters":true,"trigger_controller_scope":"any","trigger_effect":"gain_life","trigger_entering_card_types":["creature"],"trigger_gain_life":1,"trigger_optional":false,"xmage_ability_class":"EntersBattlefieldAllTriggeredAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class EssenceWarden translated into ManaLoom runtime scope xmage_creature_enters_life_gain_trigger_v1. This row is package-ready only because the source signature is a narrow permanent trigger when a creature enters and controller gains life with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('healer of the pride', 'Healer of the Pride', '1a8c83b7c87404d6374a48479a91191f', 'battle_rule_v1:633cd660f33c0fbfd62a2b44e3885178', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_enters_life_gain_trigger_v1","effect":"creature","trigger":"creature_you_control_enters","trigger_another_creature_enters":true,"trigger_controller_scope":"self","trigger_effect":"gain_life","trigger_entering_card_types":["creature"],"trigger_gain_life":2,"trigger_optional":false,"xmage_ability_class":"EntersBattlefieldControlledTriggeredAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HealerOfThePride translated into ManaLoom runtime scope xmage_creature_enters_life_gain_trigger_v1. This row is package-ready only because the source signature is a narrow permanent trigger when a creature enters and controller gains life with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('hinterland sanctifier', 'Hinterland Sanctifier', 'e7a0375eed54098f412273247b5f1092', 'battle_rule_v1:e8bfae58e56b3d8549356753d856f890', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_enters_life_gain_trigger_v1","effect":"creature","trigger":"creature_you_control_enters","trigger_another_creature_enters":true,"trigger_controller_scope":"self","trigger_effect":"gain_life","trigger_entering_card_types":["creature"],"trigger_gain_life":1,"trigger_optional":false,"xmage_ability_class":"EntersBattlefieldAllTriggeredAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HinterlandSanctifier translated into ManaLoom runtime scope xmage_creature_enters_life_gain_trigger_v1. This row is package-ready only because the source signature is a narrow permanent trigger when a creature enters and controller gains life with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('impassioned orator', 'Impassioned Orator', 'e7a0375eed54098f412273247b5f1092', 'battle_rule_v1:e7b144f63b6e37e3970f3ca0753d00f8', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_enters_life_gain_trigger_v1","effect":"creature","trigger":"creature_you_control_enters","trigger_another_creature_enters":true,"trigger_controller_scope":"self","trigger_effect":"gain_life","trigger_entering_card_types":["creature"],"trigger_gain_life":1,"trigger_optional":false,"xmage_ability_class":"EntersBattlefieldControlledTriggeredAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ImpassionedOrator translated into ManaLoom runtime scope xmage_creature_enters_life_gain_trigger_v1. This row is package-ready only because the source signature is a narrow permanent trigger when a creature enters and controller gains life with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('kor celebrant', 'Kor Celebrant', '4f1dcd5e34ac1dcc36285db8ea88fe55', 'battle_rule_v1:f7abc667a056e8f3a9e9f532c8e2d71b', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_enters_life_gain_trigger_v1","effect":"creature","trigger":"creature_you_control_enters","trigger_another_creature_enters":false,"trigger_controller_scope":"self","trigger_effect":"gain_life","trigger_entering_card_types":["creature"],"trigger_gain_life":1,"trigger_optional":false,"xmage_ability_class":"EntersBattlefieldThisOrAnotherTriggeredAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class KorCelebrant translated into ManaLoom runtime scope xmage_creature_enters_life_gain_trigger_v1. This row is package-ready only because the source signature is a narrow permanent trigger when a creature enters and controller gains life with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('soul warden', 'Soul Warden', '541ce650961d6205c6983a80f0de26c8', 'battle_rule_v1:d872267cd94ffd18d01759dffea4b534', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_enters_life_gain_trigger_v1","effect":"creature","trigger":"creature_enters","trigger_another_creature_enters":true,"trigger_controller_scope":"any","trigger_effect":"gain_life","trigger_entering_card_types":["creature"],"trigger_gain_life":1,"trigger_optional":false,"xmage_ability_class":"EntersBattlefieldAllTriggeredAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SoulWarden translated into ManaLoom runtime scope xmage_creature_enters_life_gain_trigger_v1. This row is package-ready only because the source signature is a narrow permanent trigger when a creature enters and controller gains life with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('soul''s attendant', 'Soul''s Attendant', '62c289d4ca14a9ac8ace7faa3460b6a6', 'battle_rule_v1:9a4743d4ac2cab2cf9ef969669b9606c', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_enters_life_gain_trigger_v1","effect":"creature","trigger":"creature_enters","trigger_another_creature_enters":true,"trigger_controller_scope":"any","trigger_effect":"gain_life","trigger_entering_card_types":["creature"],"trigger_gain_life":1,"trigger_optional":true,"xmage_ability_class":"EntersBattlefieldAllTriggeredAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SoulsAttendant translated into ManaLoom runtime scope xmage_creature_enters_life_gain_trigger_v1. This row is package-ready only because the source signature is a narrow permanent trigger when a creature enters and controller gains life with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('ajani''s welcome', 'Ajani''s Welcome', '6d09a37bd5c0505506c94b6f2d94a7a5', 'battle_rule_v1:089f3a0bad3917be07c2b3be1816798a', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_enters_life_gain_trigger_v1","effect":"enchantment","trigger":"creature_you_control_enters","trigger_another_creature_enters":false,"trigger_controller_scope":"self","trigger_effect":"gain_life","trigger_entering_card_types":["creature"],"trigger_gain_life":1,"trigger_optional":false,"xmage_ability_class":"EntersBattlefieldControlledTriggeredAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"enchantment"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AjanisWelcome translated into ManaLoom runtime scope xmage_creature_enters_life_gain_trigger_v1. This row is package-ready only because the source signature is a narrow permanent trigger when a creature enters and controller gains life with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('bogwater lumaret', 'Bogwater Lumaret', '4f1dcd5e34ac1dcc36285db8ea88fe55', 'battle_rule_v1:f7abc667a056e8f3a9e9f532c8e2d71b', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_enters_life_gain_trigger_v1","effect":"creature","trigger":"creature_you_control_enters","trigger_another_creature_enters":false,"trigger_controller_scope":"self","trigger_effect":"gain_life","trigger_entering_card_types":["creature"],"trigger_gain_life":1,"trigger_optional":false,"xmage_ability_class":"EntersBattlefieldThisOrAnotherTriggeredAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BogwaterLumaret translated into ManaLoom runtime scope xmage_creature_enters_life_gain_trigger_v1. This row is package-ready only because the source signature is a narrow permanent trigger when a creature enters and controller gains life with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('essence warden', 'Essence Warden', '541ce650961d6205c6983a80f0de26c8', 'battle_rule_v1:d872267cd94ffd18d01759dffea4b534', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_enters_life_gain_trigger_v1","effect":"creature","trigger":"creature_enters","trigger_another_creature_enters":true,"trigger_controller_scope":"any","trigger_effect":"gain_life","trigger_entering_card_types":["creature"],"trigger_gain_life":1,"trigger_optional":false,"xmage_ability_class":"EntersBattlefieldAllTriggeredAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class EssenceWarden translated into ManaLoom runtime scope xmage_creature_enters_life_gain_trigger_v1. This row is package-ready only because the source signature is a narrow permanent trigger when a creature enters and controller gains life with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('healer of the pride', 'Healer of the Pride', '1a8c83b7c87404d6374a48479a91191f', 'battle_rule_v1:633cd660f33c0fbfd62a2b44e3885178', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_enters_life_gain_trigger_v1","effect":"creature","trigger":"creature_you_control_enters","trigger_another_creature_enters":true,"trigger_controller_scope":"self","trigger_effect":"gain_life","trigger_entering_card_types":["creature"],"trigger_gain_life":2,"trigger_optional":false,"xmage_ability_class":"EntersBattlefieldControlledTriggeredAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HealerOfThePride translated into ManaLoom runtime scope xmage_creature_enters_life_gain_trigger_v1. This row is package-ready only because the source signature is a narrow permanent trigger when a creature enters and controller gains life with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('hinterland sanctifier', 'Hinterland Sanctifier', 'e7a0375eed54098f412273247b5f1092', 'battle_rule_v1:e8bfae58e56b3d8549356753d856f890', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_enters_life_gain_trigger_v1","effect":"creature","trigger":"creature_you_control_enters","trigger_another_creature_enters":true,"trigger_controller_scope":"self","trigger_effect":"gain_life","trigger_entering_card_types":["creature"],"trigger_gain_life":1,"trigger_optional":false,"xmage_ability_class":"EntersBattlefieldAllTriggeredAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HinterlandSanctifier translated into ManaLoom runtime scope xmage_creature_enters_life_gain_trigger_v1. This row is package-ready only because the source signature is a narrow permanent trigger when a creature enters and controller gains life with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('impassioned orator', 'Impassioned Orator', 'e7a0375eed54098f412273247b5f1092', 'battle_rule_v1:e7b144f63b6e37e3970f3ca0753d00f8', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_enters_life_gain_trigger_v1","effect":"creature","trigger":"creature_you_control_enters","trigger_another_creature_enters":true,"trigger_controller_scope":"self","trigger_effect":"gain_life","trigger_entering_card_types":["creature"],"trigger_gain_life":1,"trigger_optional":false,"xmage_ability_class":"EntersBattlefieldControlledTriggeredAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ImpassionedOrator translated into ManaLoom runtime scope xmage_creature_enters_life_gain_trigger_v1. This row is package-ready only because the source signature is a narrow permanent trigger when a creature enters and controller gains life with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('kor celebrant', 'Kor Celebrant', '4f1dcd5e34ac1dcc36285db8ea88fe55', 'battle_rule_v1:f7abc667a056e8f3a9e9f532c8e2d71b', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_enters_life_gain_trigger_v1","effect":"creature","trigger":"creature_you_control_enters","trigger_another_creature_enters":false,"trigger_controller_scope":"self","trigger_effect":"gain_life","trigger_entering_card_types":["creature"],"trigger_gain_life":1,"trigger_optional":false,"xmage_ability_class":"EntersBattlefieldThisOrAnotherTriggeredAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class KorCelebrant translated into ManaLoom runtime scope xmage_creature_enters_life_gain_trigger_v1. This row is package-ready only because the source signature is a narrow permanent trigger when a creature enters and controller gains life with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('soul warden', 'Soul Warden', '541ce650961d6205c6983a80f0de26c8', 'battle_rule_v1:d872267cd94ffd18d01759dffea4b534', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_enters_life_gain_trigger_v1","effect":"creature","trigger":"creature_enters","trigger_another_creature_enters":true,"trigger_controller_scope":"any","trigger_effect":"gain_life","trigger_entering_card_types":["creature"],"trigger_gain_life":1,"trigger_optional":false,"xmage_ability_class":"EntersBattlefieldAllTriggeredAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SoulWarden translated into ManaLoom runtime scope xmage_creature_enters_life_gain_trigger_v1. This row is package-ready only because the source signature is a narrow permanent trigger when a creature enters and controller gains life with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('soul''s attendant', 'Soul''s Attendant', '62c289d4ca14a9ac8ace7faa3460b6a6', 'battle_rule_v1:9a4743d4ac2cab2cf9ef969669b9606c', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_enters_life_gain_trigger_v1","effect":"creature","trigger":"creature_enters","trigger_another_creature_enters":true,"trigger_controller_scope":"any","trigger_effect":"gain_life","trigger_entering_card_types":["creature"],"trigger_gain_life":1,"trigger_optional":true,"xmage_ability_class":"EntersBattlefieldAllTriggeredAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SoulsAttendant translated into ManaLoom runtime scope xmage_creature_enters_life_gain_trigger_v1. This row is package-ready only because the source signature is a narrow permanent trigger when a creature enters and controller gains life with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
