-- PG061 Deck 6 L3B simple red rituals metadata confirmation postcheck.

WITH target_runtime(
  normalized_name,
  logical_rule_key,
  expected_hash,
  expected_mana,
  expected_scope,
  expected_runtime_scope,
  expected_mana_color_status
) AS (
  VALUES
    ('rite of flame', 'battle_rule_v1:b66dd96fa32c9822c798f16a83fa5518', '35a034ee45b092bc443cd5992d8793f4', 2, 'rite_of_flame_singleton_baseline_red_ritual_v1', 'single_shot_red_ritual_runtime_graveyard_copy_scaling_annotation_only', 'abstracted_to_generic_pool_runtime'),
    ('seething song', 'battle_rule_v1:3eb15dc581c6b913158f9b63c023f3d7', 'ccd492289c6f1c14c8fb7a248d7bbf32', 5, 'single_shot_red_ritual_v1', 'single_shot_red_ritual_runtime_generic_pool_color_annotation', 'abstracted_to_generic_pool_runtime')
),
target_rules AS (
  SELECT tr.*, cbr.source, cbr.review_status, cbr.execution_status, cbr.oracle_hash, cbr.effect_json, md5(coalesce(c.oracle_text, '')) AS live_hash
  FROM target_runtime tr
  JOIN card_battle_rules cbr ON cbr.normalized_name = tr.normalized_name
    AND cbr.logical_rule_key = tr.logical_rule_key
  JOIN cards c ON c.id = cbr.card_id
)
SELECT 'target_runtime_rows' AS metric, count(*)::text AS value
FROM target_rules
WHERE source = 'curated'
  AND review_status IN ('active', 'verified')
  AND execution_status = 'auto'
UNION ALL
SELECT 'target_hash_mismatch_rows', count(*)::text
FROM target_rules
WHERE oracle_hash IS DISTINCT FROM expected_hash
   OR live_hash IS DISTINCT FROM expected_hash
UNION ALL
SELECT 'target_bad_effect_rows', count(*)::text
FROM target_rules
WHERE effect_json->>'effect' IS DISTINCT FROM 'ramp_ritual'
UNION ALL
SELECT 'target_bad_mana_rows', count(*)::text
FROM target_rules
WHERE (effect_json->>'mana_produced')::int IS DISTINCT FROM expected_mana
UNION ALL
SELECT 'target_bad_scope_rows', count(*)::text
FROM target_rules
WHERE effect_json->>'battle_model_scope' IS DISTINCT FROM expected_scope
UNION ALL
SELECT 'target_missing_runtime_scope_rows', count(*)::text
FROM target_rules
WHERE effect_json->>'oracle_runtime_scope' IS DISTINCT FROM expected_runtime_scope
UNION ALL
SELECT 'target_missing_mana_color_status_rows', count(*)::text
FROM target_rules
WHERE effect_json->>'mana_color_status' IS DISTINCT FROM expected_mana_color_status
UNION ALL
SELECT 'backup_rows', count(*)::text
FROM manaloom_deploy_audit.pg061_deck6_l3b_simple_red_rituals_metadata_20260623_022418;
