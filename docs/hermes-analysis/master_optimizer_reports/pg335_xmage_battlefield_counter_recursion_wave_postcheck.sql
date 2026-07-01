WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('aberrant return', 'Aberrant Return', 'efe3ccf1e525a5312589b212ee754280', 'battle_rule_v1:42745b0cb7d5187b475dffddde020a44', '{"additional_counter":true,"battle_model_scope":"xmage_return_target_graveyard_creature_to_battlefield_with_counter_spell_v1","battlefield_controller":"self","count":3,"counter_amount":1,"counter_type":"-1/-1","destination":"battlefield","effect":"recursion","instant":false,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"],"controller":"any_player","zone":"graveyard"},"target_controller":"any_player","target_count_min":1,"target_graveyard_controller":"any_player","xmage_effect_class":"ReturnFromGraveyardToBattlefieldWithCounterTargetEffect"}'::jsonb, '{"category":"engine","effect":"recursion","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AberrantReturn translated into ManaLoom runtime scope xmage_return_target_graveyard_creature_to_battlefield_with_counter_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('evil reawakened', 'Evil Reawakened', '293caf5db856fc4ee566fd1a8bc2fc83', 'battle_rule_v1:e55d06ea39357c597a59f0f55563dbba', '{"additional_counter":true,"battle_model_scope":"xmage_return_target_graveyard_creature_to_battlefield_with_counter_spell_v1","battlefield_controller":"self","count":1,"counter_amount":2,"counter_type":"+1/+1","destination":"battlefield","effect":"recursion","instant":false,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"],"controller":"self","zone":"graveyard"},"target_controller":"self","target_graveyard_controller":"self","xmage_effect_class":"ReturnFromGraveyardToBattlefieldWithCounterTargetEffect"}'::jsonb, '{"category":"engine","effect":"recursion","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class EvilReawakened translated into ManaLoom runtime scope xmage_return_target_graveyard_creature_to_battlefield_with_counter_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('unbreakable bond', 'Unbreakable Bond', '0247c39c83582e4c135501beeabd2799', 'battle_rule_v1:ef5fffa2825b1b0e56b2b630f8b483ec', '{"battle_model_scope":"xmage_return_target_graveyard_creature_to_battlefield_with_counter_spell_v1","battlefield_controller":"self","count":1,"counter_amount":1,"counter_grants_keywords":["lifelink"],"counter_type":"lifelink","destination":"battlefield","effect":"recursion","instant":false,"keywords":["lifelink"],"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"],"controller":"self","zone":"graveyard"},"target_controller":"self","target_graveyard_controller":"self","xmage_effect_class":"ReturnFromGraveyardToBattlefieldWithCounterTargetEffect"}'::jsonb, '{"category":"engine","effect":"recursion","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class UnbreakableBond translated into ManaLoom runtime scope xmage_return_target_graveyard_creature_to_battlefield_with_counter_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg335_xmage_battlefield_counter_recursion_wave_20260701_) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
