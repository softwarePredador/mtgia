WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('boggart harbinger', 'Boggart Harbinger', 'e5f0576f0172323b7e8798a69069199d', 'battle_rule_v1:8ac6a6877f0b44d0ae26c029bb8d1117', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_library_search_to_top_v1","count":1,"destination":"library_top","effect":"creature","etb_tutor_count":1,"etb_tutor_target":"any_to_top","target":"any_to_top","target_subtypes":["goblin"],"trigger":"enters_battlefield","trigger_effect":"library_tutor_to_top","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"SearchLibraryPutOnLibraryEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"any_to_top"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BoggartHarbinger translated into ManaLoom runtime scope xmage_creature_etb_library_search_to_top_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('campus guide', 'Campus Guide', '26846e5bc0ddcbe7957a74e496d92122', 'battle_rule_v1:24ee2f2441cb28108d4b7aa8f39a71a1', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_library_search_to_top_v1","count":1,"destination":"library_top","effect":"creature","etb_tutor_count":1,"etb_tutor_target":"basic_land_to_top","target":"basic_land_to_top","trigger":"enters_battlefield","trigger_effect":"library_tutor_to_top","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"SearchLibraryPutOnLibraryEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"basic_land_to_top"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CampusGuide translated into ManaLoom runtime scope xmage_creature_etb_library_search_to_top_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('compass gnome', 'Compass Gnome', '58fba482e97f4685625e59f26bd9f81b', 'battle_rule_v1:2b5adb3004f8226b1aa0087791143ecc', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_library_search_to_top_v1","count":1,"destination":"library_top","effect":"creature","etb_tutor_count":1,"etb_tutor_target":"basic_land_or_cave_to_top","target":"basic_land_or_cave_to_top","trigger":"enters_battlefield","trigger_effect":"library_tutor_to_top","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"SearchLibraryPutOnLibraryEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"basic_land_or_cave_to_top"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CompassGnome translated into ManaLoom runtime scope xmage_creature_etb_library_search_to_top_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('faerie harbinger', 'Faerie Harbinger', '87cee14f7ca7688e6ac4672bc3c647f5', 'battle_rule_v1:81f3b3a7231902b0adcec03d32c1820c', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_library_search_to_top_v1","count":1,"destination":"library_top","effect":"creature","etb_tutor_count":1,"etb_tutor_target":"any_to_top","flash":true,"flying":true,"keywords":["flash","flying"],"target":"any_to_top","target_subtypes":["faerie"],"trigger":"enters_battlefield","trigger_effect":"library_tutor_to_top","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"SearchLibraryPutOnLibraryEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"any_to_top"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FaerieHarbinger translated into ManaLoom runtime scope xmage_creature_etb_library_search_to_top_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('flamekin harbinger', 'Flamekin Harbinger', '84183e5321971ca284ee29c5b8a26ef1', 'battle_rule_v1:c1678afe69fd7114cfa482cc934c3d4f', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_library_search_to_top_v1","count":1,"destination":"library_top","effect":"creature","etb_tutor_count":1,"etb_tutor_target":"any_to_top","target":"any_to_top","target_subtypes":["elemental"],"trigger":"enters_battlefield","trigger_effect":"library_tutor_to_top","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"SearchLibraryPutOnLibraryEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"any_to_top"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FlamekinHarbinger translated into ManaLoom runtime scope xmage_creature_etb_library_search_to_top_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('giant harbinger', 'Giant Harbinger', 'af5745b1d22887f3db63255a170b92d5', 'battle_rule_v1:222a10f082bfc14fbeba7ccf10884f71', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_library_search_to_top_v1","count":1,"destination":"library_top","effect":"creature","etb_tutor_count":1,"etb_tutor_target":"any_to_top","target":"any_to_top","target_subtypes":["giant"],"trigger":"enters_battlefield","trigger_effect":"library_tutor_to_top","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"SearchLibraryPutOnLibraryEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"any_to_top"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GiantHarbinger translated into ManaLoom runtime scope xmage_creature_etb_library_search_to_top_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('giant ladybug', 'Giant Ladybug', 'd343af3b0c3541b8852d86033512b64d', 'battle_rule_v1:126ee4675a65076a75dd82647a715d20', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_library_search_to_top_v1","count":1,"destination":"library_top","effect":"creature","etb_tutor_count":1,"etb_tutor_target":"basic_land_to_top","keywords":["reach"],"reach":true,"target":"basic_land_to_top","trigger":"enters_battlefield","trigger_effect":"library_tutor_to_top","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"SearchLibraryPutOnLibraryEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"basic_land_to_top"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GiantLadybug translated into ManaLoom runtime scope xmage_creature_etb_library_search_to_top_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('kithkin harbinger', 'Kithkin Harbinger', '9c4bf40f15566d622be1fb3b21a06592', 'battle_rule_v1:d6ecac707233523e08b819dc3628b6ac', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_library_search_to_top_v1","count":1,"destination":"library_top","effect":"creature","etb_tutor_count":1,"etb_tutor_target":"any_to_top","target":"any_to_top","target_subtypes":["kithkin"],"trigger":"enters_battlefield","trigger_effect":"library_tutor_to_top","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"SearchLibraryPutOnLibraryEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"any_to_top"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class KithkinHarbinger translated into ManaLoom runtime scope xmage_creature_etb_library_search_to_top_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('loam larva', 'Loam Larva', '26846e5bc0ddcbe7957a74e496d92122', 'battle_rule_v1:24ee2f2441cb28108d4b7aa8f39a71a1', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_library_search_to_top_v1","count":1,"destination":"library_top","effect":"creature","etb_tutor_count":1,"etb_tutor_target":"basic_land_to_top","target":"basic_land_to_top","trigger":"enters_battlefield","trigger_effect":"library_tutor_to_top","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"SearchLibraryPutOnLibraryEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"basic_land_to_top"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class LoamLarva translated into ManaLoom runtime scope xmage_creature_etb_library_search_to_top_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('scampering surveyor', 'Scampering Surveyor', 'c6ca72b3b7a3634ea5caa3d9b2c4c9a4', 'battle_rule_v1:ca664664ddad191cdf11a5036f2e92b7', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_library_search_to_battlefield_v1","count":1,"destination":"battlefield","effect":"creature","etb_tutor_count":1,"etb_tutor_target":"basic_land_or_cave_to_battlefield","target":"basic_land_or_cave_to_battlefield","trigger":"enters_battlefield","tutor_enters_tapped":true,"xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"SearchLibraryPutInPlayEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"basic_land_or_cave_to_battlefield"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ScamperingSurveyor translated into ManaLoom runtime scope xmage_creature_etb_library_search_to_battlefield_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('spider-bot', 'Spider-Bot', 'd343af3b0c3541b8852d86033512b64d', 'battle_rule_v1:126ee4675a65076a75dd82647a715d20', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_library_search_to_top_v1","count":1,"destination":"library_top","effect":"creature","etb_tutor_count":1,"etb_tutor_target":"basic_land_to_top","keywords":["reach"],"reach":true,"target":"basic_land_to_top","trigger":"enters_battlefield","trigger_effect":"library_tutor_to_top","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"SearchLibraryPutOnLibraryEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"basic_land_to_top"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SpiderBot translated into ManaLoom runtime scope xmage_creature_etb_library_search_to_top_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
