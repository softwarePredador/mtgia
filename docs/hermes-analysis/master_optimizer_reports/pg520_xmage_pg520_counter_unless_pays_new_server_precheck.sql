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
matched_cards AS (
  SELECT
    p.normalized_name,
    p.card_name,
    p.oracle_hash,
    c.id AS card_id,
    c.name AS db_card_name
  FROM proposed p
  LEFT JOIN public.cards c
    ON (
         lower(c.name) = p.normalized_name
         OR split_part(lower(c.name), ' // ', 1) = p.normalized_name
       )
   AND md5(coalesce(c.oracle_text, '')) = p.oracle_hash
),
target_cards AS (
  SELECT
    normalized_name,
    card_name,
    oracle_hash,
    count(card_id) AS target_card_rows,
    min(card_id::text)::uuid AS canonical_card_id,
    min(db_card_name) AS canonical_card_name
  FROM matched_cards
  GROUP BY normalized_name, card_name, oracle_hash
),
rule_rows AS (
  SELECT p.normalized_name, count(r.*) AS existing_rule_rows
  FROM proposed p
  LEFT JOIN public.card_battle_rules r
    ON (
         r.normalized_name = p.normalized_name
         OR r.normalized_name LIKE p.normalized_name || ' // %'
       )
  GROUP BY p.normalized_name
),
expected_rows AS (
  SELECT p.normalized_name, count(r.*) AS expected_rule_rows_before
  FROM proposed p
  LEFT JOIN public.card_battle_rules r
    ON (
         r.normalized_name = p.normalized_name
         OR r.normalized_name LIKE p.normalized_name || ' // %'
       )
   AND r.logical_rule_key = p.logical_rule_key
  GROUP BY p.normalized_name
),
shadow_rows AS (
  SELECT p.normalized_name, count(r.*) AS would_deprecate_shadow_rows
  FROM proposed p
  LEFT JOIN public.card_battle_rules r
    ON (
         r.normalized_name = p.normalized_name
         OR r.normalized_name LIKE p.normalized_name || ' // %'
       )
   AND r.logical_rule_key <> p.logical_rule_key
   AND r.review_status NOT IN ('deprecated', 'rejected')
   AND r.execution_status <> 'disabled'
  GROUP BY p.normalized_name
)
SELECT
  p.card_name,
  p.normalized_name,
  p.oracle_hash,
  p.logical_rule_key,
  p.shadow_handling,
  tc.target_card_rows,
  tc.canonical_card_id,
  rr.existing_rule_rows,
  er.expected_rule_rows_before,
  sr.would_deprecate_shadow_rows
FROM proposed p
JOIN target_cards tc USING (normalized_name, card_name, oracle_hash)
JOIN rule_rows rr USING (normalized_name)
JOIN expected_rows er USING (normalized_name)
JOIN shadow_rows sr USING (normalized_name)
ORDER BY p.card_name;
