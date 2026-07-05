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
