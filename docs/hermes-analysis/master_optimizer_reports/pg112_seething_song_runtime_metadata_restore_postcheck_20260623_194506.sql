\pset pager off

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
  (SELECT count(*) FROM row_match WHERE effect_json->>'battle_model_scope' = 'single_shot_red_ritual_v1') AS expected_scope_rows,
  (SELECT count(*) FROM row_match WHERE effect_json->>'mana_color_status' = 'abstracted_to_generic_pool_runtime') AS expected_mana_color_status_rows,
  (SELECT count(*) FROM row_match WHERE effect_json->>'oracle_runtime_scope' = 'single_shot_red_ritual_runtime_generic_pool_color_annotation') AS expected_runtime_scope_rows,
  (SELECT count(*) FROM row_match WHERE effect_json->>'pg058_l3b_simple_red_ritual_family' = 'deck6_simple_red_rituals') AS expected_family_rows,
  (SELECT count(*) FROM manaloom_deploy_audit.pg112_seething_song_runtime_metadata_restore_20260623_194506) AS backup_rows;

SELECT
  r.card_name,
  r.normalized_name,
  r.logical_rule_key,
  r.review_status,
  r.execution_status,
  r.rule_version,
  r.oracle_hash,
  r.effect_json->>'effect' AS effect,
  r.effect_json->>'battle_model_scope' AS battle_model_scope,
  r.effect_json->>'produces' AS produces,
  r.effect_json->>'mana_produced' AS mana_produced,
  r.effect_json->>'mana_color_status' AS mana_color_status,
  r.effect_json->>'oracle_runtime_scope' AS oracle_runtime_scope,
  r.effect_json->>'pg058_l3b_simple_red_ritual_family' AS pg058_family,
  r.reviewed_by,
  r.updated_at
FROM public.card_battle_rules r
WHERE r.normalized_name = 'seething song'
  AND r.logical_rule_key = 'battle_rule_v1:3eb15dc581c6b913158f9b63c023f3d7';
