\pset pager off
\set ON_ERROR_STOP on

SELECT
  'pg035_lorehold_postcheck_counts' AS check_name,
  (
    SELECT count(*)
    FROM card_battle_rules
    WHERE normalized_name = 'lorehold, the historian'
      AND logical_rule_key = 'battle_rule_v1:06d892f8ad75831f785aef6dcedc82b4'
      AND effect_json->>'effect' = 'passive'
      AND effect_json->>'battle_model_scope' =
        'lorehold_opponent_upkeep_miracle_v1'
      AND effect_json->>'cmc' = '5.0'
      AND effect_json->>'is_commander' = 'true'
      AND effect_json->>'flying' = 'true'
      AND effect_json->>'haste' = 'true'
      AND effect_json->>'grants_miracle_cost' = '2'
      AND effect_json->>'opponent_upkeep_rummage' = 'true'
      AND deck_role_json->>'battle_model_scope' =
        'lorehold_opponent_upkeep_miracle_v1'
      AND review_status = 'active'
      AND execution_status = 'auto'
      AND source = 'curated'
      AND oracle_hash = 'f1b6d4f38a533e56f0efb5a3f1547214'
  ) AS exact_executable_rule_rows,
  (
    SELECT count(*)
    FROM card_battle_rules
    WHERE normalized_name = 'lorehold, the historian'
      AND logical_rule_key <> 'battle_rule_v1:06d892f8ad75831f785aef6dcedc82b4'
      AND effect_json->>'effect' IN ('commander', 'draw_engine', 'passive')
      AND review_status NOT IN ('rejected', 'deprecated')
      AND execution_status IN ('auto', 'executable', 'review_only')
  ) AS legacy_enabled_lorehold_rows,
  (
    SELECT count(*)
    FROM card_battle_rules
    WHERE normalized_name = 'lorehold, the historian'
      AND review_status IN ('verified', 'active')
      AND execution_status IN ('auto', 'executable')
      AND coalesce(oracle_hash, '') = ''
  ) AS trusted_executable_without_oracle_hash_rows;

SELECT
  'pg035_lorehold_rule_postcheck' AS check_name,
  card_name,
  logical_rule_key,
  effect_json,
  deck_role_json,
  source,
  confidence,
  review_status,
  execution_status,
  oracle_hash,
  reviewed_by,
  reviewed_at
FROM card_battle_rules
WHERE normalized_name = 'lorehold, the historian'
ORDER BY source, review_status, execution_status, logical_rule_key;

SELECT
  'pg035_lorehold_snapshot_postcheck' AS check_name,
  name,
  function_tags,
  battle_rules
FROM card_intelligence_snapshot
WHERE lower(name) = 'lorehold, the historian';
