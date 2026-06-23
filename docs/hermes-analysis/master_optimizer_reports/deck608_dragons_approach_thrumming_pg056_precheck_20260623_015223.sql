-- PG056 Deck 608 Dragon's Approach / Thrumming Stone precheck.
-- Scope: card_battle_rules provenance/runtime model for the Dragon's Approach
-- package in Lorehold Variant 03 deck 608. PostgreSQL is source of truth.

WITH target_names(name) AS (
  VALUES
    ('Dragon''s Approach'),
    ('Thrumming Stone')
),
target_cards AS (
  SELECT
    c.id AS card_id,
    lower(c.name) AS normalized_name,
    c.name,
    c.oracle_id,
    c.mana_cost,
    c.cmc,
    c.type_line,
    md5(coalesce(c.oracle_text, '')) AS target_oracle_hash,
    regexp_replace(coalesce(c.oracle_text, ''), E'[\\n\\r]+', ' / ', 'g') AS oracle_text
  FROM cards c
  JOIN target_names tn ON tn.name = c.name
),
target_rules AS (
  SELECT
    tc.name,
    tc.card_id AS target_card_id,
    tc.oracle_id,
    tc.target_oracle_hash,
    cbr.card_id AS rule_card_id,
    cbr.card_name,
    cbr.source,
    cbr.review_status,
    cbr.execution_status,
    cbr.logical_rule_key,
    cbr.oracle_hash,
    cbr.effect_json,
    rc.oracle_id AS rule_oracle_id
  FROM target_cards tc
  LEFT JOIN card_battle_rules cbr ON cbr.normalized_name = tc.normalized_name
  LEFT JOIN cards rc ON rc.id = cbr.card_id
)
SELECT 'target_cards' AS metric, count(*)::text AS value
FROM target_cards
UNION ALL
SELECT 'target_rule_rows', count(*)::text
FROM target_rules
WHERE logical_rule_key IS NOT NULL
UNION ALL
SELECT 'trusted_active_rows', count(*)::text
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
SELECT 'trusted_without_scope_rows', count(*)::text
FROM target_rules
WHERE source = 'curated'
  AND review_status IN ('verified', 'active')
  AND execution_status = 'auto'
  AND coalesce(effect_json->>'battle_model_scope', '') = ''
UNION ALL
SELECT 'generated_review_only_rows', count(*)::text
FROM target_rules
WHERE source = 'generated'
  AND review_status = 'needs_review'
  AND execution_status = 'review_only'
UNION ALL
SELECT 'thrumming_trusted_active_rows', count(*)::text
FROM target_rules
WHERE name = 'Thrumming Stone'
  AND source = 'curated'
  AND review_status IN ('verified', 'active')
  AND execution_status = 'auto'
UNION ALL
SELECT 'active_card_id_mismatch_same_oracle_rows', count(*)::text
FROM target_rules
WHERE rule_card_id IS DISTINCT FROM target_card_id
  AND rule_oracle_id = oracle_id
  AND execution_status IS DISTINCT FROM 'disabled'
UNION ALL
SELECT 'active_card_id_mismatch_unknown_or_mismatch_oracle_rows', count(*)::text
FROM target_rules
WHERE rule_card_id IS DISTINCT FROM target_card_id
  AND rule_oracle_id IS DISTINCT FROM oracle_id
  AND execution_status IS DISTINCT FROM 'disabled'
UNION ALL
SELECT 'target_names_missing_rules', count(*)::text
FROM target_cards tc
WHERE NOT EXISTS (
  SELECT 1
  FROM card_battle_rules cbr
  WHERE cbr.normalized_name = tc.normalized_name
);

WITH target_names(name) AS (
  VALUES
    ('Dragon''s Approach'),
    ('Thrumming Stone')
),
target_cards AS (
  SELECT
    c.id AS card_id,
    lower(c.name) AS normalized_name,
    c.name,
    c.oracle_id,
    c.mana_cost,
    c.cmc,
    c.type_line,
    md5(coalesce(c.oracle_text, '')) AS target_oracle_hash,
    regexp_replace(coalesce(c.oracle_text, ''), E'[\\n\\r]+', ' / ', 'g') AS oracle_text
  FROM cards c
  JOIN target_names tn ON tn.name = c.name
)
SELECT
  name,
  card_id,
  oracle_id,
  mana_cost,
  cmc,
  type_line,
  target_oracle_hash,
  oracle_text
FROM target_cards
ORDER BY name;

WITH target_names(name) AS (
  VALUES
    ('Dragon''s Approach'),
    ('Thrumming Stone')
),
target_cards AS (
  SELECT c.id AS card_id, lower(c.name) AS normalized_name, c.name
  FROM cards c
  JOIN target_names tn ON tn.name = c.name
)
SELECT
  tc.name,
  cbr.card_name,
  cbr.card_id AS rule_card_id,
  tc.card_id AS target_card_id,
  cbr.source,
  cbr.review_status,
  cbr.execution_status,
  cbr.logical_rule_key,
  cbr.oracle_hash,
  cbr.effect_json::text AS effect_json,
  left(coalesce(cbr.notes, ''), 260) AS notes
FROM target_cards tc
LEFT JOIN card_battle_rules cbr ON cbr.normalized_name = tc.normalized_name
ORDER BY tc.name, cbr.source, cbr.review_status, cbr.execution_status, cbr.logical_rule_key;
