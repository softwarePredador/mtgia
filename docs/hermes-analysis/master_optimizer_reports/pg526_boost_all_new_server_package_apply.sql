BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg526_boost_all_new_server_20260705_194024 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('cower in fear', 'hell swarm', 'hysterical blindness', 'infest', 'languish', 'magnify', 'marsh gas', 'nausea', 'rollick of abandon', 'shrivel')
   OR normalized_name LIKE 'cower in fear // %'
   OR normalized_name LIKE 'hell swarm // %'
   OR normalized_name LIKE 'hysterical blindness // %'
   OR normalized_name LIKE 'infest // %'
   OR normalized_name LIKE 'languish // %'
   OR normalized_name LIKE 'magnify // %'
   OR normalized_name LIKE 'marsh gas // %'
   OR normalized_name LIKE 'nausea // %'
   OR normalized_name LIKE 'rollick of abandon // %'
   OR normalized_name LIKE 'shrivel // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('cower in fear', 'Cower in Fear', 'd0311c1b77837fc4fc3002c1cc658da2', 'battle_rule_v1:337d66b30a687e5e150f482158801abc', '{"battle_model_scope":"xmage_fixed_boost_all_or_opponents_creatures_until_eot_spell_v1","effect":"global_stat_modifier_until_eot","instant":true,"power_delta":-1,"sorcery":false,"target":"opponents_creatures","target_constraints":{"card_types":["creature"],"controller":"opponents"},"target_controller":"opponents","toughness_delta":-1,"xmage_effect_class":"BoostAllEffect"}'::jsonb, '{"category":"unknown","effect":"global_stat_modifier_until_eot","target":"opponents_creatures","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CowerInFear translated into ManaLoom runtime scope xmage_fixed_boost_all_or_opponents_creatures_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow fixed all/opponents-creature boost until end of turn spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('hell swarm', 'Hell Swarm', '51f6af0039eec27db65207f4fe67a4cb', 'battle_rule_v1:baaab7ad1a72b3e32f10ae9aad54dd2e', '{"battle_model_scope":"xmage_fixed_boost_all_or_opponents_creatures_until_eot_spell_v1","effect":"global_stat_modifier_until_eot","instant":true,"power_delta":-1,"sorcery":false,"target":"all_creatures","target_constraints":{"card_types":["creature"]},"target_controller":"all","toughness_delta":0,"xmage_effect_class":"BoostAllEffect"}'::jsonb, '{"category":"unknown","effect":"global_stat_modifier_until_eot","target":"all_creatures","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HellSwarm translated into ManaLoom runtime scope xmage_fixed_boost_all_or_opponents_creatures_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow fixed all/opponents-creature boost until end of turn spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('hysterical blindness', 'Hysterical Blindness', '05dd7a0df25f6404bbe1d94a6fd3e65e', 'battle_rule_v1:a2f2072bd8f5a0309e414d33c73998aa', '{"battle_model_scope":"xmage_fixed_boost_all_or_opponents_creatures_until_eot_spell_v1","effect":"global_stat_modifier_until_eot","instant":true,"power_delta":-4,"sorcery":false,"target":"opponents_creatures","target_constraints":{"card_types":["creature"],"controller":"opponents"},"target_controller":"opponents","toughness_delta":0,"xmage_effect_class":"BoostAllEffect"}'::jsonb, '{"category":"unknown","effect":"global_stat_modifier_until_eot","target":"opponents_creatures","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HystericalBlindness translated into ManaLoom runtime scope xmage_fixed_boost_all_or_opponents_creatures_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow fixed all/opponents-creature boost until end of turn spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('infest', 'Infest', 'de675042b01e8a73e81030a56668db6d', 'battle_rule_v1:61acff86c382b352911a02e78ce6247f', '{"battle_model_scope":"xmage_fixed_boost_all_or_opponents_creatures_until_eot_spell_v1","effect":"global_stat_modifier_until_eot","instant":false,"power_delta":-2,"sorcery":true,"target":"all_creatures","target_constraints":{"card_types":["creature"]},"target_controller":"all","toughness_delta":-2,"xmage_effect_class":"BoostAllEffect"}'::jsonb, '{"category":"unknown","effect":"global_stat_modifier_until_eot","target":"all_creatures"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Infest translated into ManaLoom runtime scope xmage_fixed_boost_all_or_opponents_creatures_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow fixed all/opponents-creature boost until end of turn spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('languish', 'Languish', 'bac50aeeb74271c0cde0535bae01c6fe', 'battle_rule_v1:947c46100669395b8987c123809e4a28', '{"battle_model_scope":"xmage_fixed_boost_all_or_opponents_creatures_until_eot_spell_v1","effect":"global_stat_modifier_until_eot","instant":false,"power_delta":-4,"sorcery":true,"target":"all_creatures","target_constraints":{"card_types":["creature"]},"target_controller":"all","toughness_delta":-4,"xmage_effect_class":"BoostAllEffect"}'::jsonb, '{"category":"unknown","effect":"global_stat_modifier_until_eot","target":"all_creatures"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Languish translated into ManaLoom runtime scope xmage_fixed_boost_all_or_opponents_creatures_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow fixed all/opponents-creature boost until end of turn spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('magnify', 'Magnify', '7e278e44bc95d6ffc235a568753d226e', 'battle_rule_v1:11b4966577ba19d9e1d3f515557fa5b0', '{"battle_model_scope":"xmage_fixed_boost_all_or_opponents_creatures_until_eot_spell_v1","effect":"global_stat_modifier_until_eot","instant":true,"power_delta":1,"sorcery":false,"target":"all_creatures","target_constraints":{"card_types":["creature"]},"target_controller":"all","toughness_delta":1,"xmage_effect_class":"BoostAllEffect"}'::jsonb, '{"category":"unknown","effect":"global_stat_modifier_until_eot","target":"all_creatures","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Magnify translated into ManaLoom runtime scope xmage_fixed_boost_all_or_opponents_creatures_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow fixed all/opponents-creature boost until end of turn spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('marsh gas', 'Marsh Gas', '8a0d48ff220104dcca1ff68cfce9104e', 'battle_rule_v1:e55fb97c2ca407fb32118fa2439c7df8', '{"battle_model_scope":"xmage_fixed_boost_all_or_opponents_creatures_until_eot_spell_v1","effect":"global_stat_modifier_until_eot","instant":true,"power_delta":-2,"sorcery":false,"target":"all_creatures","target_constraints":{"card_types":["creature"]},"target_controller":"all","toughness_delta":0,"xmage_effect_class":"BoostAllEffect"}'::jsonb, '{"category":"unknown","effect":"global_stat_modifier_until_eot","target":"all_creatures","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MarshGas translated into ManaLoom runtime scope xmage_fixed_boost_all_or_opponents_creatures_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow fixed all/opponents-creature boost until end of turn spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('nausea', 'Nausea', 'd616f39ce55b12fe55a9c3c060f72cff', 'battle_rule_v1:8779b0605241adfc7eeff5e5749628ca', '{"battle_model_scope":"xmage_fixed_boost_all_or_opponents_creatures_until_eot_spell_v1","effect":"global_stat_modifier_until_eot","instant":false,"power_delta":-1,"sorcery":true,"target":"all_creatures","target_constraints":{"card_types":["creature"]},"target_controller":"all","toughness_delta":-1,"xmage_effect_class":"BoostAllEffect"}'::jsonb, '{"category":"unknown","effect":"global_stat_modifier_until_eot","target":"all_creatures"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Nausea translated into ManaLoom runtime scope xmage_fixed_boost_all_or_opponents_creatures_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow fixed all/opponents-creature boost until end of turn spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('rollick of abandon', 'Rollick of Abandon', '7e1e6ba5e37207b13d95ce0c9a8b437b', 'battle_rule_v1:d2e31f17c284efb49cab9e5a41f642a2', '{"battle_model_scope":"xmage_fixed_boost_all_or_opponents_creatures_until_eot_spell_v1","effect":"global_stat_modifier_until_eot","instant":false,"power_delta":2,"sorcery":true,"target":"all_creatures","target_constraints":{"card_types":["creature"]},"target_controller":"all","toughness_delta":-2,"xmage_effect_class":"BoostAllEffect"}'::jsonb, '{"category":"unknown","effect":"global_stat_modifier_until_eot","target":"all_creatures"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RollickOfAbandon translated into ManaLoom runtime scope xmage_fixed_boost_all_or_opponents_creatures_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow fixed all/opponents-creature boost until end of turn spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('shrivel', 'Shrivel', 'd616f39ce55b12fe55a9c3c060f72cff', 'battle_rule_v1:8779b0605241adfc7eeff5e5749628ca', '{"battle_model_scope":"xmage_fixed_boost_all_or_opponents_creatures_until_eot_spell_v1","effect":"global_stat_modifier_until_eot","instant":false,"power_delta":-1,"sorcery":true,"target":"all_creatures","target_constraints":{"card_types":["creature"]},"target_controller":"all","toughness_delta":-1,"xmage_effect_class":"BoostAllEffect"}'::jsonb, '{"category":"unknown","effect":"global_stat_modifier_until_eot","target":"all_creatures"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Shrivel translated into ManaLoom runtime scope xmage_fixed_boost_all_or_opponents_creatures_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow fixed all/opponents-creature boost until end of turn spell with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('cower in fear', 'Cower in Fear', 'd0311c1b77837fc4fc3002c1cc658da2', 'battle_rule_v1:337d66b30a687e5e150f482158801abc', '{"battle_model_scope":"xmage_fixed_boost_all_or_opponents_creatures_until_eot_spell_v1","effect":"global_stat_modifier_until_eot","instant":true,"power_delta":-1,"sorcery":false,"target":"opponents_creatures","target_constraints":{"card_types":["creature"],"controller":"opponents"},"target_controller":"opponents","toughness_delta":-1,"xmage_effect_class":"BoostAllEffect"}'::jsonb, '{"category":"unknown","effect":"global_stat_modifier_until_eot","target":"opponents_creatures","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CowerInFear translated into ManaLoom runtime scope xmage_fixed_boost_all_or_opponents_creatures_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow fixed all/opponents-creature boost until end of turn spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('hell swarm', 'Hell Swarm', '51f6af0039eec27db65207f4fe67a4cb', 'battle_rule_v1:baaab7ad1a72b3e32f10ae9aad54dd2e', '{"battle_model_scope":"xmage_fixed_boost_all_or_opponents_creatures_until_eot_spell_v1","effect":"global_stat_modifier_until_eot","instant":true,"power_delta":-1,"sorcery":false,"target":"all_creatures","target_constraints":{"card_types":["creature"]},"target_controller":"all","toughness_delta":0,"xmage_effect_class":"BoostAllEffect"}'::jsonb, '{"category":"unknown","effect":"global_stat_modifier_until_eot","target":"all_creatures","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HellSwarm translated into ManaLoom runtime scope xmage_fixed_boost_all_or_opponents_creatures_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow fixed all/opponents-creature boost until end of turn spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('hysterical blindness', 'Hysterical Blindness', '05dd7a0df25f6404bbe1d94a6fd3e65e', 'battle_rule_v1:a2f2072bd8f5a0309e414d33c73998aa', '{"battle_model_scope":"xmage_fixed_boost_all_or_opponents_creatures_until_eot_spell_v1","effect":"global_stat_modifier_until_eot","instant":true,"power_delta":-4,"sorcery":false,"target":"opponents_creatures","target_constraints":{"card_types":["creature"],"controller":"opponents"},"target_controller":"opponents","toughness_delta":0,"xmage_effect_class":"BoostAllEffect"}'::jsonb, '{"category":"unknown","effect":"global_stat_modifier_until_eot","target":"opponents_creatures","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HystericalBlindness translated into ManaLoom runtime scope xmage_fixed_boost_all_or_opponents_creatures_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow fixed all/opponents-creature boost until end of turn spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('infest', 'Infest', 'de675042b01e8a73e81030a56668db6d', 'battle_rule_v1:61acff86c382b352911a02e78ce6247f', '{"battle_model_scope":"xmage_fixed_boost_all_or_opponents_creatures_until_eot_spell_v1","effect":"global_stat_modifier_until_eot","instant":false,"power_delta":-2,"sorcery":true,"target":"all_creatures","target_constraints":{"card_types":["creature"]},"target_controller":"all","toughness_delta":-2,"xmage_effect_class":"BoostAllEffect"}'::jsonb, '{"category":"unknown","effect":"global_stat_modifier_until_eot","target":"all_creatures"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Infest translated into ManaLoom runtime scope xmage_fixed_boost_all_or_opponents_creatures_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow fixed all/opponents-creature boost until end of turn spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('languish', 'Languish', 'bac50aeeb74271c0cde0535bae01c6fe', 'battle_rule_v1:947c46100669395b8987c123809e4a28', '{"battle_model_scope":"xmage_fixed_boost_all_or_opponents_creatures_until_eot_spell_v1","effect":"global_stat_modifier_until_eot","instant":false,"power_delta":-4,"sorcery":true,"target":"all_creatures","target_constraints":{"card_types":["creature"]},"target_controller":"all","toughness_delta":-4,"xmage_effect_class":"BoostAllEffect"}'::jsonb, '{"category":"unknown","effect":"global_stat_modifier_until_eot","target":"all_creatures"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Languish translated into ManaLoom runtime scope xmage_fixed_boost_all_or_opponents_creatures_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow fixed all/opponents-creature boost until end of turn spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('magnify', 'Magnify', '7e278e44bc95d6ffc235a568753d226e', 'battle_rule_v1:11b4966577ba19d9e1d3f515557fa5b0', '{"battle_model_scope":"xmage_fixed_boost_all_or_opponents_creatures_until_eot_spell_v1","effect":"global_stat_modifier_until_eot","instant":true,"power_delta":1,"sorcery":false,"target":"all_creatures","target_constraints":{"card_types":["creature"]},"target_controller":"all","toughness_delta":1,"xmage_effect_class":"BoostAllEffect"}'::jsonb, '{"category":"unknown","effect":"global_stat_modifier_until_eot","target":"all_creatures","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Magnify translated into ManaLoom runtime scope xmage_fixed_boost_all_or_opponents_creatures_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow fixed all/opponents-creature boost until end of turn spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('marsh gas', 'Marsh Gas', '8a0d48ff220104dcca1ff68cfce9104e', 'battle_rule_v1:e55fb97c2ca407fb32118fa2439c7df8', '{"battle_model_scope":"xmage_fixed_boost_all_or_opponents_creatures_until_eot_spell_v1","effect":"global_stat_modifier_until_eot","instant":true,"power_delta":-2,"sorcery":false,"target":"all_creatures","target_constraints":{"card_types":["creature"]},"target_controller":"all","toughness_delta":0,"xmage_effect_class":"BoostAllEffect"}'::jsonb, '{"category":"unknown","effect":"global_stat_modifier_until_eot","target":"all_creatures","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MarshGas translated into ManaLoom runtime scope xmage_fixed_boost_all_or_opponents_creatures_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow fixed all/opponents-creature boost until end of turn spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('nausea', 'Nausea', 'd616f39ce55b12fe55a9c3c060f72cff', 'battle_rule_v1:8779b0605241adfc7eeff5e5749628ca', '{"battle_model_scope":"xmage_fixed_boost_all_or_opponents_creatures_until_eot_spell_v1","effect":"global_stat_modifier_until_eot","instant":false,"power_delta":-1,"sorcery":true,"target":"all_creatures","target_constraints":{"card_types":["creature"]},"target_controller":"all","toughness_delta":-1,"xmage_effect_class":"BoostAllEffect"}'::jsonb, '{"category":"unknown","effect":"global_stat_modifier_until_eot","target":"all_creatures"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Nausea translated into ManaLoom runtime scope xmage_fixed_boost_all_or_opponents_creatures_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow fixed all/opponents-creature boost until end of turn spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('rollick of abandon', 'Rollick of Abandon', '7e1e6ba5e37207b13d95ce0c9a8b437b', 'battle_rule_v1:d2e31f17c284efb49cab9e5a41f642a2', '{"battle_model_scope":"xmage_fixed_boost_all_or_opponents_creatures_until_eot_spell_v1","effect":"global_stat_modifier_until_eot","instant":false,"power_delta":2,"sorcery":true,"target":"all_creatures","target_constraints":{"card_types":["creature"]},"target_controller":"all","toughness_delta":-2,"xmage_effect_class":"BoostAllEffect"}'::jsonb, '{"category":"unknown","effect":"global_stat_modifier_until_eot","target":"all_creatures"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RollickOfAbandon translated into ManaLoom runtime scope xmage_fixed_boost_all_or_opponents_creatures_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow fixed all/opponents-creature boost until end of turn spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('shrivel', 'Shrivel', 'd616f39ce55b12fe55a9c3c060f72cff', 'battle_rule_v1:8779b0605241adfc7eeff5e5749628ca', '{"battle_model_scope":"xmage_fixed_boost_all_or_opponents_creatures_until_eot_spell_v1","effect":"global_stat_modifier_until_eot","instant":false,"power_delta":-1,"sorcery":true,"target":"all_creatures","target_constraints":{"card_types":["creature"]},"target_controller":"all","toughness_delta":-1,"xmage_effect_class":"BoostAllEffect"}'::jsonb, '{"category":"unknown","effect":"global_stat_modifier_until_eot","target":"all_creatures"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Shrivel translated into ManaLoom runtime scope xmage_fixed_boost_all_or_opponents_creatures_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow fixed all/opponents-creature boost until end of turn spell with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('cower in fear', 'Cower in Fear', 'd0311c1b77837fc4fc3002c1cc658da2', 'battle_rule_v1:337d66b30a687e5e150f482158801abc', '{"battle_model_scope":"xmage_fixed_boost_all_or_opponents_creatures_until_eot_spell_v1","effect":"global_stat_modifier_until_eot","instant":true,"power_delta":-1,"sorcery":false,"target":"opponents_creatures","target_constraints":{"card_types":["creature"],"controller":"opponents"},"target_controller":"opponents","toughness_delta":-1,"xmage_effect_class":"BoostAllEffect"}'::jsonb, '{"category":"unknown","effect":"global_stat_modifier_until_eot","target":"opponents_creatures","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CowerInFear translated into ManaLoom runtime scope xmage_fixed_boost_all_or_opponents_creatures_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow fixed all/opponents-creature boost until end of turn spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('hell swarm', 'Hell Swarm', '51f6af0039eec27db65207f4fe67a4cb', 'battle_rule_v1:baaab7ad1a72b3e32f10ae9aad54dd2e', '{"battle_model_scope":"xmage_fixed_boost_all_or_opponents_creatures_until_eot_spell_v1","effect":"global_stat_modifier_until_eot","instant":true,"power_delta":-1,"sorcery":false,"target":"all_creatures","target_constraints":{"card_types":["creature"]},"target_controller":"all","toughness_delta":0,"xmage_effect_class":"BoostAllEffect"}'::jsonb, '{"category":"unknown","effect":"global_stat_modifier_until_eot","target":"all_creatures","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HellSwarm translated into ManaLoom runtime scope xmage_fixed_boost_all_or_opponents_creatures_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow fixed all/opponents-creature boost until end of turn spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('hysterical blindness', 'Hysterical Blindness', '05dd7a0df25f6404bbe1d94a6fd3e65e', 'battle_rule_v1:a2f2072bd8f5a0309e414d33c73998aa', '{"battle_model_scope":"xmage_fixed_boost_all_or_opponents_creatures_until_eot_spell_v1","effect":"global_stat_modifier_until_eot","instant":true,"power_delta":-4,"sorcery":false,"target":"opponents_creatures","target_constraints":{"card_types":["creature"],"controller":"opponents"},"target_controller":"opponents","toughness_delta":0,"xmage_effect_class":"BoostAllEffect"}'::jsonb, '{"category":"unknown","effect":"global_stat_modifier_until_eot","target":"opponents_creatures","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HystericalBlindness translated into ManaLoom runtime scope xmage_fixed_boost_all_or_opponents_creatures_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow fixed all/opponents-creature boost until end of turn spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('infest', 'Infest', 'de675042b01e8a73e81030a56668db6d', 'battle_rule_v1:61acff86c382b352911a02e78ce6247f', '{"battle_model_scope":"xmage_fixed_boost_all_or_opponents_creatures_until_eot_spell_v1","effect":"global_stat_modifier_until_eot","instant":false,"power_delta":-2,"sorcery":true,"target":"all_creatures","target_constraints":{"card_types":["creature"]},"target_controller":"all","toughness_delta":-2,"xmage_effect_class":"BoostAllEffect"}'::jsonb, '{"category":"unknown","effect":"global_stat_modifier_until_eot","target":"all_creatures"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Infest translated into ManaLoom runtime scope xmage_fixed_boost_all_or_opponents_creatures_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow fixed all/opponents-creature boost until end of turn spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('languish', 'Languish', 'bac50aeeb74271c0cde0535bae01c6fe', 'battle_rule_v1:947c46100669395b8987c123809e4a28', '{"battle_model_scope":"xmage_fixed_boost_all_or_opponents_creatures_until_eot_spell_v1","effect":"global_stat_modifier_until_eot","instant":false,"power_delta":-4,"sorcery":true,"target":"all_creatures","target_constraints":{"card_types":["creature"]},"target_controller":"all","toughness_delta":-4,"xmage_effect_class":"BoostAllEffect"}'::jsonb, '{"category":"unknown","effect":"global_stat_modifier_until_eot","target":"all_creatures"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Languish translated into ManaLoom runtime scope xmage_fixed_boost_all_or_opponents_creatures_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow fixed all/opponents-creature boost until end of turn spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('magnify', 'Magnify', '7e278e44bc95d6ffc235a568753d226e', 'battle_rule_v1:11b4966577ba19d9e1d3f515557fa5b0', '{"battle_model_scope":"xmage_fixed_boost_all_or_opponents_creatures_until_eot_spell_v1","effect":"global_stat_modifier_until_eot","instant":true,"power_delta":1,"sorcery":false,"target":"all_creatures","target_constraints":{"card_types":["creature"]},"target_controller":"all","toughness_delta":1,"xmage_effect_class":"BoostAllEffect"}'::jsonb, '{"category":"unknown","effect":"global_stat_modifier_until_eot","target":"all_creatures","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Magnify translated into ManaLoom runtime scope xmage_fixed_boost_all_or_opponents_creatures_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow fixed all/opponents-creature boost until end of turn spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('marsh gas', 'Marsh Gas', '8a0d48ff220104dcca1ff68cfce9104e', 'battle_rule_v1:e55fb97c2ca407fb32118fa2439c7df8', '{"battle_model_scope":"xmage_fixed_boost_all_or_opponents_creatures_until_eot_spell_v1","effect":"global_stat_modifier_until_eot","instant":true,"power_delta":-2,"sorcery":false,"target":"all_creatures","target_constraints":{"card_types":["creature"]},"target_controller":"all","toughness_delta":0,"xmage_effect_class":"BoostAllEffect"}'::jsonb, '{"category":"unknown","effect":"global_stat_modifier_until_eot","target":"all_creatures","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MarshGas translated into ManaLoom runtime scope xmage_fixed_boost_all_or_opponents_creatures_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow fixed all/opponents-creature boost until end of turn spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('nausea', 'Nausea', 'd616f39ce55b12fe55a9c3c060f72cff', 'battle_rule_v1:8779b0605241adfc7eeff5e5749628ca', '{"battle_model_scope":"xmage_fixed_boost_all_or_opponents_creatures_until_eot_spell_v1","effect":"global_stat_modifier_until_eot","instant":false,"power_delta":-1,"sorcery":true,"target":"all_creatures","target_constraints":{"card_types":["creature"]},"target_controller":"all","toughness_delta":-1,"xmage_effect_class":"BoostAllEffect"}'::jsonb, '{"category":"unknown","effect":"global_stat_modifier_until_eot","target":"all_creatures"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Nausea translated into ManaLoom runtime scope xmage_fixed_boost_all_or_opponents_creatures_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow fixed all/opponents-creature boost until end of turn spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('rollick of abandon', 'Rollick of Abandon', '7e1e6ba5e37207b13d95ce0c9a8b437b', 'battle_rule_v1:d2e31f17c284efb49cab9e5a41f642a2', '{"battle_model_scope":"xmage_fixed_boost_all_or_opponents_creatures_until_eot_spell_v1","effect":"global_stat_modifier_until_eot","instant":false,"power_delta":2,"sorcery":true,"target":"all_creatures","target_constraints":{"card_types":["creature"]},"target_controller":"all","toughness_delta":-2,"xmage_effect_class":"BoostAllEffect"}'::jsonb, '{"category":"unknown","effect":"global_stat_modifier_until_eot","target":"all_creatures"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RollickOfAbandon translated into ManaLoom runtime scope xmage_fixed_boost_all_or_opponents_creatures_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow fixed all/opponents-creature boost until end of turn spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('shrivel', 'Shrivel', 'd616f39ce55b12fe55a9c3c060f72cff', 'battle_rule_v1:8779b0605241adfc7eeff5e5749628ca', '{"battle_model_scope":"xmage_fixed_boost_all_or_opponents_creatures_until_eot_spell_v1","effect":"global_stat_modifier_until_eot","instant":false,"power_delta":-1,"sorcery":true,"target":"all_creatures","target_constraints":{"card_types":["creature"]},"target_controller":"all","toughness_delta":-1,"xmage_effect_class":"BoostAllEffect"}'::jsonb, '{"category":"unknown","effect":"global_stat_modifier_until_eot","target":"all_creatures"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Shrivel translated into ManaLoom runtime scope xmage_fixed_boost_all_or_opponents_creatures_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow fixed all/opponents-creature boost until end of turn spell with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
