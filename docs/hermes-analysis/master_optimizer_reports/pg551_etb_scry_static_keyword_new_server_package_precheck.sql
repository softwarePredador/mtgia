WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('augury owl', 'Augury Owl', 'b7c450e1cc1c7574009f6120b406d00f', 'battle_rule_v1:575ffe521a678ebd6048179921e143c4', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_scry_v1","effect":"creature","etb_scry_count":3,"etb_trigger_effect":"scry","flying":true,"keywords":["flying"],"scry_count":3,"trigger":"enters_battlefield","trigger_effect":"scry","trigger_scry_count":3,"xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ScryEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AuguryOwl translated into ManaLoom runtime scope xmage_creature_etb_scry_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('cloudreader sphinx', 'Cloudreader Sphinx', '68d074a48c8f785d82b12014eb8b3f41', 'battle_rule_v1:8c424968cc1906699fad2ba5866d5ef7', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_scry_v1","effect":"creature","etb_scry_count":2,"etb_trigger_effect":"scry","flying":true,"keywords":["flying"],"scry_count":2,"trigger":"enters_battlefield","trigger_effect":"scry","trigger_scry_count":2,"xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ScryEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CloudreaderSphinx translated into ManaLoom runtime scope xmage_creature_etb_scry_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('faerie seer', 'Faerie Seer', '68d074a48c8f785d82b12014eb8b3f41', 'battle_rule_v1:8c424968cc1906699fad2ba5866d5ef7', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_scry_v1","effect":"creature","etb_scry_count":2,"etb_trigger_effect":"scry","flying":true,"keywords":["flying"],"scry_count":2,"trigger":"enters_battlefield","trigger_effect":"scry","trigger_scry_count":2,"xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ScryEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FaerieSeer translated into ManaLoom runtime scope xmage_creature_etb_scry_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('glider kids', 'Glider Kids', 'ad26d1495915babc0e86243a49761178', 'battle_rule_v1:83bb17942e6f86ca784d1785783c02f8', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_scry_v1","effect":"creature","etb_scry_count":1,"etb_trigger_effect":"scry","flying":true,"keywords":["flying"],"scry_count":1,"trigger":"enters_battlefield","trigger_effect":"scry","trigger_scry_count":1,"xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ScryEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GliderKids translated into ManaLoom runtime scope xmage_creature_etb_scry_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('grey havens navigator', 'Grey Havens Navigator', '3446d3cb3c4454d8bcaef4afb24a03aa', 'battle_rule_v1:13d75d87933e5b87f6584ce7d870f88b', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_scry_v1","effect":"creature","etb_scry_count":1,"etb_trigger_effect":"scry","flash":true,"keywords":["flash"],"scry_count":1,"trigger":"enters_battlefield","trigger_effect":"scry","trigger_scry_count":1,"xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ScryEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GreyHavensNavigator translated into ManaLoom runtime scope xmage_creature_etb_scry_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('horizon scholar', 'Horizon Scholar', '68d074a48c8f785d82b12014eb8b3f41', 'battle_rule_v1:8c424968cc1906699fad2ba5866d5ef7', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_scry_v1","effect":"creature","etb_scry_count":2,"etb_trigger_effect":"scry","flying":true,"keywords":["flying"],"scry_count":2,"trigger":"enters_battlefield","trigger_effect":"scry","trigger_scry_count":2,"xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ScryEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HorizonScholar translated into ManaLoom runtime scope xmage_creature_etb_scry_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('senate griffin', 'Senate Griffin', '6d564a66429df23676e0a2d72d667473', 'battle_rule_v1:83bb17942e6f86ca784d1785783c02f8', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_scry_v1","effect":"creature","etb_scry_count":1,"etb_trigger_effect":"scry","flying":true,"keywords":["flying"],"scry_count":1,"trigger":"enters_battlefield","trigger_effect":"scry","trigger_scry_count":1,"xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ScryEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SenateGriffin translated into ManaLoom runtime scope xmage_creature_etb_scry_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('silver raven', 'Silver Raven', 'd70888b658f8ccdbcf9730d995915e7b', 'battle_rule_v1:83bb17942e6f86ca784d1785783c02f8', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_scry_v1","effect":"creature","etb_scry_count":1,"etb_trigger_effect":"scry","flying":true,"keywords":["flying"],"scry_count":1,"trigger":"enters_battlefield","trigger_effect":"scry","trigger_scry_count":1,"xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ScryEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SilverRaven translated into ManaLoom runtime scope xmage_creature_etb_scry_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('thaumaturge''s familiar', 'Thaumaturge''s Familiar', '6d564a66429df23676e0a2d72d667473', 'battle_rule_v1:83bb17942e6f86ca784d1785783c02f8', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_scry_v1","effect":"creature","etb_scry_count":1,"etb_trigger_effect":"scry","flying":true,"keywords":["flying"],"scry_count":1,"trigger":"enters_battlefield","trigger_effect":"scry","trigger_scry_count":1,"xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ScryEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ThaumaturgesFamiliar translated into ManaLoom runtime scope xmage_creature_etb_scry_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('wall of runes', 'Wall of Runes', 'd3d9386b475168e08a8a86ad8f75d8a2', 'battle_rule_v1:f02e41ac1bd0430218b795975f29fb9d', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_scry_v1","defender":true,"effect":"creature","etb_scry_count":1,"etb_trigger_effect":"scry","keywords":["defender"],"scry_count":1,"trigger":"enters_battlefield","trigger_effect":"scry","trigger_scry_count":1,"xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ScryEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WallOfRunes translated into ManaLoom runtime scope xmage_creature_etb_scry_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('willow-wind', 'Willow-Wind', 'e50f14b80485abf7b731a36129db45f4', 'battle_rule_v1:8c424968cc1906699fad2ba5866d5ef7', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_scry_v1","effect":"creature","etb_scry_count":2,"etb_trigger_effect":"scry","flying":true,"keywords":["flying"],"scry_count":2,"trigger":"enters_battlefield","trigger_effect":"scry","trigger_scry_count":2,"xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ScryEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WillowWind translated into ManaLoom runtime scope xmage_creature_etb_scry_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
