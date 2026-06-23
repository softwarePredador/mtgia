\pset pager off

CREATE TEMP TABLE pg069_target_rules AS
SELECT
  c.name,
  cbr.normalized_name,
  cbr.logical_rule_key,
  cbr.source,
  cbr.review_status,
  cbr.execution_status,
  cbr.confidence,
  cbr.oracle_hash,
  cbr.effect_json,
  cbr.deck_role_json,
  cbr.notes
FROM card_battle_rules cbr
JOIN cards c ON c.id = cbr.card_id
WHERE cbr.normalized_name IN ('the one ring', 'unexpected windfall');

SELECT
  count(*) AS target_rule_rows,
  count(*) FILTER (
    WHERE (
        normalized_name = 'the one ring'
        AND logical_rule_key = 'battle_rule_v1:a71907ee296b5801e92e8d7f1940dba1'
        AND oracle_hash = '644d5305e6be932586a6d3b7325cadf7'
        AND effect_json->>'effect' = 'draw_engine'
        AND effect_json->>'battle_model_scope' = 'the_one_ring_etb_protection_burden_draw_v1'
      )
      OR (
        normalized_name = 'unexpected windfall'
        AND logical_rule_key = 'battle_rule_v1:f9f98ea1925518eea7a7c94c21ef2dc4'
        AND oracle_hash = '9c4fbe06104051a2e8b1d295d307b26a'
        AND effect_json->>'effect' = 'treasure_maker'
        AND effect_json->>'battle_model_scope' = 'discard_draw_create_treasures_v1'
        AND coalesce((effect_json->>'requires_discard_card')::boolean, false) IS true
        AND (effect_json->>'draw_count')::integer = 2
        AND (effect_json->>'treasure_count')::integer = 2
      )
  ) AS expected_runtime_rows,
  count(*) FILTER (
    WHERE logical_rule_key NOT IN (
        'battle_rule_v1:a71907ee296b5801e92e8d7f1940dba1',
        'battle_rule_v1:f9f98ea1925518eea7a7c94c21ef2dc4'
      )
      AND review_status IN ('verified', 'active', 'needs_review')
      AND execution_status IN ('auto', 'executable', 'review_only')
  ) AS old_active_shadow_rows,
  count(*) FILTER (
    WHERE logical_rule_key IN (
        'battle_rule_v1:a71907ee296b5801e92e8d7f1940dba1',
        'battle_rule_v1:f9f98ea1925518eea7a7c94c21ef2dc4'
      )
      AND oracle_hash IS NULL
  ) AS runtime_missing_hash_rows,
  (
    SELECT count(*)
    FROM manaloom_deploy_audit.pg069_deck6_l2_specific_runtime_cleanup_20260623_005736
  ) AS backup_rows
FROM pg069_target_rules;

SELECT
  name,
  normalized_name,
  logical_rule_key,
  source,
  review_status,
  execution_status,
  confidence,
  oracle_hash,
  effect_json,
  deck_role_json,
  notes
FROM pg069_target_rules
ORDER BY name, review_status, execution_status, logical_rule_key;
