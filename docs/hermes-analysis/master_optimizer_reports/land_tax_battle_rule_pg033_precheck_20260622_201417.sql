\pset pager off

SELECT
  'pg033_land_tax_current_rule_state' AS check_name,
  c.id::text AS card_id,
  c.name,
  c.type_line,
  c.cmc,
  c.mana_cost,
  c.oracle_text,
  md5(regexp_replace(lower(coalesce(c.oracle_text, '')), '\s+', ' ', 'g')) AS oracle_hash,
  cbr.logical_rule_key,
  cbr.effect_json,
  cbr.deck_role_json,
  cbr.source,
  cbr.confidence,
  cbr.review_status,
  cbr.execution_status,
  cbr.oracle_hash AS rule_oracle_hash
FROM cards c
LEFT JOIN card_battle_rules cbr
  ON cbr.card_id = c.id
  OR cbr.normalized_name = lower(c.name)
WHERE lower(c.name) = 'land tax'
ORDER BY cbr.source, cbr.review_status, cbr.execution_status, cbr.logical_rule_key;

SELECT
  'pg033_land_tax_precheck_counts' AS check_name,
  (SELECT count(*) FROM cards WHERE lower(name) = 'land tax') AS card_rows,
  (
    SELECT count(*)
    FROM cards
    WHERE lower(name) = 'land tax'
      AND md5(regexp_replace(lower(coalesce(oracle_text, '')), '\s+', ' ', 'g')) =
        '83b074e38da3e6c4eb6ec3e7568c914b'
  ) AS expected_oracle_hash_rows,
  (
    SELECT count(*)
    FROM card_battle_rules
    WHERE normalized_name = 'land tax'
      AND logical_rule_key = 'battle_rule_v1:e3f5f35c6a9ee4fd8c7b9972c4152bef'
      AND effect_json->>'effect' = 'land_tax'
      AND effect_json->>'battle_model_scope' =
        'land_tax_upkeep_opponent_more_lands_basic_land_tutor_to_hand_v1'
      AND review_status IN ('verified', 'active')
      AND execution_status IN ('auto', 'executable')
      AND oracle_hash = '83b074e38da3e6c4eb6ec3e7568c914b'
  ) AS exact_executable_rule_rows,
  (
    SELECT count(*)
    FROM card_battle_rules
    WHERE normalized_name = 'land tax'
      AND logical_rule_key <> 'battle_rule_v1:e3f5f35c6a9ee4fd8c7b9972c4152bef'
      AND effect_json->>'effect' IN ('passive', 'tutor')
      AND review_status NOT IN ('rejected', 'deprecated')
      AND execution_status IN ('auto', 'executable', 'review_only')
  ) AS legacy_enabled_passive_or_shadow_rows;

SELECT
  'pg033_land_tax_snapshot_precheck' AS check_name,
  name,
  function_tags,
  battle_rules
FROM card_intelligence_snapshot
WHERE lower(name) = 'land tax';
