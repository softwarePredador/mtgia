\pset pager off
\set ON_ERROR_STOP on

WITH target_card AS (
  SELECT *
  FROM cards
  WHERE lower(name) = 'teferi''s protection'
),
exact_rule AS (
  SELECT *
  FROM card_battle_rules
  WHERE normalized_name = 'teferi''s protection'
    AND logical_rule_key = 'battle_rule_v1:c8b6905f312e06fe599dfb81bf4f3f4a'
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
SELECT 'card_rows' AS check_name, count(*)::text AS value FROM target_card
UNION ALL
SELECT 'distinct_oracle_ids', count(DISTINCT oracle_id)::text FROM target_card
UNION ALL
SELECT 'expected_oracle_hash_rows', count(*)::text
FROM target_card
WHERE md5(coalesce(oracle_text, '')) = 'bdc0faecf4420dc6162c7e72e98cc0eb'
UNION ALL
SELECT 'exact_executable_rule_rows', count(*)::text FROM exact_rule
UNION ALL
SELECT 'legacy_enabled_phase_out_rows', count(*)::text FROM legacy_rows
UNION ALL
SELECT 'trusted_executable_without_oracle_hash_rows', count(*)::text FROM trusted_without_hash;
