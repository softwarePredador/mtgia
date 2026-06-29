WITH target_rules AS (
  SELECT *
  FROM public.card_battle_rules
  WHERE (
      normalized_name = 'city of brass'
      AND logical_rule_key = 'battle_rule_v1:603c776839827f2f21cef8b62e22a1be'
      AND oracle_hash = '969b41c45b968319b44f77454c6ac55b'
    )
    OR (
      normalized_name = 'elves of deep shadow'
      AND logical_rule_key = 'battle_rule_v1:1272fb910383d34360702e343ec16b37'
      AND oracle_hash = '5dd30cbea74064369bcba667795049e2'
    )
    OR (
      normalized_name = 'mana confluence'
      AND logical_rule_key = 'battle_rule_v1:603c776839827f2f21cef8b62e22a1be'
      AND oracle_hash = '11173c5296485bfd3cdd28822d4634e9'
    )
    OR (
      normalized_name = 'tarnished citadel'
      AND logical_rule_key = 'battle_rule_v1:d5663032352408a845b7602f9cb5adf9'
      AND oracle_hash = 'd8bdb24e586e16274f0bd42e40e2dc58'
    )
)
SELECT
  (
    SELECT count(*)
    FROM manaloom_deploy_audit.pgc063_pain_mana_source_cost_runtime_20260629
  ) AS backup_rows,
  count(*) AS target_rows,
  count(*) FILTER (
    WHERE review_status = 'verified'
      AND execution_status = 'auto'
      AND effect_json->>'conditional_mana_modes_status' = 'runtime_executor_v1'
      AND effect_json::text NOT LIKE '%annotation_only%'
  ) AS runtime_rows,
  count(*) FILTER (
    WHERE normalized_name = 'city of brass'
      AND effect_json->>'tap_damage_status' = 'runtime_executor_v1'
      AND effect_json->>'battle_model_scope' = 'five_color_tap_damage_land_runtime_v1'
  ) AS city_runtime_rows,
  count(*) FILTER (
    WHERE normalized_name = 'elves of deep shadow'
      AND effect_json->>'tap_damage_status' = 'runtime_executor_v1'
      AND effect_json->>'battle_model_scope' = 'one_mana_one_one_black_pain_mana_dork_runtime_v1'
  ) AS elves_runtime_rows,
  count(*) FILTER (
    WHERE normalized_name = 'mana confluence'
      AND effect_json->>'life_payment_status' = 'runtime_executor_v1'
      AND effect_json->>'battle_model_scope' = 'five_color_life_paid_land_runtime_v1'
  ) AS mana_confluence_runtime_rows,
  count(*) FILTER (
    WHERE normalized_name = 'tarnished citadel'
      AND effect_json->>'life_loss_on_colored_mana_status' = 'runtime_executor_v1'
      AND effect_json->>'battle_model_scope' = 'colorless_or_any_color_pain_land_runtime_v1'
  ) AS tarnished_runtime_rows
FROM target_rules;
