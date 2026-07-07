BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg586_static_controlled_trample_new_serv_20260707_021928 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('aggressive mammoth', 'bloodcrusher of khorne', 'groundshaker sliver', 'khenra charioteer', 'nylea''s forerunner', 'primal rage', 'roughshod mentor', 'thicket crasher')
   OR normalized_name LIKE 'aggressive mammoth // %'
   OR normalized_name LIKE 'bloodcrusher of khorne // %'
   OR normalized_name LIKE 'groundshaker sliver // %'
   OR normalized_name LIKE 'khenra charioteer // %'
   OR normalized_name LIKE 'nylea''s forerunner // %'
   OR normalized_name LIKE 'primal rage // %'
   OR normalized_name LIKE 'roughshod mentor // %'
   OR normalized_name LIKE 'thicket crasher // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('aggressive mammoth', 'Aggressive Mammoth', '1a9fad0b7e938d5339fcb2a9a6c76427', 'battle_rule_v1:31ed27eaaea6b43f5bce5a1219f39dc0', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_controlled_keyword_grant_v1","effect":"creature","keywords":["trample"],"permanent_type":"creature","static_applies_to":"creatures_you_control","static_effect":"controlled_keyword_grant","static_exclude_source":true,"static_granted_keywords":["trample"],"target":"controlled_creatures","target_constraints":{"card_types":["creature"],"controller":"self"},"target_controller":"self","trample":true,"xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"GainAbilityControlledEffect","xmage_granted_ability_class":"TrampleAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"controlled_creatures"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AggressiveMammoth translated into ManaLoom runtime scope xmage_static_controlled_keyword_grant_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('bloodcrusher of khorne', 'Bloodcrusher of Khorne', 'add52677a0e693e79ccd3290ab703076', 'battle_rule_v1:31ed27eaaea6b43f5bce5a1219f39dc0', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_controlled_keyword_grant_v1","effect":"creature","keywords":["trample"],"permanent_type":"creature","static_applies_to":"creatures_you_control","static_effect":"controlled_keyword_grant","static_exclude_source":true,"static_granted_keywords":["trample"],"target":"controlled_creatures","target_constraints":{"card_types":["creature"],"controller":"self"},"target_controller":"self","trample":true,"xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"GainAbilityControlledEffect","xmage_granted_ability_class":"TrampleAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"controlled_creatures"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BloodcrusherOfKhorne translated into ManaLoom runtime scope xmage_static_controlled_keyword_grant_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('groundshaker sliver', 'Groundshaker Sliver', '585fdd46d978b86a9007554050630ca9', 'battle_rule_v1:48e0618f7275569070a4db62d971a9ba', '{"ability_kind":"static","battle_model_scope":"xmage_static_controlled_keyword_grant_v1","effect":"creature","permanent_type":"creature","static_applies_to":"creatures_you_control","static_effect":"controlled_keyword_grant","static_exclude_source":false,"static_granted_keywords":["trample"],"static_required_subtypes":["sliver"],"target":"controlled_creatures","target_constraints":{"card_types":["creature"],"controller":"self","subtypes":["sliver"]},"target_controller":"self","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"GainAbilityControlledEffect","xmage_granted_ability_class":"TrampleAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"controlled_creatures"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GroundshakerSliver translated into ManaLoom runtime scope xmage_static_controlled_keyword_grant_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('khenra charioteer', 'Khenra Charioteer', '65f7b9f5ecda0ab8578963164076b601', 'battle_rule_v1:31ed27eaaea6b43f5bce5a1219f39dc0', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_controlled_keyword_grant_v1","effect":"creature","keywords":["trample"],"permanent_type":"creature","static_applies_to":"creatures_you_control","static_effect":"controlled_keyword_grant","static_exclude_source":true,"static_granted_keywords":["trample"],"target":"controlled_creatures","target_constraints":{"card_types":["creature"],"controller":"self"},"target_controller":"self","trample":true,"xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"GainAbilityControlledEffect","xmage_granted_ability_class":"TrampleAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"controlled_creatures"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class KhenraCharioteer translated into ManaLoom runtime scope xmage_static_controlled_keyword_grant_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('nylea''s forerunner', 'Nylea''s Forerunner', '65f7b9f5ecda0ab8578963164076b601', 'battle_rule_v1:31ed27eaaea6b43f5bce5a1219f39dc0', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_controlled_keyword_grant_v1","effect":"creature","keywords":["trample"],"permanent_type":"creature","static_applies_to":"creatures_you_control","static_effect":"controlled_keyword_grant","static_exclude_source":true,"static_granted_keywords":["trample"],"target":"controlled_creatures","target_constraints":{"card_types":["creature"],"controller":"self"},"target_controller":"self","trample":true,"xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"GainAbilityControlledEffect","xmage_granted_ability_class":"TrampleAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"controlled_creatures"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class NyleasForerunner translated into ManaLoom runtime scope xmage_static_controlled_keyword_grant_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('primal rage', 'Primal Rage', 'b532311af37638867a24270200d81d24', 'battle_rule_v1:363974e6bda920ddcbd5655a2ba63caa', '{"ability_kind":"static","battle_model_scope":"xmage_static_controlled_keyword_grant_v1","effect":"passive","permanent_type":"enchantment","static_applies_to":"creatures_you_control","static_effect":"controlled_keyword_grant","static_exclude_source":false,"static_granted_keywords":["trample"],"target":"controlled_creatures","target_constraints":{"card_types":["creature"],"controller":"self"},"target_controller":"self","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"GainAbilityControlledEffect","xmage_granted_ability_class":"TrampleAbility"}'::jsonb, '{"category":"unknown","effect":"passive","target":"controlled_creatures"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PrimalRage translated into ManaLoom runtime scope xmage_static_controlled_keyword_grant_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('roughshod mentor', 'Roughshod Mentor', '03eba077ad4be2b9a9fbaad44087cf62', 'battle_rule_v1:0e7575f499a93af361184ebc70967e84', '{"ability_kind":"static","battle_model_scope":"xmage_static_controlled_keyword_grant_v1","effect":"creature","permanent_type":"creature","static_applies_to":"creatures_you_control","static_effect":"controlled_keyword_grant","static_exclude_source":false,"static_granted_keywords":["trample"],"static_required_colors":["G"],"target":"controlled_creatures","target_constraints":{"card_types":["creature"],"colors":["G"],"controller":"self"},"target_controller":"self","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"GainAbilityControlledEffect","xmage_granted_ability_class":"TrampleAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"controlled_creatures"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RoughshodMentor translated into ManaLoom runtime scope xmage_static_controlled_keyword_grant_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('thicket crasher', 'Thicket Crasher', 'c0da9dbcfb5eff6e27a2929dbac73811', 'battle_rule_v1:64dc5dab62cd8f17e3c7f4ede9228277', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_controlled_keyword_grant_v1","effect":"creature","keywords":["trample"],"permanent_type":"creature","static_applies_to":"creatures_you_control","static_effect":"controlled_keyword_grant","static_exclude_source":true,"static_granted_keywords":["trample"],"static_required_subtypes":["elemental"],"target":"controlled_creatures","target_constraints":{"card_types":["creature"],"controller":"self","subtypes":["elemental"]},"target_controller":"self","trample":true,"xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"GainAbilityControlledEffect","xmage_granted_ability_class":"TrampleAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"controlled_creatures"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ThicketCrasher translated into ManaLoom runtime scope xmage_static_controlled_keyword_grant_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('aggressive mammoth', 'Aggressive Mammoth', '1a9fad0b7e938d5339fcb2a9a6c76427', 'battle_rule_v1:31ed27eaaea6b43f5bce5a1219f39dc0', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_controlled_keyword_grant_v1","effect":"creature","keywords":["trample"],"permanent_type":"creature","static_applies_to":"creatures_you_control","static_effect":"controlled_keyword_grant","static_exclude_source":true,"static_granted_keywords":["trample"],"target":"controlled_creatures","target_constraints":{"card_types":["creature"],"controller":"self"},"target_controller":"self","trample":true,"xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"GainAbilityControlledEffect","xmage_granted_ability_class":"TrampleAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"controlled_creatures"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AggressiveMammoth translated into ManaLoom runtime scope xmage_static_controlled_keyword_grant_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('bloodcrusher of khorne', 'Bloodcrusher of Khorne', 'add52677a0e693e79ccd3290ab703076', 'battle_rule_v1:31ed27eaaea6b43f5bce5a1219f39dc0', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_controlled_keyword_grant_v1","effect":"creature","keywords":["trample"],"permanent_type":"creature","static_applies_to":"creatures_you_control","static_effect":"controlled_keyword_grant","static_exclude_source":true,"static_granted_keywords":["trample"],"target":"controlled_creatures","target_constraints":{"card_types":["creature"],"controller":"self"},"target_controller":"self","trample":true,"xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"GainAbilityControlledEffect","xmage_granted_ability_class":"TrampleAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"controlled_creatures"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BloodcrusherOfKhorne translated into ManaLoom runtime scope xmage_static_controlled_keyword_grant_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('groundshaker sliver', 'Groundshaker Sliver', '585fdd46d978b86a9007554050630ca9', 'battle_rule_v1:48e0618f7275569070a4db62d971a9ba', '{"ability_kind":"static","battle_model_scope":"xmage_static_controlled_keyword_grant_v1","effect":"creature","permanent_type":"creature","static_applies_to":"creatures_you_control","static_effect":"controlled_keyword_grant","static_exclude_source":false,"static_granted_keywords":["trample"],"static_required_subtypes":["sliver"],"target":"controlled_creatures","target_constraints":{"card_types":["creature"],"controller":"self","subtypes":["sliver"]},"target_controller":"self","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"GainAbilityControlledEffect","xmage_granted_ability_class":"TrampleAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"controlled_creatures"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GroundshakerSliver translated into ManaLoom runtime scope xmage_static_controlled_keyword_grant_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('khenra charioteer', 'Khenra Charioteer', '65f7b9f5ecda0ab8578963164076b601', 'battle_rule_v1:31ed27eaaea6b43f5bce5a1219f39dc0', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_controlled_keyword_grant_v1","effect":"creature","keywords":["trample"],"permanent_type":"creature","static_applies_to":"creatures_you_control","static_effect":"controlled_keyword_grant","static_exclude_source":true,"static_granted_keywords":["trample"],"target":"controlled_creatures","target_constraints":{"card_types":["creature"],"controller":"self"},"target_controller":"self","trample":true,"xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"GainAbilityControlledEffect","xmage_granted_ability_class":"TrampleAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"controlled_creatures"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class KhenraCharioteer translated into ManaLoom runtime scope xmage_static_controlled_keyword_grant_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('nylea''s forerunner', 'Nylea''s Forerunner', '65f7b9f5ecda0ab8578963164076b601', 'battle_rule_v1:31ed27eaaea6b43f5bce5a1219f39dc0', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_controlled_keyword_grant_v1","effect":"creature","keywords":["trample"],"permanent_type":"creature","static_applies_to":"creatures_you_control","static_effect":"controlled_keyword_grant","static_exclude_source":true,"static_granted_keywords":["trample"],"target":"controlled_creatures","target_constraints":{"card_types":["creature"],"controller":"self"},"target_controller":"self","trample":true,"xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"GainAbilityControlledEffect","xmage_granted_ability_class":"TrampleAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"controlled_creatures"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class NyleasForerunner translated into ManaLoom runtime scope xmage_static_controlled_keyword_grant_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('primal rage', 'Primal Rage', 'b532311af37638867a24270200d81d24', 'battle_rule_v1:363974e6bda920ddcbd5655a2ba63caa', '{"ability_kind":"static","battle_model_scope":"xmage_static_controlled_keyword_grant_v1","effect":"passive","permanent_type":"enchantment","static_applies_to":"creatures_you_control","static_effect":"controlled_keyword_grant","static_exclude_source":false,"static_granted_keywords":["trample"],"target":"controlled_creatures","target_constraints":{"card_types":["creature"],"controller":"self"},"target_controller":"self","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"GainAbilityControlledEffect","xmage_granted_ability_class":"TrampleAbility"}'::jsonb, '{"category":"unknown","effect":"passive","target":"controlled_creatures"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PrimalRage translated into ManaLoom runtime scope xmage_static_controlled_keyword_grant_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('roughshod mentor', 'Roughshod Mentor', '03eba077ad4be2b9a9fbaad44087cf62', 'battle_rule_v1:0e7575f499a93af361184ebc70967e84', '{"ability_kind":"static","battle_model_scope":"xmage_static_controlled_keyword_grant_v1","effect":"creature","permanent_type":"creature","static_applies_to":"creatures_you_control","static_effect":"controlled_keyword_grant","static_exclude_source":false,"static_granted_keywords":["trample"],"static_required_colors":["G"],"target":"controlled_creatures","target_constraints":{"card_types":["creature"],"colors":["G"],"controller":"self"},"target_controller":"self","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"GainAbilityControlledEffect","xmage_granted_ability_class":"TrampleAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"controlled_creatures"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RoughshodMentor translated into ManaLoom runtime scope xmage_static_controlled_keyword_grant_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('thicket crasher', 'Thicket Crasher', 'c0da9dbcfb5eff6e27a2929dbac73811', 'battle_rule_v1:64dc5dab62cd8f17e3c7f4ede9228277', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_controlled_keyword_grant_v1","effect":"creature","keywords":["trample"],"permanent_type":"creature","static_applies_to":"creatures_you_control","static_effect":"controlled_keyword_grant","static_exclude_source":true,"static_granted_keywords":["trample"],"static_required_subtypes":["elemental"],"target":"controlled_creatures","target_constraints":{"card_types":["creature"],"controller":"self","subtypes":["elemental"]},"target_controller":"self","trample":true,"xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"GainAbilityControlledEffect","xmage_granted_ability_class":"TrampleAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"controlled_creatures"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ThicketCrasher translated into ManaLoom runtime scope xmage_static_controlled_keyword_grant_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('aggressive mammoth', 'Aggressive Mammoth', '1a9fad0b7e938d5339fcb2a9a6c76427', 'battle_rule_v1:31ed27eaaea6b43f5bce5a1219f39dc0', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_controlled_keyword_grant_v1","effect":"creature","keywords":["trample"],"permanent_type":"creature","static_applies_to":"creatures_you_control","static_effect":"controlled_keyword_grant","static_exclude_source":true,"static_granted_keywords":["trample"],"target":"controlled_creatures","target_constraints":{"card_types":["creature"],"controller":"self"},"target_controller":"self","trample":true,"xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"GainAbilityControlledEffect","xmage_granted_ability_class":"TrampleAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"controlled_creatures"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AggressiveMammoth translated into ManaLoom runtime scope xmage_static_controlled_keyword_grant_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('bloodcrusher of khorne', 'Bloodcrusher of Khorne', 'add52677a0e693e79ccd3290ab703076', 'battle_rule_v1:31ed27eaaea6b43f5bce5a1219f39dc0', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_controlled_keyword_grant_v1","effect":"creature","keywords":["trample"],"permanent_type":"creature","static_applies_to":"creatures_you_control","static_effect":"controlled_keyword_grant","static_exclude_source":true,"static_granted_keywords":["trample"],"target":"controlled_creatures","target_constraints":{"card_types":["creature"],"controller":"self"},"target_controller":"self","trample":true,"xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"GainAbilityControlledEffect","xmage_granted_ability_class":"TrampleAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"controlled_creatures"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BloodcrusherOfKhorne translated into ManaLoom runtime scope xmage_static_controlled_keyword_grant_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('groundshaker sliver', 'Groundshaker Sliver', '585fdd46d978b86a9007554050630ca9', 'battle_rule_v1:48e0618f7275569070a4db62d971a9ba', '{"ability_kind":"static","battle_model_scope":"xmage_static_controlled_keyword_grant_v1","effect":"creature","permanent_type":"creature","static_applies_to":"creatures_you_control","static_effect":"controlled_keyword_grant","static_exclude_source":false,"static_granted_keywords":["trample"],"static_required_subtypes":["sliver"],"target":"controlled_creatures","target_constraints":{"card_types":["creature"],"controller":"self","subtypes":["sliver"]},"target_controller":"self","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"GainAbilityControlledEffect","xmage_granted_ability_class":"TrampleAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"controlled_creatures"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GroundshakerSliver translated into ManaLoom runtime scope xmage_static_controlled_keyword_grant_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('khenra charioteer', 'Khenra Charioteer', '65f7b9f5ecda0ab8578963164076b601', 'battle_rule_v1:31ed27eaaea6b43f5bce5a1219f39dc0', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_controlled_keyword_grant_v1","effect":"creature","keywords":["trample"],"permanent_type":"creature","static_applies_to":"creatures_you_control","static_effect":"controlled_keyword_grant","static_exclude_source":true,"static_granted_keywords":["trample"],"target":"controlled_creatures","target_constraints":{"card_types":["creature"],"controller":"self"},"target_controller":"self","trample":true,"xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"GainAbilityControlledEffect","xmage_granted_ability_class":"TrampleAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"controlled_creatures"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class KhenraCharioteer translated into ManaLoom runtime scope xmage_static_controlled_keyword_grant_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('nylea''s forerunner', 'Nylea''s Forerunner', '65f7b9f5ecda0ab8578963164076b601', 'battle_rule_v1:31ed27eaaea6b43f5bce5a1219f39dc0', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_controlled_keyword_grant_v1","effect":"creature","keywords":["trample"],"permanent_type":"creature","static_applies_to":"creatures_you_control","static_effect":"controlled_keyword_grant","static_exclude_source":true,"static_granted_keywords":["trample"],"target":"controlled_creatures","target_constraints":{"card_types":["creature"],"controller":"self"},"target_controller":"self","trample":true,"xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"GainAbilityControlledEffect","xmage_granted_ability_class":"TrampleAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"controlled_creatures"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class NyleasForerunner translated into ManaLoom runtime scope xmage_static_controlled_keyword_grant_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('primal rage', 'Primal Rage', 'b532311af37638867a24270200d81d24', 'battle_rule_v1:363974e6bda920ddcbd5655a2ba63caa', '{"ability_kind":"static","battle_model_scope":"xmage_static_controlled_keyword_grant_v1","effect":"passive","permanent_type":"enchantment","static_applies_to":"creatures_you_control","static_effect":"controlled_keyword_grant","static_exclude_source":false,"static_granted_keywords":["trample"],"target":"controlled_creatures","target_constraints":{"card_types":["creature"],"controller":"self"},"target_controller":"self","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"GainAbilityControlledEffect","xmage_granted_ability_class":"TrampleAbility"}'::jsonb, '{"category":"unknown","effect":"passive","target":"controlled_creatures"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PrimalRage translated into ManaLoom runtime scope xmage_static_controlled_keyword_grant_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('roughshod mentor', 'Roughshod Mentor', '03eba077ad4be2b9a9fbaad44087cf62', 'battle_rule_v1:0e7575f499a93af361184ebc70967e84', '{"ability_kind":"static","battle_model_scope":"xmage_static_controlled_keyword_grant_v1","effect":"creature","permanent_type":"creature","static_applies_to":"creatures_you_control","static_effect":"controlled_keyword_grant","static_exclude_source":false,"static_granted_keywords":["trample"],"static_required_colors":["G"],"target":"controlled_creatures","target_constraints":{"card_types":["creature"],"colors":["G"],"controller":"self"},"target_controller":"self","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"GainAbilityControlledEffect","xmage_granted_ability_class":"TrampleAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"controlled_creatures"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RoughshodMentor translated into ManaLoom runtime scope xmage_static_controlled_keyword_grant_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('thicket crasher', 'Thicket Crasher', 'c0da9dbcfb5eff6e27a2929dbac73811', 'battle_rule_v1:64dc5dab62cd8f17e3c7f4ede9228277', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_controlled_keyword_grant_v1","effect":"creature","keywords":["trample"],"permanent_type":"creature","static_applies_to":"creatures_you_control","static_effect":"controlled_keyword_grant","static_exclude_source":true,"static_granted_keywords":["trample"],"static_required_subtypes":["elemental"],"target":"controlled_creatures","target_constraints":{"card_types":["creature"],"controller":"self","subtypes":["elemental"]},"target_controller":"self","trample":true,"xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"GainAbilityControlledEffect","xmage_granted_ability_class":"TrampleAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"controlled_creatures"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ThicketCrasher translated into ManaLoom runtime scope xmage_static_controlled_keyword_grant_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
