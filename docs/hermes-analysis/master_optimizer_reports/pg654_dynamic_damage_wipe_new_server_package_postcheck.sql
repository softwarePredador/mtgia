WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('calamitous cave-in', 'Calamitous Cave-In', '4069479e2214edce819d6a9edc3da97f', 'battle_rule_v1:ff384c2972d27eae1173bbbb12bcd2e0', '{"amount":0,"battle_model_scope":"xmage_fixed_damage_all_matching_permanents_spell_v1","damage":0,"damage_amount_source":"caves_controlled_plus_cave_cards_in_graveyard","damage_base_amount":0,"damage_per_count":1,"damage_scope":"each_creature_and_planeswalker","effect":"damage_wipe","instant":false,"sorcery":true,"xmage_effect_class":"DamageAllEffect"}'::jsonb, '{"category":"wipe","effect":"damage_wipe"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CalamitousCaveIn translated into ManaLoom runtime scope xmage_fixed_damage_all_matching_permanents_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('chain reaction', 'Chain Reaction', '7133da1b111adf3a50a495277840c796', 'battle_rule_v1:b721248b835b2a566a36928f7de5f211', '{"amount":0,"battle_model_scope":"xmage_fixed_damage_all_matching_permanents_spell_v1","battlefield_count_card_types":["creature"],"battlefield_count_scope":"all_battlefields","damage":0,"damage_amount_source":"battlefield_permanent_count","damage_base_amount":0,"damage_per_count":1,"damage_scope":"each_creature","effect":"damage_wipe","instant":false,"sorcery":true,"xmage_effect_class":"DamageAllEffect"}'::jsonb, '{"category":"wipe","effect":"damage_wipe"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ChainReaction translated into ManaLoom runtime scope xmage_fixed_damage_all_matching_permanents_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('gates ablaze', 'Gates Ablaze', '93d9ca2d64d6702472f1beba1505cc00', 'battle_rule_v1:bce9b09587369ceddee79a4d87b2639d', '{"amount":0,"battle_model_scope":"xmage_fixed_damage_all_matching_permanents_spell_v1","battlefield_count_scope":"controller_battlefield","battlefield_count_subtypes":["gate"],"damage":0,"damage_amount_source":"battlefield_permanent_count","damage_base_amount":0,"damage_per_count":1,"damage_scope":"each_creature","effect":"damage_wipe","instant":false,"sorcery":true,"xmage_effect_class":"DamageAllEffect"}'::jsonb, '{"category":"wipe","effect":"damage_wipe"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GatesAblaze translated into ManaLoom runtime scope xmage_fixed_damage_all_matching_permanents_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('immolating gyre', 'Immolating Gyre', '92e197d6b4ce1c5741779d0b5f327e0e', 'battle_rule_v1:3a36e4c65fe5fbd1658a5dc91815619d', '{"amount":0,"battle_model_scope":"xmage_fixed_damage_all_matching_permanents_spell_v1","damage":0,"damage_amount_source":"graveyard_card_count","damage_base_amount":0,"damage_per_count":1,"damage_scope":"each_creature_and_planeswalker_opponents_control","effect":"damage_wipe","graveyard_count_card_types":["instant","sorcery"],"graveyard_count_scope":"controller_graveyard","instant":false,"sorcery":true,"xmage_effect_class":"DamageAllEffect"}'::jsonb, '{"category":"wipe","effect":"damage_wipe"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ImmolatingGyre translated into ManaLoom runtime scope xmage_fixed_damage_all_matching_permanents_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('skyreaping', 'Skyreaping', '0c832362e9df1c38970d782accc8a1c3', 'battle_rule_v1:e00622e2a40dda1f82a2eb04c0b22f91', '{"amount":0,"battle_model_scope":"xmage_fixed_damage_all_matching_permanents_spell_v1","damage":0,"damage_amount_source":"devotion_to_green","damage_base_amount":0,"damage_per_count":1,"damage_scope":"each_flying_creature","effect":"damage_wipe","instant":false,"sorcery":true,"xmage_effect_class":"DamageAllEffect"}'::jsonb, '{"category":"wipe","effect":"damage_wipe"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Skyreaping translated into ManaLoom runtime scope xmage_fixed_damage_all_matching_permanents_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
),
rule_rows AS (
  SELECT
    r.normalized_name,
    r.logical_rule_key,
    r.oracle_hash,
    r.review_status,
    r.execution_status
  FROM proposed p
  LEFT JOIN public.card_battle_rules r
    ON (
         r.normalized_name = p.normalized_name
         OR r.normalized_name LIKE p.normalized_name || ' // %'
       )
   AND r.logical_rule_key = p.logical_rule_key
)
SELECT
  p.card_name,
  p.normalized_name,
  p.logical_rule_key,
  count(r.*) FILTER (WHERE r.logical_rule_key = p.logical_rule_key) AS promoted_rule_rows,
  count(r.*) FILTER (WHERE r.review_status = 'verified' AND r.execution_status = 'auto') AS promoted_verified_auto_rows,
  count(r.*) FILTER (WHERE r.oracle_hash = p.oracle_hash) AS promoted_oracle_hash_rows,
  (SELECT count(*) FROM manaloom_deploy_audit.pg654_dynamic_damage_wipe_new_server_20260708_115133) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
