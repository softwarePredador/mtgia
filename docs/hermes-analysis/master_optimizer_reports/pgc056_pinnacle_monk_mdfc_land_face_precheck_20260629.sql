WITH target AS (
  SELECT
    r.normalized_name,
    r.logical_rule_key,
    r.oracle_hash,
    r.rule_version,
    r.review_status,
    r.execution_status,
    r.effect_json
  FROM public.card_battle_rules r
  WHERE r.normalized_name = 'pinnacle monk // mystic peak'
    AND r.logical_rule_key = 'battle_rule_v1:bcde63b5e56f2b9f20af6384bc70ad5d'
)
SELECT
  count(*) AS target_rows,
  count(*) FILTER (
    WHERE review_status = 'verified'
      AND execution_status = 'auto'
      AND oracle_hash = 'aa1967461796c715e0c5e0b4d741f249'
  ) AS trusted_target_rows,
  count(*) FILTER (
    WHERE effect_json ->> 'back_face_land_status' = 'annotation_only'
  ) AS current_annotation_rows,
  count(*) FILTER (
    WHERE effect_json ? 'mdfc_land_face'
  ) AS current_mdfc_land_face_rows,
  CASE
    WHEN to_regclass('manaloom_deploy_audit.pgc056_pinnacle_monk_mdfc_land_face_20260629') IS NULL
      THEN 0
    ELSE 1
  END AS backup_table_exists
FROM target;
