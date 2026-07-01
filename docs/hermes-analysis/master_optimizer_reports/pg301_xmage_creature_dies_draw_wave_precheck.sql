WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('aven fisher', 'Aven Fisher', '35358c6326c79dff970e9334ec8c9fc7', 'battle_rule_v1:561fedc0b7c3a796f8a3426d6f0a7880', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_draw_cards_v1","dies_draw_optional":true,"draw_cards_when_this_dies":1,"effect":"creature","flying":true,"keywords":["flying"],"trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AvenFisher translated into ManaLoom runtime scope xmage_creature_dies_draw_cards_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('buzz bots', 'Buzz Bots', '36f0097c0400d7b90626ea3f2f801a9c', 'battle_rule_v1:addae1873b8bafa674aa0afff1ada67c', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_draw_cards_v1","draw_cards_when_this_dies":1,"effect":"creature","flying":true,"keywords":["flying","vigilance"],"trigger":"dies","vigilance":true,"xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BuzzBots translated into ManaLoom runtime scope xmage_creature_dies_draw_cards_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('darkslick drake', 'Darkslick Drake', 'd94cef7f36b0d7157e06c077abb1e2be', 'battle_rule_v1:78e122775d9a4b686877fa187b753bcf', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_draw_cards_v1","draw_cards_when_this_dies":1,"effect":"creature","flying":true,"keywords":["flying"],"trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DarkslickDrake translated into ManaLoom runtime scope xmage_creature_dies_draw_cards_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('exultant cultist', 'Exultant Cultist', 'fb092a7e7ac7389ff02bf4b417932b5f', 'battle_rule_v1:65cc6b89128097ecf46cac9de6ac6a0d', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_draw_cards_v1","draw_cards_when_this_dies":1,"effect":"creature","trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ExultantCultist translated into ManaLoom runtime scope xmage_creature_dies_draw_cards_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('feral prowler', 'Feral Prowler', 'fb092a7e7ac7389ff02bf4b417932b5f', 'battle_rule_v1:65cc6b89128097ecf46cac9de6ac6a0d', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_draw_cards_v1","draw_cards_when_this_dies":1,"effect":"creature","trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FeralProwler translated into ManaLoom runtime scope xmage_creature_dies_draw_cards_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('ithilien kingfisher', 'Ithilien Kingfisher', 'd94cef7f36b0d7157e06c077abb1e2be', 'battle_rule_v1:78e122775d9a4b686877fa187b753bcf', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_draw_cards_v1","draw_cards_when_this_dies":1,"effect":"creature","flying":true,"keywords":["flying"],"trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class IthilienKingfisher translated into ManaLoom runtime scope xmage_creature_dies_draw_cards_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('kingfisher', 'Kingfisher', 'd94cef7f36b0d7157e06c077abb1e2be', 'battle_rule_v1:78e122775d9a4b686877fa187b753bcf', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_draw_cards_v1","draw_cards_when_this_dies":1,"effect":"creature","flying":true,"keywords":["flying"],"trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Kingfisher translated into ManaLoom runtime scope xmage_creature_dies_draw_cards_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('malcator''s watcher', 'Malcator''s Watcher', '36f0097c0400d7b90626ea3f2f801a9c', 'battle_rule_v1:addae1873b8bafa674aa0afff1ada67c', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_draw_cards_v1","draw_cards_when_this_dies":1,"effect":"creature","flying":true,"keywords":["flying","vigilance"],"trigger":"dies","vigilance":true,"xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MalcatorsWatcher translated into ManaLoom runtime scope xmage_creature_dies_draw_cards_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('messenger drake', 'Messenger Drake', 'd94cef7f36b0d7157e06c077abb1e2be', 'battle_rule_v1:78e122775d9a4b686877fa187b753bcf', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_draw_cards_v1","draw_cards_when_this_dies":1,"effect":"creature","flying":true,"keywords":["flying"],"trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MessengerDrake translated into ManaLoom runtime scope xmage_creature_dies_draw_cards_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('oculus', 'Oculus', '6b50ed9a786cc4c6a67a39958cde14d5', 'battle_rule_v1:baf5208731a47caf902b797a4015f6c1', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_draw_cards_v1","dies_draw_optional":true,"draw_cards_when_this_dies":1,"effect":"creature","trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Oculus translated into ManaLoom runtime scope xmage_creature_dies_draw_cards_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('outlaw medic', 'Outlaw Medic', '5222cfc1c97ff774bd7ae4c29facbcb9', 'battle_rule_v1:a1716618c3327adc32eff035e108b562', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_draw_cards_v1","draw_cards_when_this_dies":1,"effect":"creature","keywords":["lifelink"],"lifelink":true,"trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class OutlawMedic translated into ManaLoom runtime scope xmage_creature_dies_draw_cards_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('palace familiar', 'Palace Familiar', 'd94cef7f36b0d7157e06c077abb1e2be', 'battle_rule_v1:78e122775d9a4b686877fa187b753bcf', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_draw_cards_v1","draw_cards_when_this_dies":1,"effect":"creature","flying":true,"keywords":["flying"],"trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PalaceFamiliar translated into ManaLoom runtime scope xmage_creature_dies_draw_cards_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('purple-crystal crab', 'Purple-Crystal Crab', 'fb092a7e7ac7389ff02bf4b417932b5f', 'battle_rule_v1:65cc6b89128097ecf46cac9de6ac6a0d', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_draw_cards_v1","draw_cards_when_this_dies":1,"effect":"creature","trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PurpleCrystalCrab translated into ManaLoom runtime scope xmage_creature_dies_draw_cards_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('riptide crab', 'Riptide Crab', '2280fa92174caef69c202572ea704e5d', 'battle_rule_v1:e5a56c6f641c9b74b02fdbdcdedd2a09', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_draw_cards_v1","draw_cards_when_this_dies":1,"effect":"creature","keywords":["vigilance"],"trigger":"dies","vigilance":true,"xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RiptideCrab translated into ManaLoom runtime scope xmage_creature_dies_draw_cards_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('runewing', 'Runewing', 'd94cef7f36b0d7157e06c077abb1e2be', 'battle_rule_v1:371517171c3c8e8acf8a1361cfa159a0', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_draw_cards_v1","defender":true,"draw_cards_when_this_dies":1,"effect":"creature","flying":true,"keywords":["flying","defender"],"trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Runewing translated into ManaLoom runtime scope xmage_creature_dies_draw_cards_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('silverback shaman', 'Silverback Shaman', 'b45dc07e5871f7dba2ae764dfb4247b1', 'battle_rule_v1:a99f0e46cabe2435deed0a78680e6169', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_draw_cards_v1","draw_cards_when_this_dies":1,"effect":"creature","keywords":["trample"],"trample":true,"trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SilverbackShaman translated into ManaLoom runtime scope xmage_creature_dies_draw_cards_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('spore crawler', 'Spore Crawler', 'fb092a7e7ac7389ff02bf4b417932b5f', 'battle_rule_v1:65cc6b89128097ecf46cac9de6ac6a0d', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_draw_cards_v1","draw_cards_when_this_dies":1,"effect":"creature","trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SporeCrawler translated into ManaLoom runtime scope xmage_creature_dies_draw_cards_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('summit sentinel', 'Summit Sentinel', 'fb092a7e7ac7389ff02bf4b417932b5f', 'battle_rule_v1:65cc6b89128097ecf46cac9de6ac6a0d', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_draw_cards_v1","draw_cards_when_this_dies":1,"effect":"creature","trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SummitSentinel translated into ManaLoom runtime scope xmage_creature_dies_draw_cards_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('surveilling sprite', 'Surveilling Sprite', '9337d0e3a5e0c18a935780ff11d2fd75', 'battle_rule_v1:561fedc0b7c3a796f8a3426d6f0a7880', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_draw_cards_v1","dies_draw_optional":true,"draw_cards_when_this_dies":1,"effect":"creature","flying":true,"keywords":["flying"],"trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SurveillingSprite translated into ManaLoom runtime scope xmage_creature_dies_draw_cards_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('youthful scholar', 'Youthful Scholar', 'c5a00d45e9edfaf008a133c55fea3f24', 'battle_rule_v1:0e16e994fbe4555f04230a5cd25e40d8', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_draw_cards_v1","draw_cards_when_this_dies":2,"effect":"creature","trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class YouthfulScholar translated into ManaLoom runtime scope xmage_creature_dies_draw_cards_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
