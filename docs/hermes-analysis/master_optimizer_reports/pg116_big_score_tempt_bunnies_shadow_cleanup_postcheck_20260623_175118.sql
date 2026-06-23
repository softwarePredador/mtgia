WITH promoted AS (
  SELECT
    normalized_name,
    count(*) FILTER (
      WHERE review_status IN ('verified', 'active')
        AND execution_status IN ('auto', 'executable')
        AND (
          (normalized_name = 'big score'
            AND logical_rule_key = 'battle_rule_v1:af9f14d18cc283719be2ef2680b6f1ed'
            AND oracle_hash = '9c4fbe06104051a2e8b1d295d307b26a')
          OR
          (normalized_name = 'tempt with bunnies'
            AND logical_rule_key IN (
              'battle_rule_v1:64814289c1def19e7cd5bb7462c4cf86',
              'battle_rule_v1:ac96c7799172699f5d7b6b0dc5e4aa80'
            )
            AND oracle_hash = '201f6c7234bfef550f3d497e736f0d7a')
        )
    ) AS promoted_rows,
    count(*) FILTER (
      WHERE review_status NOT IN ('deprecated', 'rejected')
        AND (
          (normalized_name = 'big score' AND logical_rule_key IN (
            'battle_rule_v1:1c91b96cef3218cfe2eaed9484a5661b',
            'battle_rule_v1:ff9144b5fff75408e1a76a99888fdeca'
          ))
          OR
          (normalized_name = 'tempt with bunnies' AND logical_rule_key = 'battle_rule_v1:030b2f3e0f549a462c3c8ea429877980')
        )
    ) AS active_shadow_rows
  FROM public.card_battle_rules
  WHERE normalized_name IN ('big score', 'tempt with bunnies')
  GROUP BY normalized_name
)
SELECT *
FROM promoted
ORDER BY normalized_name;

SELECT count(*) AS backup_rows
FROM manaloom_deploy_audit.pg116_big_score_tempt_bunnies_shadow_cleanup_20260623_175118;

SELECT
  r.card_name,
  r.logical_rule_key,
  r.review_status,
  r.execution_status,
  r.rule_version,
  r.oracle_hash,
  r.effect_json
FROM public.card_battle_rules r
WHERE r.normalized_name IN ('big score', 'tempt with bunnies')
ORDER BY r.card_name, r.review_status, r.execution_status, r.logical_rule_key;
