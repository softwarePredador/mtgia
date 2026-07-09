WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('edgewall pack', 'Edgewall Pack', '271b1e8e3df78b7c426c23200d186581', 'battle_rule_v1:a100e3f3b59c8767819cc6f271052d61', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_create_tokens_v1","effect":"creature","etb_token_cant_block":true,"etb_token_colors":["B"],"etb_token_count":1,"etb_token_name":"Rat Token","etb_token_power":1,"etb_token_static_restrictions":["cant_block"],"etb_token_subtype":"Rat","etb_token_toughness":1,"keywords":["menace"],"menace":true,"token_description":"1/1 black Rat creature token with \"This token can''t block.\"","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"RatCantBlockToken"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class EdgewallPack translated into ManaLoom runtime scope xmage_creature_etb_create_tokens_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('harried spearguard', 'Harried Spearguard', '12922d50039c146f4833110dfadb40de', 'battle_rule_v1:21fecc381b6135d9c2987a722d9a5868', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_create_tokens_v1","dies_token_cant_block":true,"dies_token_colors":["B"],"dies_token_count":1,"dies_token_name":"Rat Token","dies_token_power":1,"dies_token_static_restrictions":["cant_block"],"dies_token_subtype":"Rat","dies_token_toughness":1,"dies_trigger_effect":"token_maker","effect":"creature","haste":true,"keywords":["haste"],"token_description":"1/1 black Rat creature token with \"This token can''t block.\"","trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"RatCantBlockToken"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HarriedSpearguard translated into ManaLoom runtime scope xmage_creature_dies_create_tokens_v1. This row is package-ready only because the source signature is a narrow creature dies triggered fixed creature-token ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('synapse necromage', 'Synapse Necromage', 'dc9f36a669ef827fa3dcd3e941c556a6', 'battle_rule_v1:115a25934705a57f0c1d3b500ab00765', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_create_tokens_v1","dies_token_cant_block":true,"dies_token_colors":["B"],"dies_token_count":2,"dies_token_name":"Fungus Token","dies_token_power":1,"dies_token_static_restrictions":["cant_block"],"dies_token_subtype":"Fungus","dies_token_toughness":1,"dies_trigger_effect":"token_maker","effect":"creature","token_description":"1/1 black Fungus creature token with \"This creature can''t block.\"","trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"FungusCantBlockToken"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SynapseNecromage translated into ManaLoom runtime scope xmage_creature_dies_create_tokens_v1. This row is package-ready only because the source signature is a narrow creature dies triggered fixed creature-token ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg691_token_cant_block_20260709_045133) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
