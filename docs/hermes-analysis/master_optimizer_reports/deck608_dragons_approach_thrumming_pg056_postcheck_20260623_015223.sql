-- PG056 Deck 608 Dragon's Approach / Thrumming Stone postcheck.

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
    md5(coalesce(c.oracle_text, '')) AS target_oracle_hash
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
SELECT 'trusted_hash_mismatch_rows', count(*)::text
FROM target_rules
WHERE source = 'curated'
  AND review_status IN ('verified', 'active')
  AND execution_status = 'auto'
  AND oracle_hash IS DISTINCT FROM target_oracle_hash
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
SELECT 'disabled_or_deprecated_rows', count(*)::text
FROM target_rules
WHERE review_status = 'deprecated'
  AND execution_status = 'disabled'
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
SELECT 'backup_rows', count(*)::text
FROM manaloom_deploy_audit.pg056_deck608_dragons_approach_thrumming_20260623_015223;

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
    md5(coalesce(c.oracle_text, '')) AS target_oracle_hash
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
  tc.target_oracle_hash,
  cbr.effect_json::text AS effect_json
FROM target_cards tc
JOIN card_battle_rules cbr ON cbr.normalized_name = tc.normalized_name
ORDER BY tc.name, cbr.source, cbr.review_status, cbr.execution_status, cbr.logical_rule_key;
