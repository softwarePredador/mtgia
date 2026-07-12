WITH target(card_name, normalized_name, logical_rule_key, expected_effect, expected_scope, expected_oracle_hash) AS (
  VALUES
    ('Fellwar Stone', 'fellwar stone', 'battle_rule_v1:3906ffa3cbf7d3437d68e44e13e10bba', 'ramp_permanent', 'conditional_opponent_color_mana_rock_v1', 'd63befc8ac40d9a38732f9b5c1a7414a'),
    ('Library of Leng', 'library of leng', 'battle_rule_v1:b6491cf6f7d7df9a3fb0d91abd3d31c3', 'passive', 'discard_replacement_to_top_v1', '575aef3cc2523831e440ea7dcd55fa6e'),
    ('Scroll Rack', 'scroll rack', 'battle_rule_v1:3b58ff16a7eb52fb05c1bd8517225cd2', 'topdeck_manipulation', 'scroll_rack_upkeep_single_exchange_v1', '8133928f03d5a5a77f2beecfcbd09e30'),
    ('Talisman of Conviction', 'talisman of conviction', 'battle_rule_v1:02133e513da5ea98ac74d32d39b16470', 'ramp_permanent', 'pain_talisman_color_pair_partial_v1', 'd49ceec937367a344a9f0948eea4f8f2')
),
matched AS (
  SELECT
    t.*,
    c.id AS card_id,
    c.name AS db_card_name,
    md5(coalesce(c.oracle_text, '')) AS current_oracle_hash,
    r.review_status,
    r.execution_status,
    r.oracle_hash AS current_rule_oracle_hash,
    r.effect_json->>'effect' AS current_effect,
    r.effect_json->>'battle_model_scope' AS current_scope
  FROM target t
  LEFT JOIN public.cards c
    ON lower(c.name) = t.normalized_name
  LEFT JOIN public.card_battle_rules r
    ON r.normalized_name = t.normalized_name
   AND r.logical_rule_key = t.logical_rule_key
)
SELECT
  card_name,
  normalized_name,
  logical_rule_key,
  card_id,
  current_oracle_hash,
  expected_oracle_hash,
  review_status,
  execution_status,
  coalesce(current_rule_oracle_hash, '') AS current_rule_oracle_hash,
  current_effect,
  current_scope,
  (card_id IS NOT NULL) AS card_row_found,
  (current_oracle_hash = expected_oracle_hash) AS oracle_hash_matches_current_text,
  (review_status = 'active' AND execution_status = 'auto') AS active_auto_before,
  (current_effect = expected_effect AND current_scope = expected_scope) AS effect_scope_matches
FROM matched
ORDER BY card_name;
