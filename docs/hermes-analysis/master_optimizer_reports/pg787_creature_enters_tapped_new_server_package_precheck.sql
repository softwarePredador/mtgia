WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('crooked custodian', 'Crooked Custodian', 'a23de8c8e43937b987f482e3cc66ad77', 'battle_rule_v1:971f2437e4979c25f09b1e537115ab06', '{"ability_kind":"static","battle_model_scope":"xmage_creature_enters_tapped_v1","effect":"creature","enters_battlefield_tapped":true,"enters_tapped":true,"static_effect":"self_enters_tapped","target":"self","target_constraints":{"card_types":["creature"],"source":"self"},"target_controller":"self","xmage_ability_class":"EntersBattlefieldTappedAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CrookedCustodian translated into ManaLoom runtime scope xmage_creature_enters_tapped_v1. This row is package-ready only because the source signature is a narrow creature replacement/static entry state entering the battlefield tapped with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('diregraf ghoul', 'Diregraf Ghoul', 'a23de8c8e43937b987f482e3cc66ad77', 'battle_rule_v1:971f2437e4979c25f09b1e537115ab06', '{"ability_kind":"static","battle_model_scope":"xmage_creature_enters_tapped_v1","effect":"creature","enters_battlefield_tapped":true,"enters_tapped":true,"static_effect":"self_enters_tapped","target":"self","target_constraints":{"card_types":["creature"],"source":"self"},"target_controller":"self","xmage_ability_class":"EntersBattlefieldTappedAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DiregrafGhoul translated into ManaLoom runtime scope xmage_creature_enters_tapped_v1. This row is package-ready only because the source signature is a narrow creature replacement/static entry state entering the battlefield tapped with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('forgotten sentinel', 'Forgotten Sentinel', 'a23de8c8e43937b987f482e3cc66ad77', 'battle_rule_v1:971f2437e4979c25f09b1e537115ab06', '{"ability_kind":"static","battle_model_scope":"xmage_creature_enters_tapped_v1","effect":"creature","enters_battlefield_tapped":true,"enters_tapped":true,"static_effect":"self_enters_tapped","target":"self","target_constraints":{"card_types":["creature"],"source":"self"},"target_controller":"self","xmage_ability_class":"EntersBattlefieldTappedAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ForgottenSentinel translated into ManaLoom runtime scope xmage_creature_enters_tapped_v1. This row is package-ready only because the source signature is a narrow creature replacement/static entry state entering the battlefield tapped with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('rotting legion', 'Rotting Legion', 'a23de8c8e43937b987f482e3cc66ad77', 'battle_rule_v1:971f2437e4979c25f09b1e537115ab06', '{"ability_kind":"static","battle_model_scope":"xmage_creature_enters_tapped_v1","effect":"creature","enters_battlefield_tapped":true,"enters_tapped":true,"static_effect":"self_enters_tapped","target":"self","target_constraints":{"card_types":["creature"],"source":"self"},"target_controller":"self","xmage_ability_class":"EntersBattlefieldTappedAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RottingLegion translated into ManaLoom runtime scope xmage_creature_enters_tapped_v1. This row is package-ready only because the source signature is a narrow creature replacement/static entry state entering the battlefield tapped with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('rusted sentinel', 'Rusted Sentinel', 'a23de8c8e43937b987f482e3cc66ad77', 'battle_rule_v1:971f2437e4979c25f09b1e537115ab06', '{"ability_kind":"static","battle_model_scope":"xmage_creature_enters_tapped_v1","effect":"creature","enters_battlefield_tapped":true,"enters_tapped":true,"static_effect":"self_enters_tapped","target":"self","target_constraints":{"card_types":["creature"],"source":"self"},"target_controller":"self","xmage_ability_class":"EntersBattlefieldTappedAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RustedSentinel translated into ManaLoom runtime scope xmage_creature_enters_tapped_v1. This row is package-ready only because the source signature is a narrow creature replacement/static entry state entering the battlefield tapped with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('scarwood treefolk', 'Scarwood Treefolk', 'a23de8c8e43937b987f482e3cc66ad77', 'battle_rule_v1:c3a3adb1b8ff70ce1de41ebe57159291', '{"ability_kind":"static","battle_model_scope":"xmage_creature_enters_tapped_v1","effect":"creature","enters_battlefield_tapped":true,"enters_tapped":true,"static_effect":"self_enters_tapped","target":"self","target_constraints":{"card_types":["creature"],"source":"self"},"target_controller":"self","xmage_ability_class":"EntersBattlefieldAbility","xmage_effect_class":"TapSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ScarwoodTreefolk translated into ManaLoom runtime scope xmage_creature_enters_tapped_v1. This row is package-ready only because the source signature is a narrow creature replacement/static entry state entering the battlefield tapped with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('shambling ghoul', 'Shambling Ghoul', 'a23de8c8e43937b987f482e3cc66ad77', 'battle_rule_v1:c3a3adb1b8ff70ce1de41ebe57159291', '{"ability_kind":"static","battle_model_scope":"xmage_creature_enters_tapped_v1","effect":"creature","enters_battlefield_tapped":true,"enters_tapped":true,"static_effect":"self_enters_tapped","target":"self","target_constraints":{"card_types":["creature"],"source":"self"},"target_controller":"self","xmage_ability_class":"EntersBattlefieldAbility","xmage_effect_class":"TapSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ShamblingGhoul translated into ManaLoom runtime scope xmage_creature_enters_tapped_v1. This row is package-ready only because the source signature is a narrow creature replacement/static entry state entering the battlefield tapped with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('unhallowed phalanx', 'Unhallowed Phalanx', 'a23de8c8e43937b987f482e3cc66ad77', 'battle_rule_v1:971f2437e4979c25f09b1e537115ab06', '{"ability_kind":"static","battle_model_scope":"xmage_creature_enters_tapped_v1","effect":"creature","enters_battlefield_tapped":true,"enters_tapped":true,"static_effect":"self_enters_tapped","target":"self","target_constraints":{"card_types":["creature"],"source":"self"},"target_controller":"self","xmage_ability_class":"EntersBattlefieldTappedAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class UnhallowedPhalanx translated into ManaLoom runtime scope xmage_creature_enters_tapped_v1. This row is package-ready only because the source signature is a narrow creature replacement/static entry state entering the battlefield tapped with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('wolf cove villager', 'Wolf Cove Villager', 'a23de8c8e43937b987f482e3cc66ad77', 'battle_rule_v1:971f2437e4979c25f09b1e537115ab06', '{"ability_kind":"static","battle_model_scope":"xmage_creature_enters_tapped_v1","effect":"creature","enters_battlefield_tapped":true,"enters_tapped":true,"static_effect":"self_enters_tapped","target":"self","target_constraints":{"card_types":["creature"],"source":"self"},"target_controller":"self","xmage_ability_class":"EntersBattlefieldTappedAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WolfCoveVillager translated into ManaLoom runtime scope xmage_creature_enters_tapped_v1. This row is package-ready only because the source signature is a narrow creature replacement/static entry state entering the battlefield tapped with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
