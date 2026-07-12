WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('horrifying revelation', 'Horrifying Revelation', '71078f24d81cecdc3fe4f318677a92ac', 'battle_rule_v1:c24adcab7800c426dfd2242e9d6b6e48', '{"_composite_rule_components":[{"battle_model_scope":"xmage_fixed_target_player_discard_spell_v1","compose_on_resolution":true,"count":1,"discard_count":1,"effect":"target_player_discard","target":"player","target_constraints":{"players":["any"]},"target_controller":"target_player","target_player_discard":true,"target_player_scope":"any","target_preference":"opponent","xmage_effect_class":"DiscardTargetEffect"},{"battle_model_scope":"xmage_fixed_target_player_mill_spell_v1","compose_on_resolution":true,"count":1,"effect":"mill_cards","mill_count":1,"target":"player","target_constraints":{"players":["any"]},"target_controller":"target_player","target_from_previous_discard":true,"target_player_mill":true,"target_player_scope":"any","target_preference":"previous_discard_target","xmage_effect_class":"MillCardsTargetEffect"}],"battle_model_scope":"xmage_fixed_target_player_discard_mill_spell_v1","count":1,"discard_count":1,"effect":"composite_resolution","instant":false,"mill_count":1,"resolution_order":"discard_then_mill","sorcery":true,"target":"player","target_constraints":{"players":["any"]},"target_controller":"target_player","target_player_discard":true,"target_player_mill":true,"target_player_scope":"any","target_preference":"opponent","xmage_effect_classes":["DiscardTargetEffect","MillCardsTargetEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"player"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HorrifyingRevelation translated into ManaLoom runtime scope xmage_fixed_target_player_discard_mill_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg843_target_player_discard_mill_new_ser_20260712_201055) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
