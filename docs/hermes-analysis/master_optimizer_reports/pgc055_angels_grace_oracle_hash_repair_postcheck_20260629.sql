SELECT
  count(*) AS target_rows,
  count(*) FILTER (
    WHERE r.oracle_hash = md5(coalesce(c.oracle_text, ''))
      AND r.oracle_hash = '627c4ce7adf5be44b93e2b850159e5d9'
  ) AS restored_hash_rows,
  count(*) FILTER (
    WHERE r.review_status = 'verified'
      AND r.execution_status = 'auto'
  ) AS verified_auto_rows,
  count(*) FILTER (
    WHERE r.effect_json ->> 'battle_model_scope' = 'split_second_cannot_lose_opponents_cannot_win_damage_life_floor_v1'
      AND r.effect_json ->> 'oracle_runtime_scope' = 'cannot_lose_opponents_cannot_win_damage_life_floor_split_second_annotation'
      AND r.effect_json ->> 'split_second' = 'true'
      AND r.effect_json ->> 'opponents_cant_win_this_turn' = 'true'
  ) AS restored_runtime_metadata_rows,
  (
    SELECT count(*)
    FROM manaloom_deploy_audit.pgc055_angels_grace_oracle_hash_repair_20260629
  ) AS backup_rows
FROM public.card_battle_rules r
JOIN public.cards c
  ON c.id = r.card_id
WHERE r.normalized_name = 'angel''s grace'
  AND r.logical_rule_key = 'battle_rule_v1:2833836fd4d943d3e02d1cfa2d284227';
