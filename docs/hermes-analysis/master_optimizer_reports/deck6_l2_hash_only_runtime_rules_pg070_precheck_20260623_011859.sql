\pset pager off

WITH target_rules(normalized_name, logical_rule_key, expected_scope) AS (
  VALUES
    ('fellwar stone', 'battle_rule_v1:3906ffa3cbf7d3437d68e44e13e10bba', 'conditional_opponent_color_mana_rock_v1'),
    ('mana vault', 'battle_rule_v1:5a2533694ffd19223d3cde1e25d258ff', 'fast_mana_artifact_partial_v1'),
    ('mox amber', 'battle_rule_v1:972703914ee50acd7a4e6f529fea1adf', 'legend_gated_fast_mana_v1'),
    ('scroll rack', 'battle_rule_v1:3b58ff16a7eb52fb05c1bd8517225cd2', 'scroll_rack_upkeep_single_exchange_v1'),
    ('seething song', 'battle_rule_v1:3eb15dc581c6b913158f9b63c023f3d7', 'single_shot_red_ritual_v1'),
    ('silence', 'battle_rule_v1:74b210b77b004a677906e0216d44e445', 'silence_until_eot_v1'),
    ('talisman of conviction', 'battle_rule_v1:02133e513da5ea98ac74d32d39b16470', 'pain_talisman_color_pair_partial_v1'),
    ('unexpected windfall', 'battle_rule_v1:f9f98ea1925518eea7a7c94c21ef2dc4', 'discard_draw_create_treasures_v1'),
    ('valakut awakening // valakut stoneforge', 'battle_rule_v1:6e1f3b876822abafe1de47610f46858d', 'bottom_then_draw_plus_one_mdfc_land_v1')
),
card_hashes AS (
  SELECT
    tr.normalized_name,
    count(c.id) AS card_rows,
    count(DISTINCT md5(coalesce(c.oracle_text, ''))) AS distinct_oracle_hashes,
    max(md5(coalesce(c.oracle_text, ''))) AS oracle_hash
  FROM target_rules tr
  LEFT JOIN cards c ON lower(c.name) = tr.normalized_name
  GROUP BY tr.normalized_name
),
runtime_rows AS (
  SELECT
    tr.normalized_name,
    tr.logical_rule_key,
    tr.expected_scope,
    cbr.source,
    cbr.review_status,
    cbr.execution_status,
    cbr.oracle_hash,
    cbr.effect_json->>'battle_model_scope' AS battle_model_scope
  FROM target_rules tr
  LEFT JOIN card_battle_rules cbr
    ON cbr.normalized_name = tr.normalized_name
   AND cbr.logical_rule_key = tr.logical_rule_key
)
SELECT
  (SELECT count(*) FROM target_rules) AS expected_target_rows,
  (SELECT count(*) FROM card_hashes WHERE card_rows >= 1 AND distinct_oracle_hashes = 1) AS target_cards_with_single_oracle_hash,
  (SELECT count(*) FROM runtime_rows WHERE source = 'curated' AND review_status IN ('verified', 'active') AND execution_status IN ('auto', 'executable') AND battle_model_scope = expected_scope) AS matching_runtime_rows,
  (SELECT count(*) FROM runtime_rows WHERE coalesce(oracle_hash, '') = '') AS runtime_rows_missing_oracle_hash,
  (SELECT count(*) FROM card_battle_rules cbr JOIN target_rules tr ON tr.normalized_name = cbr.normalized_name WHERE cbr.review_status = 'needs_review' AND cbr.execution_status <> 'disabled') AS active_needs_review_shadow_rows,
  to_regclass('manaloom_deploy_audit.pg070_deck6_l2_hash_only_runtime_rules_20260623_011859') IS NOT NULL AS backup_table_already_exists;

WITH target_rules(normalized_name, logical_rule_key, expected_scope) AS (
  VALUES
    ('fellwar stone', 'battle_rule_v1:3906ffa3cbf7d3437d68e44e13e10bba', 'conditional_opponent_color_mana_rock_v1'),
    ('mana vault', 'battle_rule_v1:5a2533694ffd19223d3cde1e25d258ff', 'fast_mana_artifact_partial_v1'),
    ('mox amber', 'battle_rule_v1:972703914ee50acd7a4e6f529fea1adf', 'legend_gated_fast_mana_v1'),
    ('scroll rack', 'battle_rule_v1:3b58ff16a7eb52fb05c1bd8517225cd2', 'scroll_rack_upkeep_single_exchange_v1'),
    ('seething song', 'battle_rule_v1:3eb15dc581c6b913158f9b63c023f3d7', 'single_shot_red_ritual_v1'),
    ('silence', 'battle_rule_v1:74b210b77b004a677906e0216d44e445', 'silence_until_eot_v1'),
    ('talisman of conviction', 'battle_rule_v1:02133e513da5ea98ac74d32d39b16470', 'pain_talisman_color_pair_partial_v1'),
    ('unexpected windfall', 'battle_rule_v1:f9f98ea1925518eea7a7c94c21ef2dc4', 'discard_draw_create_treasures_v1'),
    ('valakut awakening // valakut stoneforge', 'battle_rule_v1:6e1f3b876822abafe1de47610f46858d', 'bottom_then_draw_plus_one_mdfc_land_v1')
),
card_hashes AS (
  SELECT
    tr.normalized_name,
    min(c.name) AS card_name,
    min(c.type_line) AS type_line,
    min(c.layout) AS layout,
    count(c.id) AS card_rows,
    count(DISTINCT md5(coalesce(c.oracle_text, ''))) AS distinct_oracle_hashes,
    max(md5(coalesce(c.oracle_text, ''))) AS oracle_hash,
    max(regexp_replace(coalesce(c.oracle_text, ''), E'[\\n\\r]+', ' / ', 'g')) AS oracle_text
  FROM target_rules tr
  LEFT JOIN cards c ON lower(c.name) = tr.normalized_name
  GROUP BY tr.normalized_name
)
SELECT
  ch.normalized_name,
  ch.card_name,
  ch.type_line,
  ch.layout,
  ch.card_rows,
  ch.distinct_oracle_hashes,
  ch.oracle_hash,
  rr.logical_rule_key,
  rr.review_status,
  rr.execution_status,
  rr.oracle_hash AS current_rule_hash,
  rr.battle_model_scope,
  ch.oracle_text
FROM card_hashes ch
JOIN (
  SELECT
    tr.normalized_name,
    tr.logical_rule_key,
    cbr.review_status,
    cbr.execution_status,
    cbr.oracle_hash,
    cbr.effect_json->>'battle_model_scope' AS battle_model_scope
  FROM target_rules tr
  LEFT JOIN card_battle_rules cbr
    ON cbr.normalized_name = tr.normalized_name
   AND cbr.logical_rule_key = tr.logical_rule_key
) rr ON rr.normalized_name = ch.normalized_name
ORDER BY ch.normalized_name;
