WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('cloudblazer', 'Cloudblazer', '0c4c46eee1e928181e5ad49e8ebd06df', 'battle_rule_v1:a2e9e3898e7fb57c8271996957f6345a', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_gain_life_draw_cards_v1","draw_count":2,"effect":"creature","etb_draw_count":2,"etb_life_gain_amount":2,"etb_life_gain_draw":true,"etb_trigger_effect":"life_gain_draw","flying":true,"keywords":["flying"],"life_gain_amount":2,"resolution_order":"gain_then_draw","trigger":"enters_battlefield","trigger_effect":"life_gain_draw","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_classes":["GainLifeEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Cloudblazer translated into ManaLoom runtime scope xmage_creature_etb_gain_life_draw_cards_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('elite guardmage', 'Elite Guardmage', 'ec08795757538f182c192e6b5d89754d', 'battle_rule_v1:6029c2bcb98d10e624308c4171f0c6a5', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_gain_life_draw_cards_v1","draw_count":1,"effect":"creature","etb_draw_count":1,"etb_life_gain_amount":3,"etb_life_gain_draw":true,"etb_trigger_effect":"life_gain_draw","flying":true,"keywords":["flying"],"life_gain_amount":3,"resolution_order":"gain_then_draw","trigger":"enters_battlefield","trigger_effect":"life_gain_draw","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_classes":["GainLifeEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class EliteGuardmage translated into ManaLoom runtime scope xmage_creature_etb_gain_life_draw_cards_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('inspiring overseer', 'Inspiring Overseer', 'f439383516b5b053e1620acef32a6636', 'battle_rule_v1:2175e84b8027d2a04b7e0070616cb4bd', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_gain_life_draw_cards_v1","draw_count":1,"effect":"creature","etb_draw_count":1,"etb_life_gain_amount":1,"etb_life_gain_draw":true,"etb_trigger_effect":"life_gain_draw","flying":true,"keywords":["flying"],"life_gain_amount":1,"resolution_order":"gain_then_draw","trigger":"enters_battlefield","trigger_effect":"life_gain_draw","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_classes":["GainLifeEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class InspiringOverseer translated into ManaLoom runtime scope xmage_creature_etb_gain_life_draw_cards_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('priest of ancient lore', 'Priest of Ancient Lore', 'ad803d8b8e94e3d742306497af5eab37', 'battle_rule_v1:9f85f598a9f42c9fa90f7639234aa2aa', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_gain_life_draw_cards_v1","draw_count":1,"effect":"creature","etb_draw_count":1,"etb_life_gain_amount":1,"etb_life_gain_draw":true,"etb_trigger_effect":"life_gain_draw","life_gain_amount":1,"resolution_order":"gain_then_draw","trigger":"enters_battlefield","trigger_effect":"life_gain_draw","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_classes":["GainLifeEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PriestOfAncientLore translated into ManaLoom runtime scope xmage_creature_etb_gain_life_draw_cards_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg793_etb_life_gain_draw_new_server_20260711_232612) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
