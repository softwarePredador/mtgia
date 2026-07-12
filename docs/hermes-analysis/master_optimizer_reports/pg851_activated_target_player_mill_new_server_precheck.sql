WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('ambassador laquatus', 'Ambassador Laquatus', 'ad54b5b88947c8a76fb89d808369a5fb', 'battle_rule_v1:e96f7f8d6ee5af0f8cdf5e904bd62b32', '{"ability_kind":"activated","activated_effect":"target_player_mill","activated_target_player_mill_count":3,"activation_cost_colors":[],"activation_cost_generic":3,"activation_cost_mana":"{3}","activation_requires_tap":false,"battle_model_scope":"xmage_permanent_simple_activated_target_player_mill_v1","count":3,"effect":"passive","instant":false,"mill_count":3,"permanent_type":"creature","sorcery":false,"target":"player","target_constraints":{"players":["any"]},"target_controller":"target_player","target_player_mill":true,"target_player_mill_activation_requires_tap":false,"target_player_scope":"any","target_preference":"opponent","xmage_effect_class":"MillCardsTargetEffect"}'::jsonb, '{"category":"unknown","effect":"passive","target":"player"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AmbassadorLaquatus translated into ManaLoom runtime scope xmage_permanent_simple_activated_target_player_mill_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated target-player mill ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('cathartic adept', 'Cathartic Adept', '39d6fd8448c94ab8241181f2e233298d', 'battle_rule_v1:e608086be5ab09c0a603a3c18c02aaf0', '{"ability_kind":"activated","activated_effect":"target_player_mill","activated_target_player_mill_count":1,"activation_cost_colors":[],"activation_cost_generic":0,"activation_cost_mana":"{0}","activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_target_player_mill_v1","count":1,"effect":"passive","instant":false,"mill_count":1,"permanent_type":"creature","sorcery":false,"target":"player","target_constraints":{"players":["any"]},"target_controller":"target_player","target_player_mill":true,"target_player_mill_activation_requires_tap":true,"target_player_scope":"any","target_preference":"opponent","xmage_effect_class":"MillCardsTargetEffect"}'::jsonb, '{"category":"unknown","effect":"passive","target":"player"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CatharticAdept translated into ManaLoom runtime scope xmage_permanent_simple_activated_target_player_mill_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated target-player mill ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('drowner of secrets', 'Drowner of Secrets', 'd4569dabe8965dfb1e0b8c0a095f5178', 'battle_rule_v1:2dfe7943384a38c238a9f19d7654368b', '{"ability_kind":"activated","activated_effect":"target_player_mill","activated_target_player_mill_count":1,"activation_cost_colors":[],"activation_cost_generic":0,"activation_cost_mana":"{0}","activation_requires_tap":false,"activation_requires_tap_target":true,"activation_tap_cost":{"constraints":{"card_types":["creature"],"required_subtypes":["merfolk"],"tapped_state":"untapped"},"count":1,"target_controller":"self"},"battle_model_scope":"xmage_permanent_simple_activated_target_player_mill_v1","count":1,"effect":"passive","instant":false,"mill_count":1,"permanent_type":"creature","sorcery":false,"target":"player","target_constraints":{"players":["any"]},"target_controller":"target_player","target_player_mill":true,"target_player_mill_activation_requires_tap":false,"target_player_scope":"any","target_preference":"opponent","xmage_effect_class":"MillCardsTargetEffect"}'::jsonb, '{"category":"unknown","effect":"passive","target":"player"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DrownerOfSecrets translated into ManaLoom runtime scope xmage_permanent_simple_activated_target_player_mill_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated target-player mill ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('hair-strung koto', 'Hair-Strung Koto', '776b9dc49728f77f039b32b235db1d97', 'battle_rule_v1:ae75b0e944f3ee083648c47e01a041ae', '{"ability_kind":"activated","activated_effect":"target_player_mill","activated_target_player_mill_count":1,"activation_cost_colors":[],"activation_cost_generic":0,"activation_cost_mana":"{0}","activation_requires_tap":false,"activation_requires_tap_target":true,"activation_tap_cost":{"constraints":{"card_types":["creature"],"tapped_state":"untapped"},"count":1,"target_controller":"self"},"battle_model_scope":"xmage_permanent_simple_activated_target_player_mill_v1","count":1,"effect":"passive","instant":false,"mill_count":1,"permanent_type":"artifact","sorcery":false,"target":"player","target_constraints":{"players":["any"]},"target_controller":"target_player","target_player_mill":true,"target_player_mill_activation_requires_tap":false,"target_player_scope":"any","target_preference":"opponent","xmage_effect_class":"MillCardsTargetEffect"}'::jsonb, '{"category":"unknown","effect":"passive","target":"player"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HairStrungKoto translated into ManaLoom runtime scope xmage_permanent_simple_activated_target_player_mill_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated target-player mill ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('merfolk mesmerist', 'Merfolk Mesmerist', 'e8e21863e1bb9b497c7f16d9206a34ab', 'battle_rule_v1:678908d11c3b9efffb663e1323a342f5', '{"ability_kind":"activated","activated_effect":"target_player_mill","activated_target_player_mill_count":2,"activation_cost_colors":["U"],"activation_cost_generic":0,"activation_cost_mana":"{U}","activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_target_player_mill_v1","count":2,"effect":"passive","instant":false,"mill_count":2,"permanent_type":"creature","sorcery":false,"target":"player","target_constraints":{"players":["any"]},"target_controller":"target_player","target_player_mill":true,"target_player_mill_activation_requires_tap":true,"target_player_scope":"any","target_preference":"opponent","xmage_effect_class":"MillCardsTargetEffect"}'::jsonb, '{"category":"unknown","effect":"passive","target":"player"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MerfolkMesmerist translated into ManaLoom runtime scope xmage_permanent_simple_activated_target_player_mill_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated target-player mill ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('millstone', 'Millstone', '665c181aa39a6360eee485487a7a7c3f', 'battle_rule_v1:cadaf38b811377f55277faf8cda7cbdb', '{"ability_kind":"activated","activated_effect":"target_player_mill","activated_target_player_mill_count":2,"activation_cost_colors":[],"activation_cost_generic":2,"activation_cost_mana":"{2}","activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_target_player_mill_v1","count":2,"effect":"passive","instant":false,"mill_count":2,"permanent_type":"artifact","sorcery":false,"target":"player","target_constraints":{"players":["any"]},"target_controller":"target_player","target_player_mill":true,"target_player_mill_activation_requires_tap":true,"target_player_scope":"any","target_preference":"opponent","xmage_effect_class":"MillCardsTargetEffect"}'::jsonb, '{"category":"unknown","effect":"passive","target":"player"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Millstone translated into ManaLoom runtime scope xmage_permanent_simple_activated_target_player_mill_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated target-player mill ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('tower of murmurs', 'Tower of Murmurs', '275f84036dff173b7901983ae22a42c1', 'battle_rule_v1:660909401f05c36198940ddc34ccd278', '{"ability_kind":"activated","activated_effect":"target_player_mill","activated_target_player_mill_count":8,"activation_cost_colors":[],"activation_cost_generic":8,"activation_cost_mana":"{8}","activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_target_player_mill_v1","count":8,"effect":"passive","instant":false,"mill_count":8,"permanent_type":"artifact","sorcery":false,"target":"player","target_constraints":{"players":["any"]},"target_controller":"target_player","target_player_mill":true,"target_player_mill_activation_requires_tap":true,"target_player_scope":"any","target_preference":"opponent","xmage_effect_class":"MillCardsTargetEffect"}'::jsonb, '{"category":"unknown","effect":"passive","target":"player"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TowerOfMurmurs translated into ManaLoom runtime scope xmage_permanent_simple_activated_target_player_mill_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated target-player mill ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('vedalken entrancer', 'Vedalken Entrancer', 'e8e21863e1bb9b497c7f16d9206a34ab', 'battle_rule_v1:678908d11c3b9efffb663e1323a342f5', '{"ability_kind":"activated","activated_effect":"target_player_mill","activated_target_player_mill_count":2,"activation_cost_colors":["U"],"activation_cost_generic":0,"activation_cost_mana":"{U}","activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_target_player_mill_v1","count":2,"effect":"passive","instant":false,"mill_count":2,"permanent_type":"creature","sorcery":false,"target":"player","target_constraints":{"players":["any"]},"target_controller":"target_player","target_player_mill":true,"target_player_mill_activation_requires_tap":true,"target_player_scope":"any","target_preference":"opponent","xmage_effect_class":"MillCardsTargetEffect"}'::jsonb, '{"category":"unknown","effect":"passive","target":"player"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class VedalkenEntrancer translated into ManaLoom runtime scope xmage_permanent_simple_activated_target_player_mill_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated target-player mill ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
