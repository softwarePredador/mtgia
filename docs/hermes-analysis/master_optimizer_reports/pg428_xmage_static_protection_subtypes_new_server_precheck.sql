WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('baneslayer angel', 'Baneslayer Angel', '6ff8233e60ef21831394c03d584cc90b', 'battle_rule_v1:973bf73edcfe9d86e8844d2171f10962', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_self_protection_from_subtypes_creature_v1","effect":"creature","first_strike":true,"flying":true,"keywords":["flying","first_strike","lifelink"],"lifelink":true,"protection_from_subtypes":["demon","dragon"],"static_effect":"self_protection_from_subtypes","target":"self","target_controller":"self","xmage_ability_class":"ProtectionAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BaneslayerAngel translated into ManaLoom runtime scope xmage_static_self_protection_from_subtypes_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('dragonstalker', 'Dragonstalker', '16f20165bc82d6ca26da2052b1820080', 'battle_rule_v1:84f814838cb82adbdbd052401b9ea24d', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_self_protection_from_subtypes_creature_v1","effect":"creature","flying":true,"keywords":["flying"],"protection_from_subtypes":["dragon"],"static_effect":"self_protection_from_subtypes","target":"self","target_controller":"self","xmage_ability_class":"ProtectionAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Dragonstalker translated into ManaLoom runtime scope xmage_static_self_protection_from_subtypes_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('elite inquisitor', 'Elite Inquisitor', 'af26f954b35928382f87b6428f2080c9', 'battle_rule_v1:2438eab81680409d0c44fd12d28c5ae7', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_self_protection_from_subtypes_creature_v1","effect":"creature","first_strike":true,"keywords":["first_strike","vigilance"],"protection_from_subtypes":["vampire","werewolf","zombie"],"static_effect":"self_protection_from_subtypes","target":"self","target_controller":"self","vigilance":true,"xmage_ability_class":"ProtectionAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class EliteInquisitor translated into ManaLoom runtime scope xmage_static_self_protection_from_subtypes_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('grave bramble', 'Grave Bramble', 'fad649d082c01228a4b2cbbdfe3aa747', 'battle_rule_v1:5073a13207eb34682e126dfea00b0fc6', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_self_protection_from_subtypes_creature_v1","defender":true,"effect":"creature","keywords":["defender"],"protection_from_subtypes":["zombie"],"static_effect":"self_protection_from_subtypes","target":"self","target_controller":"self","xmage_ability_class":"ProtectionAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GraveBramble translated into ManaLoom runtime scope xmage_static_self_protection_from_subtypes_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('kitsune riftwalker', 'Kitsune Riftwalker', '1a467785235070a14689341eaa7feae0', 'battle_rule_v1:ed169e07fbc5efe8ca83d222c2c3e0da', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_protection_from_subtypes_creature_v1","effect":"creature","protection_from_subtypes":["arcane","spirit"],"static_effect":"self_protection_from_subtypes","target":"self","target_controller":"self","xmage_ability_class":"ProtectionAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class KitsuneRiftwalker translated into ManaLoom runtime scope xmage_static_self_protection_from_subtypes_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('midnight duelist', 'Midnight Duelist', 'c8f30f806e27ed47a11d3a0a7ee1d44e', 'battle_rule_v1:5edf74990c5a9ec0cb78917c0cefbec0', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_protection_from_subtypes_creature_v1","effect":"creature","protection_from_subtypes":["vampire"],"static_effect":"self_protection_from_subtypes","target":"self","target_controller":"self","xmage_ability_class":"ProtectionAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MidnightDuelist translated into ManaLoom runtime scope xmage_static_self_protection_from_subtypes_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('nath''s buffoon', 'Nath''s Buffoon', 'a7b9dde1c54d861d6ff1bc885775c22a', 'battle_rule_v1:8f4af176e1c167faade458042f4e8a05', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_protection_from_subtypes_creature_v1","effect":"creature","protection_from_subtypes":["elf"],"static_effect":"self_protection_from_subtypes","target":"self","target_controller":"self","xmage_ability_class":"ProtectionAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class NathsBuffoon translated into ManaLoom runtime scope xmage_static_self_protection_from_subtypes_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('shoreline raider', 'Shoreline Raider', '6c7c7021f6a9cc09fded6a19d160c31c', 'battle_rule_v1:97a60cbe14d8a270721264c8545213f9', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_protection_from_subtypes_creature_v1","effect":"creature","protection_from_subtypes":["kavu"],"static_effect":"self_protection_from_subtypes","target":"self","target_controller":"self","xmage_ability_class":"ProtectionAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ShorelineRaider translated into ManaLoom runtime scope xmage_static_self_protection_from_subtypes_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('tel-jilad archers', 'Tel-Jilad Archers', '12b0bc0b3cc904955ae10eba99c3c985', 'battle_rule_v1:dc27d7f5f035d51b05a72775a1328276', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_self_protection_from_card_types_creature_v1","effect":"creature","keywords":["reach"],"protection_from_card_types":["artifact"],"reach":true,"static_effect":"self_protection_from_card_types","target":"self","target_controller":"self","xmage_ability_class":"ProtectionAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TelJiladArchers translated into ManaLoom runtime scope xmage_static_self_protection_from_card_types_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
