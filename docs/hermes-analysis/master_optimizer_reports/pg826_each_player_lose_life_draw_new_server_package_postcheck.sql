WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('crushing disappointment', 'Crushing Disappointment', '4067937d3e47b39762d4ee07b0ea41b0', 'battle_rule_v1:76e6899630805fefcf7a76367f997c29', '{"_composite_rule_components":[{"battle_model_scope":"xmage_each_player_lose_life_component_v1","compose_on_resolution":true,"effect":"life_total_change","life_loss":2,"life_loss_amount":2,"life_total_delta":-2,"target":"all_players","target_controller":"all_players","xmage_effect_class":"LoseLifeAllPlayersEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":2,"draw_count":2,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_each_player_lose_life_draw_card_spell_v1","count":2,"draw_count":2,"each_player_life_loss":2,"effect":"composite_resolution","instant":true,"life_loss":2,"life_loss_amount":2,"life_loss_target":"all_players","resolution_order":"lose_life_then_draw","sorcery":false,"xmage_effect_classes":["DrawCardSourceControllerEffect","LoseLifeAllPlayersEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CrushingDisappointment translated into ManaLoom runtime scope xmage_each_player_lose_life_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('risky shortcut', 'Risky Shortcut', 'ccb8b3c872f69d157c2bd6c8242efbec', 'battle_rule_v1:60a12a6d1b6fe7954d1f401120e64b2c', '{"_composite_rule_components":[{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":2,"draw_count":2,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"},{"battle_model_scope":"xmage_each_player_lose_life_component_v1","compose_on_resolution":true,"effect":"life_total_change","life_loss":2,"life_loss_amount":2,"life_total_delta":-2,"target":"all_players","target_controller":"all_players","xmage_effect_class":"LoseLifeAllPlayersEffect"}],"battle_model_scope":"xmage_each_player_lose_life_draw_card_spell_v1","count":2,"draw_count":2,"each_player_life_loss":2,"effect":"composite_resolution","instant":false,"life_loss":2,"life_loss_amount":2,"life_loss_target":"all_players","resolution_order":"draw_then_lose_life","sorcery":true,"xmage_effect_classes":["DrawCardSourceControllerEffect","LoseLifeAllPlayersEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RiskyShortcut translated into ManaLoom runtime scope xmage_each_player_lose_life_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg826_pg826_each_player_lose_life_draw_n_20260712_104644) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
