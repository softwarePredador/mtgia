-- PG058 Deck 6 L3B simple red rituals precheck.
-- Scope: Rite of Flame and Seething Song as one-shot red ritual mana.
-- Excludes modal/engine/cost-reduction mana cards from this pass.
-- PostgreSQL is source of truth. Hermes SQLite must be synced after apply.

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
    c.type_line,
    c.layout,
    c.card_faces_json IS NOT NULL AS has_faces,
    md5(coalesce(c.oracle_text, '')) AS target_oracle_hash,
    regexp_replace(coalesce(c.oracle_text, ''), E'[\\n\\r]+', ' / ', 'g') AS oracle_text,
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
SELECT 'generated_review_only_rows', count(*)::text
FROM target_rules
WHERE source = 'generated'
  AND review_status = 'needs_review'
  AND execution_status = 'review_only'
UNION ALL
SELECT 'curated_shadow_rows_to_disable', count(*)::text
FROM target_rules
WHERE source = 'curated'
  AND review_status IN ('verified', 'active')
  AND execution_status = 'auto'
  AND logical_rule_key IS DISTINCT FROM target_logical_rule_key
UNION ALL
SELECT 'trusted_missing_hash_rows', count(*)::text
FROM target_rules
WHERE source = 'curated'
  AND review_status IN ('verified', 'active')
  AND execution_status = 'auto'
  AND coalesce(oracle_hash, '') = ''
UNION ALL
SELECT 'trusted_without_scope_rows', count(*)::text
FROM target_rules
WHERE source = 'curated'
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
SELECT 'target_names_missing_rules', count(*)::text
FROM deck_target dt
WHERE NOT EXISTS (
  SELECT 1
  FROM card_battle_rules cbr
  WHERE cbr.normalized_name = dt.normalized_name
);

WITH target_metadata(name) AS (
  VALUES
    ('Rite of Flame'),
    ('Seething Song')
),
deck_target AS (
  SELECT
    c.name,
    c.id AS deck_card_id,
    c.oracle_id,
    md5(coalesce(c.oracle_text, '')) AS target_oracle_hash,
    c.type_line,
    c.layout,
    c.card_faces_json IS NOT NULL AS has_faces,
    regexp_replace(coalesce(c.oracle_text, ''), E'[\\n\\r]+', ' / ', 'g') AS oracle_text
  FROM deck_cards dc
  JOIN cards c ON c.id = dc.card_id
  JOIN target_metadata tm ON tm.name = c.name
  WHERE dc.deck_id = '528c877f-f829-4207-95e6-73981776c323'::uuid
)
SELECT
  name,
  deck_card_id,
  oracle_id,
  target_oracle_hash,
  type_line,
  layout,
  has_faces,
  oracle_text
FROM deck_target
ORDER BY name;

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
    c.id AS deck_card_id,
    tm.target_logical_rule_key
  FROM deck_cards dc
  JOIN cards c ON c.id = dc.card_id
  JOIN target_metadata tm ON tm.name = c.name
  WHERE dc.deck_id = '528c877f-f829-4207-95e6-73981776c323'::uuid
)
SELECT
  dt.name,
  cbr.card_name,
  cbr.card_id AS rule_card_id,
  dt.deck_card_id,
  cbr.source,
  cbr.review_status,
  cbr.execution_status,
  cbr.logical_rule_key,
  cbr.oracle_hash,
  cbr.effect_json::text AS effect_json,
  left(coalesce(cbr.notes, ''), 220) AS notes
FROM deck_target dt
JOIN card_battle_rules cbr ON cbr.normalized_name = dt.normalized_name
ORDER BY dt.name, cbr.source, cbr.review_status, cbr.logical_rule_key;
