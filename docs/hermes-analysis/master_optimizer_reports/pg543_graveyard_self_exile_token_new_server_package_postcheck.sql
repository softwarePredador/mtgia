WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('eternal student', 'Eternal Student', '5d0d28b33adc1da99013cace22fa94e3', 'battle_rule_v1:14a6c4f3e3b0ff2645919f71c042b467', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"token_maker","activation_cost_colors":["B"],"activation_cost_generic":1,"activation_cost_mana":"{1}{B}","activation_requires_exile_source_from_graveyard":true,"activation_requires_sacrifice":false,"activation_requires_tap":false,"activation_zone":"graveyard","battle_model_scope":"xmage_graveyard_self_exile_activated_create_token_v1","effect":"token_maker","token_colors":["W","B"],"token_count":2,"token_description":"1/1 white and black Inkling creature token with flying","token_flying":true,"token_keywords":["flying"],"token_name":"Inkling Token","token_power":1,"token_subtype":"Inkling","token_toughness":1,"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"Inkling11Token"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_graveyard_self_exile_activated_create_token_v1","activated_create_token":true,"activated_effect":"token_maker","activation_cost_colors":["B"],"activation_cost_generic":1,"activation_cost_mana":"{1}{B}","activation_requires_exile_source_from_graveyard":true,"activation_requires_sacrifice":false,"activation_requires_tap":false,"activation_zone":"graveyard","battle_model_scope":"xmage_graveyard_self_exile_activated_create_token_v1","effect":"creature","token_colors":["W","B"],"token_count":2,"token_description":"1/1 white and black Inkling creature token with flying","token_flying":true,"token_keywords":["flying"],"token_name":"Inkling Token","token_power":1,"token_subtype":"Inkling","token_toughness":1,"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"Inkling11Token"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class EternalStudent translated into ManaLoom runtime scope xmage_graveyard_self_exile_activated_create_token_v1. This row is package-ready only because the source signature is a narrow card with a graveyard self-exile activated fixed creature-token ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('illustrious historian', 'Illustrious Historian', 'fa81074d782e0d0677343f5b38ee6ce4', 'battle_rule_v1:c1687c5ca0cc72d415cd8e171f2436e0', '{"_activated_rule_effects":[{"ability_kind":"activated","activated_effect":"token_maker","activation_cost_colors":[],"activation_cost_generic":5,"activation_cost_mana":"{5}","activation_requires_exile_source_from_graveyard":true,"activation_requires_sacrifice":false,"activation_requires_tap":false,"activation_zone":"graveyard","battle_model_scope":"xmage_graveyard_self_exile_activated_create_token_v1","effect":"token_maker","token_colors":["W","R"],"token_count":1,"token_description":"3/2 red and white Spirit creature token","token_name":"Spirit Token","token_power":3,"token_subtype":"Spirit","token_tapped":true,"token_toughness":2,"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"Spirit32Token"}],"ability_kind":"static_and_activated","activated_battle_model_scope":"xmage_graveyard_self_exile_activated_create_token_v1","activated_create_token":true,"activated_effect":"token_maker","activation_cost_colors":[],"activation_cost_generic":5,"activation_cost_mana":"{5}","activation_requires_exile_source_from_graveyard":true,"activation_requires_sacrifice":false,"activation_requires_tap":false,"activation_zone":"graveyard","battle_model_scope":"xmage_graveyard_self_exile_activated_create_token_v1","effect":"creature","token_colors":["W","R"],"token_count":1,"token_description":"3/2 red and white Spirit creature token","token_name":"Spirit Token","token_power":3,"token_subtype":"Spirit","token_tapped":true,"token_toughness":2,"xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"CreateTokenEffect","xmage_token_class":"Spirit32Token"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class IllustriousHistorian translated into ManaLoom runtime scope xmage_graveyard_self_exile_activated_create_token_v1. This row is package-ready only because the source signature is a narrow card with a graveyard self-exile activated fixed creature-token ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg543_graveyard_self_exile_token_new_ser_20260706_022127) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
