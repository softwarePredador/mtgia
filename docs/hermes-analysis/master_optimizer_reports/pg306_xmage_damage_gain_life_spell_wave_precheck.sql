WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('agonizing syphon', 'Agonizing Syphon', 'bb99dc3202d60eebefd671ebb94d5fdd', 'battle_rule_v1:c1efa9874143362f23fce5bed164f104', '{"amount":3,"battle_model_scope":"xmage_fixed_damage_target_and_controller_gain_life_spell_v1","controller_gain_life":3,"damage":3,"effect":"direct_damage","gain_life":3,"instant":false,"sorcery":true,"target":"any_target","target_constraints":{"scope":"any_target"},"xmage_effect_classes":["DamageTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"any_target"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AgonizingSyphon translated into ManaLoom runtime scope xmage_fixed_damage_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed damage plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('dark nourishment', 'Dark Nourishment', '9ad9181ce8b6bf194df67591eba0005d', 'battle_rule_v1:029f28307ce7b3b6c69a0d41cc7deab2', '{"amount":3,"battle_model_scope":"xmage_fixed_damage_target_and_controller_gain_life_spell_v1","controller_gain_life":3,"damage":3,"effect":"direct_damage","gain_life":3,"instant":true,"sorcery":false,"target":"any_target","target_constraints":{"scope":"any_target"},"xmage_effect_classes":["DamageTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"any_target","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DarkNourishment translated into ManaLoom runtime scope xmage_fixed_damage_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed damage plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('defibrillating current', 'Defibrillating Current', '32b8aad46992cb58b5cfae49735140ca', 'battle_rule_v1:8b75e08deb84e2d0e42ca28533f68bea', '{"amount":4,"battle_model_scope":"xmage_fixed_damage_target_and_controller_gain_life_spell_v1","controller_gain_life":2,"damage":4,"effect":"direct_damage","gain_life":2,"instant":false,"sorcery":true,"target":"creature_or_planeswalker","target_constraints":{"card_types":["creature","planeswalker"]},"xmage_effect_classes":["DamageTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"creature_or_planeswalker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DefibrillatingCurrent translated into ManaLoom runtime scope xmage_fixed_damage_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed damage plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('douse in gloom', 'Douse in Gloom', '790b89d001d4612f47355b6eaa3c4090', 'battle_rule_v1:788f7c2c874671de1271b7435856eb66', '{"amount":2,"battle_model_scope":"xmage_fixed_damage_target_and_controller_gain_life_spell_v1","controller_gain_life":2,"damage":2,"effect":"direct_damage","gain_life":2,"instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_classes":["DamageTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DouseInGloom translated into ManaLoom runtime scope xmage_fixed_damage_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed damage plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('essence drain', 'Essence Drain', 'f7797f346011287d89fbfc7663670476', 'battle_rule_v1:c1efa9874143362f23fce5bed164f104', '{"amount":3,"battle_model_scope":"xmage_fixed_damage_target_and_controller_gain_life_spell_v1","controller_gain_life":3,"damage":3,"effect":"direct_damage","gain_life":3,"instant":false,"sorcery":true,"target":"any_target","target_constraints":{"scope":"any_target"},"xmage_effect_classes":["DamageTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"any_target"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class EssenceDrain translated into ManaLoom runtime scope xmage_fixed_damage_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed damage plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('essence extraction', 'Essence Extraction', 'd96959f3a27de4e120c64de80c6a9aaa', 'battle_rule_v1:fd24ff97747cfcb1638dbf9636156765', '{"amount":3,"battle_model_scope":"xmage_fixed_damage_target_and_controller_gain_life_spell_v1","controller_gain_life":3,"damage":3,"effect":"direct_damage","gain_life":3,"instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_classes":["DamageTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class EssenceExtraction translated into ManaLoom runtime scope xmage_fixed_damage_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed damage plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('last kiss', 'Last Kiss', '2b9469002ffd3fc0a880f6f8c3c0cf19', 'battle_rule_v1:788f7c2c874671de1271b7435856eb66', '{"amount":2,"battle_model_scope":"xmage_fixed_damage_target_and_controller_gain_life_spell_v1","controller_gain_life":2,"damage":2,"effect":"direct_damage","gain_life":2,"instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_classes":["DamageTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class LastKiss translated into ManaLoom runtime scope xmage_fixed_damage_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed damage plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('pharika''s cure', 'Pharika''s Cure', '4a9e7997580341e5bcf6dd7fd9c1e887', 'battle_rule_v1:788f7c2c874671de1271b7435856eb66', '{"amount":2,"battle_model_scope":"xmage_fixed_damage_target_and_controller_gain_life_spell_v1","controller_gain_life":2,"damage":2,"effect":"direct_damage","gain_life":2,"instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_classes":["DamageTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PharikasCure translated into ManaLoom runtime scope xmage_fixed_damage_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed damage plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('sorin''s thirst', 'Sorin''s Thirst', '1e54bf29b16bbc69cf01b968ef142778', 'battle_rule_v1:788f7c2c874671de1271b7435856eb66', '{"amount":2,"battle_model_scope":"xmage_fixed_damage_target_and_controller_gain_life_spell_v1","controller_gain_life":2,"damage":2,"effect":"direct_damage","gain_life":2,"instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_classes":["DamageTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SorinsThirst translated into ManaLoom runtime scope xmage_fixed_damage_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed damage plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('vampiric feast', 'Vampiric Feast', 'b395d91294a22cd813bfe27939364c56', 'battle_rule_v1:1d56c7af6c995b8069895ee5a393b1b5', '{"amount":4,"battle_model_scope":"xmage_fixed_damage_target_and_controller_gain_life_spell_v1","controller_gain_life":4,"damage":4,"effect":"direct_damage","gain_life":4,"instant":false,"sorcery":true,"target":"any_target","target_constraints":{"scope":"any_target"},"xmage_effect_classes":["DamageTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"any_target"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class VampiricFeast translated into ManaLoom runtime scope xmage_fixed_damage_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed damage plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('vicious hunger', 'Vicious Hunger', '0d8c6360af4725e1e185f7d7c48e0596', 'battle_rule_v1:afdcaac9d85814160b0c5bdc9cad24ed', '{"amount":2,"battle_model_scope":"xmage_fixed_damage_target_and_controller_gain_life_spell_v1","controller_gain_life":2,"damage":2,"effect":"direct_damage","gain_life":2,"instant":false,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_classes":["DamageTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ViciousHunger translated into ManaLoom runtime scope xmage_fixed_damage_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed damage plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('warleader''s helix', 'Warleader''s Helix', '70dd7a07d63e3c7d3705cf0efdb341d6', 'battle_rule_v1:b30ee9a5fcd603703d248235230ed80f', '{"amount":4,"battle_model_scope":"xmage_fixed_damage_target_and_controller_gain_life_spell_v1","controller_gain_life":4,"damage":4,"effect":"direct_damage","gain_life":4,"instant":true,"sorcery":false,"target":"any_target","target_constraints":{"scope":"any_target"},"xmage_effect_classes":["DamageTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"any_target","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WarleadersHelix translated into ManaLoom runtime scope xmage_fixed_damage_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed damage plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('winter''s intervention', 'Winter''s Intervention', '6a5018c20fad5c79a5f827f693574a27', 'battle_rule_v1:788f7c2c874671de1271b7435856eb66', '{"amount":2,"battle_model_scope":"xmage_fixed_damage_target_and_controller_gain_life_spell_v1","controller_gain_life":2,"damage":2,"effect":"direct_damage","gain_life":2,"instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_classes":["DamageTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WintersIntervention translated into ManaLoom runtime scope xmage_fixed_damage_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed damage plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
