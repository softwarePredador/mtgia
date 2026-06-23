\pset pager off

SELECT
  'pg028_austere_command_postcheck_counts' AS check_name,
  (
    SELECT count(*)
    FROM card_battle_rules
    WHERE normalized_name = 'austere command'
      AND logical_rule_key = 'battle_rule_v1:5f19a608b87445bcc5c7ebb7ad96eb64'
      AND effect_json->>'effect' = 'board_wipe'
      AND effect_json->>'battle_model_scope' = 'austere_command_choose_two_destroy_modes_v1'
      AND effect_json->'modal_destroy_modes' = jsonb_build_array(
        'artifacts',
        'enchantments',
        'creatures_mana_value_3_or_less',
        'creatures_mana_value_4_or_greater'
      )
      AND effect_json->>'choose_modes' = '2'
      AND review_status = 'active'
      AND execution_status = 'auto'
      AND source = 'curated'
      AND oracle_hash = 'bce631c9a75d6856dd8c0d7de442b47f'
  ) AS exact_executable_rule_rows,
  (
    SELECT count(*)
    FROM card_battle_rules
    WHERE normalized_name = 'austere command'
      AND logical_rule_key <> 'battle_rule_v1:5f19a608b87445bcc5c7ebb7ad96eb64'
      AND effect_json->>'effect' = 'board_wipe'
      AND review_status NOT IN ('rejected', 'deprecated')
      AND execution_status IN ('auto', 'executable', 'review_only')
  ) AS legacy_enabled_board_wipe_rows;

SELECT
  'pg028_austere_command_rule_postcheck' AS check_name,
  card_name,
  logical_rule_key,
  effect_json,
  deck_role_json,
  source,
  confidence,
  review_status,
  execution_status,
  oracle_hash,
  reviewed_by,
  reviewed_at
FROM card_battle_rules
WHERE normalized_name = 'austere command'
ORDER BY source, review_status, execution_status, logical_rule_key;

SELECT
  'pg028_austere_command_snapshot_postcheck' AS check_name,
  name,
  function_tags,
  battle_rules
FROM card_intelligence_snapshot
WHERE lower(name) = 'austere command';
