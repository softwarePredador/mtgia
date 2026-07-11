WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('donatello, turtle techie', 'Donatello, Turtle Techie', 'eda48af85c5a2d0650124fee42bc6db7', 'battle_rule_v1:1aad34391a400d2e31b1d03c367eab8b', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_draw_cards_v1","effect":"creature","etb_draw_condition":"controller_controls_matching_permanent","etb_draw_condition_card_types":["artifact"],"etb_draw_condition_min_count":1,"etb_draw_condition_status":"runtime_executor_v1","etb_draw_count":1,"trigger":"enters_battlefield","trigger_effect":"draw_cards","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DonatelloTurtleTechie translated into ManaLoom runtime scope xmage_creature_etb_draw_cards_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('opal lake gatekeepers', 'Opal Lake Gatekeepers', 'de09ec948a338bab499e6c6b39445b73', 'battle_rule_v1:2bb5212efd94973b17869d451eb3b392', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_draw_cards_v1","effect":"creature","etb_draw_condition":"controller_controls_matching_permanent","etb_draw_condition_min_count":2,"etb_draw_condition_status":"runtime_executor_v1","etb_draw_condition_subtypes":["gate"],"etb_draw_count":1,"etb_draw_optional":true,"trigger":"enters_battlefield","trigger_effect":"draw_cards","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class OpalLakeGatekeepers translated into ManaLoom runtime scope xmage_creature_etb_draw_cards_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('resistance squad', 'Resistance Squad', '8b3c1ca7c447f3805edf9378bc24ad85', 'battle_rule_v1:a0d576366fc549ff6443caf99a1da039', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_draw_cards_v1","effect":"creature","etb_draw_condition":"controller_controls_matching_permanent","etb_draw_condition_exclude_source":true,"etb_draw_condition_min_count":1,"etb_draw_condition_status":"runtime_executor_v1","etb_draw_condition_subtypes":["human"],"etb_draw_count":1,"trigger":"enters_battlefield","trigger_effect":"draw_cards","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ResistanceSquad translated into ManaLoom runtime scope xmage_creature_etb_draw_cards_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('rhox meditant', 'Rhox Meditant', '3cff932a1bf7c11de356754ab1633d37', 'battle_rule_v1:f0c2ed710efb1593ae4104b739f7dde9', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_draw_cards_v1","effect":"creature","etb_draw_condition":"controller_controls_matching_permanent","etb_draw_condition_colors":["green"],"etb_draw_condition_min_count":1,"etb_draw_condition_status":"runtime_executor_v1","etb_draw_count":1,"trigger":"enters_battlefield","trigger_effect":"draw_cards","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RhoxMeditant translated into ManaLoom runtime scope xmage_creature_etb_draw_cards_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('scholar of stars', 'Scholar of Stars', 'aaa80647de08038783b0262987df6cd6', 'battle_rule_v1:1aad34391a400d2e31b1d03c367eab8b', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_draw_cards_v1","effect":"creature","etb_draw_condition":"controller_controls_matching_permanent","etb_draw_condition_card_types":["artifact"],"etb_draw_condition_min_count":1,"etb_draw_condition_status":"runtime_executor_v1","etb_draw_count":1,"trigger":"enters_battlefield","trigger_effect":"draw_cards","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ScholarOfStars translated into ManaLoom runtime scope xmage_creature_etb_draw_cards_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('settlement blacksmith', 'Settlement Blacksmith', 'c1650f7bacfb0f78846e1cffce33d7e8', 'battle_rule_v1:e1dbd39a50c39509f45c6daa06064062', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_draw_cards_v1","effect":"creature","etb_draw_condition":"controller_controls_matching_permanent","etb_draw_condition_min_count":1,"etb_draw_condition_status":"runtime_executor_v1","etb_draw_condition_subtypes":["equipment"],"etb_draw_count":1,"trigger":"enters_battlefield","trigger_effect":"draw_cards","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SettlementBlacksmith translated into ManaLoom runtime scope xmage_creature_etb_draw_cards_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
