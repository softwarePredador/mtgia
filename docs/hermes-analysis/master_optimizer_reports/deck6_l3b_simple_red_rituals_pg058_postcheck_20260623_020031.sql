-- PG058 Deck 6 L3B simple red rituals postcheck.

WITH target_metadata(
  name,
  target_logical_rule_key,
  produces,
  mana_produced,
  battle_model_scope
) AS (
  VALUES
    ('Rite of Flame', 'battle_rule_v1:b66dd96fa32c9822c798f16a83fa5518', 'R', 2, 'rite_of_flame_singleton_baseline_red_ritual_v1'),
    ('Seething Song', 'battle_rule_v1:3eb15dc581c6b913158f9b63c023f3d7', 'R', 5, 'single_shot_red_ritual_v1')
),
deck_target AS (
  SELECT
    lower(c.name) AS normalized_name,
    c.name,
    c.id AS deck_card_id,
    c.oracle_id,
    md5(coalesce(c.oracle_text, '')) AS target_oracle_hash,
    tm.target_logical_rule_key,
    tm.produces,
    tm.mana_produced,
    tm.battle_model_scope
  FROM deck_cards dc
  JOIN cards c ON c.id = dc.card_id
  JOIN target_metadata tm ON tm.name = c.name
  WHERE dc.deck_id = '528c877f-f829-4207-95e6-73981776c323'::uuid
),
target_rules AS (
  SELECT
    dt.name,
    dt.normalized_name,
    dt.deck_card_id,
    dt.oracle_id,
    dt.target_oracle_hash,
    dt.target_logical_rule_key,
    dt.produces,
    dt.mana_produced,
    dt.battle_model_scope,
    cbr.card_id AS rule_card_id,
    cbr.card_name,
    cbr.source,
    cbr.review_status,
    cbr.execution_status,
    cbr.logical_rule_key,
    cbr.oracle_hash,
    cbr.effect_json,
    rc.oracle_id AS rule_oracle_id
  FROM deck_target dt
  JOIN card_battle_rules cbr ON cbr.normalized_name = dt.normalized_name
  LEFT JOIN cards rc ON rc.id = cbr.card_id
)
SELECT 'deck_target_cards' AS metric, count(*)::text AS value
FROM deck_target
UNION ALL
SELECT 'target_rule_rows', count(*)::text
FROM target_rules
UNION ALL
SELECT 'target_runtime_rows', count(*)::text
FROM target_rules
WHERE logical_rule_key = target_logical_rule_key
  AND source = 'curated'
  AND review_status IN ('verified', 'active')
  AND execution_status = 'auto'
UNION ALL
SELECT 'trusted_missing_hash_rows', count(*)::text
FROM target_rules
WHERE logical_rule_key = target_logical_rule_key
  AND source = 'curated'
  AND review_status IN ('verified', 'active')
  AND execution_status = 'auto'
  AND coalesce(oracle_hash, '') = ''
UNION ALL
SELECT 'trusted_hash_mismatch_rows', count(*)::text
FROM target_rules
WHERE logical_rule_key = target_logical_rule_key
  AND source = 'curated'
  AND review_status IN ('verified', 'active')
  AND execution_status = 'auto'
  AND oracle_hash IS DISTINCT FROM target_oracle_hash
UNION ALL
SELECT 'trusted_without_scope_rows', count(*)::text
FROM target_rules
WHERE logical_rule_key = target_logical_rule_key
  AND source = 'curated'
  AND review_status IN ('verified', 'active')
  AND execution_status = 'auto'
  AND coalesce(effect_json->>'battle_model_scope', '') = ''
UNION ALL
SELECT 'target_runtime_rows_without_produces', count(*)::text
FROM target_rules
WHERE logical_rule_key = target_logical_rule_key
  AND source = 'curated'
  AND review_status IN ('verified', 'active')
  AND execution_status = 'auto'
  AND coalesce(effect_json->>'produces', '') = ''
UNION ALL
SELECT 'target_runtime_rows_bad_mana_produced', count(*)::text
FROM target_rules
WHERE logical_rule_key = target_logical_rule_key
  AND source = 'curated'
  AND review_status IN ('verified', 'active')
  AND execution_status = 'auto'
  AND (effect_json->>'mana_produced')::int IS DISTINCT FROM mana_produced
UNION ALL
SELECT 'target_runtime_rows_bad_scope', count(*)::text
FROM target_rules
WHERE logical_rule_key = target_logical_rule_key
  AND source = 'curated'
  AND review_status IN ('verified', 'active')
  AND execution_status = 'auto'
  AND effect_json->>'battle_model_scope' IS DISTINCT FROM battle_model_scope
UNION ALL
SELECT 'generated_review_only_rows', count(*)::text
FROM target_rules
WHERE source = 'generated'
  AND review_status = 'needs_review'
  AND execution_status = 'review_only'
UNION ALL
SELECT 'active_curated_shadow_rows', count(*)::text
FROM target_rules
WHERE source = 'curated'
  AND review_status IN ('verified', 'active')
  AND execution_status = 'auto'
  AND logical_rule_key IS DISTINCT FROM target_logical_rule_key
UNION ALL
SELECT 'active_card_id_mismatch_same_oracle_rows', count(*)::text
FROM target_rules
WHERE rule_card_id IS DISTINCT FROM deck_card_id
  AND rule_oracle_id = oracle_id
  AND execution_status IS DISTINCT FROM 'disabled'
UNION ALL
SELECT 'active_card_id_mismatch_unknown_or_mismatch_oracle_rows', count(*)::text
FROM target_rules
WHERE rule_card_id IS DISTINCT FROM deck_card_id
  AND rule_oracle_id IS DISTINCT FROM oracle_id
  AND execution_status IS DISTINCT FROM 'disabled'
UNION ALL
SELECT 'disabled_or_deprecated_rows', count(*)::text
FROM target_rules
WHERE review_status = 'deprecated'
  AND execution_status = 'disabled'
UNION ALL
SELECT 'backup_rows', count(*)::text
FROM manaloom_deploy_audit.pg058_deck6_l3b_simple_red_rituals_20260623_020031;

WITH target_metadata(
  name,
  target_logical_rule_key
) AS (
  VALUES
    ('Rite of Flame', 'battle_rule_v1:b66dd96fa32c9822c798f16a83fa5518'),
    ('Seething Song', 'battle_rule_v1:3eb15dc581c6b913158f9b63c023f3d7')
),
deck_target AS (
  SELECT
    lower(c.name) AS normalized_name,
    c.name,
    tm.target_logical_rule_key
  FROM deck_cards dc
  JOIN cards c ON c.id = dc.card_id
  JOIN target_metadata tm ON tm.name = c.name
  WHERE dc.deck_id = '528c877f-f829-4207-95e6-73981776c323'::uuid
)
SELECT
  dt.name,
  cbr.card_id,
  cbr.source,
  cbr.review_status,
  cbr.execution_status,
  cbr.logical_rule_key,
  cbr.oracle_hash,
  cbr.effect_json::text AS effect_json
FROM deck_target dt
JOIN card_battle_rules cbr ON cbr.normalized_name = dt.normalized_name
ORDER BY dt.name, cbr.execution_status, cbr.source, cbr.logical_rule_key;
