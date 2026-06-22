\pset pager off

SELECT
  'pg018_opponent_forensic_postcheck_counts' AS check_name,
  (
    SELECT count(*)
    FROM cards
    WHERE lower(name) IN ('jin-gitaxias, core augur', 'chandra, flameshaper')
  ) AS card_rows,
  (
    SELECT count(*)
    FROM card_battle_rules
    WHERE normalized_name IN ('jin-gitaxias, core augur', 'chandra, flameshaper')
      AND logical_rule_key IN (
        'battle_rule_v1:d14acbe78307b4328ec7c6b58500d39e',
        'battle_rule_v1:ee7ee13e3d57abd378763be663390375'
      )
      AND review_status = 'verified'
      AND execution_status = 'auto'
      AND source = 'curated'
  ) AS curated_executable_rows,
  (
    SELECT count(*)
    FROM card_function_tags
    WHERE lower(card_name) IN ('jin-gitaxias, core augur', 'chandra, flameshaper')
      AND source = 'card_battle_rules_v1'
      AND tag IN ('draw', 'ramp')
  ) AS function_tag_rows;

SELECT
  'pg018_opponent_forensic_rule_postcheck' AS check_name,
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
WHERE lower(card_name) IN ('jin-gitaxias, core augur', 'chandra, flameshaper')
ORDER BY card_name, source, review_status, execution_status, logical_rule_key;

SELECT
  'pg018_opponent_forensic_snapshot_postcheck' AS check_name,
  name,
  function_tags,
  battle_rules
FROM card_intelligence_snapshot
WHERE lower(name) IN ('jin-gitaxias, core augur', 'chandra, flameshaper')
ORDER BY name;
