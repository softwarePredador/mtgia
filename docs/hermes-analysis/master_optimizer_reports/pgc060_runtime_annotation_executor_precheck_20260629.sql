WITH target AS (
  SELECT
    normalized_name,
    logical_rule_key,
    oracle_hash,
    rule_version,
    review_status,
    execution_status,
    effect_json
  FROM public.card_battle_rules
  WHERE (normalized_name = 'furygale flocking'
     AND logical_rule_key = 'battle_rule_v1:63b66f50aad09aa5669ac693b2fca7e5')
     OR (normalized_name = 'tempt with bunnies'
     AND logical_rule_key IN (
       'battle_rule_v1:64814289c1def19e7cd5bb7462c4cf86',
       'battle_rule_v1:ac96c7799172699f5d7b6b0dc5e4aa80'
     ))
)
SELECT
  count(*) AS target_rows,
  count(*) FILTER (
    WHERE review_status = 'verified'
      AND execution_status = 'auto'
      AND (
        (normalized_name = 'furygale flocking'
          AND oracle_hash = '8946b0e85c8430c6105ea70c7fb2724a')
        OR
        (normalized_name = 'tempt with bunnies'
          AND oracle_hash = '201f6c7234bfef550f3d497e736f0d7a')
      )
  ) AS trusted_target_rows,
  count(*) FILTER (
    WHERE effect_json ->> 'attack_each_opponent_this_turn_status' = 'annotation_only'
       OR effect_json ->> 'tempting_offer_opponent_choice_status' = 'annotation_only'
  ) AS current_annotation_rows,
  CASE
    WHEN to_regclass('manaloom_deploy_audit.pgc060_runtime_annotation_executor_20260629') IS NULL
      THEN 0
    ELSE 1
  END AS backup_table_exists
FROM target;
