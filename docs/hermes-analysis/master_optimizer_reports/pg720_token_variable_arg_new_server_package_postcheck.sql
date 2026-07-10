WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('ant queen', 'Ant Queen', '53a7ae4dd6f6a5ef1c68b5fe980dd44b', 'battle_rule_v1:6c6a795001e21e4f389c32adde4533d0', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"token_maker","activation_cost_colors":["G"],"activation_cost_generic":1,"activation_cost_mana":"{1}{G}","activation_requires_sacrifice":false,"activation_requires_tap":false,"battle_model_scope":"xmage_permanent_simple_activated_create_token_v1","effect":"token_maker","token_colors":["G"],"token_count":1,"token_description":"1/1 green Insect creature token","token_name":"Insect Token","token_power":1,"token_subtype":"Insect","token_toughness":1,"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"InsectToken"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_permanent_simple_activated_create_token_v1","activated_create_token":true,"activated_effect":"token_maker","activation_cost_colors":["G"],"activation_cost_generic":1,"activation_cost_mana":"{1}{G}","activation_requires_sacrifice":false,"activation_requires_tap":false,"battle_model_scope":"xmage_permanent_simple_activated_create_token_v1","effect":"creature","token_colors":["G"],"token_count":1,"token_description":"1/1 green Insect creature token","token_name":"Insect Token","token_power":1,"token_subtype":"Insect","token_toughness":1,"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"InsectToken"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AntQueen translated into ManaLoom runtime scope xmage_permanent_simple_activated_create_token_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated fixed creature-token ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('broodmate dragon', 'Broodmate Dragon', '423b550b931b4696b2288ce547c32449', 'battle_rule_v1:4063c079795837e8b94c581cf24ee0a8', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_create_tokens_v1","effect":"creature","etb_token_colors":["R"],"etb_token_count":1,"etb_token_flying":true,"etb_token_keywords":["flying"],"etb_token_name":"Dragon Token","etb_token_power":4,"etb_token_subtype":"Dragon","etb_token_toughness":4,"flying":true,"keywords":["flying"],"token_description":"4/4 red Dragon creature token with flying","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"DragonToken"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BroodmateDragon translated into ManaLoom runtime scope xmage_creature_etb_create_tokens_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('roc egg', 'Roc Egg', 'c35bfc0f113c1ee5e7539b5d813aec4f', 'battle_rule_v1:5385b7d23648efeaf502bff68b2a7f0b', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_create_tokens_v1","defender":true,"dies_token_colors":["W"],"dies_token_count":1,"dies_token_flying":true,"dies_token_keywords":["flying"],"dies_token_name":"Bird Token","dies_token_power":3,"dies_token_subtype":"Bird","dies_token_toughness":3,"dies_trigger_effect":"token_maker","effect":"creature","keywords":["defender"],"token_description":"3/3 white Bird creature token with flying","trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"RocEggToken"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RocEgg translated into ManaLoom runtime scope xmage_creature_dies_create_tokens_v1. This row is package-ready only because the source signature is a narrow creature dies triggered fixed creature-token ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('sprouting thrinax', 'Sprouting Thrinax', 'ea0c06cc0ad372bf9d662623bfc90f2a', 'battle_rule_v1:302fae4cf3a57e7203c835da45e5b69c', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_create_tokens_v1","dies_token_colors":["G"],"dies_token_count":3,"dies_token_name":"Saproling Token","dies_token_power":1,"dies_token_subtype":"Saproling","dies_token_toughness":1,"dies_trigger_effect":"token_maker","effect":"creature","token_description":"1/1 green Saproling creature token","trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"SaprolingToken"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SproutingThrinax translated into ManaLoom runtime scope xmage_creature_dies_create_tokens_v1. This row is package-ready only because the source signature is a narrow creature dies triggered fixed creature-token ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg720_token_variable_arg_new_server_toke_20260710_203259) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
