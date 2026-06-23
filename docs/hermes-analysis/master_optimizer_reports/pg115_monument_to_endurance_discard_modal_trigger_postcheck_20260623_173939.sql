WITH wanted(normalized_name, expected_hash, expected_rule_key) AS (
  VALUES
    (
      'monument to endurance',
      'a60dc736f7e86e15001c8c7e59ff23c4',
      'battle_rule_v1:0ae531be7c36226d3f118c93feab3735'
    )
),
rule_rows AS (
  SELECT
    w.normalized_name AS wanted_normalized_name,
    w.expected_hash,
    w.expected_rule_key,
    r.logical_rule_key,
    r.review_status,
    r.execution_status,
    r.oracle_hash
  FROM wanted w
  LEFT JOIN public.card_battle_rules r
    ON r.normalized_name = w.normalized_name
)
SELECT
  wanted_normalized_name AS normalized_name,
  expected_rule_key,
  count(*) FILTER (WHERE logical_rule_key = expected_rule_key) AS promoted_rule_rows,
  count(*) FILTER (
    WHERE logical_rule_key = expected_rule_key
      AND review_status = 'verified'
      AND execution_status = 'auto'
  ) AS promoted_verified_auto_rows,
  count(*) FILTER (
    WHERE logical_rule_key = expected_rule_key
      AND oracle_hash = expected_hash
  ) AS promoted_oracle_hash_rows,
  count(*) FILTER (
    WHERE logical_rule_key <> expected_rule_key
      AND review_status NOT IN ('deprecated', 'rejected')
      AND execution_status <> 'disabled'
  ) AS active_shadow_rows,
  (SELECT count(*) FROM manaloom_deploy_audit.pg115_monument_to_endurance_discard_modal_trigger_20260623_1739) AS backup_rows
FROM rule_rows
GROUP BY wanted_normalized_name, expected_rule_key, expected_hash
ORDER BY wanted_normalized_name;

SELECT
  r.normalized_name,
  r.logical_rule_key,
  r.review_status,
  r.execution_status,
  r.oracle_hash,
  r.effect_json->>'battle_model_scope' AS battle_model_scope,
  r.effect_json->>'effect' AS effect,
  r.effect_json->>'trigger_event' AS trigger_event,
  r.effect_json->>'turn_limited_unique_modes' AS turn_limited_unique_modes,
  r.effect_json->'discard_trigger_modes' AS discard_trigger_modes
FROM public.card_battle_rules r
WHERE r.normalized_name = 'monument to endurance'
ORDER BY r.review_status, r.execution_status, r.logical_rule_key;
