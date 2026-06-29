SELECT
  count(*) AS target_rows,
  count(*) FILTER (
    WHERE effect_json ->> 'back_face_land_status' = 'runtime_executor_v1'
  ) AS back_face_runtime_rows,
  count(*) FILTER (
    WHERE effect_json #>> '{mdfc_land_face,name}' = 'Mystic Peak'
      AND effect_json #>> '{mdfc_land_face,effect}' = 'land'
      AND effect_json #>> '{mdfc_land_face,produces}' = 'R'
      AND effect_json #>> '{mdfc_land_face,enters_tapped_unless_pay_life}' = '3'
      AND effect_json #>> '{mdfc_land_face,enters_tapped_unless_pay_life_status}' = 'runtime_executor_v1'
  ) AS mdfc_red_land_face_rows,
  count(*) FILTER (
    WHERE rule_version >= 3
      AND reviewed_by = 'codex-pgc056'
  ) AS reviewed_version_rows,
  (
    SELECT count(*)
    FROM manaloom_deploy_audit.pgc056_pinnacle_monk_mdfc_land_face_20260629
  ) AS backup_rows
FROM public.card_battle_rules
WHERE normalized_name = 'pinnacle monk // mystic peak'
  AND logical_rule_key = 'battle_rule_v1:bcde63b5e56f2b9f20af6384bc70ad5d';
