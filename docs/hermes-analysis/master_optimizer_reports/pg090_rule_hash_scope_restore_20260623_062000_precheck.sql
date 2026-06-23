\pset pager off

BEGIN;

CREATE TEMP TABLE pg090_rule_hash_scope_restore_target AS
SELECT 'Angel''s Grace'::text AS name, 'angel''s grace'::text AS normalized_name, 'battle_rule_v1:2833836fd4d943d3e02d1cfa2d284227'::text AS logical_rule_key, '627c4ce7adf5be44b93e2b850159e5d9'::text AS expected_oracle_hash, 0.97::numeric AS expected_confidence, '{"battle_model_scope": "split_second_cannot_lose_opponents_cannot_win_damage_life_floor_v1", "opponents_cant_win_this_turn": true, "oracle_runtime_scope": "cannot_lose_opponents_cannot_win_damage_life_floor_split_second_annotation", "split_second": true}'::jsonb AS effect_patch
UNION ALL
SELECT 'Fellwar Stone'::text AS name, 'fellwar stone'::text AS normalized_name, 'battle_rule_v1:3906ffa3cbf7d3437d68e44e13e10bba'::text AS logical_rule_key, 'd63befc8ac40d9a38732f9b5c1a7414a'::text AS expected_oracle_hash, 0.9::numeric AS expected_confidence, '{}'::jsonb AS effect_patch
UNION ALL
SELECT 'Library of Leng'::text AS name, 'library of leng'::text AS normalized_name, 'battle_rule_v1:b6491cf6f7d7df9a3fb0d91abd3d31c3'::text AS logical_rule_key, '575aef3cc2523831e440ea7dcd55fa6e'::text AS expected_oracle_hash, 0.93::numeric AS expected_confidence, '{}'::jsonb AS effect_patch
UNION ALL
SELECT 'Mana Vault'::text AS name, 'mana vault'::text AS normalized_name, 'battle_rule_v1:5a2533694ffd19223d3cde1e25d258ff'::text AS logical_rule_key, '35e3fd94c8453c0e326033af49ae18c8'::text AS expected_oracle_hash, 0.91::numeric AS expected_confidence, '{}'::jsonb AS effect_patch
UNION ALL
SELECT 'Mox Amber'::text AS name, 'mox amber'::text AS normalized_name, 'battle_rule_v1:972703914ee50acd7a4e6f529fea1adf'::text AS logical_rule_key, 'e47b40cf2afc4c9ceac6bf91815da706'::text AS expected_oracle_hash, 0.98::numeric AS expected_confidence, '{}'::jsonb AS effect_patch
UNION ALL
SELECT 'Scroll Rack'::text AS name, 'scroll rack'::text AS normalized_name, 'battle_rule_v1:3b58ff16a7eb52fb05c1bd8517225cd2'::text AS logical_rule_key, '8133928f03d5a5a77f2beecfcbd09e30'::text AS expected_oracle_hash, 0.8::numeric AS expected_confidence, '{}'::jsonb AS effect_patch
UNION ALL
SELECT 'Seething Song'::text AS name, 'seething song'::text AS normalized_name, 'battle_rule_v1:3eb15dc581c6b913158f9b63c023f3d7'::text AS logical_rule_key, 'ccd492289c6f1c14c8fb7a248d7bbf32'::text AS expected_oracle_hash, 0.97::numeric AS expected_confidence, '{"mana_color_status": "abstracted_to_generic_pool_runtime", "oracle_runtime_scope": "single_shot_red_ritual_runtime_generic_pool_color_annotation", "pg058_l3b_simple_red_ritual_family": "deck6_simple_red_rituals"}'::jsonb AS effect_patch
UNION ALL
SELECT 'Silence'::text AS name, 'silence'::text AS normalized_name, 'battle_rule_v1:74b210b77b004a677906e0216d44e445'::text AS logical_rule_key, 'a0ca3c09a7db091c435ab31adb9c1780'::text AS expected_oracle_hash, 0.97::numeric AS expected_confidence, '{"oracle_runtime_scope": "opponent_spell_cast_lock_until_eot_runtime"}'::jsonb AS effect_patch
UNION ALL
SELECT 'Talisman of Conviction'::text AS name, 'talisman of conviction'::text AS normalized_name, 'battle_rule_v1:02133e513da5ea98ac74d32d39b16470'::text AS logical_rule_key, 'd49ceec937367a344a9f0948eea4f8f2'::text AS expected_oracle_hash, 0.9::numeric AS expected_confidence, '{}'::jsonb AS effect_patch
UNION ALL
SELECT 'Unexpected Windfall'::text AS name, 'unexpected windfall'::text AS normalized_name, 'battle_rule_v1:f9f98ea1925518eea7a7c94c21ef2dc4'::text AS logical_rule_key, '9c4fbe06104051a2e8b1d295d307b26a'::text AS expected_oracle_hash, 0.97::numeric AS expected_confidence, '{}'::jsonb AS effect_patch
UNION ALL
SELECT 'Valakut Awakening // Valakut Stoneforge'::text AS name, 'valakut awakening // valakut stoneforge'::text AS normalized_name, 'battle_rule_v1:6e1f3b876822abafe1de47610f46858d'::text AS logical_rule_key, '22b42fcc181b7aed71f78b2e1e51e887'::text AS expected_oracle_hash, 0.95::numeric AS expected_confidence, '{}'::jsonb AS effect_patch
UNION ALL
SELECT 'Wayfarer''s Bauble'::text AS name, 'wayfarer''s bauble'::text AS normalized_name, 'battle_rule_v1:97eb0d5868d1c777b74aa7d35fc85eab'::text AS logical_rule_key, 'f11935fa793ae03d95ae75d62cdfa516'::text AS expected_oracle_hash, 0.92::numeric AS expected_confidence, '{}'::jsonb AS effect_patch;

