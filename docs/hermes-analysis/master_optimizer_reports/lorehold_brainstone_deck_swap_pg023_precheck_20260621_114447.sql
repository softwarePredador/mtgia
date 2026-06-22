\pset pager off

WITH target AS (
  SELECT '528c877f-f829-4207-95e6-73981776c323'::uuid AS deck_id
),
ids AS (
  SELECT
    (SELECT (array_agg(id ORDER BY id::text))[1] FROM cards WHERE lower(name) = 'generous gift') AS gift_id,
    (SELECT count(*) FROM cards WHERE lower(name) = 'generous gift') AS gift_printings,
    (SELECT (array_agg(id ORDER BY id::text))[1] FROM cards WHERE lower(name) = 'brainstone') AS brainstone_id,
    (SELECT count(*) FROM cards WHERE lower(name) = 'brainstone') AS brainstone_printings
),
deck_state AS (
  SELECT
    count(*) AS deck_rows,
    coalesce(sum(quantity), 0) AS deck_quantity,
    count(*) FILTER (WHERE dc.card_id = ids.gift_id) AS gift_rows,
    coalesce(sum(quantity) FILTER (WHERE dc.card_id = ids.gift_id), 0) AS gift_quantity,
    coalesce(bool_or(is_commander) FILTER (WHERE dc.card_id = ids.gift_id), false) AS gift_is_commander,
    count(*) FILTER (WHERE dc.card_id = ids.brainstone_id) AS brainstone_rows,
    coalesce(sum(quantity) FILTER (WHERE dc.card_id = ids.brainstone_id), 0) AS brainstone_quantity
  FROM deck_cards dc
  CROSS JOIN ids
  JOIN target t ON t.deck_id = dc.deck_id
),
brainstone_card AS (
  SELECT
    c.id,
    c.name,
    c.type_line,
    c.color_identity,
    cl.status AS commander_status
  FROM ids
  JOIN cards c ON c.id = ids.brainstone_id
  LEFT JOIN card_legalities cl ON cl.card_id = c.id AND cl.format = 'commander'
),
brainstone_rule AS (
  SELECT
    count(*) FILTER (
      WHERE logical_rule_key = 'battle_rule_v1:03bed5506a427743723cd7676c6a67d9'
    ) AS exact_rule_rows,
    bool_or(
      logical_rule_key = 'battle_rule_v1:03bed5506a427743723cd7676c6a67d9'
      AND source = 'curated'
      AND review_status IN ('active', 'verified')
      AND execution_status = 'auto'
      AND effect_json->>'battle_model_scope' = 'brainstone_draw_three_put_two_back_unexecuted_v1'
      AND effect_json->>'effect' = 'topdeck_manipulation'
    ) AS rule_ready,
    array_agg(
      logical_rule_key || ':' || review_status || '/' || execution_status || '/' || source
      ORDER BY logical_rule_key
    ) AS rule_states
  FROM card_battle_rules
  WHERE normalized_name = 'brainstone'
),
backup_state AS (
  SELECT
    to_regclass('manaloom_deploy_audit.pg023_lorehold_brainstone_deck_swap_20260621_114447_deck') AS deck_backup_table,
    to_regclass('manaloom_deploy_audit.pg023_lorehold_brainstone_deck_swap_20260621_114447_rule') AS rule_backup_table
)
SELECT
  'pg023_lorehold_brainstone_precheck' AS check_name,
  ids.gift_id,
  ids.gift_printings,
  ids.brainstone_id,
  ids.brainstone_printings,
  deck_state.*,
  brainstone_card.commander_status AS brainstone_commander_status,
  brainstone_card.color_identity AS brainstone_color_identity,
  brainstone_rule.exact_rule_rows AS brainstone_exact_rule_rows,
  brainstone_rule.rule_ready AS brainstone_rule_ready,
  brainstone_rule.rule_states AS brainstone_rule_states,
  backup_state.deck_backup_table,
  backup_state.rule_backup_table,
  (
    ids.gift_id IS NOT NULL
    AND ids.brainstone_id IS NOT NULL
    AND ids.gift_printings = 1
    AND ids.brainstone_printings = 1
    AND deck_state.deck_rows = 100
    AND deck_state.deck_quantity = 100
    AND deck_state.gift_rows = 1
    AND deck_state.gift_quantity = 1
    AND NOT deck_state.gift_is_commander
    AND deck_state.brainstone_rows = 0
    AND deck_state.brainstone_quantity = 0
    AND brainstone_card.commander_status = 'legal'
    AND brainstone_card.color_identity::text = '{}'
    AND brainstone_rule.exact_rule_rows = 1
    AND brainstone_rule.rule_ready
    AND backup_state.deck_backup_table IS NULL
    AND backup_state.rule_backup_table IS NULL
  ) AS ready_to_apply
FROM ids
CROSS JOIN deck_state
CROSS JOIN brainstone_card
CROSS JOIN brainstone_rule
CROSS JOIN backup_state;
