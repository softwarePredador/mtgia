WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('clockwork servant', 'Clockwork Servant', 'ca861e39c30a62d3eaf7f65a059a2708', 'battle_rule_v1:d544333815c26227aa07e8047e88307e', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_draw_cards_v1","effect":"creature","etb_draw_condition":"controller_spent_same_color_mana_to_cast","etb_draw_condition_min_count":3,"etb_draw_condition_status":"runtime_executor_v1","etb_draw_count":1,"trigger":"enters_battlefield","trigger_effect":"draw_cards","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ClockworkServant translated into ManaLoom runtime scope xmage_creature_etb_draw_cards_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('orator of ojutai', 'Orator of Ojutai', '45c82fc30a4987eac847a5d72c4dc388', 'battle_rule_v1:f87475242cdbce13f367c135cf1a428d', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_draw_cards_v1","defender":true,"effect":"creature","etb_draw_condition":"controller_revealed_or_controlled_subtype_as_cast","etb_draw_condition_min_count":1,"etb_draw_condition_status":"runtime_executor_v1","etb_draw_condition_subtypes":["dragon"],"etb_draw_count":1,"flying":true,"keywords":["flying","defender"],"trigger":"enters_battlefield","trigger_effect":"draw_cards","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class OratorOfOjutai translated into ManaLoom runtime scope xmage_creature_etb_draw_cards_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('silkweaver elite', 'Silkweaver Elite', '0d89d103f4e6b4c775f6f849ecdd25d2', 'battle_rule_v1:8ec70b1d50922db2a5db856656a7e9e0', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_draw_cards_v1","effect":"creature","etb_draw_condition":"controller_permanent_left_battlefield_this_turn","etb_draw_condition_min_count":1,"etb_draw_condition_status":"runtime_executor_v1","etb_draw_count":1,"keywords":["reach"],"reach":true,"trigger":"enters_battlefield","trigger_effect":"draw_cards","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SilkweaverElite translated into ManaLoom runtime scope xmage_creature_etb_draw_cards_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('skyship buccaneer', 'Skyship Buccaneer', 'ab721672227a3b87b1b85c751c355dc9', 'battle_rule_v1:5baa008072a02de51142c97732ecc526', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_draw_cards_v1","effect":"creature","etb_draw_condition":"controller_attacked_this_turn","etb_draw_condition_min_count":1,"etb_draw_condition_status":"runtime_executor_v1","etb_draw_count":1,"flying":true,"keywords":["flying"],"trigger":"enters_battlefield","trigger_effect":"draw_cards","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SkyshipBuccaneer translated into ManaLoom runtime scope xmage_creature_etb_draw_cards_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('storm fleet spy', 'Storm Fleet Spy', 'cd69a4bf283b35efca3aab9e8af04da9', 'battle_rule_v1:5cf0a7e83f7388023780e67c5e38f795', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_draw_cards_v1","effect":"creature","etb_draw_condition":"controller_attacked_this_turn","etb_draw_condition_min_count":1,"etb_draw_condition_status":"runtime_executor_v1","etb_draw_count":1,"trigger":"enters_battlefield","trigger_effect":"draw_cards","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class StormFleetSpy translated into ManaLoom runtime scope xmage_creature_etb_draw_cards_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg846_etb_context_draw_new_server_20260712_213929) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
