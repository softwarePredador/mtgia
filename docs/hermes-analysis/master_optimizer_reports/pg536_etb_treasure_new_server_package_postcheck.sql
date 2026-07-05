WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('brazen freebooter', 'Brazen Freebooter', '441156232f9960289f037b839d3e9204', 'battle_rule_v1:e81703c8563fb9e3055ce8e50520769f', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_create_treasure_v1","effect":"creature","etb_treasure_count":1,"treasure_count":1,"treasure_recipient":"controller","treasure_trigger":"enters_battlefield","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"TreasureToken"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BrazenFreebooter translated into ManaLoom runtime scope xmage_creature_etb_create_treasure_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('plundering pirate', 'Plundering Pirate', '441156232f9960289f037b839d3e9204', 'battle_rule_v1:e81703c8563fb9e3055ce8e50520769f', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_create_treasure_v1","effect":"creature","etb_treasure_count":1,"treasure_count":1,"treasure_recipient":"controller","treasure_trigger":"enters_battlefield","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"TreasureToken"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PlunderingPirate translated into ManaLoom runtime scope xmage_creature_etb_create_treasure_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('prosperous pirates', 'Prosperous Pirates', 'fc491f26e1bfb3a2b6a271e3a3f85d32', 'battle_rule_v1:a5d6ceeef4a66475945711afc48eab79', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_create_treasure_v1","effect":"creature","etb_treasure_count":2,"treasure_count":2,"treasure_recipient":"controller","treasure_trigger":"enters_battlefield","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"TreasureToken"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ProsperousPirates translated into ManaLoom runtime scope xmage_creature_etb_create_treasure_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('redcap thief', 'Redcap Thief', '441156232f9960289f037b839d3e9204', 'battle_rule_v1:e81703c8563fb9e3055ce8e50520769f', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_create_treasure_v1","effect":"creature","etb_treasure_count":1,"treasure_count":1,"treasure_recipient":"controller","treasure_trigger":"enters_battlefield","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"TreasureToken"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RedcapThief translated into ManaLoom runtime scope xmage_creature_etb_create_treasure_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('sailor of means', 'Sailor of Means', '441156232f9960289f037b839d3e9204', 'battle_rule_v1:e81703c8563fb9e3055ce8e50520769f', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_create_treasure_v1","effect":"creature","etb_treasure_count":1,"treasure_count":1,"treasure_recipient":"controller","treasure_trigger":"enters_battlefield","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"TreasureToken"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SailorOfMeans translated into ManaLoom runtime scope xmage_creature_etb_create_treasure_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('wily goblin', 'Wily Goblin', '441156232f9960289f037b839d3e9204', 'battle_rule_v1:e81703c8563fb9e3055ce8e50520769f', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_create_treasure_v1","effect":"creature","etb_treasure_count":1,"treasure_count":1,"treasure_recipient":"controller","treasure_trigger":"enters_battlefield","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"TreasureToken"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WilyGoblin translated into ManaLoom runtime scope xmage_creature_etb_create_treasure_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg536_etb_treasure_new_server_20260705_232440) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
