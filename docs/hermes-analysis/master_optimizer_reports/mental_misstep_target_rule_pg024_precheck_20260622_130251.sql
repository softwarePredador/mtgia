\pset pager off

SELECT
  'pg024_mental_misstep_current_rule_state' AS check_name,
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
LEFT JOIN card_battle_rules cbr ON cbr.card_id = c.id
WHERE lower(c.name) = 'mental misstep'
ORDER BY cbr.source, cbr.review_status, cbr.execution_status, cbr.logical_rule_key;

SELECT
  'pg024_mental_misstep_precheck_counts' AS check_name,
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
      AND review_status IN ('verified', 'active')
      AND execution_status IN ('auto', 'executable')
  ) AS exact_target_rule_rows,
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
  'pg024_mental_misstep_snapshot_precheck' AS check_name,
  name,
  function_tags,
  battle_rules
FROM card_intelligence_snapshot
WHERE lower(name) = 'mental misstep';
