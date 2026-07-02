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
  LEFT JOIN public.cards c
    ON (
         lower(c.name) = p.normalized_name
         OR split_part(lower(c.name), ' // ', 1) = p.normalized_name
       )
   AND md5(coalesce(c.oracle_text, '')) = p.oracle_hash
),
target_cards AS (
  SELECT
    normalized_name,
    card_name,
    oracle_hash,
    count(card_id) AS target_card_rows,
    min(card_id::text)::uuid AS canonical_card_id,
    min(db_card_name) AS canonical_card_name
  FROM matched_cards
  GROUP BY normalized_name, card_name, oracle_hash
),
rule_rows AS (
  SELECT p.normalized_name, count(r.*) AS existing_rule_rows
  FROM proposed p
  LEFT JOIN public.card_battle_rules r
    ON (
         r.normalized_name = p.normalized_name
         OR r.normalized_name LIKE p.normalized_name || ' // %'
       )
  GROUP BY p.normalized_name
),
expected_rows AS (
  SELECT p.normalized_name, count(r.*) AS expected_rule_rows_before
  FROM proposed p
  LEFT JOIN public.card_battle_rules r
    ON (
         r.normalized_name = p.normalized_name
         OR r.normalized_name LIKE p.normalized_name || ' // %'
       )
   AND r.logical_rule_key = p.logical_rule_key
  GROUP BY p.normalized_name
),
shadow_rows AS (
  SELECT p.normalized_name, count(r.*) AS would_deprecate_shadow_rows
  FROM proposed p
  LEFT JOIN public.card_battle_rules r
    ON (
         r.normalized_name = p.normalized_name
         OR r.normalized_name LIKE p.normalized_name || ' // %'
       )
   AND r.logical_rule_key <> p.logical_rule_key
   AND r.review_status NOT IN ('deprecated', 'rejected')
   AND r.execution_status <> 'disabled'
  GROUP BY p.normalized_name
)
SELECT
  p.card_name,
  p.normalized_name,
  p.oracle_hash,
  p.logical_rule_key,
  p.shadow_handling,
  tc.target_card_rows,
  tc.canonical_card_id,
  rr.existing_rule_rows,
  er.expected_rule_rows_before,
  sr.would_deprecate_shadow_rows
FROM proposed p
JOIN target_cards tc USING (normalized_name, card_name, oracle_hash)
JOIN rule_rows rr USING (normalized_name)
JOIN expected_rows er USING (normalized_name)
JOIN shadow_rows sr USING (normalized_name)
ORDER BY p.card_name;
