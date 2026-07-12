WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('aesthir glider', 'Aesthir Glider', '4893eefbd4bc76a7b9d1e891a37d70be', 'battle_rule_v1:8b80cbc5dee879a560224daf9172f1d0', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_self_cant_block_creature_v1","cannot_block":true,"cant_block":true,"effect":"creature","flying":true,"keywords":["flying"],"static_cant_block":true,"static_effect":"self_cant_block","target":"self","target_controller":"self","xmage_ability_class":"CantBlockAbility","xmage_ability_classes":["CantBlockAbility","FlyingAbility"]}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AesthirGlider translated into ManaLoom runtime scope xmage_static_self_cant_block_creature_v1. This row is package-ready only because the source signature is a narrow creature static self can''t-block restriction with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('daggerclaw imp', 'Daggerclaw Imp', '4893eefbd4bc76a7b9d1e891a37d70be', 'battle_rule_v1:8b80cbc5dee879a560224daf9172f1d0', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_self_cant_block_creature_v1","cannot_block":true,"cant_block":true,"effect":"creature","flying":true,"keywords":["flying"],"static_cant_block":true,"static_effect":"self_cant_block","target":"self","target_controller":"self","xmage_ability_class":"CantBlockAbility","xmage_ability_classes":["CantBlockAbility","FlyingAbility"]}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DaggerclawImp translated into ManaLoom runtime scope xmage_static_self_cant_block_creature_v1. This row is package-ready only because the source signature is a narrow creature static self can''t-block restriction with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('goblin glider', 'Goblin Glider', '4893eefbd4bc76a7b9d1e891a37d70be', 'battle_rule_v1:8b80cbc5dee879a560224daf9172f1d0', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_self_cant_block_creature_v1","cannot_block":true,"cant_block":true,"effect":"creature","flying":true,"keywords":["flying"],"static_cant_block":true,"static_effect":"self_cant_block","target":"self","target_controller":"self","xmage_ability_class":"CantBlockAbility","xmage_ability_classes":["CantBlockAbility","FlyingAbility"]}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GoblinGlider translated into ManaLoom runtime scope xmage_static_self_cant_block_creature_v1. This row is package-ready only because the source signature is a narrow creature static self can''t-block restriction with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('iron-barb hellion', 'Iron-Barb Hellion', '2befb1427bdc8b017a18f5f51eeaaa71', 'battle_rule_v1:e38b28bd3c0984bc6c252aa8b1594fa7', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_self_cant_block_creature_v1","cannot_block":true,"cant_block":true,"effect":"creature","haste":true,"keywords":["haste"],"static_cant_block":true,"static_effect":"self_cant_block","target":"self","target_controller":"self","xmage_ability_class":"CantBlockAbility","xmage_ability_classes":["CantBlockAbility","HasteAbility"]}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class IronBarbHellion translated into ManaLoom runtime scope xmage_static_self_cant_block_creature_v1. This row is package-ready only because the source signature is a narrow creature static self can''t-block restriction with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('kyren glider', 'Kyren Glider', '4893eefbd4bc76a7b9d1e891a37d70be', 'battle_rule_v1:8b80cbc5dee879a560224daf9172f1d0', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_self_cant_block_creature_v1","cannot_block":true,"cant_block":true,"effect":"creature","flying":true,"keywords":["flying"],"static_cant_block":true,"static_effect":"self_cant_block","target":"self","target_controller":"self","xmage_ability_class":"CantBlockAbility","xmage_ability_classes":["CantBlockAbility","FlyingAbility"]}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class KyrenGlider translated into ManaLoom runtime scope xmage_static_self_cant_block_creature_v1. This row is package-ready only because the source signature is a narrow creature static self can''t-block restriction with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('nezumi cutthroat', 'Nezumi Cutthroat', '50f19cc3f7bb41d61e0eb0b7c2838df9', 'battle_rule_v1:c7b91b48e780f212a286c4011ac31b5b', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_self_cant_block_creature_v1","cannot_block":true,"cant_block":true,"effect":"creature","fear":true,"keywords":["fear"],"static_cant_block":true,"static_effect":"self_cant_block","target":"self","target_controller":"self","xmage_ability_class":"CantBlockAbility","xmage_ability_classes":["CantBlockAbility","FearAbility"]}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class NezumiCutthroat translated into ManaLoom runtime scope xmage_static_self_cant_block_creature_v1. This row is package-ready only because the source signature is a narrow creature static self can''t-block restriction with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('nightshade stinger', 'Nightshade Stinger', '4893eefbd4bc76a7b9d1e891a37d70be', 'battle_rule_v1:8b80cbc5dee879a560224daf9172f1d0', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_self_cant_block_creature_v1","cannot_block":true,"cant_block":true,"effect":"creature","flying":true,"keywords":["flying"],"static_cant_block":true,"static_effect":"self_cant_block","target":"self","target_controller":"self","xmage_ability_class":"CantBlockAbility","xmage_ability_classes":["CantBlockAbility","FlyingAbility"]}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class NightshadeStinger translated into ManaLoom runtime scope xmage_static_self_cant_block_creature_v1. This row is package-ready only because the source signature is a narrow creature static self can''t-block restriction with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('vampire interloper', 'Vampire Interloper', '4893eefbd4bc76a7b9d1e891a37d70be', 'battle_rule_v1:8b80cbc5dee879a560224daf9172f1d0', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_self_cant_block_creature_v1","cannot_block":true,"cant_block":true,"effect":"creature","flying":true,"keywords":["flying"],"static_cant_block":true,"static_effect":"self_cant_block","target":"self","target_controller":"self","xmage_ability_class":"CantBlockAbility","xmage_ability_classes":["CantBlockAbility","FlyingAbility"]}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class VampireInterloper translated into ManaLoom runtime scope xmage_static_self_cant_block_creature_v1. This row is package-ready only because the source signature is a narrow creature static self can''t-block restriction with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
