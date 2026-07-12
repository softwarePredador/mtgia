BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg851_activated_target_player_mill_20260712_233444 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('ambassador laquatus', 'cathartic adept', 'drowner of secrets', 'hair-strung koto', 'merfolk mesmerist', 'millstone', 'tower of murmurs', 'vedalken entrancer')
   OR normalized_name LIKE 'ambassador laquatus // %'
   OR normalized_name LIKE 'cathartic adept // %'
   OR normalized_name LIKE 'drowner of secrets // %'
   OR normalized_name LIKE 'hair-strung koto // %'
   OR normalized_name LIKE 'merfolk mesmerist // %'
   OR normalized_name LIKE 'millstone // %'
   OR normalized_name LIKE 'tower of murmurs // %'
   OR normalized_name LIKE 'vedalken entrancer // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
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
    ('ambassador laquatus', 'Ambassador Laquatus', 'ad54b5b88947c8a76fb89d808369a5fb', 'battle_rule_v1:e96f7f8d6ee5af0f8cdf5e904bd62b32', '{"ability_kind":"activated","activated_effect":"target_player_mill","activated_target_player_mill_count":3,"activation_cost_colors":[],"activation_cost_generic":3,"activation_cost_mana":"{3}","activation_requires_tap":false,"battle_model_scope":"xmage_permanent_simple_activated_target_player_mill_v1","count":3,"effect":"passive","instant":false,"mill_count":3,"permanent_type":"creature","sorcery":false,"target":"player","target_constraints":{"players":["any"]},"target_controller":"target_player","target_player_mill":true,"target_player_mill_activation_requires_tap":false,"target_player_scope":"any","target_preference":"opponent","xmage_effect_class":"MillCardsTargetEffect"}'::jsonb, '{"category":"unknown","effect":"passive","target":"player"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AmbassadorLaquatus translated into ManaLoom runtime scope xmage_permanent_simple_activated_target_player_mill_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated target-player mill ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('cathartic adept', 'Cathartic Adept', '39d6fd8448c94ab8241181f2e233298d', 'battle_rule_v1:e608086be5ab09c0a603a3c18c02aaf0', '{"ability_kind":"activated","activated_effect":"target_player_mill","activated_target_player_mill_count":1,"activation_cost_colors":[],"activation_cost_generic":0,"activation_cost_mana":"{0}","activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_target_player_mill_v1","count":1,"effect":"passive","instant":false,"mill_count":1,"permanent_type":"creature","sorcery":false,"target":"player","target_constraints":{"players":["any"]},"target_controller":"target_player","target_player_mill":true,"target_player_mill_activation_requires_tap":true,"target_player_scope":"any","target_preference":"opponent","xmage_effect_class":"MillCardsTargetEffect"}'::jsonb, '{"category":"unknown","effect":"passive","target":"player"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CatharticAdept translated into ManaLoom runtime scope xmage_permanent_simple_activated_target_player_mill_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated target-player mill ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('drowner of secrets', 'Drowner of Secrets', 'd4569dabe8965dfb1e0b8c0a095f5178', 'battle_rule_v1:2dfe7943384a38c238a9f19d7654368b', '{"ability_kind":"activated","activated_effect":"target_player_mill","activated_target_player_mill_count":1,"activation_cost_colors":[],"activation_cost_generic":0,"activation_cost_mana":"{0}","activation_requires_tap":false,"activation_requires_tap_target":true,"activation_tap_cost":{"constraints":{"card_types":["creature"],"required_subtypes":["merfolk"],"tapped_state":"untapped"},"count":1,"target_controller":"self"},"battle_model_scope":"xmage_permanent_simple_activated_target_player_mill_v1","count":1,"effect":"passive","instant":false,"mill_count":1,"permanent_type":"creature","sorcery":false,"target":"player","target_constraints":{"players":["any"]},"target_controller":"target_player","target_player_mill":true,"target_player_mill_activation_requires_tap":false,"target_player_scope":"any","target_preference":"opponent","xmage_effect_class":"MillCardsTargetEffect"}'::jsonb, '{"category":"unknown","effect":"passive","target":"player"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DrownerOfSecrets translated into ManaLoom runtime scope xmage_permanent_simple_activated_target_player_mill_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated target-player mill ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('hair-strung koto', 'Hair-Strung Koto', '776b9dc49728f77f039b32b235db1d97', 'battle_rule_v1:ae75b0e944f3ee083648c47e01a041ae', '{"ability_kind":"activated","activated_effect":"target_player_mill","activated_target_player_mill_count":1,"activation_cost_colors":[],"activation_cost_generic":0,"activation_cost_mana":"{0}","activation_requires_tap":false,"activation_requires_tap_target":true,"activation_tap_cost":{"constraints":{"card_types":["creature"],"tapped_state":"untapped"},"count":1,"target_controller":"self"},"battle_model_scope":"xmage_permanent_simple_activated_target_player_mill_v1","count":1,"effect":"passive","instant":false,"mill_count":1,"permanent_type":"artifact","sorcery":false,"target":"player","target_constraints":{"players":["any"]},"target_controller":"target_player","target_player_mill":true,"target_player_mill_activation_requires_tap":false,"target_player_scope":"any","target_preference":"opponent","xmage_effect_class":"MillCardsTargetEffect"}'::jsonb, '{"category":"unknown","effect":"passive","target":"player"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HairStrungKoto translated into ManaLoom runtime scope xmage_permanent_simple_activated_target_player_mill_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated target-player mill ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('merfolk mesmerist', 'Merfolk Mesmerist', 'e8e21863e1bb9b497c7f16d9206a34ab', 'battle_rule_v1:678908d11c3b9efffb663e1323a342f5', '{"ability_kind":"activated","activated_effect":"target_player_mill","activated_target_player_mill_count":2,"activation_cost_colors":["U"],"activation_cost_generic":0,"activation_cost_mana":"{U}","activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_target_player_mill_v1","count":2,"effect":"passive","instant":false,"mill_count":2,"permanent_type":"creature","sorcery":false,"target":"player","target_constraints":{"players":["any"]},"target_controller":"target_player","target_player_mill":true,"target_player_mill_activation_requires_tap":true,"target_player_scope":"any","target_preference":"opponent","xmage_effect_class":"MillCardsTargetEffect"}'::jsonb, '{"category":"unknown","effect":"passive","target":"player"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MerfolkMesmerist translated into ManaLoom runtime scope xmage_permanent_simple_activated_target_player_mill_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated target-player mill ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('millstone', 'Millstone', '665c181aa39a6360eee485487a7a7c3f', 'battle_rule_v1:cadaf38b811377f55277faf8cda7cbdb', '{"ability_kind":"activated","activated_effect":"target_player_mill","activated_target_player_mill_count":2,"activation_cost_colors":[],"activation_cost_generic":2,"activation_cost_mana":"{2}","activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_target_player_mill_v1","count":2,"effect":"passive","instant":false,"mill_count":2,"permanent_type":"artifact","sorcery":false,"target":"player","target_constraints":{"players":["any"]},"target_controller":"target_player","target_player_mill":true,"target_player_mill_activation_requires_tap":true,"target_player_scope":"any","target_preference":"opponent","xmage_effect_class":"MillCardsTargetEffect"}'::jsonb, '{"category":"unknown","effect":"passive","target":"player"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Millstone translated into ManaLoom runtime scope xmage_permanent_simple_activated_target_player_mill_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated target-player mill ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('tower of murmurs', 'Tower of Murmurs', '275f84036dff173b7901983ae22a42c1', 'battle_rule_v1:660909401f05c36198940ddc34ccd278', '{"ability_kind":"activated","activated_effect":"target_player_mill","activated_target_player_mill_count":8,"activation_cost_colors":[],"activation_cost_generic":8,"activation_cost_mana":"{8}","activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_target_player_mill_v1","count":8,"effect":"passive","instant":false,"mill_count":8,"permanent_type":"artifact","sorcery":false,"target":"player","target_constraints":{"players":["any"]},"target_controller":"target_player","target_player_mill":true,"target_player_mill_activation_requires_tap":true,"target_player_scope":"any","target_preference":"opponent","xmage_effect_class":"MillCardsTargetEffect"}'::jsonb, '{"category":"unknown","effect":"passive","target":"player"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TowerOfMurmurs translated into ManaLoom runtime scope xmage_permanent_simple_activated_target_player_mill_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated target-player mill ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('vedalken entrancer', 'Vedalken Entrancer', 'e8e21863e1bb9b497c7f16d9206a34ab', 'battle_rule_v1:678908d11c3b9efffb663e1323a342f5', '{"ability_kind":"activated","activated_effect":"target_player_mill","activated_target_player_mill_count":2,"activation_cost_colors":["U"],"activation_cost_generic":0,"activation_cost_mana":"{U}","activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_target_player_mill_v1","count":2,"effect":"passive","instant":false,"mill_count":2,"permanent_type":"creature","sorcery":false,"target":"player","target_constraints":{"players":["any"]},"target_controller":"target_player","target_player_mill":true,"target_player_mill_activation_requires_tap":true,"target_player_scope":"any","target_preference":"opponent","xmage_effect_class":"MillCardsTargetEffect"}'::jsonb, '{"category":"unknown","effect":"passive","target":"player"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class VedalkenEntrancer translated into ManaLoom runtime scope xmage_permanent_simple_activated_target_player_mill_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated target-player mill ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
