WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('farhaven elf', 'Farhaven Elf', 'a1911864ebef631dda5f3217ba8e81d3', 'battle_rule_v1:6083c47a002100c88f241b4ef7e5e9c8', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_library_search_to_battlefield_v1","count":1,"destination":"battlefield","effect":"creature","etb_tutor_count":1,"etb_tutor_target":"basic_land_to_battlefield","target":"basic_land_to_battlefield","trigger":"enters_battlefield","tutor_enters_tapped":true,"xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"SearchLibraryPutInPlayEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"basic_land_to_battlefield"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FarhavenElf translated into ManaLoom runtime scope xmage_creature_etb_library_search_to_battlefield_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('kor cartographer', 'Kor Cartographer', '1f7e890320cf85f7a4334520d01bebb3', 'battle_rule_v1:0e4e552a7adc8c6d744abdd7562f6a4d', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_library_search_to_battlefield_v1","count":1,"destination":"battlefield","effect":"creature","etb_tutor_count":1,"etb_tutor_target":"plains_to_battlefield","target":"plains_to_battlefield","trigger":"enters_battlefield","tutor_enters_tapped":true,"xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"SearchLibraryPutInPlayEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"plains_to_battlefield"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class KorCartographer translated into ManaLoom runtime scope xmage_creature_etb_library_search_to_battlefield_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('ondu giant', 'Ondu Giant', 'a1911864ebef631dda5f3217ba8e81d3', 'battle_rule_v1:6083c47a002100c88f241b4ef7e5e9c8', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_library_search_to_battlefield_v1","count":1,"destination":"battlefield","effect":"creature","etb_tutor_count":1,"etb_tutor_target":"basic_land_to_battlefield","target":"basic_land_to_battlefield","trigger":"enters_battlefield","tutor_enters_tapped":true,"xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"SearchLibraryPutInPlayEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"basic_land_to_battlefield"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class OnduGiant translated into ManaLoom runtime scope xmage_creature_etb_library_search_to_battlefield_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('quandrix cultivator', 'Quandrix Cultivator', '5a8241aabb39c48a25a4f61c80c3f91d', 'battle_rule_v1:5a35faf7994c507956d5ae39d661c8ee', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_library_search_to_battlefield_v1","count":1,"destination":"battlefield","effect":"creature","etb_tutor_count":1,"etb_tutor_target":"basic_forest_or_island_to_battlefield","target":"basic_forest_or_island_to_battlefield","trigger":"enters_battlefield","tutor_enters_tapped":false,"xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"SearchLibraryPutInPlayEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"basic_forest_or_island_to_battlefield"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class QuandrixCultivator translated into ManaLoom runtime scope xmage_creature_etb_library_search_to_battlefield_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('quirion trailblazer', 'Quirion Trailblazer', '590c51ac8e2c916beff6e25d458634f0', 'battle_rule_v1:6083c47a002100c88f241b4ef7e5e9c8', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_library_search_to_battlefield_v1","count":1,"destination":"battlefield","effect":"creature","etb_tutor_count":1,"etb_tutor_target":"basic_land_to_battlefield","target":"basic_land_to_battlefield","trigger":"enters_battlefield","tutor_enters_tapped":true,"xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"SearchLibraryPutInPlayEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"basic_land_to_battlefield"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class QuirionTrailblazer translated into ManaLoom runtime scope xmage_creature_etb_library_search_to_battlefield_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('wild wanderer', 'Wild Wanderer', 'a1911864ebef631dda5f3217ba8e81d3', 'battle_rule_v1:6083c47a002100c88f241b4ef7e5e9c8', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_library_search_to_battlefield_v1","count":1,"destination":"battlefield","effect":"creature","etb_tutor_count":1,"etb_tutor_target":"basic_land_to_battlefield","target":"basic_land_to_battlefield","trigger":"enters_battlefield","tutor_enters_tapped":true,"xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"SearchLibraryPutInPlayEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"basic_land_to_battlefield"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WildWanderer translated into ManaLoom runtime scope xmage_creature_etb_library_search_to_battlefield_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg467_xmage_creature_etb_library_search_battlefield_new_) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
