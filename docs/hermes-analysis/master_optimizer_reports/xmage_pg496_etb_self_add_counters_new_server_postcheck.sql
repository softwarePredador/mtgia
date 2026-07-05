WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('baleful ammit', 'Baleful Ammit', 'c09a6925405dfadf6fdcbc29f162faa6', 'battle_rule_v1:fa0019b8582c157d2c0e32d882b1a652', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_add_counters_target_creature_v1","counter_count":1,"counter_type":"-1/-1","effect":"creature","etb_add_counters_count":1,"etb_add_counters_counter_type":"-1/-1","etb_add_counters_target":"creature","instant":false,"keywords":["lifelink"],"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"controller_scope":"self"},"target_controller":"self","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"AddCountersTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BalefulAmmit translated into ManaLoom runtime scope xmage_creature_etb_add_counters_target_creature_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('crocodile of the crossing', 'Crocodile of the Crossing', 'db20e0c9bc9c5cfe3603529e7968c7f3', 'battle_rule_v1:27465a710750482c623d57ae0d68babe', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_add_counters_target_creature_v1","counter_count":1,"counter_type":"-1/-1","effect":"creature","etb_add_counters_count":1,"etb_add_counters_counter_type":"-1/-1","etb_add_counters_target":"creature","instant":false,"keywords":["haste"],"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"controller_scope":"self"},"target_controller":"self","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"AddCountersTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CrocodileOfTheCrossing translated into ManaLoom runtime scope xmage_creature_etb_add_counters_target_creature_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('kujar seedsculptor', 'Kujar Seedsculptor', 'ecd0af3dae6fd6bbde266c383c072442', 'battle_rule_v1:84b7f8cc323541cbb43e8d82a2c689be', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_add_counters_target_creature_v1","counter_count":1,"counter_type":"+1/+1","effect":"creature","etb_add_counters_count":1,"etb_add_counters_counter_type":"+1/+1","etb_add_counters_target":"creature","instant":false,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"controller_scope":"self"},"target_controller":"self","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"AddCountersTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class KujarSeedsculptor translated into ManaLoom runtime scope xmage_creature_etb_add_counters_target_creature_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('ornery kudu', 'Ornery Kudu', 'bc42575f1a964dd1fc9d804a2fd07ed2', 'battle_rule_v1:2aa3f12b5d8a055e9834bc356b1570c8', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_add_counters_target_creature_v1","counter_count":1,"counter_type":"-1/-1","effect":"creature","etb_add_counters_count":1,"etb_add_counters_counter_type":"-1/-1","etb_add_counters_target":"creature","instant":false,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"controller_scope":"self"},"target_controller":"self","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"AddCountersTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class OrneryKudu translated into ManaLoom runtime scope xmage_creature_etb_add_counters_target_creature_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('teyo''s lightshield', 'Teyo''s Lightshield', 'ecd0af3dae6fd6bbde266c383c072442', 'battle_rule_v1:84b7f8cc323541cbb43e8d82a2c689be', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_add_counters_target_creature_v1","counter_count":1,"counter_type":"+1/+1","effect":"creature","etb_add_counters_count":1,"etb_add_counters_counter_type":"+1/+1","etb_add_counters_target":"creature","instant":false,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"controller_scope":"self"},"target_controller":"self","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"AddCountersTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TeyosLightshield translated into ManaLoom runtime scope xmage_creature_etb_add_counters_target_creature_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.xmage_pg496_etb_self_add_counters_new_se_20260705_090433) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
