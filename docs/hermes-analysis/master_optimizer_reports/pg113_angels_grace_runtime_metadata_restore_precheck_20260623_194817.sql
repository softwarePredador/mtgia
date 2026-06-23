\pset pager off

WITH target AS (
  SELECT
    'angel''s grace'::text AS normalized_name,
    'battle_rule_v1:2833836fd4d943d3e02d1cfa2d284227'::text AS logical_rule_key,
    '627c4ce7adf5be44b93e2b850159e5d9'::text AS expected_oracle_hash
),
row_match AS (
  SELECT
    c.name,
    md5(coalesce(c.oracle_text, '')) AS current_oracle_hash,
    r.normalized_name,
    r.logical_rule_key,
    r.source,
    r.review_status,
    r.execution_status,
    r.rule_version,
    r.oracle_hash,
    r.effect_json,
    r.deck_role_json,
    r.reviewed_by,
    r.updated_at
  FROM target t
  JOIN public.cards c ON lower(c.name) = t.normalized_name
  JOIN public.card_battle_rules r
    ON r.normalized_name = t.normalized_name
   AND r.logical_rule_key = t.logical_rule_key
)
SELECT
  (SELECT count(*) FROM row_match) AS target_rule_rows,
  (SELECT count(*) FROM row_match WHERE review_status = 'verified' AND execution_status = 'auto' AND source = 'curated') AS trusted_auto_rows,
  (SELECT count(*) FROM row_match rm JOIN target t ON rm.current_oracle_hash = t.expected_oracle_hash) AS card_hash_match_rows,
  (SELECT count(*) FROM row_match rm JOIN target t ON rm.oracle_hash = t.expected_oracle_hash) AS rule_hash_match_rows,
  (SELECT count(*) FROM row_match WHERE effect_json->>'battle_model_scope' = 'split_second_cannot_lose_opponents_cannot_win_damage_life_floor_v1') AS expected_scope_rows,
  (SELECT count(*) FROM row_match WHERE effect_json->>'oracle_runtime_scope' = 'cannot_lose_opponents_cannot_win_damage_life_floor_split_second_annotation') AS expected_runtime_scope_rows,
  (SELECT count(*) FROM row_match WHERE effect_json->>'split_second' = 'true') AS split_second_rows,
  (SELECT count(*) FROM row_match WHERE effect_json->>'opponents_cant_win_this_turn' = 'true') AS opponents_cant_win_rows,
  (SELECT count(*) FROM row_match WHERE nullif(oracle_hash, '') IS NULL
      OR effect_json->>'battle_model_scope' IS DISTINCT FROM 'split_second_cannot_lose_opponents_cannot_win_damage_life_floor_v1'
      OR effect_json->>'oracle_runtime_scope' IS DISTINCT FROM 'cannot_lose_opponents_cannot_win_damage_life_floor_split_second_annotation'
      OR effect_json->>'split_second' IS DISTINCT FROM 'true'
      OR effect_json->>'opponents_cant_win_this_turn' IS DISTINCT FROM 'true') AS metadata_deficient_rows,
  (SELECT to_regclass('manaloom_deploy_audit.pg113_angels_grace_runtime_metadata_restore_20260623_194817') IS NOT NULL) AS backup_table_exists;

SELECT
  r.card_name,
  r.normalized_name,
  r.logical_rule_key,
  r.review_status,
  r.execution_status,
  r.rule_version,
  r.oracle_hash,
  r.confidence,
  r.effect_json->>'effect' AS effect,
  r.effect_json->>'battle_model_scope' AS battle_model_scope,
  r.effect_json->>'life_floor_on_damage' AS life_floor_on_damage,
  r.effect_json->>'split_second' AS split_second,
  r.effect_json->>'opponents_cant_win_this_turn' AS opponents_cant_win_this_turn,
  r.effect_json->>'oracle_runtime_scope' AS oracle_runtime_scope,
  r.reviewed_by,
  r.updated_at
FROM public.card_battle_rules r
WHERE r.normalized_name = 'angel''s grace'
  AND r.logical_rule_key = 'battle_rule_v1:2833836fd4d943d3e02d1cfa2d284227';
