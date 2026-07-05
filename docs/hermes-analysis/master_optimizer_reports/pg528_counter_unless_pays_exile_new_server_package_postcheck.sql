WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('no more lies', 'No More Lies', '3c5074858301b944a71cd8254e2d32a9', 'battle_rule_v1:909891bf8700cdfa91cd983ad4e5923b', '{"battle_model_scope":"xmage_counter_target_spell_unless_controller_pays_generic_v1","counter_unless_pays_generic":3,"countered_spell_to_exile":true,"countered_spell_to_exile_reason":"counter_unless_pays_exile_replacement","effect":"counter","instant":true,"sorcery":false,"target":"spell","target_constraints":{"stack_object":"spell","zone":"stack"},"xmage_effect_class":"CounterUnlessPaysEffect"}'::jsonb, '{"category":"protection","effect":"counter","target":"spell","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class NoMoreLies translated into ManaLoom runtime scope xmage_counter_target_spell_unless_controller_pays_generic_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('reject', 'Reject', '2c81d02c83ce79a6c5c8f1b68d944515', 'battle_rule_v1:4cbd233f7190d3b772b7498252402cbc', '{"battle_model_scope":"xmage_counter_target_spell_unless_controller_pays_generic_v1","counter_unless_pays_generic":3,"countered_spell_to_exile":true,"countered_spell_to_exile_reason":"counter_unless_pays_exile_replacement","effect":"counter","instant":true,"sorcery":false,"target":"creature_or_planeswalker_spell","target_constraints":{"card_types":["creature","planeswalker"],"stack_object":"spell","zone":"stack"},"xmage_effect_class":"CounterUnlessPaysEffect"}'::jsonb, '{"category":"protection","effect":"counter","target":"creature_or_planeswalker_spell","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Reject translated into ManaLoom runtime scope xmage_counter_target_spell_unless_controller_pays_generic_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('scatter ray', 'Scatter Ray', '717571524b5db7d31c5bd6b15958ec43', 'battle_rule_v1:e7b82482944f444a554485c286834efc', '{"battle_model_scope":"xmage_counter_target_spell_unless_controller_pays_generic_v1","counter_unless_pays_generic":4,"effect":"counter","instant":true,"sorcery":false,"target":"artifact_or_creature_spell","target_constraints":{"card_types":["artifact","creature"],"stack_object":"spell","zone":"stack"},"xmage_effect_class":"CounterUnlessPaysEffect"}'::jsonb, '{"category":"protection","effect":"counter","target":"artifact_or_creature_spell","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ScatterRay translated into ManaLoom runtime scope xmage_counter_target_spell_unless_controller_pays_generic_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('spectral interference', 'Spectral Interference', '717571524b5db7d31c5bd6b15958ec43', 'battle_rule_v1:e7b82482944f444a554485c286834efc', '{"battle_model_scope":"xmage_counter_target_spell_unless_controller_pays_generic_v1","counter_unless_pays_generic":4,"effect":"counter","instant":true,"sorcery":false,"target":"artifact_or_creature_spell","target_constraints":{"card_types":["artifact","creature"],"stack_object":"spell","zone":"stack"},"xmage_effect_class":"CounterUnlessPaysEffect"}'::jsonb, '{"category":"protection","effect":"counter","target":"artifact_or_creature_spell","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SpectralInterference translated into ManaLoom runtime scope xmage_counter_target_spell_unless_controller_pays_generic_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg528_counter_unless_pays_exile_new_serv_20260705_201753) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
