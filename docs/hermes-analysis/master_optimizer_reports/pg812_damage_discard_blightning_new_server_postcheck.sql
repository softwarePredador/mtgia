WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('blightning', 'Blightning', '704b9b3861bd442e46bd3b1cf947982e', 'battle_rule_v1:64f43dbbf5748cf4727c28d30fdfa916', '{"_composite_rule_components":[{"amount":3,"battle_model_scope":"xmage_fixed_damage_target_spell_v1","compose_on_resolution":true,"damage":3,"effect":"direct_damage","target":"player_or_planeswalker","target_constraints":{"scope":"player_or_planeswalker"},"xmage_effect_class":"DamageTargetEffect"},{"battle_model_scope":"xmage_fixed_target_player_discard_spell_v1","compose_on_resolution":true,"count":2,"discard_count":2,"discard_random":false,"effect":"target_player_discard","target":"player","target_constraints":{"players":["any"]},"target_controller":"target_player","target_from_previous_damage":true,"target_player_discard":true,"target_preference":"previous_damage_target_controller","xmage_effect_class":"DiscardTargetEffect"}],"amount":3,"battle_model_scope":"xmage_fixed_damage_target_then_same_player_discard_spell_v1","damage":3,"discard_count":2,"discard_random":false,"effect":"composite_resolution","instant":false,"resolution_order":"damage_then_same_player_discard","sorcery":true,"target":"player_or_planeswalker","target_constraints":{"scope":"player_or_planeswalker"},"target_player_discard":true,"xmage_effect_classes":["BlightningEffect","DamageTargetEffect","DiscardTargetEffect","OneShotEffect"]}'::jsonb, '{"category":"removal","effect":"composite_resolution","subtype":"damage_discard","target":"player_or_planeswalker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Blightning translated into ManaLoom runtime scope xmage_fixed_damage_target_then_same_player_discard_spell_v1. This row is package-ready only because the source signature is a narrow fixed damage spell with same damaged player/controller discard with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg812_damage_discard_blightning_new_serv_20260712_070524) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
