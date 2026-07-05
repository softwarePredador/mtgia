WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('contract killing', 'Contract Killing', 'f1cbc4d4cc19b2e1822644e3a6aa7d73', 'battle_rule_v1:ff1e6910d13613aa0f6c0970dce15189', '{"battle_model_scope":"xmage_destroy_target_create_treasure_spell_v1","controller_treasure_tokens":2,"destination":"graveyard","effect":"remove_creature","instant":false,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"]},"treasure_count":2,"treasure_recipient":"controller","treasure_trigger":"on_resolution_after_destroy","xmage_effect_classes":["DestroyTargetEffect","CreateTokenEffect"]}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ContractKilling translated into ManaLoom runtime scope xmage_destroy_target_create_treasure_spell_v1. This row is package-ready only because the source signature is a narrow fixed destroy-target plus controller Treasure creation spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('crack open', 'Crack Open', 'b0dab9c2113f397762b4a4cef17538cf', 'battle_rule_v1:1e40acd2dc6d17116ccdca7014df3b6e', '{"battle_model_scope":"xmage_destroy_target_create_treasure_spell_v1","controller_treasure_tokens":1,"destination":"graveyard","effect":"remove_permanent","instant":false,"sorcery":true,"target":"artifact_or_enchantment","target_constraints":{"card_types":["artifact","enchantment"]},"treasure_count":1,"treasure_recipient":"controller","treasure_trigger":"on_resolution_after_destroy","xmage_effect_classes":["DestroyTargetEffect","CreateTokenEffect"]}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"artifact_or_enchantment"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CrackOpen translated into ManaLoom runtime scope xmage_destroy_target_create_treasure_spell_v1. This row is package-ready only because the source signature is a narrow fixed destroy-target plus controller Treasure creation spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('grim bounty', 'Grim Bounty', '898ad01083f20b024fe8b0bafeb32ee1', 'battle_rule_v1:40e2945395e3e9538c8d101258c37603', '{"battle_model_scope":"xmage_destroy_target_create_treasure_spell_v1","controller_treasure_tokens":1,"destination":"graveyard","effect":"remove_permanent","instant":false,"sorcery":true,"target":"creature_or_planeswalker","target_constraints":{"card_types":["creature","planeswalker"]},"treasure_count":1,"treasure_recipient":"controller","treasure_trigger":"on_resolution_after_destroy","xmage_effect_classes":["DestroyTargetEffect","CreateTokenEffect"]}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"creature_or_planeswalker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GrimBounty translated into ManaLoom runtime scope xmage_destroy_target_create_treasure_spell_v1. This row is package-ready only because the source signature is a narrow fixed destroy-target plus controller Treasure creation spell with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg533_destroy_treasure_new_server_20260705_221743) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
