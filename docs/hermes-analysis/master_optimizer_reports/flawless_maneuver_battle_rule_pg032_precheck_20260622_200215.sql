\pset pager off

SELECT
  'pg032_flawless_maneuver_current_rule_state' AS check_name,
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
WHERE lower(c.name) = 'flawless maneuver'
ORDER BY cbr.source, cbr.review_status, cbr.execution_status, cbr.logical_rule_key;

SELECT
  'pg032_flawless_maneuver_precheck_counts' AS check_name,
  (SELECT count(*) FROM cards WHERE lower(name) = 'flawless maneuver') AS card_rows,
  (
    SELECT count(*)
    FROM cards
    WHERE lower(name) = 'flawless maneuver'
      AND md5(regexp_replace(lower(coalesce(oracle_text, '')), '\s+', ' ', 'g')) =
        'fa955216fa827bf75c5b79dcbdb4b97e'
  ) AS expected_oracle_hash_rows,
  (
    SELECT count(*)
    FROM card_battle_rules
    WHERE normalized_name = 'flawless maneuver'
      AND logical_rule_key = 'battle_rule_v1:73622071c1ad89267708f914a0729bf2'
      AND effect_json->>'effect' = 'indestructible'
      AND effect_json->>'battle_model_scope' =
        'flawless_maneuver_control_commander_free_creatures_indestructible_until_eot_v1'
      AND effect_json->>'free_if_control_commander' = 'true'
      AND review_status IN ('verified', 'active')
      AND execution_status IN ('auto', 'executable')
      AND oracle_hash = 'fa955216fa827bf75c5b79dcbdb4b97e'
  ) AS exact_executable_rule_rows,
  (
    SELECT count(*)
    FROM card_battle_rules
    WHERE normalized_name = 'flawless maneuver'
      AND logical_rule_key <> 'battle_rule_v1:73622071c1ad89267708f914a0729bf2'
      AND effect_json->>'effect' = 'indestructible'
      AND review_status NOT IN ('rejected', 'deprecated')
      AND execution_status IN ('auto', 'executable', 'review_only')
  ) AS legacy_enabled_indestructible_or_shadow_rows;

SELECT
  'pg032_flawless_maneuver_snapshot_precheck' AS check_name,
  name,
  function_tags,
  battle_rules
FROM card_intelligence_snapshot
WHERE lower(name) = 'flawless maneuver';
