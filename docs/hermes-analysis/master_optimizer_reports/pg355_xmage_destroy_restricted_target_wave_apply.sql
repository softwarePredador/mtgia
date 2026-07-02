BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE manaloom_deploy_audit.pg355_xmage_destroy_restricted_target_wave_20260702_0541 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('bramblecrush', 'crush', 'dark banishing', 'dark betrayal', 'deathmark', 'exorcist', 'go for the throat', 'hero''s demise', 'joven', 'saltblast', 'terror // terror', 'ultimate price')
   OR normalized_name LIKE 'bramblecrush // %'
   OR normalized_name LIKE 'crush // %'
   OR normalized_name LIKE 'dark banishing // %'
   OR normalized_name LIKE 'dark betrayal // %'
   OR normalized_name LIKE 'deathmark // %'
   OR normalized_name LIKE 'exorcist // %'
   OR normalized_name LIKE 'go for the throat // %'
   OR normalized_name LIKE 'hero''s demise // %'
   OR normalized_name LIKE 'joven // %'
   OR normalized_name LIKE 'saltblast // %'
   OR normalized_name LIKE 'terror // terror // %'
   OR normalized_name LIKE 'ultimate price // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('bramblecrush', 'Bramblecrush', 'fe6491ef278d361374788a27b740fd37', 'battle_rule_v1:79265e727ee6e920df659c74947096a2', '{"battle_model_scope":"xmage_destroy_target_spell_v1","destination":"graveyard","effect":"remove_permanent","instant":false,"sorcery":true,"target":"permanent","target_constraints":{"card_types":["permanent"],"exclude_card_types":["creature"]},"xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Bramblecrush translated into ManaLoom runtime scope xmage_destroy_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('crush', 'Crush', '844a39ce47b11aacfc64d6b0eb41eeee', 'battle_rule_v1:d0fc8434b2ac621ca3607b4e216b17d2', '{"battle_model_scope":"xmage_destroy_target_spell_v1","destination":"graveyard","effect":"remove_permanent","instant":true,"sorcery":false,"target":"artifact","target_constraints":{"card_types":["artifact"],"exclude_card_types":["creature"]},"xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"artifact","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Crush translated into ManaLoom runtime scope xmage_destroy_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('dark banishing', 'Dark Banishing', '68c4c921de0e9d82a4943ef113e34c00', 'battle_rule_v1:168dcdc18248bd9b8dcd053f2113a0b4', '{"battle_model_scope":"xmage_destroy_target_spell_v1","destination":"graveyard","effect":"remove_creature","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"exclude_colors":["B"]},"xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DarkBanishing translated into ManaLoom runtime scope xmage_destroy_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('dark betrayal', 'Dark Betrayal', '2b60ac003bf4b46ac39b8160e1773e5e', 'battle_rule_v1:4b5bb6b237e872c84fbc0c18373bf2f1', '{"battle_model_scope":"xmage_destroy_target_spell_v1","destination":"graveyard","effect":"remove_creature","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"target_colors":["B"]},"xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DarkBetrayal translated into ManaLoom runtime scope xmage_destroy_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('deathmark', 'Deathmark', '0699c47559459652c6a913285d052778', 'battle_rule_v1:b3a7e7b19f0e9ae8b9c68ec3066b1164', '{"battle_model_scope":"xmage_destroy_target_spell_v1","destination":"graveyard","effect":"remove_creature","instant":false,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"],"target_colors":["G","W"]},"xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Deathmark translated into ManaLoom runtime scope xmage_destroy_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('exorcist', 'Exorcist', '76f53944b3d17a8a5820ee2a6f5edc32', 'battle_rule_v1:f0ac49ca156fa580353c5a46c7e259c1', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"destroy_target","activated_remove_effect":"remove_creature","activated_remove_target":"black_creature","activation_cost_colors":["W"],"activation_cost_generic":1,"activation_cost_mana":"{1}{W}","activation_requires_sacrifice":false,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_destroy_target_v1","destination":"graveyard","effect":"remove_creature","target":"creature","target_constraints":{"card_types":["creature"],"target_colors":["B"]},"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DestroyTargetEffect"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_destroy_target_v1","activated_effect":"destroy_target","activated_remove_effect":"remove_creature","activated_remove_target":"black_creature","activation_cost_colors":["W"],"activation_cost_generic":1,"activation_cost_mana":"{1}{W}","activation_requires_sacrifice":false,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_destroy_target_v1","destination":"graveyard","effect":"creature","target":"creature","target_constraints":{"card_types":["creature"],"target_colors":["B"]},"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Exorcist translated into ManaLoom runtime scope xmage_permanent_simple_activated_destroy_target_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated destroy-target ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('go for the throat', 'Go for the Throat', 'd660b2689650031cc8b27c26690921b8', 'battle_rule_v1:c708d1a0359745a6eb1e1a5136acbfe9', '{"battle_model_scope":"xmage_destroy_target_spell_v1","destination":"graveyard","effect":"remove_creature","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"exclude_card_types":["artifact"]},"xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GoForTheThroat translated into ManaLoom runtime scope xmage_destroy_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('hero''s demise', 'Hero''s Demise', '8aca12f0dcf5a4a057e14a4869524788', 'battle_rule_v1:759687ccde0f5cdbaee41e17619315e9', '{"battle_model_scope":"xmage_destroy_target_spell_v1","destination":"graveyard","effect":"remove_creature","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"required_supertypes":["legendary"]},"xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HerosDemise translated into ManaLoom runtime scope xmage_destroy_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('joven', 'Joven', '4956741e28adf6e2c08aaac6551ecc07', 'battle_rule_v1:16faca08fbda6c20c43df1e9c36712d4', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"destroy_target","activated_remove_effect":"remove_permanent","activated_remove_target":"noncreature_artifact","activation_cost_colors":["R","R","R"],"activation_cost_generic":0,"activation_cost_mana":"{R}{R}{R}","activation_requires_sacrifice":false,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_destroy_target_v1","destination":"graveyard","effect":"remove_permanent","target":"artifact","target_constraints":{"card_types":["artifact"],"exclude_card_types":["creature"]},"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DestroyTargetEffect"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_destroy_target_v1","activated_effect":"destroy_target","activated_remove_effect":"remove_permanent","activated_remove_target":"noncreature_artifact","activation_cost_colors":["R","R","R"],"activation_cost_generic":0,"activation_cost_mana":"{R}{R}{R}","activation_requires_sacrifice":false,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_destroy_target_v1","destination":"graveyard","effect":"creature","target":"artifact","target_constraints":{"card_types":["artifact"],"exclude_card_types":["creature"]},"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"artifact"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Joven translated into ManaLoom runtime scope xmage_permanent_simple_activated_destroy_target_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated destroy-target ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('saltblast', 'Saltblast', '4bb73ac6ef9d4e06b2a38618c3ebda38', 'battle_rule_v1:4db418f86ab5604a6f03745f99f8691f', '{"battle_model_scope":"xmage_destroy_target_spell_v1","destination":"graveyard","effect":"remove_permanent","instant":false,"sorcery":true,"target":"permanent","target_constraints":{"card_types":["permanent"],"exclude_colors":["W"]},"xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Saltblast translated into ManaLoom runtime scope xmage_destroy_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('terror // terror', 'Terror // Terror', '45ccc162eeb4ca85514e50f6ec971e62', 'battle_rule_v1:9811339b3ee6bf8bf1a584db8dfd5015', '{"battle_model_scope":"xmage_destroy_target_spell_v1","destination":"graveyard","effect":"remove_creature","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"exclude_card_types":["artifact"],"exclude_colors":["B"]},"xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Terror translated into ManaLoom runtime scope xmage_destroy_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('ultimate price', 'Ultimate Price', '17080584b8f3636e668c23397e2cd273', 'battle_rule_v1:49e3e90cd87848c2690e8700de3454aa', '{"battle_model_scope":"xmage_destroy_target_spell_v1","destination":"graveyard","effect":"remove_creature","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"color_count_exact":1},"xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class UltimatePrice translated into ManaLoom runtime scope xmage_destroy_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('bramblecrush', 'Bramblecrush', 'fe6491ef278d361374788a27b740fd37', 'battle_rule_v1:79265e727ee6e920df659c74947096a2', '{"battle_model_scope":"xmage_destroy_target_spell_v1","destination":"graveyard","effect":"remove_permanent","instant":false,"sorcery":true,"target":"permanent","target_constraints":{"card_types":["permanent"],"exclude_card_types":["creature"]},"xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Bramblecrush translated into ManaLoom runtime scope xmage_destroy_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('crush', 'Crush', '844a39ce47b11aacfc64d6b0eb41eeee', 'battle_rule_v1:d0fc8434b2ac621ca3607b4e216b17d2', '{"battle_model_scope":"xmage_destroy_target_spell_v1","destination":"graveyard","effect":"remove_permanent","instant":true,"sorcery":false,"target":"artifact","target_constraints":{"card_types":["artifact"],"exclude_card_types":["creature"]},"xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"artifact","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Crush translated into ManaLoom runtime scope xmage_destroy_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('dark banishing', 'Dark Banishing', '68c4c921de0e9d82a4943ef113e34c00', 'battle_rule_v1:168dcdc18248bd9b8dcd053f2113a0b4', '{"battle_model_scope":"xmage_destroy_target_spell_v1","destination":"graveyard","effect":"remove_creature","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"exclude_colors":["B"]},"xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DarkBanishing translated into ManaLoom runtime scope xmage_destroy_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('dark betrayal', 'Dark Betrayal', '2b60ac003bf4b46ac39b8160e1773e5e', 'battle_rule_v1:4b5bb6b237e872c84fbc0c18373bf2f1', '{"battle_model_scope":"xmage_destroy_target_spell_v1","destination":"graveyard","effect":"remove_creature","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"target_colors":["B"]},"xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DarkBetrayal translated into ManaLoom runtime scope xmage_destroy_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('deathmark', 'Deathmark', '0699c47559459652c6a913285d052778', 'battle_rule_v1:b3a7e7b19f0e9ae8b9c68ec3066b1164', '{"battle_model_scope":"xmage_destroy_target_spell_v1","destination":"graveyard","effect":"remove_creature","instant":false,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"],"target_colors":["G","W"]},"xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Deathmark translated into ManaLoom runtime scope xmage_destroy_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('exorcist', 'Exorcist', '76f53944b3d17a8a5820ee2a6f5edc32', 'battle_rule_v1:f0ac49ca156fa580353c5a46c7e259c1', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"destroy_target","activated_remove_effect":"remove_creature","activated_remove_target":"black_creature","activation_cost_colors":["W"],"activation_cost_generic":1,"activation_cost_mana":"{1}{W}","activation_requires_sacrifice":false,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_destroy_target_v1","destination":"graveyard","effect":"remove_creature","target":"creature","target_constraints":{"card_types":["creature"],"target_colors":["B"]},"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DestroyTargetEffect"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_destroy_target_v1","activated_effect":"destroy_target","activated_remove_effect":"remove_creature","activated_remove_target":"black_creature","activation_cost_colors":["W"],"activation_cost_generic":1,"activation_cost_mana":"{1}{W}","activation_requires_sacrifice":false,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_destroy_target_v1","destination":"graveyard","effect":"creature","target":"creature","target_constraints":{"card_types":["creature"],"target_colors":["B"]},"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Exorcist translated into ManaLoom runtime scope xmage_permanent_simple_activated_destroy_target_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated destroy-target ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('go for the throat', 'Go for the Throat', 'd660b2689650031cc8b27c26690921b8', 'battle_rule_v1:c708d1a0359745a6eb1e1a5136acbfe9', '{"battle_model_scope":"xmage_destroy_target_spell_v1","destination":"graveyard","effect":"remove_creature","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"exclude_card_types":["artifact"]},"xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GoForTheThroat translated into ManaLoom runtime scope xmage_destroy_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('hero''s demise', 'Hero''s Demise', '8aca12f0dcf5a4a057e14a4869524788', 'battle_rule_v1:759687ccde0f5cdbaee41e17619315e9', '{"battle_model_scope":"xmage_destroy_target_spell_v1","destination":"graveyard","effect":"remove_creature","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"required_supertypes":["legendary"]},"xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HerosDemise translated into ManaLoom runtime scope xmage_destroy_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('joven', 'Joven', '4956741e28adf6e2c08aaac6551ecc07', 'battle_rule_v1:16faca08fbda6c20c43df1e9c36712d4', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"destroy_target","activated_remove_effect":"remove_permanent","activated_remove_target":"noncreature_artifact","activation_cost_colors":["R","R","R"],"activation_cost_generic":0,"activation_cost_mana":"{R}{R}{R}","activation_requires_sacrifice":false,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_destroy_target_v1","destination":"graveyard","effect":"remove_permanent","target":"artifact","target_constraints":{"card_types":["artifact"],"exclude_card_types":["creature"]},"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DestroyTargetEffect"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_destroy_target_v1","activated_effect":"destroy_target","activated_remove_effect":"remove_permanent","activated_remove_target":"noncreature_artifact","activation_cost_colors":["R","R","R"],"activation_cost_generic":0,"activation_cost_mana":"{R}{R}{R}","activation_requires_sacrifice":false,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_destroy_target_v1","destination":"graveyard","effect":"creature","target":"artifact","target_constraints":{"card_types":["artifact"],"exclude_card_types":["creature"]},"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"artifact"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Joven translated into ManaLoom runtime scope xmage_permanent_simple_activated_destroy_target_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated destroy-target ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('saltblast', 'Saltblast', '4bb73ac6ef9d4e06b2a38618c3ebda38', 'battle_rule_v1:4db418f86ab5604a6f03745f99f8691f', '{"battle_model_scope":"xmage_destroy_target_spell_v1","destination":"graveyard","effect":"remove_permanent","instant":false,"sorcery":true,"target":"permanent","target_constraints":{"card_types":["permanent"],"exclude_colors":["W"]},"xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Saltblast translated into ManaLoom runtime scope xmage_destroy_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('terror // terror', 'Terror // Terror', '45ccc162eeb4ca85514e50f6ec971e62', 'battle_rule_v1:9811339b3ee6bf8bf1a584db8dfd5015', '{"battle_model_scope":"xmage_destroy_target_spell_v1","destination":"graveyard","effect":"remove_creature","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"exclude_card_types":["artifact"],"exclude_colors":["B"]},"xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Terror translated into ManaLoom runtime scope xmage_destroy_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('ultimate price', 'Ultimate Price', '17080584b8f3636e668c23397e2cd273', 'battle_rule_v1:49e3e90cd87848c2690e8700de3454aa', '{"battle_model_scope":"xmage_destroy_target_spell_v1","destination":"graveyard","effect":"remove_creature","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"color_count_exact":1},"xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class UltimatePrice translated into ManaLoom runtime scope xmage_destroy_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('bramblecrush', 'Bramblecrush', 'fe6491ef278d361374788a27b740fd37', 'battle_rule_v1:79265e727ee6e920df659c74947096a2', '{"battle_model_scope":"xmage_destroy_target_spell_v1","destination":"graveyard","effect":"remove_permanent","instant":false,"sorcery":true,"target":"permanent","target_constraints":{"card_types":["permanent"],"exclude_card_types":["creature"]},"xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Bramblecrush translated into ManaLoom runtime scope xmage_destroy_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('crush', 'Crush', '844a39ce47b11aacfc64d6b0eb41eeee', 'battle_rule_v1:d0fc8434b2ac621ca3607b4e216b17d2', '{"battle_model_scope":"xmage_destroy_target_spell_v1","destination":"graveyard","effect":"remove_permanent","instant":true,"sorcery":false,"target":"artifact","target_constraints":{"card_types":["artifact"],"exclude_card_types":["creature"]},"xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"artifact","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Crush translated into ManaLoom runtime scope xmage_destroy_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('dark banishing', 'Dark Banishing', '68c4c921de0e9d82a4943ef113e34c00', 'battle_rule_v1:168dcdc18248bd9b8dcd053f2113a0b4', '{"battle_model_scope":"xmage_destroy_target_spell_v1","destination":"graveyard","effect":"remove_creature","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"exclude_colors":["B"]},"xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DarkBanishing translated into ManaLoom runtime scope xmage_destroy_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('dark betrayal', 'Dark Betrayal', '2b60ac003bf4b46ac39b8160e1773e5e', 'battle_rule_v1:4b5bb6b237e872c84fbc0c18373bf2f1', '{"battle_model_scope":"xmage_destroy_target_spell_v1","destination":"graveyard","effect":"remove_creature","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"target_colors":["B"]},"xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DarkBetrayal translated into ManaLoom runtime scope xmage_destroy_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('deathmark', 'Deathmark', '0699c47559459652c6a913285d052778', 'battle_rule_v1:b3a7e7b19f0e9ae8b9c68ec3066b1164', '{"battle_model_scope":"xmage_destroy_target_spell_v1","destination":"graveyard","effect":"remove_creature","instant":false,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"],"target_colors":["G","W"]},"xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Deathmark translated into ManaLoom runtime scope xmage_destroy_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('exorcist', 'Exorcist', '76f53944b3d17a8a5820ee2a6f5edc32', 'battle_rule_v1:f0ac49ca156fa580353c5a46c7e259c1', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"destroy_target","activated_remove_effect":"remove_creature","activated_remove_target":"black_creature","activation_cost_colors":["W"],"activation_cost_generic":1,"activation_cost_mana":"{1}{W}","activation_requires_sacrifice":false,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_destroy_target_v1","destination":"graveyard","effect":"remove_creature","target":"creature","target_constraints":{"card_types":["creature"],"target_colors":["B"]},"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DestroyTargetEffect"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_destroy_target_v1","activated_effect":"destroy_target","activated_remove_effect":"remove_creature","activated_remove_target":"black_creature","activation_cost_colors":["W"],"activation_cost_generic":1,"activation_cost_mana":"{1}{W}","activation_requires_sacrifice":false,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_destroy_target_v1","destination":"graveyard","effect":"creature","target":"creature","target_constraints":{"card_types":["creature"],"target_colors":["B"]},"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Exorcist translated into ManaLoom runtime scope xmage_permanent_simple_activated_destroy_target_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated destroy-target ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('go for the throat', 'Go for the Throat', 'd660b2689650031cc8b27c26690921b8', 'battle_rule_v1:c708d1a0359745a6eb1e1a5136acbfe9', '{"battle_model_scope":"xmage_destroy_target_spell_v1","destination":"graveyard","effect":"remove_creature","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"exclude_card_types":["artifact"]},"xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GoForTheThroat translated into ManaLoom runtime scope xmage_destroy_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('hero''s demise', 'Hero''s Demise', '8aca12f0dcf5a4a057e14a4869524788', 'battle_rule_v1:759687ccde0f5cdbaee41e17619315e9', '{"battle_model_scope":"xmage_destroy_target_spell_v1","destination":"graveyard","effect":"remove_creature","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"required_supertypes":["legendary"]},"xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HerosDemise translated into ManaLoom runtime scope xmage_destroy_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('joven', 'Joven', '4956741e28adf6e2c08aaac6551ecc07', 'battle_rule_v1:16faca08fbda6c20c43df1e9c36712d4', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"destroy_target","activated_remove_effect":"remove_permanent","activated_remove_target":"noncreature_artifact","activation_cost_colors":["R","R","R"],"activation_cost_generic":0,"activation_cost_mana":"{R}{R}{R}","activation_requires_sacrifice":false,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_destroy_target_v1","destination":"graveyard","effect":"remove_permanent","target":"artifact","target_constraints":{"card_types":["artifact"],"exclude_card_types":["creature"]},"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DestroyTargetEffect"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_destroy_target_v1","activated_effect":"destroy_target","activated_remove_effect":"remove_permanent","activated_remove_target":"noncreature_artifact","activation_cost_colors":["R","R","R"],"activation_cost_generic":0,"activation_cost_mana":"{R}{R}{R}","activation_requires_sacrifice":false,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_destroy_target_v1","destination":"graveyard","effect":"creature","target":"artifact","target_constraints":{"card_types":["artifact"],"exclude_card_types":["creature"]},"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"artifact"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Joven translated into ManaLoom runtime scope xmage_permanent_simple_activated_destroy_target_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated destroy-target ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('saltblast', 'Saltblast', '4bb73ac6ef9d4e06b2a38618c3ebda38', 'battle_rule_v1:4db418f86ab5604a6f03745f99f8691f', '{"battle_model_scope":"xmage_destroy_target_spell_v1","destination":"graveyard","effect":"remove_permanent","instant":false,"sorcery":true,"target":"permanent","target_constraints":{"card_types":["permanent"],"exclude_colors":["W"]},"xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Saltblast translated into ManaLoom runtime scope xmage_destroy_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('terror // terror', 'Terror // Terror', '45ccc162eeb4ca85514e50f6ec971e62', 'battle_rule_v1:9811339b3ee6bf8bf1a584db8dfd5015', '{"battle_model_scope":"xmage_destroy_target_spell_v1","destination":"graveyard","effect":"remove_creature","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"exclude_card_types":["artifact"],"exclude_colors":["B"]},"xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Terror translated into ManaLoom runtime scope xmage_destroy_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('ultimate price', 'Ultimate Price', '17080584b8f3636e668c23397e2cd273', 'battle_rule_v1:49e3e90cd87848c2690e8700de3454aa', '{"battle_model_scope":"xmage_destroy_target_spell_v1","destination":"graveyard","effect":"remove_creature","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"color_count_exact":1},"xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class UltimatePrice translated into ManaLoom runtime scope xmage_destroy_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
