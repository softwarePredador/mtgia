WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('morgue theft', 'Morgue Theft', '3482d9adceeb393bac3d82c542d2c3ea', 'battle_rule_v1:7ef10090331d934746bc0b9c4c3a2deb', '{"battle_model_scope":"xmage_return_target_graveyard_card_to_hand_spell_v1","count":1,"destination":"hand","effect":"recursion","flashback_cost":"{4}{B}","flashback_status":"runtime_executor_v1","instant":false,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"],"controller":"self","zone":"graveyard"},"target_controller":"self","xmage_auxiliary_ability_classes":["FlashbackAbility"],"xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"engine","effect":"recursion","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MorgueTheft translated into ManaLoom runtime scope xmage_return_target_graveyard_card_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('mystic retrieval', 'Mystic Retrieval', 'cdfb79bdce61ab9ea33e9f56c12b830e', 'battle_rule_v1:f10e702e2b0f82cc8f5b443aef4060bb', '{"battle_model_scope":"xmage_return_target_graveyard_card_to_hand_spell_v1","count":1,"destination":"hand","effect":"recursion","flashback_cost":"{2}{R}","flashback_status":"runtime_executor_v1","instant":false,"sorcery":true,"target":"instant_or_sorcery","target_constraints":{"card_types":["instant","sorcery"],"controller":"self","zone":"graveyard"},"target_controller":"self","xmage_auxiliary_ability_classes":["FlashbackAbility"],"xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"engine","effect":"recursion","target":"instant_or_sorcery"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MysticRetrieval translated into ManaLoom runtime scope xmage_return_target_graveyard_card_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('unburial rites', 'Unburial Rites', '5c5464700efd3b715041490ae1e569a9', 'battle_rule_v1:3fcbbe9325bf4d5f05deabc46c9e6e5a', '{"battle_model_scope":"xmage_return_target_graveyard_card_to_battlefield_spell_v1","battlefield_controller":"self","count":1,"destination":"battlefield","effect":"recursion","flashback_cost":"{3}{W}","flashback_status":"runtime_executor_v1","instant":false,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"],"controller":"self","zone":"graveyard"},"target_controller":"self","target_graveyard_controller":"self","xmage_auxiliary_ability_classes":["FlashbackAbility"],"xmage_effect_class":"ReturnFromGraveyardToBattlefieldTargetEffect"}'::jsonb, '{"category":"engine","effect":"recursion","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class UnburialRites translated into ManaLoom runtime scope xmage_return_target_graveyard_card_to_battlefield_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('unearth', 'Unearth', 'c2d298f74835191e93848bb784b2985c', 'battle_rule_v1:efd07ef68567702f9ddf63eaceaea872', '{"battle_model_scope":"xmage_return_target_graveyard_card_to_battlefield_spell_v1","battlefield_controller":"self","count":1,"cycling_cost":"{2}","cycling_status":"runtime_executor_v1","destination":"battlefield","effect":"recursion","instant":false,"recursion_mana_value_max":3,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"],"controller":"self","mana_value_max":3,"zone":"graveyard"},"target_controller":"self","target_graveyard_controller":"self","xmage_auxiliary_ability_classes":["CyclingAbility"],"xmage_effect_class":"ReturnFromGraveyardToBattlefieldTargetEffect"}'::jsonb, '{"category":"engine","effect":"recursion","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Unearth translated into ManaLoom runtime scope xmage_return_target_graveyard_card_to_battlefield_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('wander in death', 'Wander in Death', 'c2b6b8df32f9cb2987c9b81a14629e97', 'battle_rule_v1:76aa1102386b493fec63d732eba4e344', '{"battle_model_scope":"xmage_return_target_graveyard_card_to_hand_spell_v1","count":2,"cycling_cost":"{2}","cycling_status":"runtime_executor_v1","destination":"hand","effect":"recursion","instant":false,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"],"controller":"self","zone":"graveyard"},"target_controller":"self","up_to_count":true,"xmage_auxiliary_ability_classes":["CyclingAbility"],"xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"engine","effect":"recursion","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WanderInDeath translated into ManaLoom runtime scope xmage_return_target_graveyard_card_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg341_xmage_recursion_auxiliary_spell_wave_20260702_0037) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