SELECT
  (SELECT count(*) FROM pg090_rule_hash_scope_restore_target) AS expected_target_rules,
  (SELECT count(*) FROM pg090_rule_hash_scope_restore_target t JOIN card_battle_rules r ON r.normalized_name = t.normalized_name AND r.logical_rule_key = t.logical_rule_key) AS target_rule_rows,
  (SELECT count(*) FROM pg090_rule_hash_scope_restore_target t JOIN cards c ON lower(c.name) = t.normalized_name WHERE md5(coalesce(c.oracle_text, '')) = t.expected_oracle_hash) AS raw_oracle_hash_match_rows,
  (SELECT count(*) FROM pg090_rule_hash_scope_restore_target t JOIN card_battle_rules r ON r.normalized_name = t.normalized_name AND r.logical_rule_key = t.logical_rule_key WHERE r.oracle_hash IS NULL OR r.oracle_hash <> t.expected_oracle_hash OR NOT (coalesce(r.effect_json, '{}'::jsonb) @> t.effect_patch)) AS rows_needing_restore,
  (SELECT count(*) FROM pg090_rule_hash_scope_restore_target t JOIN card_battle_rules r ON r.logical_rule_key = t.logical_rule_key AND r.normalized_name <> t.normalized_name) AS key_conflict_rows,
  (to_regclass('manaloom_deploy_audit.pg090_rule_hash_scope_restore_20260623_062000') IS NOT NULL) AS backup_table_already_exists;

SELECT
  t.name,
  t.logical_rule_key,
  t.expected_oracle_hash,
  r.oracle_hash AS current_oracle_hash,
  t.effect_patch,
  r.effect_json AS current_effect_json,
  r.confidence AS current_confidence,
  t.expected_confidence
FROM pg090_rule_hash_scope_restore_target t
JOIN card_battle_rules r
  ON r.normalized_name = t.normalized_name
 AND r.logical_rule_key = t.logical_rule_key
ORDER BY t.name;

ROLLBACK;
