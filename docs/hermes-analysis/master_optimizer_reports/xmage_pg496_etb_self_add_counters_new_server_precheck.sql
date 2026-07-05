WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('baleful ammit', 'Baleful Ammit', 'c09a6925405dfadf6fdcbc29f162faa6', 'battle_rule_v1:fa0019b8582c157d2c0e32d882b1a652', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_add_counters_target_creature_v1","counter_count":1,"counter_type":"-1/-1","effect":"creature","etb_add_counters_count":1,"etb_add_counters_counter_type":"-1/-1","etb_add_counters_target":"creature","instant":false,"keywords":["lifelink"],"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"controller_scope":"self"},"target_controller":"self","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"AddCountersTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BalefulAmmit translated into ManaLoom runtime scope xmage_creature_etb_add_counters_target_creature_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('crocodile of the crossing', 'Crocodile of the Crossing', 'db20e0c9bc9c5cfe3603529e7968c7f3', 'battle_rule_v1:27465a710750482c623d57ae0d68babe', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_add_counters_target_creature_v1","counter_count":1,"counter_type":"-1/-1","effect":"creature","etb_add_counters_count":1,"etb_add_counters_counter_type":"-1/-1","etb_add_counters_target":"creature","instant":false,"keywords":["haste"],"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"controller_scope":"self"},"target_controller":"self","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"AddCountersTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CrocodileOfTheCrossing translated into ManaLoom runtime scope xmage_creature_etb_add_counters_target_creature_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('kujar seedsculptor', 'Kujar Seedsculptor', 'ecd0af3dae6fd6bbde266c383c072442', 'battle_rule_v1:84b7f8cc323541cbb43e8d82a2c689be', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_add_counters_target_creature_v1","counter_count":1,"counter_type":"+1/+1","effect":"creature","etb_add_counters_count":1,"etb_add_counters_counter_type":"+1/+1","etb_add_counters_target":"creature","instant":false,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"controller_scope":"self"},"target_controller":"self","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"AddCountersTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class KujarSeedsculptor translated into ManaLoom runtime scope xmage_creature_etb_add_counters_target_creature_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('ornery kudu', 'Ornery Kudu', 'bc42575f1a964dd1fc9d804a2fd07ed2', 'battle_rule_v1:2aa3f12b5d8a055e9834bc356b1570c8', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_add_counters_target_creature_v1","counter_count":1,"counter_type":"-1/-1","effect":"creature","etb_add_counters_count":1,"etb_add_counters_counter_type":"-1/-1","etb_add_counters_target":"creature","instant":false,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"controller_scope":"self"},"target_controller":"self","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"AddCountersTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class OrneryKudu translated into ManaLoom runtime scope xmage_creature_etb_add_counters_target_creature_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('teyo''s lightshield', 'Teyo''s Lightshield', 'ecd0af3dae6fd6bbde266c383c072442', 'battle_rule_v1:84b7f8cc323541cbb43e8d82a2c689be', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_add_counters_target_creature_v1","counter_count":1,"counter_type":"+1/+1","effect":"creature","etb_add_counters_count":1,"etb_add_counters_counter_type":"+1/+1","etb_add_counters_target":"creature","instant":false,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"controller_scope":"self"},"target_controller":"self","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"AddCountersTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TeyosLightshield translated into ManaLoom runtime scope xmage_creature_etb_add_counters_target_creature_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
