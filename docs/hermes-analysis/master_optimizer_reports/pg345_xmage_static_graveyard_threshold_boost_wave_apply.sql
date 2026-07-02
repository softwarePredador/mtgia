BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE manaloom_deploy_audit.pg345_xmage_static_graveyard_threshold_boost_wave_202607 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('anurid barkripper', 'basking capybara', 'frilled cave-wurm', 'krosan beast', 'metamorphic wurm', 'seton''s scout', 'springing tiger')
   OR normalized_name LIKE 'anurid barkripper // %'
   OR normalized_name LIKE 'basking capybara // %'
   OR normalized_name LIKE 'frilled cave-wurm // %'
   OR normalized_name LIKE 'krosan beast // %'
   OR normalized_name LIKE 'metamorphic wurm // %'
   OR normalized_name LIKE 'seton''s scout // %'
   OR normalized_name LIKE 'springing tiger // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('anurid barkripper', 'Anurid Barkripper', '203e9afaf95da481ac996e23ca4d2d7e', 'battle_rule_v1:b4b407a7f3e66517c0718ce885fd8445', '{"ability_kind":"static","battle_model_scope":"xmage_static_source_boost_if_graveyard_threshold_v1","effect":"creature","graveyard_count_card_types":["card"],"graveyard_count_scope":"controller_graveyard","graveyard_count_threshold":7,"static_effect":"source_power_toughness_boost_if_graveyard_count","static_power_bonus":2,"static_toughness_bonus":2,"target":"self","target_controller":"self","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"BoostSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AnuridBarkripper translated into ManaLoom runtime scope xmage_static_source_boost_if_graveyard_threshold_v1. This row is package-ready only because the source signature is a narrow creature static source power/toughness boost gated by graveyard card count with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('basking capybara', 'Basking Capybara', '7a21fa965254fe0e0b59e9a615c6be82', 'battle_rule_v1:42f3b1ced83c10c73c08b3295358b471', '{"ability_kind":"static","battle_model_scope":"xmage_static_source_boost_if_graveyard_threshold_v1","effect":"creature","graveyard_count_card_types":["permanent"],"graveyard_count_scope":"controller_graveyard","graveyard_count_threshold":4,"static_effect":"source_power_toughness_boost_if_graveyard_count","static_power_bonus":3,"static_toughness_bonus":0,"target":"self","target_controller":"self","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"BoostSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BaskingCapybara translated into ManaLoom runtime scope xmage_static_source_boost_if_graveyard_threshold_v1. This row is package-ready only because the source signature is a narrow creature static source power/toughness boost gated by graveyard card count with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('frilled cave-wurm', 'Frilled Cave-Wurm', 'a82b4370d8d5601bdc35d993f8456cdf', 'battle_rule_v1:200cc2f6eac25de9aa5302e0ec8307e7', '{"ability_kind":"static","battle_model_scope":"xmage_static_source_boost_if_graveyard_threshold_v1","effect":"creature","graveyard_count_card_types":["permanent"],"graveyard_count_scope":"controller_graveyard","graveyard_count_threshold":4,"static_effect":"source_power_toughness_boost_if_graveyard_count","static_power_bonus":2,"static_toughness_bonus":0,"target":"self","target_controller":"self","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"BoostSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FrilledCaveWurm translated into ManaLoom runtime scope xmage_static_source_boost_if_graveyard_threshold_v1. This row is package-ready only because the source signature is a narrow creature static source power/toughness boost gated by graveyard card count with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('krosan beast', 'Krosan Beast', '6858ee81dec4d380b436ecff0e4091c0', 'battle_rule_v1:e725b896a17c56815f9d1ec58d9bad5a', '{"ability_kind":"static","battle_model_scope":"xmage_static_source_boost_if_graveyard_threshold_v1","effect":"creature","graveyard_count_card_types":["card"],"graveyard_count_scope":"controller_graveyard","graveyard_count_threshold":7,"static_effect":"source_power_toughness_boost_if_graveyard_count","static_power_bonus":7,"static_toughness_bonus":7,"target":"self","target_controller":"self","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"BoostSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class KrosanBeast translated into ManaLoom runtime scope xmage_static_source_boost_if_graveyard_threshold_v1. This row is package-ready only because the source signature is a narrow creature static source power/toughness boost gated by graveyard card count with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('metamorphic wurm', 'Metamorphic Wurm', 'c414e7610eae4070e4ef6b5bc5a6f4b0', 'battle_rule_v1:bb1f455c435995ff681b25fc60818155', '{"ability_kind":"static","battle_model_scope":"xmage_static_source_boost_if_graveyard_threshold_v1","effect":"creature","graveyard_count_card_types":["card"],"graveyard_count_scope":"controller_graveyard","graveyard_count_threshold":7,"static_effect":"source_power_toughness_boost_if_graveyard_count","static_power_bonus":4,"static_toughness_bonus":4,"target":"self","target_controller":"self","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"BoostSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MetamorphicWurm translated into ManaLoom runtime scope xmage_static_source_boost_if_graveyard_threshold_v1. This row is package-ready only because the source signature is a narrow creature static source power/toughness boost gated by graveyard card count with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('seton''s scout', 'Seton''s Scout', 'fa375ed2d3fe90010d7d1b4dc7354752', 'battle_rule_v1:7182ce0e8acd2c75f07ea0e53f39f5a5', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_source_boost_if_graveyard_threshold_v1","effect":"creature","graveyard_count_card_types":["card"],"graveyard_count_scope":"controller_graveyard","graveyard_count_threshold":7,"keywords":["reach"],"reach":true,"static_effect":"source_power_toughness_boost_if_graveyard_count","static_power_bonus":2,"static_toughness_bonus":2,"target":"self","target_controller":"self","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"BoostSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SetonsScout translated into ManaLoom runtime scope xmage_static_source_boost_if_graveyard_threshold_v1. This row is package-ready only because the source signature is a narrow creature static source power/toughness boost gated by graveyard card count with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('springing tiger', 'Springing Tiger', '203e9afaf95da481ac996e23ca4d2d7e', 'battle_rule_v1:b4b407a7f3e66517c0718ce885fd8445', '{"ability_kind":"static","battle_model_scope":"xmage_static_source_boost_if_graveyard_threshold_v1","effect":"creature","graveyard_count_card_types":["card"],"graveyard_count_scope":"controller_graveyard","graveyard_count_threshold":7,"static_effect":"source_power_toughness_boost_if_graveyard_count","static_power_bonus":2,"static_toughness_bonus":2,"target":"self","target_controller":"self","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"BoostSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SpringingTiger translated into ManaLoom runtime scope xmage_static_source_boost_if_graveyard_threshold_v1. This row is package-ready only because the source signature is a narrow creature static source power/toughness boost gated by graveyard card count with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('anurid barkripper', 'Anurid Barkripper', '203e9afaf95da481ac996e23ca4d2d7e', 'battle_rule_v1:b4b407a7f3e66517c0718ce885fd8445', '{"ability_kind":"static","battle_model_scope":"xmage_static_source_boost_if_graveyard_threshold_v1","effect":"creature","graveyard_count_card_types":["card"],"graveyard_count_scope":"controller_graveyard","graveyard_count_threshold":7,"static_effect":"source_power_toughness_boost_if_graveyard_count","static_power_bonus":2,"static_toughness_bonus":2,"target":"self","target_controller":"self","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"BoostSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AnuridBarkripper translated into ManaLoom runtime scope xmage_static_source_boost_if_graveyard_threshold_v1. This row is package-ready only because the source signature is a narrow creature static source power/toughness boost gated by graveyard card count with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('basking capybara', 'Basking Capybara', '7a21fa965254fe0e0b59e9a615c6be82', 'battle_rule_v1:42f3b1ced83c10c73c08b3295358b471', '{"ability_kind":"static","battle_model_scope":"xmage_static_source_boost_if_graveyard_threshold_v1","effect":"creature","graveyard_count_card_types":["permanent"],"graveyard_count_scope":"controller_graveyard","graveyard_count_threshold":4,"static_effect":"source_power_toughness_boost_if_graveyard_count","static_power_bonus":3,"static_toughness_bonus":0,"target":"self","target_controller":"self","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"BoostSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BaskingCapybara translated into ManaLoom runtime scope xmage_static_source_boost_if_graveyard_threshold_v1. This row is package-ready only because the source signature is a narrow creature static source power/toughness boost gated by graveyard card count with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('frilled cave-wurm', 'Frilled Cave-Wurm', 'a82b4370d8d5601bdc35d993f8456cdf', 'battle_rule_v1:200cc2f6eac25de9aa5302e0ec8307e7', '{"ability_kind":"static","battle_model_scope":"xmage_static_source_boost_if_graveyard_threshold_v1","effect":"creature","graveyard_count_card_types":["permanent"],"graveyard_count_scope":"controller_graveyard","graveyard_count_threshold":4,"static_effect":"source_power_toughness_boost_if_graveyard_count","static_power_bonus":2,"static_toughness_bonus":0,"target":"self","target_controller":"self","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"BoostSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FrilledCaveWurm translated into ManaLoom runtime scope xmage_static_source_boost_if_graveyard_threshold_v1. This row is package-ready only because the source signature is a narrow creature static source power/toughness boost gated by graveyard card count with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('krosan beast', 'Krosan Beast', '6858ee81dec4d380b436ecff0e4091c0', 'battle_rule_v1:e725b896a17c56815f9d1ec58d9bad5a', '{"ability_kind":"static","battle_model_scope":"xmage_static_source_boost_if_graveyard_threshold_v1","effect":"creature","graveyard_count_card_types":["card"],"graveyard_count_scope":"controller_graveyard","graveyard_count_threshold":7,"static_effect":"source_power_toughness_boost_if_graveyard_count","static_power_bonus":7,"static_toughness_bonus":7,"target":"self","target_controller":"self","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"BoostSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class KrosanBeast translated into ManaLoom runtime scope xmage_static_source_boost_if_graveyard_threshold_v1. This row is package-ready only because the source signature is a narrow creature static source power/toughness boost gated by graveyard card count with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('metamorphic wurm', 'Metamorphic Wurm', 'c414e7610eae4070e4ef6b5bc5a6f4b0', 'battle_rule_v1:bb1f455c435995ff681b25fc60818155', '{"ability_kind":"static","battle_model_scope":"xmage_static_source_boost_if_graveyard_threshold_v1","effect":"creature","graveyard_count_card_types":["card"],"graveyard_count_scope":"controller_graveyard","graveyard_count_threshold":7,"static_effect":"source_power_toughness_boost_if_graveyard_count","static_power_bonus":4,"static_toughness_bonus":4,"target":"self","target_controller":"self","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"BoostSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MetamorphicWurm translated into ManaLoom runtime scope xmage_static_source_boost_if_graveyard_threshold_v1. This row is package-ready only because the source signature is a narrow creature static source power/toughness boost gated by graveyard card count with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('seton''s scout', 'Seton''s Scout', 'fa375ed2d3fe90010d7d1b4dc7354752', 'battle_rule_v1:7182ce0e8acd2c75f07ea0e53f39f5a5', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_source_boost_if_graveyard_threshold_v1","effect":"creature","graveyard_count_card_types":["card"],"graveyard_count_scope":"controller_graveyard","graveyard_count_threshold":7,"keywords":["reach"],"reach":true,"static_effect":"source_power_toughness_boost_if_graveyard_count","static_power_bonus":2,"static_toughness_bonus":2,"target":"self","target_controller":"self","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"BoostSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SetonsScout translated into ManaLoom runtime scope xmage_static_source_boost_if_graveyard_threshold_v1. This row is package-ready only because the source signature is a narrow creature static source power/toughness boost gated by graveyard card count with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('springing tiger', 'Springing Tiger', '203e9afaf95da481ac996e23ca4d2d7e', 'battle_rule_v1:b4b407a7f3e66517c0718ce885fd8445', '{"ability_kind":"static","battle_model_scope":"xmage_static_source_boost_if_graveyard_threshold_v1","effect":"creature","graveyard_count_card_types":["card"],"graveyard_count_scope":"controller_graveyard","graveyard_count_threshold":7,"static_effect":"source_power_toughness_boost_if_graveyard_count","static_power_bonus":2,"static_toughness_bonus":2,"target":"self","target_controller":"self","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"BoostSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SpringingTiger translated into ManaLoom runtime scope xmage_static_source_boost_if_graveyard_threshold_v1. This row is package-ready only because the source signature is a narrow creature static source power/toughness boost gated by graveyard card count with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('anurid barkripper', 'Anurid Barkripper', '203e9afaf95da481ac996e23ca4d2d7e', 'battle_rule_v1:b4b407a7f3e66517c0718ce885fd8445', '{"ability_kind":"static","battle_model_scope":"xmage_static_source_boost_if_graveyard_threshold_v1","effect":"creature","graveyard_count_card_types":["card"],"graveyard_count_scope":"controller_graveyard","graveyard_count_threshold":7,"static_effect":"source_power_toughness_boost_if_graveyard_count","static_power_bonus":2,"static_toughness_bonus":2,"target":"self","target_controller":"self","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"BoostSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AnuridBarkripper translated into ManaLoom runtime scope xmage_static_source_boost_if_graveyard_threshold_v1. This row is package-ready only because the source signature is a narrow creature static source power/toughness boost gated by graveyard card count with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('basking capybara', 'Basking Capybara', '7a21fa965254fe0e0b59e9a615c6be82', 'battle_rule_v1:42f3b1ced83c10c73c08b3295358b471', '{"ability_kind":"static","battle_model_scope":"xmage_static_source_boost_if_graveyard_threshold_v1","effect":"creature","graveyard_count_card_types":["permanent"],"graveyard_count_scope":"controller_graveyard","graveyard_count_threshold":4,"static_effect":"source_power_toughness_boost_if_graveyard_count","static_power_bonus":3,"static_toughness_bonus":0,"target":"self","target_controller":"self","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"BoostSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BaskingCapybara translated into ManaLoom runtime scope xmage_static_source_boost_if_graveyard_threshold_v1. This row is package-ready only because the source signature is a narrow creature static source power/toughness boost gated by graveyard card count with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('frilled cave-wurm', 'Frilled Cave-Wurm', 'a82b4370d8d5601bdc35d993f8456cdf', 'battle_rule_v1:200cc2f6eac25de9aa5302e0ec8307e7', '{"ability_kind":"static","battle_model_scope":"xmage_static_source_boost_if_graveyard_threshold_v1","effect":"creature","graveyard_count_card_types":["permanent"],"graveyard_count_scope":"controller_graveyard","graveyard_count_threshold":4,"static_effect":"source_power_toughness_boost_if_graveyard_count","static_power_bonus":2,"static_toughness_bonus":0,"target":"self","target_controller":"self","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"BoostSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FrilledCaveWurm translated into ManaLoom runtime scope xmage_static_source_boost_if_graveyard_threshold_v1. This row is package-ready only because the source signature is a narrow creature static source power/toughness boost gated by graveyard card count with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('krosan beast', 'Krosan Beast', '6858ee81dec4d380b436ecff0e4091c0', 'battle_rule_v1:e725b896a17c56815f9d1ec58d9bad5a', '{"ability_kind":"static","battle_model_scope":"xmage_static_source_boost_if_graveyard_threshold_v1","effect":"creature","graveyard_count_card_types":["card"],"graveyard_count_scope":"controller_graveyard","graveyard_count_threshold":7,"static_effect":"source_power_toughness_boost_if_graveyard_count","static_power_bonus":7,"static_toughness_bonus":7,"target":"self","target_controller":"self","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"BoostSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class KrosanBeast translated into ManaLoom runtime scope xmage_static_source_boost_if_graveyard_threshold_v1. This row is package-ready only because the source signature is a narrow creature static source power/toughness boost gated by graveyard card count with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('metamorphic wurm', 'Metamorphic Wurm', 'c414e7610eae4070e4ef6b5bc5a6f4b0', 'battle_rule_v1:bb1f455c435995ff681b25fc60818155', '{"ability_kind":"static","battle_model_scope":"xmage_static_source_boost_if_graveyard_threshold_v1","effect":"creature","graveyard_count_card_types":["card"],"graveyard_count_scope":"controller_graveyard","graveyard_count_threshold":7,"static_effect":"source_power_toughness_boost_if_graveyard_count","static_power_bonus":4,"static_toughness_bonus":4,"target":"self","target_controller":"self","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"BoostSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MetamorphicWurm translated into ManaLoom runtime scope xmage_static_source_boost_if_graveyard_threshold_v1. This row is package-ready only because the source signature is a narrow creature static source power/toughness boost gated by graveyard card count with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('seton''s scout', 'Seton''s Scout', 'fa375ed2d3fe90010d7d1b4dc7354752', 'battle_rule_v1:7182ce0e8acd2c75f07ea0e53f39f5a5', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_source_boost_if_graveyard_threshold_v1","effect":"creature","graveyard_count_card_types":["card"],"graveyard_count_scope":"controller_graveyard","graveyard_count_threshold":7,"keywords":["reach"],"reach":true,"static_effect":"source_power_toughness_boost_if_graveyard_count","static_power_bonus":2,"static_toughness_bonus":2,"target":"self","target_controller":"self","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"BoostSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SetonsScout translated into ManaLoom runtime scope xmage_static_source_boost_if_graveyard_threshold_v1. This row is package-ready only because the source signature is a narrow creature static source power/toughness boost gated by graveyard card count with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('springing tiger', 'Springing Tiger', '203e9afaf95da481ac996e23ca4d2d7e', 'battle_rule_v1:b4b407a7f3e66517c0718ce885fd8445', '{"ability_kind":"static","battle_model_scope":"xmage_static_source_boost_if_graveyard_threshold_v1","effect":"creature","graveyard_count_card_types":["card"],"graveyard_count_scope":"controller_graveyard","graveyard_count_threshold":7,"static_effect":"source_power_toughness_boost_if_graveyard_count","static_power_bonus":2,"static_toughness_bonus":2,"target":"self","target_controller":"self","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"BoostSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SpringingTiger translated into ManaLoom runtime scope xmage_static_source_boost_if_graveyard_threshold_v1. This row is package-ready only because the source signature is a narrow creature static source power/toughness boost gated by graveyard card count with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
