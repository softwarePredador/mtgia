WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('builder''s blessing', 'Builder''s Blessing', 'ad19443ea215d62f8c1bd4fb81e0d6aa', 'battle_rule_v1:879c6fd1182165350d95adb96bccf042', '{"ability_kind":"static","battle_model_scope":"xmage_static_controlled_power_toughness_boost_v1","effect":"passive","permanent_type":"enchantment","static_applies_to":"creatures_you_control","static_effect":"controlled_power_toughness_boost","static_exclude_source":false,"static_power_bonus":0,"static_required_tapped_state":"untapped","static_toughness_bonus":2,"target":"controlled_creatures","target_constraints":{"card_types":["creature"],"controller":"self","tapped_state":"untapped"},"target_controller":"self","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"BoostControlledEffect"}'::jsonb, '{"category":"unknown","effect":"passive","target":"controlled_creatures"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BuildersBlessing translated into ManaLoom runtime scope xmage_static_controlled_power_toughness_boost_v1. This row is package-ready only because the source signature is a narrow permanent static controlled-creature power/toughness boost with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('castle', 'Castle', 'ad19443ea215d62f8c1bd4fb81e0d6aa', 'battle_rule_v1:879c6fd1182165350d95adb96bccf042', '{"ability_kind":"static","battle_model_scope":"xmage_static_controlled_power_toughness_boost_v1","effect":"passive","permanent_type":"enchantment","static_applies_to":"creatures_you_control","static_effect":"controlled_power_toughness_boost","static_exclude_source":false,"static_power_bonus":0,"static_required_tapped_state":"untapped","static_toughness_bonus":2,"target":"controlled_creatures","target_constraints":{"card_types":["creature"],"controller":"self","tapped_state":"untapped"},"target_controller":"self","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"BoostControlledEffect"}'::jsonb, '{"category":"unknown","effect":"passive","target":"controlled_creatures"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Castle translated into ManaLoom runtime scope xmage_static_controlled_power_toughness_boost_v1. This row is package-ready only because the source signature is a narrow permanent static controlled-creature power/toughness boost with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('dire fleet neckbreaker', 'Dire Fleet Neckbreaker', 'b4eb782b3781b4f82e89f44d8600c582', 'battle_rule_v1:7ee525c101a785af954a07783655f297', '{"ability_kind":"static","battle_model_scope":"xmage_static_controlled_power_toughness_boost_v1","effect":"creature","permanent_type":"creature","static_applies_to":"creatures_you_control","static_effect":"controlled_power_toughness_boost","static_exclude_source":false,"static_power_bonus":2,"static_required_combat_state":"attacking","static_required_subtypes":["pirate"],"static_toughness_bonus":0,"target":"controlled_creatures","target_constraints":{"card_types":["creature"],"combat_state":"attacking","controller":"self","subtypes":["pirate"]},"target_controller":"self","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"BoostControlledEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"controlled_creatures"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DireFleetNeckbreaker translated into ManaLoom runtime scope xmage_static_controlled_power_toughness_boost_v1. This row is package-ready only because the source signature is a narrow permanent static controlled-creature power/toughness boost with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('goblin oriflamme', 'Goblin Oriflamme', 'ac2e29ddff9b3a465105f4582b40f012', 'battle_rule_v1:4b0f6181adb21e48fae116054fe4e08b', '{"ability_kind":"static","battle_model_scope":"xmage_static_controlled_power_toughness_boost_v1","effect":"passive","permanent_type":"enchantment","static_applies_to":"creatures_you_control","static_effect":"controlled_power_toughness_boost","static_exclude_source":false,"static_power_bonus":1,"static_required_combat_state":"attacking","static_toughness_bonus":0,"target":"controlled_creatures","target_constraints":{"card_types":["creature"],"combat_state":"attacking","controller":"self"},"target_controller":"self","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"BoostControlledEffect"}'::jsonb, '{"category":"unknown","effect":"passive","target":"controlled_creatures"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GoblinOriflamme translated into ManaLoom runtime scope xmage_static_controlled_power_toughness_boost_v1. This row is package-ready only because the source signature is a narrow permanent static controlled-creature power/toughness boost with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('honor of the pure', 'Honor of the Pure', '7278ea48e2b98eab9c6802bb5d454ed7', 'battle_rule_v1:8ab29fd8f0c26aceb442058cc885461f', '{"ability_kind":"static","battle_model_scope":"xmage_static_controlled_power_toughness_boost_v1","effect":"passive","permanent_type":"enchantment","static_applies_to":"creatures_you_control","static_effect":"controlled_power_toughness_boost","static_exclude_source":false,"static_power_bonus":1,"static_required_colors":["W"],"static_toughness_bonus":1,"target":"controlled_creatures","target_constraints":{"card_types":["creature"],"colors":["W"],"controller":"self"},"target_controller":"self","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"BoostControlledEffect"}'::jsonb, '{"category":"unknown","effect":"passive","target":"controlled_creatures"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HonorOfThePure translated into ManaLoom runtime scope xmage_static_controlled_power_toughness_boost_v1. This row is package-ready only because the source signature is a narrow permanent static controlled-creature power/toughness boost with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('jacques le vert', 'Jacques le Vert', '4cb50df0f1c67841d4e69aaaf617d95d', 'battle_rule_v1:964e27bcaf5c95d549770883d5697b90', '{"ability_kind":"static","battle_model_scope":"xmage_static_controlled_power_toughness_boost_v1","effect":"creature","permanent_type":"creature","static_applies_to":"creatures_you_control","static_effect":"controlled_power_toughness_boost","static_exclude_source":false,"static_power_bonus":0,"static_required_colors":["G"],"static_toughness_bonus":2,"target":"controlled_creatures","target_constraints":{"card_types":["creature"],"colors":["G"],"controller":"self"},"target_controller":"self","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"BoostControlledEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"controlled_creatures"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class JacquesLeVert translated into ManaLoom runtime scope xmage_static_controlled_power_toughness_boost_v1. This row is package-ready only because the source signature is a narrow permanent static controlled-creature power/toughness boost with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('kaysa', 'Kaysa', '2d6428d94870902d477189d5c7405c5f', 'battle_rule_v1:c5d36e3805d11b92e963645e9f2eb522', '{"ability_kind":"static","battle_model_scope":"xmage_static_controlled_power_toughness_boost_v1","effect":"creature","permanent_type":"creature","static_applies_to":"creatures_you_control","static_effect":"controlled_power_toughness_boost","static_exclude_source":false,"static_power_bonus":1,"static_required_colors":["G"],"static_toughness_bonus":1,"target":"controlled_creatures","target_constraints":{"card_types":["creature"],"colors":["G"],"controller":"self"},"target_controller":"self","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"BoostControlledEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"controlled_creatures"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Kaysa translated into ManaLoom runtime scope xmage_static_controlled_power_toughness_boost_v1. This row is package-ready only because the source signature is a narrow permanent static controlled-creature power/toughness boost with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('orcish oriflamme', 'Orcish Oriflamme', 'ac2e29ddff9b3a465105f4582b40f012', 'battle_rule_v1:4b0f6181adb21e48fae116054fe4e08b', '{"ability_kind":"static","battle_model_scope":"xmage_static_controlled_power_toughness_boost_v1","effect":"passive","permanent_type":"enchantment","static_applies_to":"creatures_you_control","static_effect":"controlled_power_toughness_boost","static_exclude_source":false,"static_power_bonus":1,"static_required_combat_state":"attacking","static_toughness_bonus":0,"target":"controlled_creatures","target_constraints":{"card_types":["creature"],"combat_state":"attacking","controller":"self"},"target_controller":"self","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"BoostControlledEffect"}'::jsonb, '{"category":"unknown","effect":"passive","target":"controlled_creatures"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class OrcishOriflamme translated into ManaLoom runtime scope xmage_static_controlled_power_toughness_boost_v1. This row is package-ready only because the source signature is a narrow permanent static controlled-creature power/toughness boost with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('war horn', 'War Horn', 'ac2e29ddff9b3a465105f4582b40f012', 'battle_rule_v1:0eedfd9a81253b55467d6dfbd75213ba', '{"ability_kind":"static","battle_model_scope":"xmage_static_controlled_power_toughness_boost_v1","effect":"passive","permanent_type":"artifact","static_applies_to":"creatures_you_control","static_effect":"controlled_power_toughness_boost","static_exclude_source":false,"static_power_bonus":1,"static_required_combat_state":"attacking","static_toughness_bonus":0,"target":"controlled_creatures","target_constraints":{"card_types":["creature"],"combat_state":"attacking","controller":"self"},"target_controller":"self","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"BoostControlledEffect"}'::jsonb, '{"category":"unknown","effect":"passive","target":"controlled_creatures"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WarHorn translated into ManaLoom runtime scope xmage_static_controlled_power_toughness_boost_v1. This row is package-ready only because the source signature is a narrow permanent static controlled-creature power/toughness boost with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
