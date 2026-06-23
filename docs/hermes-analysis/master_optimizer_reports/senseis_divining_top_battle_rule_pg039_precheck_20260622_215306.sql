\pset pager off
\set ON_ERROR_STOP on

WITH oracle_stats AS (
  SELECT
    count(*) AS card_rows,
    count(DISTINCT oracle_id) AS distinct_oracle_ids,
    count(*) FILTER (
      WHERE md5(regexp_replace(lower(coalesce(oracle_text, '')), '\s+', ' ', 'g')) =
        'f2c5ac0f52963cd710470adc25cc6d7c'
    ) AS expected_oracle_hash_rows
  FROM cards
  WHERE lower(name) = 'sensei''s divining top'
),
rule_stats AS (
  SELECT
    count(*) FILTER (
      WHERE logical_rule_key = 'battle_rule_v1:70c8478871f352b46cee1af296117951'
        AND effect_json->>'effect' = 'topdeck_manipulation'
        AND effect_json->>'reorder_top' = 'true'
        AND effect_json->>'activated_draw_put_self_on_top' = 'true'
        AND effect_json->>'generic_draw_activation_status' = 'annotation_only'
        AND effect_json->>'battle_model_scope' =
          'senseis_top_reorder_draw_lorehold_first_draw_miracle_v1'
        AND (effect_json->>'cmc')::numeric = 1.0
        AND review_status = 'active'
        AND execution_status = 'auto'
        AND source = 'curated'
        AND oracle_hash = 'f2c5ac0f52963cd710470adc25cc6d7c'
    ) AS exact_executable_rule_rows,
    count(*) FILTER (
      WHERE logical_rule_key <> 'battle_rule_v1:70c8478871f352b46cee1af296117951'
        AND effect_json->>'effect' IN ('topdeck_manipulation', 'draw_cards')
        AND review_status NOT IN ('rejected', 'deprecated')
        AND execution_status IN ('auto', 'executable', 'review_only')
    ) AS legacy_enabled_topdeck_rows,
    count(*) FILTER (
      WHERE review_status IN ('verified', 'active')
        AND execution_status IN ('auto', 'executable')
        AND coalesce(oracle_hash, '') = ''
    ) AS trusted_executable_without_oracle_hash_rows
  FROM card_battle_rules
  WHERE normalized_name = 'sensei''s divining top'
)
SELECT
  'pg039_senseis_top_precheck_counts' AS check_name,
  oracle_stats.card_rows,
  oracle_stats.distinct_oracle_ids,
  oracle_stats.expected_oracle_hash_rows,
  rule_stats.exact_executable_rule_rows,
  rule_stats.legacy_enabled_topdeck_rows,
  rule_stats.trusted_executable_without_oracle_hash_rows
FROM oracle_stats, rule_stats;

SELECT
  'pg039_senseis_top_precheck_rules' AS check_name,
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
WHERE normalized_name = 'sensei''s divining top'
ORDER BY source, review_status, execution_status, logical_rule_key;
