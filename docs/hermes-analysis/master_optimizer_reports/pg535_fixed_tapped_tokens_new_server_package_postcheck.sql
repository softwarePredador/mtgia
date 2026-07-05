WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('servo exhibition', 'Servo Exhibition', '986014963b1bb2a9361b04c58130bfca', 'battle_rule_v1:34867bd8005e3b1fb592b3dfb9a585ed', '{"ability_kind":"one_shot","artifact_tokens":true,"battle_model_scope":"xmage_fixed_create_creature_tokens_spell_v1","effect":"token_maker","token_count":2,"token_description":"1/1 colorless Servo artifact creature token","token_name":"Servo Token","token_power":1,"token_subtype":"Servo","token_toughness":1,"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"ServoToken"}'::jsonb, '{"category":"wincon","effect":"token_maker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ServoExhibition translated into ManaLoom runtime scope xmage_fixed_create_creature_tokens_spell_v1. This row is package-ready only because the source signature is a narrow fixed spell-resolution creature-token maker with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('shadow summoning', 'Shadow Summoning', '86865fd932dbac3129e8d1060691bc0d', 'battle_rule_v1:e4509add508bcaf39e79f2811c958b41', '{"ability_kind":"one_shot","battle_model_scope":"xmage_fixed_create_creature_tokens_spell_v1","effect":"token_maker","token_colors":["W"],"token_count":2,"token_description":"1/1 white Spirit creature token with flying","token_flying":true,"token_keywords":["flying"],"token_name":"Spirit Token","token_power":1,"token_subtype":"Spirit","token_tapped":true,"token_toughness":1,"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"SpiritWhiteToken"}'::jsonb, '{"category":"wincon","effect":"token_maker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ShadowSummoning translated into ManaLoom runtime scope xmage_fixed_create_creature_tokens_spell_v1. This row is package-ready only because the source signature is a narrow fixed spell-resolution creature-token maker with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg535_fixed_tapped_tokens_new_server_pg5_20260705_230150) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
