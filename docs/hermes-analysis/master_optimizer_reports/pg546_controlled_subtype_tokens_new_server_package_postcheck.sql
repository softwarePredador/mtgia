WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('elven ambush', 'Elven Ambush', '6847122917f5971195b6e688be719fe6', 'battle_rule_v1:f23c570fb19e052cecaff60afccd357e', '{"ability_kind":"one_shot","battle_model_scope":"xmage_controlled_subtype_create_creature_tokens_spell_v1","effect":"token_maker","token_colors":["G"],"token_count_source":"controlled_permanents_with_subtype","token_count_subtype":"Elf","token_description":"1/1 green Elf Warrior creature token","token_name":"Elf Warrior Token","token_power":1,"token_subtype":"Elf Warrior","token_toughness":1,"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"ElfWarriorToken"}'::jsonb, '{"category":"wincon","effect":"token_maker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ElvenAmbush translated into ManaLoom runtime scope xmage_controlled_subtype_create_creature_tokens_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('elvish promenade', 'Elvish Promenade', '6847122917f5971195b6e688be719fe6', 'battle_rule_v1:f23c570fb19e052cecaff60afccd357e', '{"ability_kind":"one_shot","battle_model_scope":"xmage_controlled_subtype_create_creature_tokens_spell_v1","effect":"token_maker","token_colors":["G"],"token_count_source":"controlled_permanents_with_subtype","token_count_subtype":"Elf","token_description":"1/1 green Elf Warrior creature token","token_name":"Elf Warrior Token","token_power":1,"token_subtype":"Elf Warrior","token_toughness":1,"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"ElfWarriorToken"}'::jsonb, '{"category":"wincon","effect":"token_maker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ElvishPromenade translated into ManaLoom runtime scope xmage_controlled_subtype_create_creature_tokens_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg546_controlled_subtype_tokens_new_serv_20260706_031919) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
