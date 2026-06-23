\pset pager off

SELECT
  'pg030_boros_charm_current_rule_state' AS check_name,
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
WHERE lower(c.name) = 'boros charm'
ORDER BY cbr.source, cbr.review_status, cbr.execution_status, cbr.logical_rule_key;

SELECT
  'pg030_boros_charm_precheck_counts' AS check_name,
  (SELECT count(*) FROM cards WHERE lower(name) = 'boros charm') AS card_rows,
  (
    SELECT count(*)
    FROM cards
    WHERE lower(name) = 'boros charm'
      AND md5(regexp_replace(lower(coalesce(oracle_text, '')), '\s+', ' ', 'g')) =
        '98a7be829075118b499a7c283a23501f'
  ) AS expected_oracle_hash_rows,
  (
    SELECT count(*)
    FROM card_battle_rules
    WHERE normalized_name = 'boros charm'
      AND logical_rule_key = 'battle_rule_v1:32605a838d7a519f44eaa0899d2c40bf'
      AND effect_json->>'effect' = 'modal_boros_charm'
      AND effect_json->>'battle_model_scope' =
        'boros_charm_choose_one_damage_indestructible_double_strike_v1'
      AND review_status IN ('verified', 'active')
      AND execution_status IN ('auto', 'executable')
      AND oracle_hash = '98a7be829075118b499a7c283a23501f'
  ) AS exact_executable_rule_rows,
  (
    SELECT count(*)
    FROM card_battle_rules
    WHERE normalized_name = 'boros charm'
      AND logical_rule_key <> 'battle_rule_v1:32605a838d7a519f44eaa0899d2c40bf'
      AND effect_json->>'effect' IN ('modal_boros_charm', 'indestructible')
      AND review_status NOT IN ('rejected', 'deprecated')
      AND execution_status IN ('auto', 'executable', 'review_only')
  ) AS legacy_enabled_modal_or_shadow_rows;

SELECT
  'pg030_boros_charm_snapshot_precheck' AS check_name,
  name,
  function_tags,
  battle_rules
FROM card_intelligence_snapshot
WHERE lower(name) = 'boros charm';
