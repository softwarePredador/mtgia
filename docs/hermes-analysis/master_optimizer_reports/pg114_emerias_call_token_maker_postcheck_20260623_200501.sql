WITH wanted(normalized_name, expected_hash, expected_rule_key) AS (
  VALUES
    (
      'emeria''s call // emeria, shattered skyclave',
      '2fab1a2b9eb87041bc9e93f3b8d52831',
      'battle_rule_v1:ae4a933d873bec332ec2a46106b79277'
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg114_emerias_call_token_maker_20260623_200501) AS backup_rows
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
  r.effect_json->>'token_count' AS token_count,
  r.effect_json->>'token_name' AS token_name,
  r.effect_json->>'grant_non_angel_creatures_indestructible_until_next_turn' AS grants_non_angel_indestructible
FROM public.card_battle_rules r
WHERE r.normalized_name = 'emeria''s call // emeria, shattered skyclave'
ORDER BY r.review_status, r.execution_status, r.logical_rule_key;
