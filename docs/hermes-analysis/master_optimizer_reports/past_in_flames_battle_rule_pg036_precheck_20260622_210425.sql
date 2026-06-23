\pset pager off
\set ON_ERROR_STOP on

WITH oracle_stats AS (
  SELECT
    count(*) AS card_rows,
    count(DISTINCT oracle_id) AS distinct_oracle_ids,
    count(*) FILTER (
      WHERE md5(regexp_replace(lower(coalesce(oracle_text, '')), '\s+', ' ', 'g')) =
        '12f293d8d746fbc4e5ba80828919dec5'
    ) AS expected_oracle_hash_rows
  FROM cards
  WHERE lower(name) = 'past in flames'
),
rule_stats AS (
  SELECT
    count(*) FILTER (
      WHERE logical_rule_key = 'battle_rule_v1:ccdb2d362690ed2c1ef32711b42e51be'
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
    count(*) FILTER (
      WHERE logical_rule_key <> 'battle_rule_v1:ccdb2d362690ed2c1ef32711b42e51be'
        AND effect_json->>'effect' IN ('recursion')
        AND review_status NOT IN ('rejected', 'deprecated')
        AND execution_status IN ('auto', 'executable', 'review_only')
    ) AS legacy_enabled_recursion_rows,
    count(*) FILTER (
      WHERE review_status IN ('verified', 'active')
        AND execution_status IN ('auto', 'executable')
        AND coalesce(oracle_hash, '') = ''
    ) AS trusted_executable_without_oracle_hash_rows
  FROM card_battle_rules
  WHERE normalized_name = 'past in flames'
)
SELECT
  'pg036_past_in_flames_precheck_counts' AS check_name,
  oracle_stats.card_rows,
  oracle_stats.distinct_oracle_ids,
  oracle_stats.expected_oracle_hash_rows,
  rule_stats.exact_executable_rule_rows,
  rule_stats.legacy_enabled_recursion_rows,
  rule_stats.trusted_executable_without_oracle_hash_rows
FROM oracle_stats, rule_stats;

SELECT
  'pg036_past_in_flames_precheck_rules' AS check_name,
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
