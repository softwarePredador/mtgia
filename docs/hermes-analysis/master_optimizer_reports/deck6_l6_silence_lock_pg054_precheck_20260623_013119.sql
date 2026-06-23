-- PG054 Deck 6 L6 silence-lock family precheck.
-- Scope: Silence and Grand Abolisher only.
-- PostgreSQL is source of truth. Hermes SQLite must be synced after apply.

WITH target_names(name) AS (
  VALUES
    ('Grand Abolisher'),
    ('Silence')
),
deck_target AS (
  SELECT
    lower(c.name) AS normalized_name,
    c.name,
    c.id AS deck_card_id,
    c.oracle_id,
    md5(coalesce(c.oracle_text, '')) AS target_oracle_hash
  FROM deck_cards dc
  JOIN cards c ON c.id = dc.card_id
  JOIN target_names tn ON tn.name = c.name
  WHERE dc.deck_id = '528c877f-f829-4207-95e6-73981776c323'::uuid
),
target_rules AS (
  SELECT
    dt.name,
    dt.normalized_name,
    dt.deck_card_id,
    dt.oracle_id,
    dt.target_oracle_hash,
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
SELECT 'active_curated_rows', count(*)::text
FROM target_rules
WHERE source = 'curated'
  AND review_status IN ('verified', 'active')
  AND execution_status = 'auto'
UNION ALL
SELECT 'trusted_missing_hash_rows', count(*)::text
FROM target_rules
WHERE source = 'curated'
  AND review_status IN ('verified', 'active')
  AND execution_status = 'auto'
  AND coalesce(oracle_hash, '') = ''
UNION ALL
SELECT 'generated_review_only_rows', count(*)::text
FROM target_rules
WHERE source = 'generated'
  AND review_status = 'needs_review'
  AND execution_status = 'review_only'
UNION ALL
SELECT 'silence_legacy_active_rows', count(*)::text
FROM target_rules
WHERE name = 'Silence'
  AND logical_rule_key = 'battle_rule_v1:d3367950588008088c6a73c604765da0'
  AND execution_status = 'auto'
UNION ALL
SELECT 'target_active_runtime_rows', count(*)::text
FROM target_rules
WHERE logical_rule_key IN (
    'battle_rule_v1:74b210b77b004a677906e0216d44e445',
    'battle_rule_v1:4df98360e4467568504b19219c8ba5d0'
  )
  AND source = 'curated'
  AND review_status IN ('verified', 'active')
  AND execution_status = 'auto'
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

WITH target_names(name) AS (
  VALUES
    ('Grand Abolisher'),
    ('Silence')
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
    regexp_replace(coalesce(c.oracle_text, ''), E'[\\n\\r]+', ' / ', 'g') AS oracle_text
  FROM deck_cards dc
  JOIN cards c ON c.id = dc.card_id
  JOIN target_names tn ON tn.name = c.name
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

WITH target_names(name) AS (
  VALUES
    ('Grand Abolisher'),
    ('Silence')
),
deck_target AS (
  SELECT
    lower(c.name) AS normalized_name,
    c.name,
    c.id AS deck_card_id,
    md5(coalesce(c.oracle_text, '')) AS target_oracle_hash
  FROM deck_cards dc
  JOIN cards c ON c.id = dc.card_id
  JOIN target_names tn ON tn.name = c.name
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
  left(coalesce(cbr.notes, ''), 240) AS notes
FROM deck_target dt
JOIN card_battle_rules cbr ON cbr.normalized_name = dt.normalized_name
ORDER BY dt.name, cbr.source, cbr.review_status, cbr.execution_status, cbr.logical_rule_key;
