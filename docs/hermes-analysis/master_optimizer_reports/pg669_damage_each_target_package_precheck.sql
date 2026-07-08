WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('dual shot', 'Dual Shot', '6daaff924d8b9f82f1cae620b46fd241', 'battle_rule_v1:842e945d5ea51e4543ecd8893d885a53', '{"ability_kind":"one_shot","amount":1,"battle_model_scope":"xmage_fixed_damage_each_target_spell_v1","damage":1,"damage_assignment_mode":"each_target","damage_per_target":1,"divided_damage":false,"effect":"multi_target_damage","instant":true,"max_targets":2,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_count":2,"target_count_max":2,"target_count_min":0,"up_to_count":true,"xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"multi_target_damage","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DualShot translated into ManaLoom runtime scope xmage_fixed_damage_each_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('furious reprisal', 'Furious Reprisal', '9bd9eb6b5582febd39fe4c14b869e597', 'battle_rule_v1:c1ab7d2e2dd263844aed44f2f2d4957a', '{"ability_kind":"one_shot","amount":2,"battle_model_scope":"xmage_fixed_damage_each_target_spell_v1","damage":2,"damage_assignment_mode":"each_target","damage_per_target":2,"divided_damage":false,"effect":"multi_target_damage","instant":false,"max_targets":2,"sorcery":true,"target":"any_target","target_constraints":{"scope":"any_target"},"target_count":2,"target_count_max":2,"target_count_min":2,"up_to_count":false,"xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"multi_target_damage","target":"any_target"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FuriousReprisal translated into ManaLoom runtime scope xmage_fixed_damage_each_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('jagged lightning', 'Jagged Lightning', '56235a14493124e5d85faebf8dcc245b', 'battle_rule_v1:2938db8afb659c7365df1829893a8cbf', '{"ability_kind":"one_shot","amount":3,"battle_model_scope":"xmage_fixed_damage_each_target_spell_v1","damage":3,"damage_assignment_mode":"each_target","damage_per_target":3,"divided_damage":false,"effect":"multi_target_damage","instant":false,"max_targets":2,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"]},"target_count":2,"target_count_max":2,"target_count_min":2,"up_to_count":false,"xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"multi_target_damage","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class JaggedLightning translated into ManaLoom runtime scope xmage_fixed_damage_each_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('pinnacle of rage', 'Pinnacle of Rage', '4ad4ecca3d73471d2abe17e9dabc39bc', 'battle_rule_v1:c8f0c970e5627709918c66013552a0a1', '{"ability_kind":"one_shot","amount":3,"battle_model_scope":"xmage_fixed_damage_each_target_spell_v1","damage":3,"damage_assignment_mode":"each_target","damage_per_target":3,"divided_damage":false,"effect":"multi_target_damage","instant":false,"max_targets":2,"sorcery":true,"target":"any_target","target_constraints":{"scope":"any_target"},"target_count":2,"target_count_max":2,"target_count_min":2,"up_to_count":false,"xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"multi_target_damage","target":"any_target"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PinnacleOfRage translated into ManaLoom runtime scope xmage_fixed_damage_each_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('storm of steel', 'Storm of Steel', '65b87bdad31235af7321ab50fae324f7', 'battle_rule_v1:7f0eaefa9d0a36848db1f9c2db74f696', '{"ability_kind":"one_shot","amount":2,"battle_model_scope":"xmage_fixed_damage_each_target_spell_v1","damage":2,"damage_assignment_mode":"each_target","damage_per_target":2,"divided_damage":false,"effect":"multi_target_damage","instant":false,"max_targets":2,"sorcery":true,"target":"any_target","target_constraints":{"scope":"any_target"},"target_count":2,"target_count_max":2,"target_count_min":1,"up_to_count":false,"xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"multi_target_damage","target":"any_target"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class StormOfSteel translated into ManaLoom runtime scope xmage_fixed_damage_each_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('swelter', 'Swelter', '2c133f34be23e41ed746a621695a9664', 'battle_rule_v1:e0d02c8b56b4c56167ea3e2e6ade5866', '{"ability_kind":"one_shot","amount":2,"battle_model_scope":"xmage_fixed_damage_each_target_spell_v1","damage":2,"damage_assignment_mode":"each_target","damage_per_target":2,"divided_damage":false,"effect":"multi_target_damage","instant":false,"max_targets":2,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"]},"target_count":2,"target_count_max":2,"target_count_min":2,"up_to_count":false,"xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"multi_target_damage","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Swelter translated into ManaLoom runtime scope xmage_fixed_damage_each_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
