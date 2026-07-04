WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('farhaven elf', 'Farhaven Elf', 'a1911864ebef631dda5f3217ba8e81d3', 'battle_rule_v1:6083c47a002100c88f241b4ef7e5e9c8', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_library_search_to_battlefield_v1","count":1,"destination":"battlefield","effect":"creature","etb_tutor_count":1,"etb_tutor_target":"basic_land_to_battlefield","target":"basic_land_to_battlefield","trigger":"enters_battlefield","tutor_enters_tapped":true,"xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"SearchLibraryPutInPlayEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"basic_land_to_battlefield"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FarhavenElf translated into ManaLoom runtime scope xmage_creature_etb_library_search_to_battlefield_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('kor cartographer', 'Kor Cartographer', '1f7e890320cf85f7a4334520d01bebb3', 'battle_rule_v1:0e4e552a7adc8c6d744abdd7562f6a4d', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_library_search_to_battlefield_v1","count":1,"destination":"battlefield","effect":"creature","etb_tutor_count":1,"etb_tutor_target":"plains_to_battlefield","target":"plains_to_battlefield","trigger":"enters_battlefield","tutor_enters_tapped":true,"xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"SearchLibraryPutInPlayEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"plains_to_battlefield"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class KorCartographer translated into ManaLoom runtime scope xmage_creature_etb_library_search_to_battlefield_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('ondu giant', 'Ondu Giant', 'a1911864ebef631dda5f3217ba8e81d3', 'battle_rule_v1:6083c47a002100c88f241b4ef7e5e9c8', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_library_search_to_battlefield_v1","count":1,"destination":"battlefield","effect":"creature","etb_tutor_count":1,"etb_tutor_target":"basic_land_to_battlefield","target":"basic_land_to_battlefield","trigger":"enters_battlefield","tutor_enters_tapped":true,"xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"SearchLibraryPutInPlayEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"basic_land_to_battlefield"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class OnduGiant translated into ManaLoom runtime scope xmage_creature_etb_library_search_to_battlefield_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('quandrix cultivator', 'Quandrix Cultivator', '5a8241aabb39c48a25a4f61c80c3f91d', 'battle_rule_v1:5a35faf7994c507956d5ae39d661c8ee', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_library_search_to_battlefield_v1","count":1,"destination":"battlefield","effect":"creature","etb_tutor_count":1,"etb_tutor_target":"basic_forest_or_island_to_battlefield","target":"basic_forest_or_island_to_battlefield","trigger":"enters_battlefield","tutor_enters_tapped":false,"xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"SearchLibraryPutInPlayEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"basic_forest_or_island_to_battlefield"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class QuandrixCultivator translated into ManaLoom runtime scope xmage_creature_etb_library_search_to_battlefield_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('quirion trailblazer', 'Quirion Trailblazer', '590c51ac8e2c916beff6e25d458634f0', 'battle_rule_v1:6083c47a002100c88f241b4ef7e5e9c8', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_library_search_to_battlefield_v1","count":1,"destination":"battlefield","effect":"creature","etb_tutor_count":1,"etb_tutor_target":"basic_land_to_battlefield","target":"basic_land_to_battlefield","trigger":"enters_battlefield","tutor_enters_tapped":true,"xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"SearchLibraryPutInPlayEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"basic_land_to_battlefield"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class QuirionTrailblazer translated into ManaLoom runtime scope xmage_creature_etb_library_search_to_battlefield_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('silverglade elemental', 'Silverglade Elemental', '20973a436f7ccb1e299d9a20b805d59a', 'battle_rule_v1:b283b714a3dc9203fccf5fb338db74f0', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_library_search_to_battlefield_v1","count":1,"destination":"battlefield","effect":"creature","etb_tutor_count":1,"etb_tutor_target":"forest_to_battlefield","target":"forest_to_battlefield","trigger":"enters_battlefield","tutor_enters_tapped":false,"xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"SearchLibraryPutInPlayEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"forest_to_battlefield"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SilvergladeElemental translated into ManaLoom runtime scope xmage_creature_etb_library_search_to_battlefield_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('wild wanderer', 'Wild Wanderer', 'a1911864ebef631dda5f3217ba8e81d3', 'battle_rule_v1:6083c47a002100c88f241b4ef7e5e9c8', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_library_search_to_battlefield_v1","count":1,"destination":"battlefield","effect":"creature","etb_tutor_count":1,"etb_tutor_target":"basic_land_to_battlefield","target":"basic_land_to_battlefield","trigger":"enters_battlefield","tutor_enters_tapped":true,"xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"SearchLibraryPutInPlayEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"basic_land_to_battlefield"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WildWanderer translated into ManaLoom runtime scope xmage_creature_etb_library_search_to_battlefield_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('wood elves', 'Wood Elves', '31dd7b282e5ce37042bdd72b0135624f', 'battle_rule_v1:b283b714a3dc9203fccf5fb338db74f0', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_library_search_to_battlefield_v1","count":1,"destination":"battlefield","effect":"creature","etb_tutor_count":1,"etb_tutor_target":"forest_to_battlefield","target":"forest_to_battlefield","trigger":"enters_battlefield","tutor_enters_tapped":false,"xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"SearchLibraryPutInPlayEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"forest_to_battlefield"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WoodElves translated into ManaLoom runtime scope xmage_creature_etb_library_search_to_battlefield_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
