\pset pager off

SELECT
  'pg031_deflecting_swat_current_rule_state' AS check_name,
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
WHERE lower(c.name) = 'deflecting swat'
ORDER BY cbr.source, cbr.review_status, cbr.execution_status, cbr.logical_rule_key;

SELECT
  'pg031_deflecting_swat_precheck_counts' AS check_name,
  (SELECT count(*) FROM cards WHERE lower(name) = 'deflecting swat') AS card_rows,
  (
    SELECT count(*)
    FROM cards
    WHERE lower(name) = 'deflecting swat'
      AND md5(regexp_replace(lower(coalesce(oracle_text, '')), '\s+', ' ', 'g')) =
        'a34c89817f87f32bedfb3d66a5bdc672'
  ) AS expected_oracle_hash_rows,
  (
    SELECT count(*)
    FROM card_battle_rules
    WHERE normalized_name = 'deflecting swat'
      AND logical_rule_key = 'battle_rule_v1:bac48343654a53205d790a8268bd2631'
      AND effect_json->>'effect' = 'redirect_removal'
      AND effect_json->>'battle_model_scope' =
        'deflecting_swat_control_commander_free_redirect_target_spell_or_ability_v1'
      AND effect_json->>'free_if_control_commander' = 'true'
      AND review_status IN ('verified', 'active')
      AND execution_status IN ('auto', 'executable')
      AND oracle_hash = 'a34c89817f87f32bedfb3d66a5bdc672'
  ) AS exact_executable_rule_rows,
  (
    SELECT count(*)
    FROM card_battle_rules
    WHERE normalized_name = 'deflecting swat'
      AND logical_rule_key <> 'battle_rule_v1:bac48343654a53205d790a8268bd2631'
      AND effect_json->>'effect' IN ('redirect_removal', 'draw_cards')
      AND review_status NOT IN ('rejected', 'deprecated')
      AND execution_status IN ('auto', 'executable', 'review_only')
  ) AS legacy_enabled_redirect_or_shadow_rows;

SELECT
  'pg031_deflecting_swat_snapshot_precheck' AS check_name,
  name,
  function_tags,
  battle_rules
FROM card_intelligence_snapshot
WHERE lower(name) = 'deflecting swat';
