\pset pager off

WITH target AS (
  SELECT '528c877f-f829-4207-95e6-73981776c323'::uuid AS deck_id
),
state AS (
  SELECT
    count(*) AS deck_rows,
    coalesce(sum(dc.quantity), 0) AS deck_quantity,
    count(*) FILTER (WHERE lower(c.name) = 'generous gift') AS gift_rows,
    coalesce(sum(dc.quantity) FILTER (WHERE lower(c.name) = 'generous gift'), 0) AS gift_quantity,
    count(*) FILTER (WHERE lower(c.name) = 'brainstone') AS brainstone_rows,
    coalesce(sum(dc.quantity) FILTER (WHERE lower(c.name) = 'brainstone'), 0) AS brainstone_quantity,
    coalesce(bool_or(dc.is_commander) FILTER (WHERE lower(c.name) = 'brainstone'), false) AS brainstone_is_commander
  FROM deck_cards dc
  JOIN cards c ON c.id = dc.card_id
  JOIN target t ON t.deck_id = dc.deck_id
),
deck_backup AS (
  SELECT count(*) AS deck_backup_rows
  FROM manaloom_deploy_audit.pg023_lorehold_brainstone_deck_swap_20260621_114447_deck
  WHERE deck_id = (SELECT deck_id FROM target)
),
rule_backup AS (
  SELECT count(*) AS rule_backup_rows
  FROM manaloom_deploy_audit.pg023_lorehold_brainstone_deck_swap_20260621_114447_rule
  WHERE normalized_name = 'brainstone'
    AND logical_rule_key = 'battle_rule_v1:03bed5506a427743723cd7676c6a67d9'
),
brainstone_rule AS (
  SELECT
    count(*) AS rule_rows,
    bool_or(
      source = 'curated'
      AND review_status = 'verified'
      AND execution_status = 'auto'
      AND effect_json->>'battle_model_scope' = 'brainstone_draw_three_put_two_back_unexecuted_v1'
      AND effect_json->>'effect' = 'topdeck_manipulation'
    ) AS rule_verified
  FROM card_battle_rules
  WHERE normalized_name = 'brainstone'
    AND logical_rule_key = 'battle_rule_v1:03bed5506a427743723cd7676c6a67d9'
)
SELECT
  'pg023_lorehold_brainstone_postcheck' AS check_name,
  state.*,
  deck_backup.deck_backup_rows,
  rule_backup.rule_backup_rows,
  brainstone_rule.rule_rows AS brainstone_rule_rows,
  brainstone_rule.rule_verified AS brainstone_rule_verified,
  (
    state.deck_rows = 100
    AND state.deck_quantity = 100
    AND state.gift_rows = 0
    AND state.gift_quantity = 0
    AND state.brainstone_rows = 1
    AND state.brainstone_quantity = 1
    AND NOT state.brainstone_is_commander
    AND deck_backup.deck_backup_rows = 1
    AND rule_backup.rule_backup_rows = 1
    AND brainstone_rule.rule_rows = 1
    AND brainstone_rule.rule_verified
  ) AS postcheck_passed
FROM state
CROSS JOIN deck_backup
CROSS JOIN rule_backup
CROSS JOIN brainstone_rule;
