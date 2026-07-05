WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('goblin offensive', 'Goblin Offensive', '300b4b6056f38f415e594aa518f18778', 'battle_rule_v1:6a713f8351226e8111bad92e7ff7d034', '{"ability_kind":"one_shot","battle_model_scope":"xmage_x_create_creature_tokens_spell_v1","effect":"token_maker","token_colors":["R"],"token_count_per_x":1,"token_count_source":"x_value","token_description":"1/1 red Goblin creature token","token_name":"Goblin Token","token_power":1,"token_subtype":"Goblin","token_toughness":1,"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"GoblinToken"}'::jsonb, '{"category":"wincon","effect":"token_maker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GoblinOffensive translated into ManaLoom runtime scope xmage_x_create_creature_tokens_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('secure the wastes', 'Secure the Wastes', 'd89800f207e3f8a98ff4ce1c12d0058e', 'battle_rule_v1:94b58a330606bda3637c52a41a15cf0a', '{"ability_kind":"one_shot","battle_model_scope":"xmage_x_create_creature_tokens_spell_v1","effect":"token_maker","token_colors":["W"],"token_count_per_x":1,"token_count_source":"x_value","token_description":"1/1 white Warrior creature token","token_name":"Warrior Token","token_power":1,"token_subtype":"Warrior","token_toughness":1,"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"WarriorToken"}'::jsonb, '{"category":"wincon","effect":"token_maker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SecureTheWastes translated into ManaLoom runtime scope xmage_x_create_creature_tokens_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.xmage_pg521_x_create_tokens_new_server_p_20260705_180221) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
