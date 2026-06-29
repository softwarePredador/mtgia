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
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'manaloom_deploy_audit'
      AND c.relname = 'pgc063_pain_mana_source_cost_runtime_20260629'
  ) AS backup_table_exists,
  count(*) AS target_rows,
  count(*) FILTER (
    WHERE review_status = 'verified'
      AND execution_status = 'auto'
  ) AS trusted_target_rows,
  count(*) FILTER (
    WHERE effect_json::text LIKE '%annotation_only%'
  ) AS current_annotation_rows,
  count(*) FILTER (
    WHERE effect_json->>'tap_damage_status' = 'annotation_only'
  ) AS tap_damage_annotation_rows,
  count(*) FILTER (
    WHERE effect_json->>'life_payment_status' = 'annotation_only'
  ) AS life_payment_annotation_rows,
  count(*) FILTER (
    WHERE effect_json->>'life_loss_on_colored_mana_status' = 'annotation_only'
  ) AS colored_life_loss_annotation_rows
FROM target_rules;
