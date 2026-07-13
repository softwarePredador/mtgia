WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('ashen monstrosity', 'Ashen Monstrosity', '2affd12d7c3e8be1f8625e634a1d5f0f', 'battle_rule_v1:77d96205cfd72d0d047985f816e4532d', '{"_keywords_are_self":true,"ability_kind":"static","attacks_each_combat_if_able":true,"battle_model_scope":"xmage_static_self_attacks_each_combat_creature_v1","effect":"creature","haste":true,"keywords":["haste"],"must_attack_each_combat_if_able":true,"must_attack_if_able":true,"static_effect":"self_attacks_each_combat_if_able","target":"self","target_controller":"self","xmage_ability_class":"AttacksEachCombatStaticAbility","xmage_ability_classes":["AttacksEachCombatStaticAbility","HasteAbility"]}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AshenMonstrosity translated into ManaLoom runtime scope xmage_static_self_attacks_each_combat_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('berserkers of blood ridge', 'Berserkers of Blood Ridge', '17b70d8d296a7d84d586fab27ddf7a7e', 'battle_rule_v1:690c965ee2aea641f734d96b36c3ba08', '{"ability_kind":"static","attacks_each_combat_if_able":true,"battle_model_scope":"xmage_static_self_attacks_each_combat_creature_v1","effect":"creature","must_attack_each_combat_if_able":true,"must_attack_if_able":true,"static_effect":"self_attacks_each_combat_if_able","target":"self","target_controller":"self","xmage_ability_class":"AttacksEachCombatStaticAbility","xmage_ability_classes":["AttacksEachCombatStaticAbility"]}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BerserkersOfBloodRidge translated into ManaLoom runtime scope xmage_static_self_attacks_each_combat_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('bloodrock cyclops', 'Bloodrock Cyclops', '17b70d8d296a7d84d586fab27ddf7a7e', 'battle_rule_v1:690c965ee2aea641f734d96b36c3ba08', '{"ability_kind":"static","attacks_each_combat_if_able":true,"battle_model_scope":"xmage_static_self_attacks_each_combat_creature_v1","effect":"creature","must_attack_each_combat_if_able":true,"must_attack_if_able":true,"static_effect":"self_attacks_each_combat_if_able","target":"self","target_controller":"self","xmage_ability_class":"AttacksEachCombatStaticAbility","xmage_ability_classes":["AttacksEachCombatStaticAbility"]}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BloodrockCyclops translated into ManaLoom runtime scope xmage_static_self_attacks_each_combat_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('crazed goblin', 'Crazed Goblin', '17b70d8d296a7d84d586fab27ddf7a7e', 'battle_rule_v1:690c965ee2aea641f734d96b36c3ba08', '{"ability_kind":"static","attacks_each_combat_if_able":true,"battle_model_scope":"xmage_static_self_attacks_each_combat_creature_v1","effect":"creature","must_attack_each_combat_if_able":true,"must_attack_if_able":true,"static_effect":"self_attacks_each_combat_if_able","target":"self","target_controller":"self","xmage_ability_class":"AttacksEachCombatStaticAbility","xmage_ability_classes":["AttacksEachCombatStaticAbility"]}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CrazedGoblin translated into ManaLoom runtime scope xmage_static_self_attacks_each_combat_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('flameborn hellion', 'Flameborn Hellion', '2affd12d7c3e8be1f8625e634a1d5f0f', 'battle_rule_v1:77d96205cfd72d0d047985f816e4532d', '{"_keywords_are_self":true,"ability_kind":"static","attacks_each_combat_if_able":true,"battle_model_scope":"xmage_static_self_attacks_each_combat_creature_v1","effect":"creature","haste":true,"keywords":["haste"],"must_attack_each_combat_if_able":true,"must_attack_if_able":true,"static_effect":"self_attacks_each_combat_if_able","target":"self","target_controller":"self","xmage_ability_class":"AttacksEachCombatStaticAbility","xmage_ability_classes":["AttacksEachCombatStaticAbility","HasteAbility"]}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FlamebornHellion translated into ManaLoom runtime scope xmage_static_self_attacks_each_combat_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('frontline rebel', 'Frontline Rebel', '17b70d8d296a7d84d586fab27ddf7a7e', 'battle_rule_v1:690c965ee2aea641f734d96b36c3ba08', '{"ability_kind":"static","attacks_each_combat_if_able":true,"battle_model_scope":"xmage_static_self_attacks_each_combat_creature_v1","effect":"creature","must_attack_each_combat_if_able":true,"must_attack_if_able":true,"static_effect":"self_attacks_each_combat_if_able","target":"self","target_controller":"self","xmage_ability_class":"AttacksEachCombatStaticAbility","xmage_ability_classes":["AttacksEachCombatStaticAbility"]}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FrontlineRebel translated into ManaLoom runtime scope xmage_static_self_attacks_each_combat_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('goblin brigand', 'Goblin Brigand', '17b70d8d296a7d84d586fab27ddf7a7e', 'battle_rule_v1:690c965ee2aea641f734d96b36c3ba08', '{"ability_kind":"static","attacks_each_combat_if_able":true,"battle_model_scope":"xmage_static_self_attacks_each_combat_creature_v1","effect":"creature","must_attack_each_combat_if_able":true,"must_attack_if_able":true,"static_effect":"self_attacks_each_combat_if_able","target":"self","target_controller":"self","xmage_ability_class":"AttacksEachCombatStaticAbility","xmage_ability_classes":["AttacksEachCombatStaticAbility"]}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GoblinBrigand translated into ManaLoom runtime scope xmage_static_self_attacks_each_combat_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('impetuous sunchaser', 'Impetuous Sunchaser', '7ecc96d79c13010ba07ea868648733d8', 'battle_rule_v1:4b4d14a89024cd07ae39decbd6a712b8', '{"_keywords_are_self":true,"ability_kind":"static","attacks_each_combat_if_able":true,"battle_model_scope":"xmage_static_self_attacks_each_combat_creature_v1","effect":"creature","flying":true,"haste":true,"keywords":["flying","haste"],"must_attack_each_combat_if_able":true,"must_attack_if_able":true,"static_effect":"self_attacks_each_combat_if_able","target":"self","target_controller":"self","xmage_ability_class":"AttacksEachCombatStaticAbility","xmage_ability_classes":["AttacksEachCombatStaticAbility","FlyingAbility","HasteAbility"]}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ImpetuousSunchaser translated into ManaLoom runtime scope xmage_static_self_attacks_each_combat_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('reckless brute', 'Reckless Brute', 'fd2e8a8a9f5f975a986dcd0b86394796', 'battle_rule_v1:77d96205cfd72d0d047985f816e4532d', '{"_keywords_are_self":true,"ability_kind":"static","attacks_each_combat_if_able":true,"battle_model_scope":"xmage_static_self_attacks_each_combat_creature_v1","effect":"creature","haste":true,"keywords":["haste"],"must_attack_each_combat_if_able":true,"must_attack_if_able":true,"static_effect":"self_attacks_each_combat_if_able","target":"self","target_controller":"self","xmage_ability_class":"AttacksEachCombatStaticAbility","xmage_ability_classes":["AttacksEachCombatStaticAbility","HasteAbility"]}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RecklessBrute translated into ManaLoom runtime scope xmage_static_self_attacks_each_combat_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('riot piker', 'Riot Piker', '4d72a630e9310e9f957eb591fd71b239', 'battle_rule_v1:833dd34cfe98c0e7b45abba82699f814', '{"_keywords_are_self":true,"ability_kind":"static","attacks_each_combat_if_able":true,"battle_model_scope":"xmage_static_self_attacks_each_combat_creature_v1","effect":"creature","first_strike":true,"keywords":["first_strike"],"must_attack_each_combat_if_able":true,"must_attack_if_able":true,"static_effect":"self_attacks_each_combat_if_able","target":"self","target_controller":"self","xmage_ability_class":"AttacksEachCombatStaticAbility","xmage_ability_classes":["AttacksEachCombatStaticAbility","FirstStrikeAbility"]}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RiotPiker translated into ManaLoom runtime scope xmage_static_self_attacks_each_combat_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('rubblebelt recluse', 'Rubblebelt Recluse', '17b70d8d296a7d84d586fab27ddf7a7e', 'battle_rule_v1:690c965ee2aea641f734d96b36c3ba08', '{"ability_kind":"static","attacks_each_combat_if_able":true,"battle_model_scope":"xmage_static_self_attacks_each_combat_creature_v1","effect":"creature","must_attack_each_combat_if_able":true,"must_attack_if_able":true,"static_effect":"self_attacks_each_combat_if_able","target":"self","target_controller":"self","xmage_ability_class":"AttacksEachCombatStaticAbility","xmage_ability_classes":["AttacksEachCombatStaticAbility"]}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RubblebeltRecluse translated into ManaLoom runtime scope xmage_static_self_attacks_each_combat_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('tattermunge maniac', 'Tattermunge Maniac', '17b70d8d296a7d84d586fab27ddf7a7e', 'battle_rule_v1:690c965ee2aea641f734d96b36c3ba08', '{"ability_kind":"static","attacks_each_combat_if_able":true,"battle_model_scope":"xmage_static_self_attacks_each_combat_creature_v1","effect":"creature","must_attack_each_combat_if_able":true,"must_attack_if_able":true,"static_effect":"self_attacks_each_combat_if_able","target":"self","target_controller":"self","xmage_ability_class":"AttacksEachCombatStaticAbility","xmage_ability_classes":["AttacksEachCombatStaticAbility"]}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TattermungeManiac translated into ManaLoom runtime scope xmage_static_self_attacks_each_combat_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('urborg drake', 'Urborg Drake', 'da1d5e36afbda76a7da9a27fdfe8e55c', 'battle_rule_v1:5807931af0c7fd0760e804ad3ef97515', '{"_keywords_are_self":true,"ability_kind":"static","attacks_each_combat_if_able":true,"battle_model_scope":"xmage_static_self_attacks_each_combat_creature_v1","effect":"creature","flying":true,"keywords":["flying"],"must_attack_each_combat_if_able":true,"must_attack_if_able":true,"static_effect":"self_attacks_each_combat_if_able","target":"self","target_controller":"self","xmage_ability_class":"AttacksEachCombatStaticAbility","xmage_ability_classes":["AttacksEachCombatStaticAbility","FlyingAbility"]}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class UrborgDrake translated into ManaLoom runtime scope xmage_static_self_attacks_each_combat_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('utvara scalper', 'Utvara Scalper', 'da1d5e36afbda76a7da9a27fdfe8e55c', 'battle_rule_v1:5807931af0c7fd0760e804ad3ef97515', '{"_keywords_are_self":true,"ability_kind":"static","attacks_each_combat_if_able":true,"battle_model_scope":"xmage_static_self_attacks_each_combat_creature_v1","effect":"creature","flying":true,"keywords":["flying"],"must_attack_each_combat_if_able":true,"must_attack_if_able":true,"static_effect":"self_attacks_each_combat_if_able","target":"self","target_controller":"self","xmage_ability_class":"AttacksEachCombatStaticAbility","xmage_ability_classes":["AttacksEachCombatStaticAbility","FlyingAbility"]}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class UtvaraScalper translated into ManaLoom runtime scope xmage_static_self_attacks_each_combat_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('valley dasher', 'Valley Dasher', '2affd12d7c3e8be1f8625e634a1d5f0f', 'battle_rule_v1:77d96205cfd72d0d047985f816e4532d', '{"_keywords_are_self":true,"ability_kind":"static","attacks_each_combat_if_able":true,"battle_model_scope":"xmage_static_self_attacks_each_combat_creature_v1","effect":"creature","haste":true,"keywords":["haste"],"must_attack_each_combat_if_able":true,"must_attack_if_able":true,"static_effect":"self_attacks_each_combat_if_able","target":"self","target_controller":"self","xmage_ability_class":"AttacksEachCombatStaticAbility","xmage_ability_classes":["AttacksEachCombatStaticAbility","HasteAbility"]}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ValleyDasher translated into ManaLoom runtime scope xmage_static_self_attacks_each_combat_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
