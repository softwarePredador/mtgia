-- PG059 Deck 6 L2 hash-only regression repair postcheck.

WITH target_runtime(
  card_name,
  normalized_name,
  logical_rule_key,
  expected_hash,
  expected_effect,
  expected_scope
) AS (
  VALUES
    ('Fellwar Stone', 'fellwar stone', 'battle_rule_v1:3906ffa3cbf7d3437d68e44e13e10bba', 'd63befc8ac40d9a38732f9b5c1a7414a', 'ramp_permanent', 'conditional_opponent_color_mana_rock_v1'),
    ('Mana Vault', 'mana vault', 'battle_rule_v1:5a2533694ffd19223d3cde1e25d258ff', '35e3fd94c8453c0e326033af49ae18c8', 'ramp_permanent', 'fast_mana_artifact_partial_v1'),
    ('Mox Amber', 'mox amber', 'battle_rule_v1:972703914ee50acd7a4e6f529fea1adf', 'e47b40cf2afc4c9ceac6bf91815da706', 'ramp_permanent', 'legend_gated_fast_mana_v1'),
    ('Seething Song', 'seething song', 'battle_rule_v1:3eb15dc581c6b913158f9b63c023f3d7', 'ccd492289c6f1c14c8fb7a248d7bbf32', 'ramp_ritual', 'single_shot_red_ritual_v1'),
    ('Silence', 'silence', 'battle_rule_v1:74b210b77b004a677906e0216d44e445', 'a0ca3c09a7db091c435ab31adb9c1780', 'silence_spell', 'silence_until_eot_v1'),
    ('Talisman of Conviction', 'talisman of conviction', 'battle_rule_v1:02133e513da5ea98ac74d32d39b16470', 'd49ceec937367a344a9f0948eea4f8f2', 'ramp_permanent', 'pain_talisman_color_pair_partial_v1'),
    ('Valakut Awakening', 'valakut awakening', 'battle_rule_v1:245b8d2627720fadfd7a30464d07605a', '22b42fcc181b7aed71f78b2e1e51e887', 'hand_filter', 'bottom_then_draw_plus_one_v1'),
    ('Valakut Awakening // Valakut Stoneforge', 'valakut awakening // valakut stoneforge', 'battle_rule_v1:6e1f3b876822abafe1de47610f46858d', '22b42fcc181b7aed71f78b2e1e51e887', 'hand_filter', 'bottom_then_draw_plus_one_mdfc_land_v1')
),
target_rules AS (
  SELECT
    tr.card_name,
    tr.normalized_name,
    tr.logical_rule_key,
    tr.expected_hash,
    tr.expected_effect,
    tr.expected_scope,
    cbr.card_id,
    cbr.source,
    cbr.review_status,
    cbr.execution_status,
    cbr.oracle_hash,
    cbr.effect_json,
    md5(coalesce(c.oracle_text, '')) AS live_oracle_hash
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
SELECT 'target_runtime_missing_hash_rows', count(*)::text
FROM target_rules
WHERE source = 'curated'
  AND review_status IN ('active', 'verified')
  AND execution_status = 'auto'
  AND coalesce(oracle_hash, '') = ''
UNION ALL
SELECT 'target_runtime_hash_mismatch_rows', count(*)::text
FROM target_rules
WHERE source = 'curated'
  AND review_status IN ('active', 'verified')
  AND execution_status = 'auto'
  AND oracle_hash IS DISTINCT FROM expected_hash
UNION ALL
SELECT 'target_runtime_live_hash_mismatch_rows', count(*)::text
FROM target_rules
WHERE live_oracle_hash IS DISTINCT FROM expected_hash
UNION ALL
SELECT 'target_runtime_bad_effect_rows', count(*)::text
FROM target_rules
WHERE effect_json->>'effect' IS DISTINCT FROM expected_effect
UNION ALL
SELECT 'target_runtime_bad_scope_rows', count(*)::text
FROM target_rules
WHERE effect_json->>'battle_model_scope' IS DISTINCT FROM expected_scope
UNION ALL
SELECT 'backup_rows', count(*)::text
FROM manaloom_deploy_audit.pg059_deck6_l2_hash_regression_repair_20260623_021840;

WITH target_runtime(normalized_name, logical_rule_key) AS (
  VALUES
    ('fellwar stone', 'battle_rule_v1:3906ffa3cbf7d3437d68e44e13e10bba'),
    ('mana vault', 'battle_rule_v1:5a2533694ffd19223d3cde1e25d258ff'),
    ('mox amber', 'battle_rule_v1:972703914ee50acd7a4e6f529fea1adf'),
    ('seething song', 'battle_rule_v1:3eb15dc581c6b913158f9b63c023f3d7'),
    ('silence', 'battle_rule_v1:74b210b77b004a677906e0216d44e445'),
    ('talisman of conviction', 'battle_rule_v1:02133e513da5ea98ac74d32d39b16470'),
    ('valakut awakening', 'battle_rule_v1:245b8d2627720fadfd7a30464d07605a'),
    ('valakut awakening // valakut stoneforge', 'battle_rule_v1:6e1f3b876822abafe1de47610f46858d')
)
SELECT
  cbr.card_name,
  cbr.normalized_name,
  cbr.card_id,
  cbr.source,
  cbr.review_status,
  cbr.execution_status,
  cbr.logical_rule_key,
  cbr.oracle_hash,
  cbr.effect_json::text AS effect_json
FROM card_battle_rules cbr
JOIN target_runtime tr ON tr.normalized_name = cbr.normalized_name
ORDER BY cbr.card_name, cbr.execution_status, cbr.source, cbr.logical_rule_key;
