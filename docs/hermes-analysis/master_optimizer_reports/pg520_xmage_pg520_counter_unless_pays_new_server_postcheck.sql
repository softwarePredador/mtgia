WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('convolute', 'Convolute', '28e054de37811a5a6c69c182c2a8133f', 'battle_rule_v1:f19dd7a4fca383cf6666d63219dfc95e', '{"battle_model_scope":"xmage_counter_target_spell_unless_controller_pays_generic_v1","counter_unless_pays_generic":4,"effect":"counter","instant":true,"sorcery":false,"target":"spell","target_constraints":{"stack_object":"spell","zone":"stack"},"xmage_effect_class":"CounterUnlessPaysEffect"}'::jsonb, '{"category":"protection","effect":"counter","target":"spell","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Convolute translated into ManaLoom runtime scope xmage_counter_target_spell_unless_controller_pays_generic_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('force spike', 'Force Spike', 'e980b1e22d76bcc7a902a7bd4494f2c2', 'battle_rule_v1:aa6da9f509ac3ac59eedf048d8c4dfa8', '{"battle_model_scope":"xmage_counter_target_spell_unless_controller_pays_generic_v1","counter_unless_pays_generic":1,"effect":"counter","instant":true,"sorcery":false,"target":"spell","target_constraints":{"stack_object":"spell","zone":"stack"},"xmage_effect_class":"CounterUnlessPaysEffect"}'::jsonb, '{"category":"protection","effect":"counter","target":"spell","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ForceSpike translated into ManaLoom runtime scope xmage_counter_target_spell_unless_controller_pays_generic_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('it''ll quench ya!', 'It''ll Quench Ya!', 'd541d6d83519c2147cb2c08404e238e3', 'battle_rule_v1:3b33285d9ff753c4c630cd7e0b756cd0', '{"battle_model_scope":"xmage_counter_target_spell_unless_controller_pays_generic_v1","counter_unless_pays_generic":2,"effect":"counter","instant":true,"sorcery":false,"target":"spell","target_constraints":{"stack_object":"spell","zone":"stack"},"xmage_effect_class":"CounterUnlessPaysEffect"}'::jsonb, '{"category":"protection","effect":"counter","target":"spell","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ItllQuenchYa translated into ManaLoom runtime scope xmage_counter_target_spell_unless_controller_pays_generic_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('mana tithe', 'Mana Tithe', 'e980b1e22d76bcc7a902a7bd4494f2c2', 'battle_rule_v1:aa6da9f509ac3ac59eedf048d8c4dfa8', '{"battle_model_scope":"xmage_counter_target_spell_unless_controller_pays_generic_v1","counter_unless_pays_generic":1,"effect":"counter","instant":true,"sorcery":false,"target":"spell","target_constraints":{"stack_object":"spell","zone":"stack"},"xmage_effect_class":"CounterUnlessPaysEffect"}'::jsonb, '{"category":"protection","effect":"counter","target":"spell","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ManaTithe translated into ManaLoom runtime scope xmage_counter_target_spell_unless_controller_pays_generic_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('mindstatic', 'Mindstatic', '31d9fa82432680ed5ed8472451543989', 'battle_rule_v1:fd343c6b32cba13d335821c7cb12913f', '{"battle_model_scope":"xmage_counter_target_spell_unless_controller_pays_generic_v1","counter_unless_pays_generic":6,"effect":"counter","instant":true,"sorcery":false,"target":"spell","target_constraints":{"stack_object":"spell","zone":"stack"},"xmage_effect_class":"CounterUnlessPaysEffect"}'::jsonb, '{"category":"protection","effect":"counter","target":"spell","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Mindstatic translated into ManaLoom runtime scope xmage_counter_target_spell_unless_controller_pays_generic_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('quench', 'Quench', 'd541d6d83519c2147cb2c08404e238e3', 'battle_rule_v1:3b33285d9ff753c4c630cd7e0b756cd0', '{"battle_model_scope":"xmage_counter_target_spell_unless_controller_pays_generic_v1","counter_unless_pays_generic":2,"effect":"counter","instant":true,"sorcery":false,"target":"spell","target_constraints":{"stack_object":"spell","zone":"stack"},"xmage_effect_class":"CounterUnlessPaysEffect"}'::jsonb, '{"category":"protection","effect":"counter","target":"spell","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Quench translated into ManaLoom runtime scope xmage_counter_target_spell_unless_controller_pays_generic_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('revolutionary rebuff', 'Revolutionary Rebuff', '4bde1d5613deab8c0f70b20b7d9ab2e7', 'battle_rule_v1:f5b3fcb5be409ce75e90a5bb9838c13d', '{"battle_model_scope":"xmage_counter_target_spell_unless_controller_pays_generic_v1","counter_unless_pays_generic":2,"effect":"counter","instant":true,"sorcery":false,"target":"nonartifact_spell","target_constraints":{"exclude_card_types":["artifact"],"stack_object":"spell","zone":"stack"},"xmage_effect_class":"CounterUnlessPaysEffect"}'::jsonb, '{"category":"protection","effect":"counter","target":"nonartifact_spell","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RevolutionaryRebuff translated into ManaLoom runtime scope xmage_counter_target_spell_unless_controller_pays_generic_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.xmage_pg520_counter_unless_pays_new_serv_20260705_174428) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
