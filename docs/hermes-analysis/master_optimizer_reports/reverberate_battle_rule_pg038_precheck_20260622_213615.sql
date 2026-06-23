\pset pager off
\set ON_ERROR_STOP on

WITH oracle_stats AS (
  SELECT
    count(*) AS card_rows,
    count(DISTINCT oracle_id) AS distinct_oracle_ids,
    count(*) FILTER (
      WHERE md5(regexp_replace(lower(coalesce(oracle_text, '')), '\s+', ' ', 'g')) =
        'cbae05dee4261e3ed5412fd5f3591c17'
    ) AS expected_oracle_hash_rows
  FROM cards
  WHERE lower(name) = 'reverberate'
),
rule_stats AS (
  SELECT
    count(*) FILTER (
      WHERE logical_rule_key = 'battle_rule_v1:0269136edf067f696c8576740b720e14'
        AND effect_json->>'effect' = 'copy_spell'
        AND effect_json->>'target' = 'instant_or_sorcery_on_stack'
        AND effect_json->>'instant' = 'true'
        AND effect_json->>'copy_is_not_cast' = 'true'
        AND effect_json->>'may_choose_new_targets' = 'true'
        AND effect_json->>'choose_new_targets_status' = 'annotation_only'
        AND effect_json->>'battle_model_scope' =
          'reverberate_copy_stack_instant_or_sorcery_new_targets_annotation_v1'
        AND (effect_json->>'cmc')::numeric = 2.0
        AND review_status = 'active'
        AND execution_status = 'auto'
        AND source = 'curated'
        AND oracle_hash = 'cbae05dee4261e3ed5412fd5f3591c17'
    ) AS exact_executable_rule_rows,
    count(*) FILTER (
      WHERE logical_rule_key <> 'battle_rule_v1:0269136edf067f696c8576740b720e14'
        AND effect_json->>'effect' = 'copy_spell'
        AND review_status NOT IN ('rejected', 'deprecated')
        AND execution_status IN ('auto', 'executable', 'review_only')
    ) AS legacy_enabled_copy_rows,
    count(*) FILTER (
      WHERE review_status IN ('verified', 'active')
        AND execution_status IN ('auto', 'executable')
        AND coalesce(oracle_hash, '') = ''
    ) AS trusted_executable_without_oracle_hash_rows
  FROM card_battle_rules
  WHERE normalized_name = 'reverberate'
)
SELECT
  'pg038_reverberate_precheck_counts' AS check_name,
  oracle_stats.card_rows,
  oracle_stats.distinct_oracle_ids,
  oracle_stats.expected_oracle_hash_rows,
  rule_stats.exact_executable_rule_rows,
  rule_stats.legacy_enabled_copy_rows,
  rule_stats.trusted_executable_without_oracle_hash_rows
FROM oracle_stats, rule_stats;

SELECT
  'pg038_reverberate_precheck_rules' AS check_name,
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
WHERE normalized_name = 'reverberate'
ORDER BY source, review_status, execution_status, logical_rule_key;
