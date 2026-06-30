WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, expected_scope) AS (
  VALUES
    ('codex shredder', 'Codex Shredder', '48dd2cf11a80189f548581507ab88df9', 'battle_rule_v1:3417000adca740f0c5036e7232221df4', 'tap_target_player_mill_one_or_five_tap_sacrifice_return_target_card_from_your_graveyard_to_hand_v1')
),
rule_rows AS (
  SELECT
    r.normalized_name,
    r.logical_rule_key,
    r.oracle_hash,
    r.review_status,
    r.execution_status,
    r.effect_json
  FROM proposed p
  LEFT JOIN public.card_battle_rules r
    ON (
         r.normalized_name = p.normalized_name
         OR r.normalized_name LIKE p.normalized_name || ' // %'
       )
   AND r.logical_rule_key = p.logical_rule_key
),
all_rows AS (
  SELECT
    p.normalized_name,
    count(r.*) FILTER (
      WHERE r.review_status IN ('verified', 'active')
        AND r.execution_status IN ('auto', 'executable')
    ) AS active_runtime_rows_after,
    count(r.*) FILTER (
      WHERE r.review_status IN ('verified', 'active')
        AND r.execution_status IN ('auto', 'executable')
        AND coalesce(r.effect_json->>'battle_model_scope', '') LIKE 'xmage_%_review_v1'
    ) AS active_review_scope_rows_after,
    count(r.*) FILTER (
      WHERE r.review_status = 'deprecated'
        AND r.execution_status = 'disabled'
    ) AS deprecated_disabled_rows_after
  FROM proposed p
  LEFT JOIN public.card_battle_rules r
    ON (
         r.normalized_name = p.normalized_name
         OR r.normalized_name LIKE p.normalized_name || ' // %'
       )
  GROUP BY p.normalized_name
)
SELECT
  p.card_name,
  p.normalized_name,
  p.logical_rule_key,
  p.expected_scope,
  count(r.*) FILTER (WHERE r.logical_rule_key = p.logical_rule_key) AS promoted_rule_rows,
  count(r.*) FILTER (WHERE r.review_status = 'verified' AND r.execution_status = 'auto') AS promoted_verified_auto_rows,
  count(r.*) FILTER (WHERE r.oracle_hash = p.oracle_hash) AS promoted_oracle_hash_rows,
  count(r.*) FILTER (WHERE r.effect_json->>'battle_model_scope' = p.expected_scope) AS promoted_expected_scope_rows,
  max(ar.active_runtime_rows_after) AS active_runtime_rows_after,
  max(ar.active_review_scope_rows_after) AS active_review_scope_rows_after,
  max(ar.deprecated_disabled_rows_after) AS deprecated_disabled_rows_after,
  (SELECT count(*) FROM manaloom_deploy_audit.pg273_codex_shredder_mill_recursion_20260630) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
JOIN all_rows ar
  ON ar.normalized_name = p.normalized_name
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash, p.expected_scope
ORDER BY p.card_name;
