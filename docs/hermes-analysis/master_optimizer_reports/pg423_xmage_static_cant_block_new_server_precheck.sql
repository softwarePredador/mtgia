WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('ashenmoor gouger', 'Ashenmoor Gouger', '8019586c29deff0d4a5543ee4d4f2726', 'battle_rule_v1:6ee53f88921f55a8efb9dafc5a3b235b', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_cant_block_creature_v1","cannot_block":true,"cant_block":true,"effect":"creature","static_cant_block":true,"static_effect":"self_cant_block","target":"self","target_controller":"self","xmage_ability_class":"CantBlockAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AshenmoorGouger translated into ManaLoom runtime scope xmage_static_self_cant_block_creature_v1. This row is package-ready only because the source signature is a narrow creature static self can''t-block restriction with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('craven giant', 'Craven Giant', '8019586c29deff0d4a5543ee4d4f2726', 'battle_rule_v1:6ee53f88921f55a8efb9dafc5a3b235b', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_cant_block_creature_v1","cannot_block":true,"cant_block":true,"effect":"creature","static_cant_block":true,"static_effect":"self_cant_block","target":"self","target_controller":"self","xmage_ability_class":"CantBlockAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CravenGiant translated into ManaLoom runtime scope xmage_static_self_cant_block_creature_v1. This row is package-ready only because the source signature is a narrow creature static self can''t-block restriction with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('craven knight', 'Craven Knight', '8019586c29deff0d4a5543ee4d4f2726', 'battle_rule_v1:6ee53f88921f55a8efb9dafc5a3b235b', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_cant_block_creature_v1","cannot_block":true,"cant_block":true,"effect":"creature","static_cant_block":true,"static_effect":"self_cant_block","target":"self","target_controller":"self","xmage_ability_class":"CantBlockAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CravenKnight translated into ManaLoom runtime scope xmage_static_self_cant_block_creature_v1. This row is package-ready only because the source signature is a narrow creature static self can''t-block restriction with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('goblin raider', 'Goblin Raider', '8019586c29deff0d4a5543ee4d4f2726', 'battle_rule_v1:6ee53f88921f55a8efb9dafc5a3b235b', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_cant_block_creature_v1","cannot_block":true,"cant_block":true,"effect":"creature","static_cant_block":true,"static_effect":"self_cant_block","target":"self","target_controller":"self","xmage_ability_class":"CantBlockAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GoblinRaider translated into ManaLoom runtime scope xmage_static_self_cant_block_creature_v1. This row is package-ready only because the source signature is a narrow creature static self can''t-block restriction with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('hulking cyclops', 'Hulking Cyclops', '8019586c29deff0d4a5543ee4d4f2726', 'battle_rule_v1:6ee53f88921f55a8efb9dafc5a3b235b', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_cant_block_creature_v1","cannot_block":true,"cant_block":true,"effect":"creature","static_cant_block":true,"static_effect":"self_cant_block","target":"self","target_controller":"self","xmage_ability_class":"CantBlockAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HulkingCyclops translated into ManaLoom runtime scope xmage_static_self_cant_block_creature_v1. This row is package-ready only because the source signature is a narrow creature static self can''t-block restriction with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('hulking goblin', 'Hulking Goblin', '8019586c29deff0d4a5543ee4d4f2726', 'battle_rule_v1:6ee53f88921f55a8efb9dafc5a3b235b', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_cant_block_creature_v1","cannot_block":true,"cant_block":true,"effect":"creature","static_cant_block":true,"static_effect":"self_cant_block","target":"self","target_controller":"self","xmage_ability_class":"CantBlockAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HulkingGoblin translated into ManaLoom runtime scope xmage_static_self_cant_block_creature_v1. This row is package-ready only because the source signature is a narrow creature static self can''t-block restriction with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('hulking ogre', 'Hulking Ogre', '8019586c29deff0d4a5543ee4d4f2726', 'battle_rule_v1:6ee53f88921f55a8efb9dafc5a3b235b', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_cant_block_creature_v1","cannot_block":true,"cant_block":true,"effect":"creature","static_cant_block":true,"static_effect":"self_cant_block","target":"self","target_controller":"self","xmage_ability_class":"CantBlockAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HulkingOgre translated into ManaLoom runtime scope xmage_static_self_cant_block_creature_v1. This row is package-ready only because the source signature is a narrow creature static self can''t-block restriction with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('jungle lion', 'Jungle Lion', '8019586c29deff0d4a5543ee4d4f2726', 'battle_rule_v1:6ee53f88921f55a8efb9dafc5a3b235b', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_cant_block_creature_v1","cannot_block":true,"cant_block":true,"effect":"creature","static_cant_block":true,"static_effect":"self_cant_block","target":"self","target_controller":"self","xmage_ability_class":"CantBlockAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class JungleLion translated into ManaLoom runtime scope xmage_static_self_cant_block_creature_v1. This row is package-ready only because the source signature is a narrow creature static self can''t-block restriction with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('ogre taskmaster', 'Ogre Taskmaster', '8019586c29deff0d4a5543ee4d4f2726', 'battle_rule_v1:6ee53f88921f55a8efb9dafc5a3b235b', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_cant_block_creature_v1","cannot_block":true,"cant_block":true,"effect":"creature","static_cant_block":true,"static_effect":"self_cant_block","target":"self","target_controller":"self","xmage_ability_class":"CantBlockAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class OgreTaskmaster translated into ManaLoom runtime scope xmage_static_self_cant_block_creature_v1. This row is package-ready only because the source signature is a narrow creature static self can''t-block restriction with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('scavenging scarab', 'Scavenging Scarab', '8019586c29deff0d4a5543ee4d4f2726', 'battle_rule_v1:6ee53f88921f55a8efb9dafc5a3b235b', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_cant_block_creature_v1","cannot_block":true,"cant_block":true,"effect":"creature","static_cant_block":true,"static_effect":"self_cant_block","target":"self","target_controller":"self","xmage_ability_class":"CantBlockAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ScavengingScarab translated into ManaLoom runtime scope xmage_static_self_cant_block_creature_v1. This row is package-ready only because the source signature is a narrow creature static self can''t-block restriction with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('spineless thug', 'Spineless Thug', '8019586c29deff0d4a5543ee4d4f2726', 'battle_rule_v1:6ee53f88921f55a8efb9dafc5a3b235b', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_cant_block_creature_v1","cannot_block":true,"cant_block":true,"effect":"creature","static_cant_block":true,"static_effect":"self_cant_block","target":"self","target_controller":"self","xmage_ability_class":"CantBlockAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SpinelessThug translated into ManaLoom runtime scope xmage_static_self_cant_block_creature_v1. This row is package-ready only because the source signature is a narrow creature static self can''t-block restriction with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('yellow scarves troops', 'Yellow Scarves Troops', '8019586c29deff0d4a5543ee4d4f2726', 'battle_rule_v1:6ee53f88921f55a8efb9dafc5a3b235b', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_cant_block_creature_v1","cannot_block":true,"cant_block":true,"effect":"creature","static_cant_block":true,"static_effect":"self_cant_block","target":"self","target_controller":"self","xmage_ability_class":"CantBlockAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class YellowScarvesTroops translated into ManaLoom runtime scope xmage_static_self_cant_block_creature_v1. This row is package-ready only because the source signature is a narrow creature static self can''t-block restriction with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('young wei recruits', 'Young Wei Recruits', '8019586c29deff0d4a5543ee4d4f2726', 'battle_rule_v1:6ee53f88921f55a8efb9dafc5a3b235b', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_cant_block_creature_v1","cannot_block":true,"cant_block":true,"effect":"creature","static_cant_block":true,"static_effect":"self_cant_block","target":"self","target_controller":"self","xmage_ability_class":"CantBlockAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class YoungWeiRecruits translated into ManaLoom runtime scope xmage_static_self_cant_block_creature_v1. This row is package-ready only because the source signature is a narrow creature static self can''t-block restriction with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
