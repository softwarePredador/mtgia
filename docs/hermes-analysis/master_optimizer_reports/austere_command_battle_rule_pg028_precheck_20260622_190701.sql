\pset pager off

SELECT
  'pg028_austere_command_current_rule_state' AS check_name,
  c.id::text AS card_id,
  c.name,
  c.type_line,
  c.cmc,
  c.oracle_text,
  md5(regexp_replace(lower(coalesce(c.oracle_text, '')), '\s+', ' ', 'g')) AS oracle_hash,
  cbr.logical_rule_key,
  cbr.effect_json,
  cbr.deck_role_json,
  cbr.source,
  cbr.confidence,
  cbr.review_status,
  cbr.execution_status
FROM cards c
LEFT JOIN card_battle_rules cbr
  ON cbr.card_id = c.id
  OR cbr.normalized_name = lower(c.name)
WHERE lower(c.name) = 'austere command'
ORDER BY cbr.source, cbr.review_status, cbr.execution_status, cbr.logical_rule_key;

SELECT
  'pg028_austere_command_precheck_counts' AS check_name,
  (SELECT count(*) FROM cards WHERE lower(name) = 'austere command') AS card_rows,
  (
    SELECT count(*)
    FROM cards
    WHERE lower(name) = 'austere command'
      AND md5(regexp_replace(lower(coalesce(oracle_text, '')), '\s+', ' ', 'g')) =
        'bce631c9a75d6856dd8c0d7de442b47f'
  ) AS expected_oracle_hash_rows,
  (
    SELECT count(*)
    FROM card_battle_rules
    WHERE normalized_name = 'austere command'
      AND logical_rule_key = 'battle_rule_v1:5f19a608b87445bcc5c7ebb7ad96eb64'
      AND effect_json->>'effect' = 'board_wipe'
      AND effect_json->>'battle_model_scope' = 'austere_command_choose_two_destroy_modes_v1'
      AND review_status IN ('verified', 'active')
      AND execution_status IN ('auto', 'executable')
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
  'pg028_austere_command_snapshot_precheck' AS check_name,
  name,
  function_tags,
  battle_rules
FROM card_intelligence_snapshot
WHERE lower(name) = 'austere command';
