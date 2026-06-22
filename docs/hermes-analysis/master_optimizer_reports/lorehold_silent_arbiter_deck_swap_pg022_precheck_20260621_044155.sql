\pset pager off

WITH target AS (
  SELECT '528c877f-f829-4207-95e6-73981776c323'::uuid AS deck_id
),
ids AS (
  SELECT
    (SELECT (array_agg(id ORDER BY id::text))[1] FROM cards WHERE lower(name) = 'monument to endurance') AS monument_id,
    (SELECT count(*) FROM cards WHERE lower(name) = 'monument to endurance') AS monument_printings,
    (SELECT (array_agg(id ORDER BY id::text))[1] FROM cards WHERE lower(name) = 'silent arbiter') AS silent_id,
    (SELECT count(*) FROM cards WHERE lower(name) = 'silent arbiter') AS silent_printings
),
deck_state AS (
  SELECT
    count(*) AS deck_rows,
    coalesce(sum(quantity), 0) AS deck_quantity,
    count(*) FILTER (WHERE dc.card_id = ids.monument_id) AS monument_rows,
    coalesce(sum(quantity) FILTER (WHERE dc.card_id = ids.monument_id), 0) AS monument_quantity,
    coalesce(bool_or(is_commander) FILTER (WHERE dc.card_id = ids.monument_id), false) AS monument_is_commander,
    count(*) FILTER (WHERE dc.card_id = ids.silent_id) AS silent_rows,
    coalesce(sum(quantity) FILTER (WHERE dc.card_id = ids.silent_id), 0) AS silent_quantity
  FROM deck_cards dc
  CROSS JOIN ids
  JOIN target t ON t.deck_id = dc.deck_id
),
silent_rule AS (
  SELECT
    count(*) AS rule_rows,
    bool_or(
      effect_json->>'battle_model_scope' = 'silent_arbiter_global_single_attacker_v2'
      AND effect_json ? 'max_attackers'
      AND NOT (effect_json ? 'max_attackers_against_you')
      AND review_status = 'verified'
      AND execution_status = 'auto'
    ) AS global_rule_ready
  FROM card_battle_rules
  WHERE normalized_name = 'silent arbiter'
    AND logical_rule_key = 'battle_rule_v1:6f6089b73fb8f7f9aee20cacb64fffc7'
),
silent_card AS (
  SELECT
    c.id,
    c.name,
    c.type_line,
    c.color_identity,
    cl.status AS commander_status
  FROM ids
  JOIN cards c ON c.id = ids.silent_id
  LEFT JOIN card_legalities cl ON cl.card_id = c.id AND cl.format = 'commander'
)
SELECT
  'pg022_lorehold_silent_arbiter_precheck' AS check_name,
  ids.monument_id,
  ids.monument_printings,
  ids.silent_id,
  ids.silent_printings,
  deck_state.*,
  silent_card.commander_status AS silent_commander_status,
  silent_card.color_identity AS silent_color_identity,
  silent_rule.rule_rows AS silent_rule_rows,
  silent_rule.global_rule_ready,
  (
    ids.monument_id IS NOT NULL
    AND ids.silent_id IS NOT NULL
    AND ids.monument_printings = 1
    AND ids.silent_printings = 1
    AND deck_state.deck_rows = 100
    AND deck_state.deck_quantity = 100
    AND deck_state.monument_rows = 1
    AND deck_state.monument_quantity = 1
    AND NOT deck_state.monument_is_commander
    AND deck_state.silent_rows = 0
    AND deck_state.silent_quantity = 0
    AND silent_card.commander_status = 'legal'
    AND silent_card.color_identity::text = '{}'
    AND silent_rule.rule_rows = 1
    AND silent_rule.global_rule_ready
  ) AS ready_to_apply
FROM ids
CROSS JOIN deck_state
CROSS JOIN silent_card
CROSS JOIN silent_rule;
