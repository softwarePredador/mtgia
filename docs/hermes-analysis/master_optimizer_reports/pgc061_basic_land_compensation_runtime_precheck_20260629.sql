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
  WHERE (normalized_name = 'erode'
     AND logical_rule_key = 'battle_rule_v1:dd175af9c77feea940de97138a916fe3')
     OR (normalized_name = 'sundering eruption // volcanic fissure'
     AND logical_rule_key = 'battle_rule_v1:98d0006543fc622cfc1d82991bd5a66a')
)
SELECT
  count(*) AS target_rows,
  count(*) FILTER (
    WHERE review_status = 'verified'
      AND execution_status = 'auto'
      AND (
        (normalized_name = 'erode'
          AND oracle_hash = 'fade62a3cbc3e6987d7988b711a5a834')
        OR
        (normalized_name = 'sundering eruption // volcanic fissure'
          AND oracle_hash = '09148a5a6f4d14c04a30bf19819e20b8')
      )
  ) AS trusted_target_rows,
  count(*) FILTER (
    WHERE effect_json ->> 'basic_land_compensation_status' = 'annotation_only'
  ) AS current_basic_land_annotation_rows,
  CASE
    WHEN to_regclass('manaloom_deploy_audit.pgc061_basic_land_compensation_runtime_20260629') IS NULL
      THEN 0
    ELSE 1
  END AS backup_table_exists
FROM target;
