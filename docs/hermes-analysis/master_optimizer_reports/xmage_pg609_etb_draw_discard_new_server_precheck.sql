WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('bazaar trademage', 'Bazaar Trademage', '0a1ea50959fedbabf7f09c82e3ab9123', 'battle_rule_v1:6f175c276cdab1952e05a4e76489ee01', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_draw_discard_cards_v1","discard_count":3,"draw_count":2,"draw_discard_order":"draw_then_discard","effect":"creature","etb_discard_count":3,"etb_draw_count":2,"etb_draw_discard":true,"flying":true,"keywords":["flying"],"trigger":"enters_battlefield","trigger_effect":"draw_discard","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DrawDiscardControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BazaarTrademage translated into ManaLoom runtime scope xmage_creature_etb_draw_discard_cards_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('bellowing crier', 'Bellowing Crier', 'd98cfb952a222f31dbae77593bad4349', 'battle_rule_v1:9b76976677d2fe7bf777fd5cba120e55', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_draw_discard_cards_v1","discard_count":1,"draw_count":1,"draw_discard_order":"draw_then_discard","effect":"creature","etb_discard_count":1,"etb_draw_count":1,"etb_draw_discard":true,"trigger":"enters_battlefield","trigger_effect":"draw_discard","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DrawDiscardControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BellowingCrier translated into ManaLoom runtime scope xmage_creature_etb_draw_discard_cards_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('elite instructor', 'Elite Instructor', 'd98cfb952a222f31dbae77593bad4349', 'battle_rule_v1:9b76976677d2fe7bf777fd5cba120e55', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_draw_discard_cards_v1","discard_count":1,"draw_count":1,"draw_discard_order":"draw_then_discard","effect":"creature","etb_discard_count":1,"etb_draw_count":1,"etb_draw_discard":true,"trigger":"enters_battlefield","trigger_effect":"draw_discard","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DrawDiscardControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class EliteInstructor translated into ManaLoom runtime scope xmage_creature_etb_draw_discard_cards_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('icewind elemental', 'Icewind Elemental', 'd8046b3557308357bd8cd0ab2fcb91f7', 'battle_rule_v1:d868cbde8fd80fcce770a888bf4c2729', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_draw_discard_cards_v1","discard_count":1,"draw_count":1,"draw_discard_order":"draw_then_discard","effect":"creature","etb_discard_count":1,"etb_draw_count":1,"etb_draw_discard":true,"flying":true,"keywords":["flying"],"trigger":"enters_battlefield","trigger_effect":"draw_discard","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DrawDiscardControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class IcewindElemental translated into ManaLoom runtime scope xmage_creature_etb_draw_discard_cards_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('merfolk traders', 'Merfolk Traders', 'd98cfb952a222f31dbae77593bad4349', 'battle_rule_v1:9b76976677d2fe7bf777fd5cba120e55', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_draw_discard_cards_v1","discard_count":1,"draw_count":1,"draw_discard_order":"draw_then_discard","effect":"creature","etb_discard_count":1,"etb_draw_count":1,"etb_draw_discard":true,"trigger":"enters_battlefield","trigger_effect":"draw_discard","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DrawDiscardControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MerfolkTraders translated into ManaLoom runtime scope xmage_creature_etb_draw_discard_cards_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('owl familiar', 'Owl Familiar', 'd8046b3557308357bd8cd0ab2fcb91f7', 'battle_rule_v1:d868cbde8fd80fcce770a888bf4c2729', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_draw_discard_cards_v1","discard_count":1,"draw_count":1,"draw_discard_order":"draw_then_discard","effect":"creature","etb_discard_count":1,"etb_draw_count":1,"etb_draw_discard":true,"flying":true,"keywords":["flying"],"trigger":"enters_battlefield","trigger_effect":"draw_discard","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DrawDiscardControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class OwlFamiliar translated into ManaLoom runtime scope xmage_creature_etb_draw_discard_cards_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('quicksilver fisher', 'Quicksilver Fisher', 'd8046b3557308357bd8cd0ab2fcb91f7', 'battle_rule_v1:d868cbde8fd80fcce770a888bf4c2729', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_draw_discard_cards_v1","discard_count":1,"draw_count":1,"draw_discard_order":"draw_then_discard","effect":"creature","etb_discard_count":1,"etb_draw_count":1,"etb_draw_discard":true,"flying":true,"keywords":["flying"],"trigger":"enters_battlefield","trigger_effect":"draw_discard","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DrawDiscardControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class QuicksilverFisher translated into ManaLoom runtime scope xmage_creature_etb_draw_discard_cards_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('screeching drake', 'Screeching Drake', 'd8046b3557308357bd8cd0ab2fcb91f7', 'battle_rule_v1:d868cbde8fd80fcce770a888bf4c2729', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_draw_discard_cards_v1","discard_count":1,"draw_count":1,"draw_discard_order":"draw_then_discard","effect":"creature","etb_discard_count":1,"etb_draw_count":1,"etb_draw_discard":true,"flying":true,"keywords":["flying"],"trigger":"enters_battlefield","trigger_effect":"draw_discard","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DrawDiscardControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ScreechingDrake translated into ManaLoom runtime scope xmage_creature_etb_draw_discard_cards_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('sky-eel school', 'Sky-Eel School', 'd8046b3557308357bd8cd0ab2fcb91f7', 'battle_rule_v1:d868cbde8fd80fcce770a888bf4c2729', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_draw_discard_cards_v1","discard_count":1,"draw_count":1,"draw_discard_order":"draw_then_discard","effect":"creature","etb_discard_count":1,"etb_draw_count":1,"etb_draw_discard":true,"flying":true,"keywords":["flying"],"trigger":"enters_battlefield","trigger_effect":"draw_discard","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DrawDiscardControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SkyEelSchool translated into ManaLoom runtime scope xmage_creature_etb_draw_discard_cards_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('temur tawnyback', 'Temur Tawnyback', 'd98cfb952a222f31dbae77593bad4349', 'battle_rule_v1:9b76976677d2fe7bf777fd5cba120e55', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_draw_discard_cards_v1","discard_count":1,"draw_count":1,"draw_discard_order":"draw_then_discard","effect":"creature","etb_discard_count":1,"etb_draw_count":1,"etb_draw_discard":true,"trigger":"enters_battlefield","trigger_effect":"draw_discard","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DrawDiscardControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TemurTawnyback translated into ManaLoom runtime scope xmage_creature_etb_draw_discard_cards_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('vodalian merchant', 'Vodalian Merchant', 'd98cfb952a222f31dbae77593bad4349', 'battle_rule_v1:9b76976677d2fe7bf777fd5cba120e55', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_draw_discard_cards_v1","discard_count":1,"draw_count":1,"draw_discard_order":"draw_then_discard","effect":"creature","etb_discard_count":1,"etb_draw_count":1,"etb_draw_discard":true,"trigger":"enters_battlefield","trigger_effect":"draw_discard","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DrawDiscardControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class VodalianMerchant translated into ManaLoom runtime scope xmage_creature_etb_draw_discard_cards_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
