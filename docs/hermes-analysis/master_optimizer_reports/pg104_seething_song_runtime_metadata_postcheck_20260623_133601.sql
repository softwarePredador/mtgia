WITH target AS (
  SELECT
    'seething song'::text AS normalized_name,
    'battle_rule_v1:3eb15dc581c6b913158f9b63c023f3d7'::text AS logical_rule_key,
    'ccd492289c6f1c14c8fb7a248d7bbf32'::text AS expected_oracle_hash
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
    r.confidence,
    r.oracle_hash,
    r.effect_json,
    r.notes
  FROM target t
  JOIN public.cards c ON lower(c.name) = t.normalized_name
  JOIN public.card_battle_rules r
    ON r.normalized_name = t.normalized_name
   AND r.logical_rule_key = t.logical_rule_key
)
SELECT
  (SELECT count(*) FROM row_match) AS target_rule_rows,
  (SELECT count(*) FROM row_match rm JOIN target t ON rm.current_oracle_hash = t.expected_oracle_hash AND rm.oracle_hash = t.expected_oracle_hash) AS hash_match_rows,
  (SELECT count(*) FROM row_match WHERE review_status = 'verified' AND execution_status = 'auto' AND source = 'curated') AS trusted_auto_rows,
  (SELECT count(*) FROM row_match WHERE oracle_hash = 'ccd492289c6f1c14c8fb7a248d7bbf32') AS restored_oracle_hash_rows,
  (SELECT count(*) FROM row_match WHERE effect_json->>'mana_color_status' = 'abstracted_to_generic_pool_runtime') AS restored_mana_color_status_rows,
  (SELECT count(*) FROM row_match WHERE effect_json->>'oracle_runtime_scope' = 'single_shot_red_ritual_runtime_generic_pool_color_annotation') AS restored_oracle_runtime_scope_rows,
  (SELECT count(*) FROM row_match WHERE effect_json->>'pg058_l3b_simple_red_ritual_family' = 'deck6_simple_red_rituals') AS restored_pg058_family_rows,
  (SELECT count(*) FROM manaloom_deploy_audit.pg104_seething_song_runtime_metadata_20260623_133601) AS backup_rows;

WITH target AS (
  SELECT
    'seething song'::text AS normalized_name,
    'battle_rule_v1:3eb15dc581c6b913158f9b63c023f3d7'::text AS logical_rule_key
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
    r.confidence,
    r.oracle_hash,
    r.effect_json,
    r.notes
  FROM target t
  JOIN public.cards c ON lower(c.name) = t.normalized_name
  JOIN public.card_battle_rules r
    ON r.normalized_name = t.normalized_name
   AND r.logical_rule_key = t.logical_rule_key
)
SELECT
  rm.name,
  rm.current_oracle_hash,
  rm.logical_rule_key,
  rm.oracle_hash,
  rm.effect_json->>'battle_model_scope' AS battle_model_scope,
  rm.effect_json->>'mana_color_status' AS mana_color_status,
  rm.effect_json->>'oracle_runtime_scope' AS oracle_runtime_scope,
  rm.effect_json->>'pg058_l3b_simple_red_ritual_family' AS pg058_family,
  rm.review_status,
  rm.execution_status,
  rm.effect_json
FROM row_match rm;
