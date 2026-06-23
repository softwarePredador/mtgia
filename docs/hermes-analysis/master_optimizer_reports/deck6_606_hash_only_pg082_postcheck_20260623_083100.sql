\pset pager off

WITH expected(normalized_name, logical_rule_key, expected_oracle_hash, expected_effect, expected_scope) AS (
  VALUES
    ('library of leng', 'battle_rule_v1:b6491cf6f7d7df9a3fb0d91abd3d31c3', '575aef3cc2523831e440ea7dcd55fa6e', 'passive', 'discard_replacement_to_top_v1'),
    ('scroll rack', 'battle_rule_v1:3b58ff16a7eb52fb05c1bd8517225cd2', '8133928f03d5a5a77f2beecfcbd09e30', 'topdeck_manipulation', 'scroll_rack_upkeep_single_exchange_v1'),
    ('unexpected windfall', 'battle_rule_v1:f9f98ea1925518eea7a7c94c21ef2dc4', '9c4fbe06104051a2e8b1d295d307b26a', 'treasure_maker', 'discard_draw_create_treasures_v1'),
    ('valakut awakening // valakut stoneforge', 'battle_rule_v1:6e1f3b876822abafe1de47610f46858d', '22b42fcc181b7aed71f78b2e1e51e887', 'hand_filter', 'bottom_then_draw_plus_one_mdfc_land_v1'),
    ('wayfarer''s bauble', 'battle_rule_v1:97eb0d5868d1c777b74aa7d35fc85eab', 'f11935fa793ae03d95ae75d62cdfa516', 'ramp_permanent', 'self_sacrifice_basic_land_tutor_artifact_v1')
),
target_rules AS (
  SELECT cbr.*, e.expected_oracle_hash, e.expected_effect, e.expected_scope
  FROM expected e
  JOIN card_battle_rules cbr
    ON cbr.normalized_name = e.normalized_name
   AND cbr.logical_rule_key = e.logical_rule_key
),
shadow_rules AS (
  SELECT cbr.*
  FROM expected e
  JOIN card_battle_rules cbr
    ON cbr.normalized_name = e.normalized_name
   AND cbr.source = 'generated'
)
SELECT
  (SELECT count(*) FROM expected) AS expected_target_rules,
  (SELECT count(*) FROM target_rules) AS target_rule_rows,
  (SELECT count(*) FROM target_rules WHERE oracle_hash = expected_oracle_hash) AS target_hash_match_rows,
  (SELECT count(*) FROM target_rules WHERE oracle_hash IS NULL OR oracle_hash = '') AS target_missing_hash_rows,
  (SELECT count(*) FROM target_rules WHERE effect_json->>'effect' = expected_effect) AS target_expected_effect_rows,
  (SELECT count(*) FROM target_rules WHERE effect_json->>'battle_model_scope' = expected_scope) AS target_expected_scope_rows,
  (SELECT count(*) FROM target_rules WHERE source IN ('manual', 'curated') AND execution_status IN ('auto', 'executable')) AS trusted_auto_rows,
  (SELECT count(*) FROM target_rules WHERE rule_version >= 2) AS rule_version_at_least_2_rows,
  (SELECT count(*) FROM shadow_rules) AS generated_shadow_rows,
  (SELECT count(*) FROM shadow_rules WHERE execution_status <> 'disabled') AS non_disabled_shadow_rows,
  (SELECT count(*) FROM manaloom_deploy_audit.pg082_deck6_606_hash_only_20260623_083100) AS backup_rows;

WITH expected(normalized_name, logical_rule_key) AS (
  VALUES
    ('library of leng', 'battle_rule_v1:b6491cf6f7d7df9a3fb0d91abd3d31c3'),
    ('scroll rack', 'battle_rule_v1:3b58ff16a7eb52fb05c1bd8517225cd2'),
    ('unexpected windfall', 'battle_rule_v1:f9f98ea1925518eea7a7c94c21ef2dc4'),
    ('valakut awakening // valakut stoneforge', 'battle_rule_v1:6e1f3b876822abafe1de47610f46858d'),
    ('wayfarer''s bauble', 'battle_rule_v1:97eb0d5868d1c777b74aa7d35fc85eab')
)
SELECT
  cbr.card_name,
  cbr.logical_rule_key,
  cbr.oracle_hash,
  cbr.effect_json->>'effect' AS effect,
  cbr.effect_json->>'battle_model_scope' AS battle_model_scope,
  cbr.review_status,
  cbr.execution_status,
  cbr.rule_version
FROM expected e
JOIN card_battle_rules cbr
  ON cbr.normalized_name = e.normalized_name
 AND cbr.logical_rule_key = e.logical_rule_key
ORDER BY e.normalized_name;
