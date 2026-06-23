\pset pager off
\set ON_ERROR_STOP on

SELECT
  'pg036_past_in_flames_postcheck_counts' AS check_name,
  (
    SELECT count(*)
    FROM card_battle_rules
    WHERE normalized_name = 'past in flames'
      AND logical_rule_key = 'battle_rule_v1:ccdb2d362690ed2c1ef32711b42e51be'
      AND effect_json->>'effect' = 'graveyard_flashback_grant'
      AND effect_json->>'battle_model_scope' =
        'past_in_flames_graveyard_instants_sorceries_flashback_until_eot_v1'
      AND effect_json->>'cmc' = '4.0'
      AND effect_json->>'target_zone' = 'graveyard'
      AND effect_json->>'grants_flashback_to' = 'instant_or_sorcery'
      AND effect_json->>'flashback_cost' = 'mana_cost'
      AND effect_json->>'duration' = 'until_end_of_turn'
      AND effect_json->>'self_flashback_cost' = '{4}{R}'
      AND effect_json->>'exile_on_flashback_resolution' = 'true'
      AND deck_role_json->>'battle_model_scope' =
        'past_in_flames_graveyard_instants_sorceries_flashback_until_eot_v1'
      AND review_status = 'active'
      AND execution_status = 'auto'
      AND source = 'curated'
      AND oracle_hash = '12f293d8d746fbc4e5ba80828919dec5'
  ) AS exact_executable_rule_rows,
  (
    SELECT count(*)
    FROM card_battle_rules
    WHERE normalized_name = 'past in flames'
      AND logical_rule_key <> 'battle_rule_v1:ccdb2d362690ed2c1ef32711b42e51be'
      AND effect_json->>'effect' IN ('recursion')
      AND review_status NOT IN ('rejected', 'deprecated')
      AND execution_status IN ('auto', 'executable', 'review_only')
  ) AS legacy_enabled_recursion_rows,
  (
    SELECT count(*)
    FROM card_battle_rules
    WHERE normalized_name = 'past in flames'
      AND review_status IN ('verified', 'active')
      AND execution_status IN ('auto', 'executable')
      AND coalesce(oracle_hash, '') = ''
  ) AS trusted_executable_without_oracle_hash_rows;

SELECT
  'pg036_past_in_flames_rule_postcheck' AS check_name,
  card_name,
  logical_rule_key,
  effect_json,
  deck_role_json,
  source,
  confidence,
  review_status,
  execution_status,
  oracle_hash,
  reviewed_by,
  reviewed_at
FROM card_battle_rules
WHERE normalized_name = 'past in flames'
ORDER BY source, review_status, execution_status, logical_rule_key;

SELECT
  'pg036_past_in_flames_snapshot_postcheck' AS check_name,
  name,
  function_tags,
  battle_rules
FROM card_intelligence_snapshot
WHERE lower(name) = 'past in flames';
