\pset pager off
\set ON_ERROR_STOP on

WITH exact_rule AS (
  SELECT *
  FROM card_battle_rules
  WHERE normalized_name = 'teferi''s protection'
    AND logical_rule_key = 'battle_rule_v1:c8b6905f312e06fe599dfb81bf4f3f4a'
    AND effect_json->>'effect' = 'phase_out'
    AND effect_json->>'life_total_cant_change' = 'true'
    AND effect_json->>'protection_from_everything' = 'true'
    AND effect_json->>'phase_out_all_permanents_you_control' = 'true'
    AND effect_json->>'phase_out_includes_lands' = 'true'
    AND effect_json->>'exiles_self' = 'true'
    AND effect_json->>'battle_model_scope' =
      'teferis_protection_life_lock_protection_all_permanents_phase_out_self_exile_v1'
    AND review_status = 'active'
    AND execution_status = 'auto'
    AND oracle_hash = 'bdc0faecf4420dc6162c7e72e98cc0eb'
),
legacy_rows AS (
  SELECT *
  FROM card_battle_rules
  WHERE normalized_name = 'teferi''s protection'
    AND logical_rule_key <> 'battle_rule_v1:c8b6905f312e06fe599dfb81bf4f3f4a'
    AND effect_json->>'effect' = 'phase_out'
    AND review_status NOT IN ('rejected', 'deprecated')
    AND execution_status IN ('auto', 'executable', 'review_only')
),
trusted_without_hash AS (
  SELECT *
  FROM card_battle_rules
  WHERE normalized_name = 'teferi''s protection'
    AND source IN ('manual', 'curated')
    AND review_status IN ('verified', 'active')
    AND execution_status IN ('auto', 'executable')
    AND coalesce(oracle_hash, '') = ''
)
SELECT 'exact_executable_rule_rows' AS check_name, count(*)::text AS value FROM exact_rule
UNION ALL
SELECT 'legacy_enabled_phase_out_rows', count(*)::text FROM legacy_rows
UNION ALL
SELECT 'trusted_executable_without_oracle_hash_rows', count(*)::text FROM trusted_without_hash
UNION ALL
SELECT 'active_rule_snapshot', jsonb_pretty(to_jsonb(exact_rule.*)) FROM exact_rule;
