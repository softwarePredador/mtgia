WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('disallow', 'Disallow', 'dab97474ff3f3f0c35c8a01c3841de37', 'battle_rule_v1:5072c4680123be4302b45c3d15980230', '{"battle_model_scope":"xmage_counter_target_spell_v1","effect":"counter","instant":true,"sorcery":false,"target":"spell_or_activated_or_triggered_ability","target_constraints":{"any_of":[{"stack_object":"spell"},{"stack_object":"activated_ability"},{"stack_object":"triggered_ability"}],"zone":"stack"},"xmage_effect_class":"CounterTargetEffect"}'::jsonb, '{"category":"protection","effect":"counter","target":"spell_or_activated_or_triggered_ability","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Disallow translated into ManaLoom runtime scope xmage_counter_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('stern scolding', 'Stern Scolding', 'f26dd82537e6e5c9206d47a50fa691c3', 'battle_rule_v1:5286b6c6a626a88c60e657c46eef1105', '{"battle_model_scope":"xmage_counter_target_spell_v1","effect":"counter","instant":true,"sorcery":false,"target":"creature_spell_power_or_toughness_2_or_less","target_constraints":{"card_types":["creature"],"power_or_toughness_max":2,"stack_object":"spell","zone":"stack"},"xmage_effect_class":"CounterTargetEffect"}'::jsonb, '{"category":"protection","effect":"counter","target":"creature_spell_power_or_toughness_2_or_less","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SternScolding translated into ManaLoom runtime scope xmage_counter_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('tale''s end', 'Tale''s End', '1347d000d1e4acf8d2675e1ed216b6f7', 'battle_rule_v1:f70b57cccbd61a55ec60298342a6613c', '{"battle_model_scope":"xmage_counter_target_spell_v1","effect":"counter","instant":true,"sorcery":false,"target":"activated_or_triggered_ability_or_legendary_spell","target_constraints":{"any_of":[{"stack_object":"activated_ability"},{"stack_object":"triggered_ability"},{"require_legendary":true,"stack_object":"spell"}],"zone":"stack"},"xmage_effect_class":"CounterTargetEffect"}'::jsonb, '{"category":"protection","effect":"counter","target":"activated_or_triggered_ability_or_legendary_spell","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TalesEnd translated into ManaLoom runtime scope xmage_counter_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('voidslime', 'Voidslime', 'dab97474ff3f3f0c35c8a01c3841de37', 'battle_rule_v1:5072c4680123be4302b45c3d15980230', '{"battle_model_scope":"xmage_counter_target_spell_v1","effect":"counter","instant":true,"sorcery":false,"target":"spell_or_activated_or_triggered_ability","target_constraints":{"any_of":[{"stack_object":"spell"},{"stack_object":"activated_ability"},{"stack_object":"triggered_ability"}],"zone":"stack"},"xmage_effect_class":"CounterTargetEffect"}'::jsonb, '{"category":"protection","effect":"counter","target":"spell_or_activated_or_triggered_ability","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Voidslime translated into ManaLoom runtime scope xmage_counter_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg642_counter_stack_object_targets_new_s_20260707_213839) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
