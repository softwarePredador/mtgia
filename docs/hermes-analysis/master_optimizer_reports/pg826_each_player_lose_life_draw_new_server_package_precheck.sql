WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('crushing disappointment', 'Crushing Disappointment', '4067937d3e47b39762d4ee07b0ea41b0', 'battle_rule_v1:76e6899630805fefcf7a76367f997c29', '{"_composite_rule_components":[{"battle_model_scope":"xmage_each_player_lose_life_component_v1","compose_on_resolution":true,"effect":"life_total_change","life_loss":2,"life_loss_amount":2,"life_total_delta":-2,"target":"all_players","target_controller":"all_players","xmage_effect_class":"LoseLifeAllPlayersEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":2,"draw_count":2,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_each_player_lose_life_draw_card_spell_v1","count":2,"draw_count":2,"each_player_life_loss":2,"effect":"composite_resolution","instant":true,"life_loss":2,"life_loss_amount":2,"life_loss_target":"all_players","resolution_order":"lose_life_then_draw","sorcery":false,"xmage_effect_classes":["DrawCardSourceControllerEffect","LoseLifeAllPlayersEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CrushingDisappointment translated into ManaLoom runtime scope xmage_each_player_lose_life_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('risky shortcut', 'Risky Shortcut', 'ccb8b3c872f69d157c2bd6c8242efbec', 'battle_rule_v1:60a12a6d1b6fe7954d1f401120e64b2c', '{"_composite_rule_components":[{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":2,"draw_count":2,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"},{"battle_model_scope":"xmage_each_player_lose_life_component_v1","compose_on_resolution":true,"effect":"life_total_change","life_loss":2,"life_loss_amount":2,"life_total_delta":-2,"target":"all_players","target_controller":"all_players","xmage_effect_class":"LoseLifeAllPlayersEffect"}],"battle_model_scope":"xmage_each_player_lose_life_draw_card_spell_v1","count":2,"draw_count":2,"each_player_life_loss":2,"effect":"composite_resolution","instant":false,"life_loss":2,"life_loss_amount":2,"life_loss_target":"all_players","resolution_order":"draw_then_lose_life","sorcery":true,"xmage_effect_classes":["DrawCardSourceControllerEffect","LoseLifeAllPlayersEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RiskyShortcut translated into ManaLoom runtime scope xmage_each_player_lose_life_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
),
matched_cards AS (
  SELECT
    p.normalized_name,
    p.card_name,
    p.oracle_hash,
    c.id AS card_id,
    c.name AS db_card_name
  FROM proposed p
  LEFT JOIN public.cards c
    ON (
         lower(c.name) = p.normalized_name
         OR split_part(lower(c.name), ' // ', 1) = p.normalized_name
       )
   AND md5(coalesce(c.oracle_text, '')) = p.oracle_hash
),
target_cards AS (
  SELECT
    normalized_name,
    card_name,
    oracle_hash,
    count(card_id) AS target_card_rows,
    min(card_id::text)::uuid AS canonical_card_id,
    min(db_card_name) AS canonical_card_name
  FROM matched_cards
  GROUP BY normalized_name, card_name, oracle_hash
),
rule_rows AS (
  SELECT p.normalized_name, count(r.*) AS existing_rule_rows
  FROM proposed p
  LEFT JOIN public.card_battle_rules r
    ON (
         r.normalized_name = p.normalized_name
         OR r.normalized_name LIKE p.normalized_name || ' // %'
       )
  GROUP BY p.normalized_name
),
expected_rows AS (
  SELECT p.normalized_name, count(r.*) AS expected_rule_rows_before
  FROM proposed p
  LEFT JOIN public.card_battle_rules r
    ON (
         r.normalized_name = p.normalized_name
         OR r.normalized_name LIKE p.normalized_name || ' // %'
       )
   AND r.logical_rule_key = p.logical_rule_key
  GROUP BY p.normalized_name
),
shadow_rows AS (
  SELECT p.normalized_name, count(r.*) AS would_deprecate_shadow_rows
  FROM proposed p
  LEFT JOIN public.card_battle_rules r
    ON (
         r.normalized_name = p.normalized_name
         OR r.normalized_name LIKE p.normalized_name || ' // %'
       )
   AND r.logical_rule_key <> p.logical_rule_key
   AND r.review_status NOT IN ('deprecated', 'rejected')
   AND r.execution_status <> 'disabled'
  GROUP BY p.normalized_name
)
SELECT
  p.card_name,
  p.normalized_name,
  p.oracle_hash,
  p.logical_rule_key,
  p.shadow_handling,
  tc.target_card_rows,
  tc.canonical_card_id,
  rr.existing_rule_rows,
  er.expected_rule_rows_before,
  sr.would_deprecate_shadow_rows
FROM proposed p
JOIN target_cards tc USING (normalized_name, card_name, oracle_hash)
JOIN rule_rows rr USING (normalized_name)
JOIN expected_rows er USING (normalized_name)
JOIN shadow_rows sr USING (normalized_name)
ORDER BY p.card_name;
