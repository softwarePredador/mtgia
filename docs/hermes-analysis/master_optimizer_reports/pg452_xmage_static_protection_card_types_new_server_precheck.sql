WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('angelic curator', 'Angelic Curator', 'c6da5f0c4b2d68f5ca57f71674898e63', 'battle_rule_v1:b067ac2a5f8fe2f33fc1ea6586c92f68', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_self_protection_from_card_types_creature_v1","effect":"creature","flying":true,"keywords":["flying"],"protection_from_card_types":["artifact"],"static_effect":"self_protection_from_card_types","target":"self","target_controller":"self","xmage_ability_class":"ProtectionAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AngelicCurator translated into ManaLoom runtime scope xmage_static_self_protection_from_card_types_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('azorius first-wing', 'Azorius First-Wing', '0bed20a30ce1893bce2a5f3525a3586d', 'battle_rule_v1:d1459b62eb8c5236cecc0803294e9c0a', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_self_protection_from_card_types_creature_v1","effect":"creature","flying":true,"keywords":["flying"],"protection_from_card_types":["enchantment"],"static_effect":"self_protection_from_card_types","target":"self","target_controller":"self","xmage_ability_class":"ProtectionAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AzoriusFirstWing translated into ManaLoom runtime scope xmage_static_self_protection_from_card_types_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('beloved chaplain', 'Beloved Chaplain', '85465de2f7bb9355e2abee50bf175551', 'battle_rule_v1:219f2afb6ddef7cf8e3f05b9f56145b4', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_protection_from_card_types_creature_v1","effect":"creature","protection_from_card_types":["creature"],"static_effect":"self_protection_from_card_types","target":"self","target_controller":"self","xmage_ability_class":"ProtectionAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BelovedChaplain translated into ManaLoom runtime scope xmage_static_self_protection_from_card_types_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('commander eesha', 'Commander Eesha', '8c397f94332b7738a90dffa5e34c1766', 'battle_rule_v1:cb4ddef26b3af5c6fae84cbcc063bcbd', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_self_protection_from_card_types_creature_v1","effect":"creature","flying":true,"keywords":["flying"],"protection_from_card_types":["creature"],"static_effect":"self_protection_from_card_types","target":"self","target_controller":"self","xmage_ability_class":"ProtectionAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CommanderEesha translated into ManaLoom runtime scope xmage_static_self_protection_from_card_types_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('horizon drake', 'Horizon Drake', '483bc74a05388029147248b9fa3327e5', 'battle_rule_v1:8bad75f82fd0185f7d6515eae6a7ee75', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_self_protection_from_card_types_creature_v1","effect":"creature","flying":true,"keywords":["flying"],"protection_from_card_types":["land"],"static_effect":"self_protection_from_card_types","target":"self","target_controller":"self","xmage_ability_class":"ProtectionAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HorizonDrake translated into ManaLoom runtime scope xmage_static_self_protection_from_card_types_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('nacatl savage', 'Nacatl Savage', 'c326b8227109ed7986576e4fc2fd8738', 'battle_rule_v1:64d5ec144e33bf5008c6ec840889e03d', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_protection_from_card_types_creature_v1","effect":"creature","protection_from_card_types":["artifact"],"static_effect":"self_protection_from_card_types","target":"self","target_controller":"self","xmage_ability_class":"ProtectionAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class NacatlSavage translated into ManaLoom runtime scope xmage_static_self_protection_from_card_types_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('needlebug', 'Needlebug', 'e6aa03762d0c8998b46747f47b554641', 'battle_rule_v1:813777fa7616859ba02a555d1232f605', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_self_protection_from_card_types_creature_v1","effect":"creature","flash":true,"keywords":["flash"],"protection_from_card_types":["artifact"],"static_effect":"self_protection_from_card_types","target":"self","target_controller":"self","xmage_ability_class":"ProtectionAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Needlebug translated into ManaLoom runtime scope xmage_static_self_protection_from_card_types_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('tel-jilad archers', 'Tel-Jilad Archers', '12b0bc0b3cc904955ae10eba99c3c985', 'battle_rule_v1:dc27d7f5f035d51b05a72775a1328276', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_self_protection_from_card_types_creature_v1","effect":"creature","keywords":["reach"],"protection_from_card_types":["artifact"],"reach":true,"static_effect":"self_protection_from_card_types","target":"self","target_controller":"self","xmage_ability_class":"ProtectionAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TelJiladArchers translated into ManaLoom runtime scope xmage_static_self_protection_from_card_types_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('tel-jilad chosen', 'Tel-Jilad Chosen', 'c326b8227109ed7986576e4fc2fd8738', 'battle_rule_v1:64d5ec144e33bf5008c6ec840889e03d', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_protection_from_card_types_creature_v1","effect":"creature","protection_from_card_types":["artifact"],"static_effect":"self_protection_from_card_types","target":"self","target_controller":"self","xmage_ability_class":"ProtectionAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TelJiladChosen translated into ManaLoom runtime scope xmage_static_self_protection_from_card_types_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('tel-jilad outrider', 'Tel-Jilad Outrider', 'c326b8227109ed7986576e4fc2fd8738', 'battle_rule_v1:64d5ec144e33bf5008c6ec840889e03d', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_protection_from_card_types_creature_v1","effect":"creature","protection_from_card_types":["artifact"],"static_effect":"self_protection_from_card_types","target":"self","target_controller":"self","xmage_ability_class":"ProtectionAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TelJiladOutrider translated into ManaLoom runtime scope xmage_static_self_protection_from_card_types_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('yavimaya scion', 'Yavimaya Scion', 'c326b8227109ed7986576e4fc2fd8738', 'battle_rule_v1:64d5ec144e33bf5008c6ec840889e03d', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_protection_from_card_types_creature_v1","effect":"creature","protection_from_card_types":["artifact"],"static_effect":"self_protection_from_card_types","target":"self","target_controller":"self","xmage_ability_class":"ProtectionAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class YavimayaScion translated into ManaLoom runtime scope xmage_static_self_protection_from_card_types_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
