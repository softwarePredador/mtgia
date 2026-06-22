\pset pager off

SELECT
  'pg015_wrath_postcheck_counts' AS check_name,
  (SELECT count(*) FROM cards WHERE lower(name) = 'wrath of god') AS card_rows,
  (
    SELECT count(*)
    FROM card_battle_rules
    WHERE normalized_name = 'wrath of god'
      AND logical_rule_key = 'battle_rule_v1:3c8d1d97cf71a2cb4fef4cb0439f474e'
      AND effect_json->>'effect' = 'board_wipe'
      AND review_status = 'verified'
      AND execution_status = 'auto'
      AND source = 'curated'
  ) AS curated_executable_rows,
  (
    SELECT count(*)
    FROM card_battle_rules
    WHERE lower(card_name) = 'wrath of god'
      AND logical_rule_key <> 'battle_rule_v1:3c8d1d97cf71a2cb4fef4cb0439f474e'
      AND effect_json->>'effect' = 'board_wipe'
      AND execution_status IN ('auto', 'executable', 'review_only')
  ) AS stale_enabled_wipe_rows;

SELECT
  'pg015_wrath_rule_postcheck' AS check_name,
  card_name,
  logical_rule_key,
  effect_json,
  deck_role_json,
  source,
  confidence,
  review_status,
  execution_status,
  reviewed_by,
  reviewed_at
FROM card_battle_rules
WHERE lower(card_name) = 'wrath of god'
ORDER BY source, review_status, execution_status, logical_rule_key;

SELECT
  'pg015_wrath_snapshot_postcheck' AS check_name,
  name,
  function_tags,
  battle_rules
FROM card_intelligence_snapshot
WHERE lower(name) = 'wrath of god';
