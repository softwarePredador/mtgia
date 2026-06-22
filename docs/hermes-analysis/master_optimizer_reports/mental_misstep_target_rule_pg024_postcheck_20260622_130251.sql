\pset pager off

SELECT
  'pg024_mental_misstep_postcheck_counts' AS check_name,
  (SELECT count(*) FROM cards WHERE lower(name) = 'mental misstep') AS card_rows,
  (
    SELECT count(*)
    FROM cards
    WHERE lower(name) = 'mental misstep'
      AND md5(regexp_replace(lower(coalesce(oracle_text, '')), '\s+', ' ', 'g')) =
        '3952e627ac586fb842eae00bd3c91786'
  ) AS expected_oracle_hash_rows,
  (
    SELECT count(*)
    FROM card_battle_rules
    WHERE normalized_name = 'mental misstep'
      AND logical_rule_key = 'battle_rule_v1:da6a568dbdfeda5d4009574d953db55e'
      AND effect_json->>'effect' = 'counter'
      AND effect_json->>'counter_target_cmc' = '1'
      AND review_status = 'verified'
      AND execution_status = 'auto'
      AND source = 'curated'
  ) AS exact_executable_rule_rows,
  (
    SELECT count(*)
    FROM card_battle_rules
    WHERE lower(card_name) = 'mental misstep'
      AND logical_rule_key <> 'battle_rule_v1:da6a568dbdfeda5d4009574d953db55e'
      AND effect_json->>'effect' = 'counter'
      AND NOT (effect_json ? 'counter_target_cmc')
      AND NOT (effect_json ? 'counter_target_mana_value')
      AND NOT (effect_json ? 'target_cmc')
      AND NOT (effect_json ? 'target_mana_value')
      AND execution_status IN ('auto', 'executable', 'review_only')
  ) AS broad_enabled_counter_rows;

SELECT
  'pg024_mental_misstep_rule_postcheck' AS check_name,
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
WHERE lower(card_name) = 'mental misstep'
ORDER BY source, review_status, execution_status, logical_rule_key;

SELECT
  'pg024_mental_misstep_snapshot_postcheck' AS check_name,
  name,
  function_tags,
  battle_rules
FROM card_intelligence_snapshot
WHERE lower(name) = 'mental misstep';
