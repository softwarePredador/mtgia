\pset pager off
\set ON_ERROR_STOP on

WITH oracle_stats AS (
  SELECT
    count(*) AS card_rows,
    count(DISTINCT oracle_id) AS distinct_oracle_ids,
    count(*) FILTER (
      WHERE md5(regexp_replace(lower(coalesce(oracle_text, '')), '\s+', ' ', 'g')) =
        'f1b6d4f38a533e56f0efb5a3f1547214'
    ) AS expected_oracle_hash_rows
  FROM cards
  WHERE lower(name) = 'lorehold, the historian'
),
rule_stats AS (
  SELECT
    count(*) FILTER (
      WHERE logical_rule_key = 'battle_rule_v1:06d892f8ad75831f785aef6dcedc82b4'
        AND effect_json->>'effect' = 'passive'
        AND effect_json->>'battle_model_scope' = 'lorehold_opponent_upkeep_miracle_v1'
        AND effect_json->>'cmc' = '5.0'
        AND effect_json->>'flying' = 'true'
        AND effect_json->>'haste' = 'true'
        AND effect_json->>'grants_miracle_cost' = '2'
        AND effect_json->>'opponent_upkeep_rummage' = 'true'
        AND review_status = 'active'
        AND execution_status = 'auto'
        AND source = 'curated'
        AND oracle_hash = 'f1b6d4f38a533e56f0efb5a3f1547214'
    ) AS exact_executable_rule_rows,
    count(*) FILTER (
      WHERE logical_rule_key <> 'battle_rule_v1:06d892f8ad75831f785aef6dcedc82b4'
        AND effect_json->>'effect' IN ('commander', 'draw_engine', 'passive')
        AND review_status NOT IN ('rejected', 'deprecated')
        AND execution_status IN ('auto', 'executable', 'review_only')
    ) AS legacy_enabled_lorehold_rows,
    count(*) FILTER (
      WHERE review_status IN ('verified', 'active')
        AND execution_status IN ('auto', 'executable')
        AND coalesce(oracle_hash, '') = ''
    ) AS trusted_executable_without_oracle_hash_rows
  FROM card_battle_rules
  WHERE normalized_name = 'lorehold, the historian'
)
SELECT
  'pg035_lorehold_precheck_counts' AS check_name,
  oracle_stats.card_rows,
  oracle_stats.distinct_oracle_ids,
  oracle_stats.expected_oracle_hash_rows,
  rule_stats.exact_executable_rule_rows,
  rule_stats.legacy_enabled_lorehold_rows,
  rule_stats.trusted_executable_without_oracle_hash_rows
FROM oracle_stats, rule_stats;

SELECT
  'pg035_lorehold_precheck_rules' AS check_name,
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
WHERE normalized_name = 'lorehold, the historian'
ORDER BY source, review_status, execution_status, logical_rule_key;
