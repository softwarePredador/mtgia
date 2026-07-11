WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('cruel bargain', 'Cruel Bargain', '07d3b64ab43eb9c20d73831494c353a2', 'battle_rule_v1:cf07b1553ad8181466039ededdf610df', '{"battle_model_scope":"xmage_controller_draw_lose_half_life_rounded_up_spell_v1","count":4,"draw_count":4,"draw_lose_life_spell":true,"effect":"draw_cards","instant":false,"life_loss_mode":"half_rounded_up","life_loss_rounding":"up","sorcery":true,"target_controller":"self","xmage_effect_classes":["DrawCardSourceControllerEffect","LoseHalfLifeEffect"]}'::jsonb, '{"category":"draw","effect":"draw_cards"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CruelBargain translated into ManaLoom runtime scope xmage_controller_draw_lose_half_life_rounded_up_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('infernal contract', 'Infernal Contract', '07d3b64ab43eb9c20d73831494c353a2', 'battle_rule_v1:cf07b1553ad8181466039ededdf610df', '{"battle_model_scope":"xmage_controller_draw_lose_half_life_rounded_up_spell_v1","count":4,"draw_count":4,"draw_lose_life_spell":true,"effect":"draw_cards","instant":false,"life_loss_mode":"half_rounded_up","life_loss_rounding":"up","sorcery":true,"target_controller":"self","xmage_effect_classes":["DrawCardSourceControllerEffect","LoseHalfLifeEffect"]}'::jsonb, '{"category":"draw","effect":"draw_cards"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class InfernalContract translated into ManaLoom runtime scope xmage_controller_draw_lose_half_life_rounded_up_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg763_draw_lose_half_life_new_server_dra_20260711_130850) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
