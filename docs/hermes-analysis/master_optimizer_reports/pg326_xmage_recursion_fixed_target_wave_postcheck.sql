WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('boggart birth rite', 'Boggart Birth Rite', '433b473e3b4d788495487cdaccc58c3f', 'battle_rule_v1:e5fe8b55aaf40cc32c696da83b37d87e', '{"battle_model_scope":"xmage_return_target_graveyard_card_to_hand_spell_v1","count":1,"destination":"hand","effect":"recursion","instant":false,"sorcery":true,"target":"goblin_card","target_constraints":{"controller":"self","subtypes":["goblin"],"zone":"graveyard"},"target_controller":"self","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"engine","effect":"recursion","target":"goblin_card"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BoggartBirthRite translated into ManaLoom runtime scope xmage_return_target_graveyard_card_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('death''s duet', 'Death''s Duet', 'c37b16d6c2c8e0d993e7714a1625b70c', 'battle_rule_v1:0414220a4ec2f9a6997383d0b9b728e1', '{"battle_model_scope":"xmage_return_target_graveyard_card_to_hand_spell_v1","count":2,"destination":"hand","effect":"recursion","instant":false,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"],"controller":"self","zone":"graveyard"},"target_controller":"self","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"engine","effect":"recursion","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DeathsDuet translated into ManaLoom runtime scope xmage_return_target_graveyard_card_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('reborn hope', 'Reborn Hope', '3916a80af120b01782f70419b4334271', 'battle_rule_v1:8b00072fef2e36205039b03f21044f1d', '{"battle_model_scope":"xmage_return_target_graveyard_card_to_hand_spell_v1","count":1,"destination":"hand","effect":"recursion","instant":false,"sorcery":true,"target":"multicolored_card","target_constraints":{"controller":"self","min_colors":2,"zone":"graveyard"},"target_controller":"self","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"engine","effect":"recursion","target":"multicolored_card"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RebornHope translated into ManaLoom runtime scope xmage_return_target_graveyard_card_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('revive', 'Revive', '19baafcc9f4b0da0129b72d41728a354', 'battle_rule_v1:bd174969a9568e932ead996951ee8ec8', '{"battle_model_scope":"xmage_return_target_graveyard_card_to_hand_spell_v1","count":1,"destination":"hand","effect":"recursion","instant":false,"sorcery":true,"target":"green_card","target_constraints":{"colors":["G"],"controller":"self","zone":"graveyard"},"target_controller":"self","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"engine","effect":"recursion","target":"green_card"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Revive translated into ManaLoom runtime scope xmage_return_target_graveyard_card_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg326_xmage_recursion_fixed_target_wave_20260701_195645) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
