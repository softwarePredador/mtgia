WITH target(normalized_name, logical_rule_key, battle_model_scope) AS (
  VALUES
    ('fellwar stone', 'battle_rule_v1:3906ffa3cbf7d3437d68e44e13e10bba', 'conditional_opponent_color_mana_rock_v1'),
    ('library of leng', 'battle_rule_v1:b6491cf6f7d7df9a3fb0d91abd3d31c3', 'discard_replacement_to_top_v1'),
    ('scroll rack', 'battle_rule_v1:3b58ff16a7eb52fb05c1bd8517225cd2', 'scroll_rack_upkeep_single_exchange_v1'),
    ('talisman of conviction', 'battle_rule_v1:02133e513da5ea98ac74d32d39b16470', 'pain_talisman_color_pair_partial_v1')
),
joined AS (
  SELECT
    target.normalized_name,
    target.logical_rule_key,
    target.battle_model_scope AS expected_scope,
    rule.card_name,
    rule.review_status,
    rule.execution_status,
    rule.oracle_hash,
    rule.effect_json->>'battle_model_scope' AS actual_scope,
    md5(COALESCE(card.oracle_text, '')) AS card_oracle_hash
  FROM target
  LEFT JOIN public.card_battle_rules rule
    ON rule.normalized_name = target.normalized_name
   AND rule.logical_rule_key = target.logical_rule_key
  LEFT JOIN public.cards card
    ON card.id = rule.card_id
)
SELECT
  count(*) AS target_rows,
  count(*) FILTER (WHERE card_name IS NOT NULL) AS found_rule_rows,
  count(*) FILTER (WHERE review_status = 'active' AND execution_status = 'auto') AS active_auto_rows,
  count(*) FILTER (WHERE actual_scope = expected_scope) AS expected_scope_rows,
  count(*) FILTER (WHERE oracle_hash = card_oracle_hash) AS oracle_hash_match_rows,
  jsonb_agg(to_jsonb(joined) ORDER BY normalized_name) AS rows
FROM joined;
