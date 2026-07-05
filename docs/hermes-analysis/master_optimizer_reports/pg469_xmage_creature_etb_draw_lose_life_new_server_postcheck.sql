WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('dusk legion zealot', 'Dusk Legion Zealot', '424678d519dbbc2b6e21734c5cd94d02', 'battle_rule_v1:396bda5c20ca8de95b2f7d087b978fb3', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_draw_lose_life_v1","effect":"creature","etb_draw_count":1,"etb_life_loss":1,"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_classes":["DrawCardSourceControllerEffect","LoseLifeSourceControllerEffect"]}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DuskLegionZealot translated into ManaLoom runtime scope xmage_creature_etb_draw_lose_life_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('phyrexian gargantua', 'Phyrexian Gargantua', '3541b0a138e9f3f20acd1c8f9f819aa5', 'battle_rule_v1:37eb20bdc9cefa352fcddc7462be9917', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_draw_lose_life_v1","effect":"creature","etb_draw_count":2,"etb_life_loss":2,"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_classes":["DrawCardSourceControllerEffect","LoseLifeSourceControllerEffect"]}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PhyrexianGargantua translated into ManaLoom runtime scope xmage_creature_etb_draw_lose_life_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('phyrexian rager', 'Phyrexian Rager', '424678d519dbbc2b6e21734c5cd94d02', 'battle_rule_v1:396bda5c20ca8de95b2f7d087b978fb3', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_draw_lose_life_v1","effect":"creature","etb_draw_count":1,"etb_life_loss":1,"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_classes":["DrawCardSourceControllerEffect","LoseLifeSourceControllerEffect"]}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PhyrexianRager translated into ManaLoom runtime scope xmage_creature_etb_draw_lose_life_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('tithebearer giant', 'Tithebearer Giant', '424678d519dbbc2b6e21734c5cd94d02', 'battle_rule_v1:396bda5c20ca8de95b2f7d087b978fb3', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_draw_lose_life_v1","effect":"creature","etb_draw_count":1,"etb_life_loss":1,"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_classes":["DrawCardSourceControllerEffect","LoseLifeSourceControllerEffect"]}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TithebearerGiant translated into ManaLoom runtime scope xmage_creature_etb_draw_lose_life_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg469_xmage_creature_etb_draw_lose_life_new_server_20260) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
