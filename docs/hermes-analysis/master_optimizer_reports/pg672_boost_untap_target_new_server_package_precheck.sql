WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('fancy footwork', 'Fancy Footwork', 'e14501ba1695a807b3a61d5f4cba064e', 'battle_rule_v1:b42f0a463ed2d14fc0ccf4e1feed3c62', '{"battle_model_scope":"xmage_fixed_boost_and_untap_target_creature_until_eot_spell_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot_untap_target","instant":true,"power_boost":2,"power_delta":2,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","target_count":2,"target_count_max":2,"target_count_min":1,"toughness_boost":2,"toughness_delta":2,"untap_target":true,"up_to_count":true,"xmage_effect_classes":["BoostTargetEffect","UntapTargetEffect"]}'::jsonb, '{"category":"support","effect":"stat_modifier_until_eot_untap_target","subtype":"temporary_pump_untap","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FancyFootwork translated into ManaLoom runtime scope xmage_fixed_boost_and_untap_target_creature_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('gerrard''s command', 'Gerrard''s Command', '00b7758c969432538371878cf150de85', 'battle_rule_v1:0eb3c3b3e9a1fb775bf171cb43acc9a5', '{"battle_model_scope":"xmage_fixed_boost_and_untap_target_creature_until_eot_spell_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot_untap_target","instant":true,"power_boost":3,"power_delta":3,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","target_count":1,"target_count_max":1,"target_count_min":1,"toughness_boost":3,"toughness_delta":3,"untap_target":true,"up_to_count":false,"xmage_effect_classes":["BoostTargetEffect","UntapTargetEffect"]}'::jsonb, '{"category":"support","effect":"stat_modifier_until_eot_untap_target","subtype":"temporary_pump_untap","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GerrardsCommand translated into ManaLoom runtime scope xmage_fixed_boost_and_untap_target_creature_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('hope and glory', 'Hope and Glory', 'af0c8534377b73832b1ad89b592b5036', 'battle_rule_v1:a0f4456dbc9260b4d4bfb6f1ce63aaf2', '{"battle_model_scope":"xmage_fixed_boost_and_untap_target_creature_until_eot_spell_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot_untap_target","instant":true,"power_boost":1,"power_delta":1,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","target_count":2,"target_count_max":2,"target_count_min":2,"toughness_boost":1,"toughness_delta":1,"untap_target":true,"up_to_count":false,"xmage_effect_classes":["BoostTargetEffect","UntapTargetEffect"]}'::jsonb, '{"category":"support","effect":"stat_modifier_until_eot_untap_target","subtype":"temporary_pump_untap","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HopeAndGlory translated into ManaLoom runtime scope xmage_fixed_boost_and_untap_target_creature_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('inspirit', 'Inspirit', '8a42138477ad3902c4e73e1b48c3c603', 'battle_rule_v1:70a898b0b2c4151e5bb4bb72293b66a6', '{"battle_model_scope":"xmage_fixed_boost_and_untap_target_creature_until_eot_spell_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot_untap_target","instant":true,"power_boost":2,"power_delta":2,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","target_count":1,"target_count_max":1,"target_count_min":1,"toughness_boost":4,"toughness_delta":4,"untap_target":true,"up_to_count":false,"xmage_effect_classes":["BoostTargetEffect","UntapTargetEffect"]}'::jsonb, '{"category":"support","effect":"stat_modifier_until_eot_untap_target","subtype":"temporary_pump_untap","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Inspirit translated into ManaLoom runtime scope xmage_fixed_boost_and_untap_target_creature_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('join forces', 'Join Forces', '1fb39c75290b9a700b9cdf043a294331', 'battle_rule_v1:50388aa062eeb449dcd7c3061cd970c5', '{"battle_model_scope":"xmage_fixed_boost_and_untap_target_creature_until_eot_spell_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot_untap_target","instant":true,"power_boost":2,"power_delta":2,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","target_count":2,"target_count_max":2,"target_count_min":0,"toughness_boost":2,"toughness_delta":2,"untap_target":true,"up_to_count":true,"xmage_effect_classes":["BoostTargetEffect","UntapTargetEffect"]}'::jsonb, '{"category":"support","effect":"stat_modifier_until_eot_untap_target","subtype":"temporary_pump_untap","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class JoinForces translated into ManaLoom runtime scope xmage_fixed_boost_and_untap_target_creature_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('ornamental courage', 'Ornamental Courage', '55bedca244ab72ad9f85919dd5c702e7', 'battle_rule_v1:10ebcba53593069463e75cc3d631a2bc', '{"battle_model_scope":"xmage_fixed_boost_and_untap_target_creature_until_eot_spell_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot_untap_target","instant":true,"power_boost":1,"power_delta":1,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","target_count":1,"target_count_max":1,"target_count_min":1,"toughness_boost":3,"toughness_delta":3,"untap_target":true,"up_to_count":false,"xmage_effect_classes":["BoostTargetEffect","UntapTargetEffect"]}'::jsonb, '{"category":"support","effect":"stat_modifier_until_eot_untap_target","subtype":"temporary_pump_untap","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class OrnamentalCourage translated into ManaLoom runtime scope xmage_fixed_boost_and_untap_target_creature_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('refuse to yield', 'Refuse to Yield', '7481fe0d1b8655924d7cf1191549c1c9', 'battle_rule_v1:0a52ccb614483ef0b02d1ec991179671', '{"battle_model_scope":"xmage_fixed_boost_and_untap_target_creature_until_eot_spell_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot_untap_target","instant":true,"power_boost":2,"power_delta":2,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","target_count":1,"target_count_max":1,"target_count_min":1,"toughness_boost":7,"toughness_delta":7,"untap_target":true,"up_to_count":false,"xmage_effect_classes":["BoostTargetEffect","UntapTargetEffect"]}'::jsonb, '{"category":"support","effect":"stat_modifier_until_eot_untap_target","subtype":"temporary_pump_untap","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RefuseToYield translated into ManaLoom runtime scope xmage_fixed_boost_and_untap_target_creature_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('savage surge', 'Savage Surge', 'c99b560c3cc3c5961c4d619c4353d186', 'battle_rule_v1:740852972ae2ca3f1792977d6a20ecaa', '{"battle_model_scope":"xmage_fixed_boost_and_untap_target_creature_until_eot_spell_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot_untap_target","instant":true,"power_boost":2,"power_delta":2,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","target_count":1,"target_count_max":1,"target_count_min":1,"toughness_boost":2,"toughness_delta":2,"untap_target":true,"up_to_count":false,"xmage_effect_classes":["BoostTargetEffect","UntapTargetEffect"]}'::jsonb, '{"category":"support","effect":"stat_modifier_until_eot_untap_target","subtype":"temporary_pump_untap","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SavageSurge translated into ManaLoom runtime scope xmage_fixed_boost_and_untap_target_creature_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('synchronized strike', 'Synchronized Strike', '1fb39c75290b9a700b9cdf043a294331', 'battle_rule_v1:50388aa062eeb449dcd7c3061cd970c5', '{"battle_model_scope":"xmage_fixed_boost_and_untap_target_creature_until_eot_spell_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot_untap_target","instant":true,"power_boost":2,"power_delta":2,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","target_count":2,"target_count_max":2,"target_count_min":0,"toughness_boost":2,"toughness_delta":2,"untap_target":true,"up_to_count":true,"xmage_effect_classes":["BoostTargetEffect","UntapTargetEffect"]}'::jsonb, '{"category":"support","effect":"stat_modifier_until_eot_untap_target","subtype":"temporary_pump_untap","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SynchronizedStrike translated into ManaLoom runtime scope xmage_fixed_boost_and_untap_target_creature_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('veteran''s reflexes', 'Veteran''s Reflexes', '91e613567a538b1d09ac3cba356584b2', 'battle_rule_v1:afef8c24d8b2bb464a6aaa4a89dd5272', '{"battle_model_scope":"xmage_fixed_boost_and_untap_target_creature_until_eot_spell_v1","duration":"until_end_of_turn","effect":"stat_modifier_until_eot_untap_target","instant":true,"power_boost":1,"power_delta":1,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","target_count":1,"target_count_max":1,"target_count_min":1,"toughness_boost":1,"toughness_delta":1,"untap_target":true,"up_to_count":false,"xmage_effect_classes":["BoostTargetEffect","UntapTargetEffect"]}'::jsonb, '{"category":"support","effect":"stat_modifier_until_eot_untap_target","subtype":"temporary_pump_untap","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class VeteransReflexes translated into ManaLoom runtime scope xmage_fixed_boost_and_untap_target_creature_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
