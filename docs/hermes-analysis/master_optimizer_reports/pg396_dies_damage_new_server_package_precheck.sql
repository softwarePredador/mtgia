WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('bogardan firefiend', 'Bogardan Firefiend', 'd210b4897146ab01359623ef415616a5', 'battle_rule_v1:9c97a0bb3f8d95c6861678f7a210a696', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_fixed_damage_target_v1","dies_damage_amount":2,"dies_damage_target":"creature","effect":"creature","target":"creature","target_constraints":{"card_types":["creature"]},"trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BogardanFirefiend translated into ManaLoom runtime scope xmage_creature_dies_fixed_damage_target_v1. This row is package-ready only because the source signature is a narrow creature dies triggered fixed damage ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('careless celebrant', 'Careless Celebrant', '14b9501f0c035da8dbd3dfb8945a7b2f', 'battle_rule_v1:47dd9df12e72454256312ff74c57a219', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_fixed_damage_target_v1","dies_damage_amount":2,"dies_damage_target":"creature_or_planeswalker","effect":"creature","target":"creature_or_planeswalker","target_constraints":{"card_types":["creature","planeswalker"]},"trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature_or_planeswalker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CarelessCelebrant translated into ManaLoom runtime scope xmage_creature_dies_fixed_damage_target_v1. This row is package-ready only because the source signature is a narrow creature dies triggered fixed damage ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('footlight fiend', 'Footlight Fiend', '849b98bfe418aa4fdad033045c561296', 'battle_rule_v1:e674fea2b801e52066c06b5504a1a242', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_fixed_damage_target_v1","dies_damage_amount":1,"dies_damage_target":"any_target","effect":"creature","target":"any_target","target_constraints":{"scope":"any_target"},"trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"any_target"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FootlightFiend translated into ManaLoom runtime scope xmage_creature_dies_fixed_damage_target_v1. This row is package-ready only because the source signature is a narrow creature dies triggered fixed damage ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('goblin arsonist', 'Goblin Arsonist', '68b46e8a49e3947f0a6b65b7aa924c04', 'battle_rule_v1:0f26849f10bf9e0357f6a7a23f392f75', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_fixed_damage_target_v1","dies_damage_amount":1,"dies_damage_optional":true,"dies_damage_target":"any_target","effect":"creature","target":"any_target","target_constraints":{"scope":"any_target"},"trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"any_target"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GoblinArsonist translated into ManaLoom runtime scope xmage_creature_dies_fixed_damage_target_v1. This row is package-ready only because the source signature is a narrow creature dies triggered fixed damage ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('mudbutton torchrunner', 'Mudbutton Torchrunner', '7fa459ff91be335e859f88b5b0c305ac', 'battle_rule_v1:5b89a7a55f519dfc8a4f39120ddda3a9', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_fixed_damage_target_v1","dies_damage_amount":3,"dies_damage_target":"any_target","effect":"creature","target":"any_target","target_constraints":{"scope":"any_target"},"trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"any_target"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MudbuttonTorchrunner translated into ManaLoom runtime scope xmage_creature_dies_fixed_damage_target_v1. This row is package-ready only because the source signature is a narrow creature dies triggered fixed damage ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('perilous myr', 'Perilous Myr', '54bcabf69140caa8b8f4b29ef191b4c0', 'battle_rule_v1:0cad1f375dbce251b5d86ecd298660a1', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_fixed_damage_target_v1","dies_damage_amount":2,"dies_damage_target":"any_target","effect":"creature","target":"any_target","target_constraints":{"scope":"any_target"},"trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"any_target"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PerilousMyr translated into ManaLoom runtime scope xmage_creature_dies_fixed_damage_target_v1. This row is package-ready only because the source signature is a narrow creature dies triggered fixed damage ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('pitchburn devils', 'Pitchburn Devils', '7fa459ff91be335e859f88b5b0c305ac', 'battle_rule_v1:5b89a7a55f519dfc8a4f39120ddda3a9', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_fixed_damage_target_v1","dies_damage_amount":3,"dies_damage_target":"any_target","effect":"creature","target":"any_target","target_constraints":{"scope":"any_target"},"trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"any_target"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PitchburnDevils translated into ManaLoom runtime scope xmage_creature_dies_fixed_damage_target_v1. This row is package-ready only because the source signature is a narrow creature dies triggered fixed damage ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('pyre spawn', 'Pyre Spawn', '7fa459ff91be335e859f88b5b0c305ac', 'battle_rule_v1:5b89a7a55f519dfc8a4f39120ddda3a9', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_fixed_damage_target_v1","dies_damage_amount":3,"dies_damage_target":"any_target","effect":"creature","target":"any_target","target_constraints":{"scope":"any_target"},"trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"any_target"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PyreSpawn translated into ManaLoom runtime scope xmage_creature_dies_fixed_damage_target_v1. This row is package-ready only because the source signature is a narrow creature dies triggered fixed damage ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
