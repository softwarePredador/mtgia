\pset pager off

SELECT
  count(*) AS target_rule_rows,
  count(*) FILTER (
    WHERE normalized_name = 'chaos warp'
      AND logical_rule_key = 'battle_rule_v1:0b547d7209a38ac2d23a1cca07917680'
      AND oracle_hash = '7db2bc44526b855fd22302e9569746b5'
      AND effect_json->>'effect' = 'remove_permanent'
      AND effect_json->>'target' = 'permanent'
      AND effect_json->>'destination' = 'library'
      AND effect_json->>'top_reveal_after_shuffle' = 'true'
      AND effect_json->>'battle_model_scope' = 'target_permanent_shuffle_into_owner_library_reveal_top_permanent_to_battlefield_v1'
      AND review_status = 'verified'
      AND execution_status = 'auto'
  ) AS expected_runtime_rows,
  count(*) FILTER (
    WHERE review_status IN ('verified', 'active', 'needs_review')
      AND execution_status IN ('auto', 'executable', 'review_only')
      AND logical_rule_key <> 'battle_rule_v1:0b547d7209a38ac2d23a1cca07917680'
  ) AS old_active_shadow_rows,
  count(*) FILTER (
    WHERE logical_rule_key = 'battle_rule_v1:0b547d7209a38ac2d23a1cca07917680'
      AND oracle_hash IS NULL
  ) AS runtime_missing_hash_rows,
  (
    SELECT count(*)
    FROM manaloom_deploy_audit.pg076_deck6_chaos_warp_runtime_20260623_055230
  ) AS backup_rows
FROM card_battle_rules
WHERE normalized_name = 'chaos warp';

SELECT
  normalized_name,
  logical_rule_key,
  source,
  review_status,
  execution_status,
  confidence,
  rule_version,
  oracle_hash,
  effect_json,
  deck_role_json,
  notes
FROM card_battle_rules
WHERE normalized_name = 'chaos warp'
ORDER BY normalized_name, review_status, execution_status, logical_rule_key;
