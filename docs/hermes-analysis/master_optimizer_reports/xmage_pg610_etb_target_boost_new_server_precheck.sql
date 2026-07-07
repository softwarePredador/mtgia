WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('blister beetle', 'Blister Beetle', 'ee848485353b6bbf8f21c7045b8f5e2d', 'battle_rule_v1:df7da59e6120c06e7a7cf424d0806dab', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_fixed_boost_target_until_eot_v1","duration":"until_end_of_turn","effect":"creature","etb_target_stat_modifier":true,"power_boost":-1,"power_delta":-1,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":-1,"toughness_delta":-1,"trigger":"enters_battlefield","trigger_effect":"stat_modifier_until_eot","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"BoostTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BlisterBeetle translated into ManaLoom runtime scope xmage_creature_etb_fixed_boost_target_until_eot_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('daybreak charger', 'Daybreak Charger', '351d6e15733b5c222f490fffe42dbdb6', 'battle_rule_v1:d676ca7df8e0a239c44ff49b71a31ead', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_fixed_boost_target_until_eot_v1","duration":"until_end_of_turn","effect":"creature","etb_target_stat_modifier":true,"power_boost":2,"power_delta":2,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":0,"toughness_delta":0,"trigger":"enters_battlefield","trigger_effect":"stat_modifier_until_eot","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"BoostTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DaybreakCharger translated into ManaLoom runtime scope xmage_creature_etb_fixed_boost_target_until_eot_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('farbog boneflinger', 'Farbog Boneflinger', '0cd8a1d30db1c953ec4a0999f5685834', 'battle_rule_v1:a9c6733045b3ee8db1367ecbab9832c8', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_fixed_boost_target_until_eot_v1","duration":"until_end_of_turn","effect":"creature","etb_target_stat_modifier":true,"power_boost":-2,"power_delta":-2,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":-2,"toughness_delta":-2,"trigger":"enters_battlefield","trigger_effect":"stat_modifier_until_eot","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"BoostTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FarbogBoneflinger translated into ManaLoom runtime scope xmage_creature_etb_fixed_boost_target_until_eot_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('guardian of pilgrims', 'Guardian of Pilgrims', '42c5389430b63b6e1a46e3a5437ea12d', 'battle_rule_v1:7c3fad25d40df83682dac894512cec82', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_fixed_boost_target_until_eot_v1","duration":"until_end_of_turn","effect":"creature","etb_target_stat_modifier":true,"power_boost":1,"power_delta":1,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":1,"toughness_delta":1,"trigger":"enters_battlefield","trigger_effect":"stat_modifier_until_eot","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"BoostTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GuardianOfPilgrims translated into ManaLoom runtime scope xmage_creature_etb_fixed_boost_target_until_eot_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('jadecraft artisan', 'Jadecraft Artisan', '3200139f56f87c26184f67fe4a5b3a54', 'battle_rule_v1:545d0764d4993cc2ec59375083699f4e', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_fixed_boost_target_until_eot_v1","duration":"until_end_of_turn","effect":"creature","etb_target_stat_modifier":true,"power_boost":2,"power_delta":2,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":2,"toughness_delta":2,"trigger":"enters_battlefield","trigger_effect":"stat_modifier_until_eot","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"BoostTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class JadecraftArtisan translated into ManaLoom runtime scope xmage_creature_etb_fixed_boost_target_until_eot_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('kinsbaile skirmisher', 'Kinsbaile Skirmisher', '42c5389430b63b6e1a46e3a5437ea12d', 'battle_rule_v1:7c3fad25d40df83682dac894512cec82', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_fixed_boost_target_until_eot_v1","duration":"until_end_of_turn","effect":"creature","etb_target_stat_modifier":true,"power_boost":1,"power_delta":1,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":1,"toughness_delta":1,"trigger":"enters_battlefield","trigger_effect":"stat_modifier_until_eot","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"BoostTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class KinsbaileSkirmisher translated into ManaLoom runtime scope xmage_creature_etb_fixed_boost_target_until_eot_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('rubblebelt boar', 'Rubblebelt Boar', '351d6e15733b5c222f490fffe42dbdb6', 'battle_rule_v1:d676ca7df8e0a239c44ff49b71a31ead', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_fixed_boost_target_until_eot_v1","duration":"until_end_of_turn","effect":"creature","etb_target_stat_modifier":true,"power_boost":2,"power_delta":2,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":0,"toughness_delta":0,"trigger":"enters_battlefield","trigger_effect":"stat_modifier_until_eot","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"BoostTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RubblebeltBoar translated into ManaLoom runtime scope xmage_creature_etb_fixed_boost_target_until_eot_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('tenth district guard', 'Tenth District Guard', 'aeac46be153986453a88dd35b683fe46', 'battle_rule_v1:72fca02cd157f856fd67771dba303dce', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_fixed_boost_target_until_eot_v1","duration":"until_end_of_turn","effect":"creature","etb_target_stat_modifier":true,"power_boost":0,"power_delta":0,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":1,"toughness_delta":1,"trigger":"enters_battlefield","trigger_effect":"stat_modifier_until_eot","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"BoostTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TenthDistrictGuard translated into ManaLoom runtime scope xmage_creature_etb_fixed_boost_target_until_eot_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('vulshok heartstoker', 'Vulshok Heartstoker', '351d6e15733b5c222f490fffe42dbdb6', 'battle_rule_v1:d676ca7df8e0a239c44ff49b71a31ead', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_fixed_boost_target_until_eot_v1","duration":"until_end_of_turn","effect":"creature","etb_target_stat_modifier":true,"power_boost":2,"power_delta":2,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":0,"toughness_delta":0,"trigger":"enters_battlefield","trigger_effect":"stat_modifier_until_eot","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"BoostTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class VulshokHeartstoker translated into ManaLoom runtime scope xmage_creature_etb_fixed_boost_target_until_eot_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('yeva''s forcemage', 'Yeva''s Forcemage', '3200139f56f87c26184f67fe4a5b3a54', 'battle_rule_v1:545d0764d4993cc2ec59375083699f4e', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_fixed_boost_target_until_eot_v1","duration":"until_end_of_turn","effect":"creature","etb_target_stat_modifier":true,"power_boost":2,"power_delta":2,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","toughness_boost":2,"toughness_delta":2,"trigger":"enters_battlefield","trigger_effect":"stat_modifier_until_eot","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"BoostTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class YevasForcemage translated into ManaLoom runtime scope xmage_creature_etb_fixed_boost_target_until_eot_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
