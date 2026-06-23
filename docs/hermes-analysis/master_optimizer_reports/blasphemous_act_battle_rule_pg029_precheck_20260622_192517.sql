\pset pager off

SELECT
  'pg029_blasphemous_act_current_rule_state' AS check_name,
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
  cbr.execution_status
FROM cards c
LEFT JOIN card_battle_rules cbr
  ON cbr.card_id = c.id
  OR cbr.normalized_name = lower(c.name)
WHERE lower(c.name) = 'blasphemous act'
ORDER BY cbr.source, cbr.review_status, cbr.execution_status, cbr.logical_rule_key;

SELECT
  'pg029_blasphemous_act_precheck_counts' AS check_name,
  (SELECT count(*) FROM cards WHERE lower(name) = 'blasphemous act') AS card_rows,
  (
    SELECT count(*)
    FROM cards
    WHERE lower(name) = 'blasphemous act'
      AND md5(regexp_replace(lower(coalesce(oracle_text, '')), '\s+', ' ', 'g')) =
        '826022a579db4551b45ad35e4cfab973'
  ) AS expected_oracle_hash_rows,
  (
    SELECT count(*)
    FROM card_battle_rules
    WHERE normalized_name = 'blasphemous act'
      AND logical_rule_key = 'battle_rule_v1:56271789d639ef390213dbc90059e4d2'
      AND effect_json->>'effect' = 'damage_wipe'
      AND effect_json->>'battle_model_scope' = 'blasphemous_act_damage_13_each_creature_v1'
      AND review_status IN ('verified', 'active')
      AND execution_status IN ('auto', 'executable')
  ) AS exact_executable_rule_rows,
  (
    SELECT count(*)
    FROM card_battle_rules
    WHERE normalized_name = 'blasphemous act'
      AND logical_rule_key <> 'battle_rule_v1:56271789d639ef390213dbc90059e4d2'
      AND effect_json->>'effect' IN ('board_wipe', 'damage_wipe')
      AND review_status NOT IN ('rejected', 'deprecated')
      AND execution_status IN ('auto', 'executable', 'review_only')
  ) AS legacy_enabled_wipe_rows;

SELECT
  'pg029_blasphemous_act_snapshot_precheck' AS check_name,
  name,
  function_tags,
  battle_rules
FROM card_intelligence_snapshot
WHERE lower(name) = 'blasphemous act';
