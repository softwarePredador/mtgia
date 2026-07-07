\echo 'PG638 priority Lorehold status validation precheck'

WITH target(normalized_name, card_name, logical_rule_key, effect, scope) AS (
  VALUES
    ('fellwar stone', 'Fellwar Stone', 'battle_rule_v1:3906ffa3cbf7d3437d68e44e13e10bba', 'ramp_permanent', 'conditional_opponent_color_mana_rock_v1'),
    ('library of leng', 'Library of Leng', 'battle_rule_v1:b6491cf6f7d7df9a3fb0d91abd3d31c3', 'passive', 'discard_replacement_to_top_v1'),
    ('scroll rack', 'Scroll Rack', 'battle_rule_v1:3b58ff16a7eb52fb05c1bd8517225cd2', 'topdeck_manipulation', 'scroll_rack_upkeep_single_exchange_v1'),
    ('talisman of conviction', 'Talisman of Conviction', 'battle_rule_v1:02133e513da5ea98ac74d32d39b16470', 'ramp_permanent', 'pain_talisman_color_pair_partial_v1')
),
matched AS (
  SELECT
    t.card_name AS expected_card_name,
    cbr.card_name,
    cbr.normalized_name,
    cbr.logical_rule_key,
    cbr.review_status,
    cbr.execution_status,
    cbr.source,
    cbr.oracle_hash,
    cbr.effect_json->>'effect' AS effect,
    cbr.effect_json->>'battle_model_scope' AS scope
  FROM target t
  LEFT JOIN card_battle_rules cbr
    ON cbr.normalized_name = t.normalized_name
   AND cbr.logical_rule_key = t.logical_rule_key
)
SELECT *
FROM matched
ORDER BY expected_card_name;

DO $$
DECLARE
  ready_count integer;
  unsafe_count integer;
BEGIN
  WITH target(normalized_name, card_name, logical_rule_key, effect, scope) AS (
    VALUES
      ('fellwar stone', 'Fellwar Stone', 'battle_rule_v1:3906ffa3cbf7d3437d68e44e13e10bba', 'ramp_permanent', 'conditional_opponent_color_mana_rock_v1'),
      ('library of leng', 'Library of Leng', 'battle_rule_v1:b6491cf6f7d7df9a3fb0d91abd3d31c3', 'passive', 'discard_replacement_to_top_v1'),
      ('scroll rack', 'Scroll Rack', 'battle_rule_v1:3b58ff16a7eb52fb05c1bd8517225cd2', 'topdeck_manipulation', 'scroll_rack_upkeep_single_exchange_v1'),
      ('talisman of conviction', 'Talisman of Conviction', 'battle_rule_v1:02133e513da5ea98ac74d32d39b16470', 'ramp_permanent', 'pain_talisman_color_pair_partial_v1')
  )
  SELECT count(*) INTO ready_count
  FROM card_battle_rules cbr
  JOIN target t
    ON cbr.normalized_name = t.normalized_name
   AND cbr.logical_rule_key = t.logical_rule_key
  WHERE cbr.card_name = t.card_name
    AND cbr.review_status = 'active'
    AND cbr.execution_status = 'auto'
    AND cbr.source = 'curated'
    AND cbr.oracle_hash IS NOT NULL
    AND cbr.effect_json->>'effect' = t.effect
    AND cbr.effect_json->>'battle_model_scope' = t.scope;

  IF ready_count <> 4 THEN
    RAISE EXCEPTION 'Expected 4 active/auto curated target rules ready for promotion, found %', ready_count;
  END IF;

  WITH target(normalized_name, card_name, logical_rule_key, effect, scope) AS (
    VALUES
      ('fellwar stone', 'Fellwar Stone', 'battle_rule_v1:3906ffa3cbf7d3437d68e44e13e10bba', 'ramp_permanent', 'conditional_opponent_color_mana_rock_v1'),
      ('library of leng', 'Library of Leng', 'battle_rule_v1:b6491cf6f7d7df9a3fb0d91abd3d31c3', 'passive', 'discard_replacement_to_top_v1'),
      ('scroll rack', 'Scroll Rack', 'battle_rule_v1:3b58ff16a7eb52fb05c1bd8517225cd2', 'topdeck_manipulation', 'scroll_rack_upkeep_single_exchange_v1'),
      ('talisman of conviction', 'Talisman of Conviction', 'battle_rule_v1:02133e513da5ea98ac74d32d39b16470', 'ramp_permanent', 'pain_talisman_color_pair_partial_v1')
  )
  SELECT count(*) INTO unsafe_count
  FROM target t
  LEFT JOIN card_battle_rules cbr
    ON cbr.normalized_name = t.normalized_name
   AND cbr.logical_rule_key = t.logical_rule_key
  WHERE cbr.normalized_name IS NULL
     OR cbr.effect_json->>'effect' <> t.effect
     OR cbr.effect_json->>'battle_model_scope' <> t.scope
     OR cbr.execution_status <> 'auto'
     OR cbr.source <> 'curated'
     OR cbr.oracle_hash IS NULL;

  IF unsafe_count <> 0 THEN
    RAISE EXCEPTION 'Unsafe target rows detected for PG638 priority promotion: %', unsafe_count;
  END IF;
END $$;
