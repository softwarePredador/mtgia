-- PG062 Deck 6 L1 fetchland cleanup postcheck.

WITH target_names(card_name) AS (
  VALUES
    ('Arid Mesa'),
    ('Bloodstained Mire'),
    ('Flooded Strand'),
    ('Marsh Flats'),
    ('Prismatic Vista'),
    ('Scalding Tarn'),
    ('Windswept Heath'),
    ('Wooded Foothills')
),
target_cards AS (
  SELECT
    c.id AS card_id,
    c.name AS card_name,
    c.type_line,
    c.card_faces_json,
    c.oracle_text,
    md5(regexp_replace(coalesce(c.oracle_text, ''), '[[:space:]]+', ' ', 'g')) AS live_oracle_hash
  FROM target_names tn
  JOIN cards c
    ON lower(c.name) = lower(tn.card_name)
  JOIN deck_cards dc
    ON dc.card_id = c.id
   AND dc.deck_id = '528c877f-f829-4207-95e6-73981776c323'::uuid
),
target_rules AS (
  SELECT cbr.*, tc.live_oracle_hash
  FROM card_battle_rules cbr
  JOIN target_cards tc
    ON tc.card_id = cbr.card_id
)
SELECT 'target_cards' AS metric, count(*)::text AS value FROM target_cards
UNION ALL
SELECT 'target_rule_rows', count(*)::text FROM target_rules
UNION ALL
SELECT 'trusted_runtime_rows', count(*)::text
FROM target_rules
WHERE source = 'curated'
  AND review_status IN ('verified', 'active')
  AND execution_status IN ('auto', 'executable')
UNION ALL
SELECT 'trusted_missing_hash_rows', count(*)::text
FROM target_rules
WHERE source = 'curated'
  AND review_status IN ('verified', 'active')
  AND execution_status IN ('auto', 'executable')
  AND coalesce(oracle_hash, '') = ''
UNION ALL
SELECT 'trusted_hash_mismatch_rows', count(*)::text
FROM target_rules
WHERE source = 'curated'
  AND review_status IN ('verified', 'active')
  AND execution_status IN ('auto', 'executable')
  AND oracle_hash <> live_oracle_hash
UNION ALL
SELECT 'trusted_missing_scope_rows', count(*)::text
FROM target_rules
WHERE source = 'curated'
  AND review_status IN ('verified', 'active')
  AND execution_status IN ('auto', 'executable')
  AND effect_json->>'battle_model_scope' <> 'fetchland_land_play_with_activation_annotation_v1'
UNION ALL
SELECT 'trusted_bad_effect_rows', count(*)::text
FROM target_rules
WHERE source = 'curated'
  AND review_status IN ('verified', 'active')
  AND execution_status IN ('auto', 'executable')
  AND effect_json->>'effect' <> 'land'
UNION ALL
SELECT 'active_review_only_or_needs_review_rows', count(*)::text
FROM target_rules
WHERE review_status = 'needs_review'
   OR execution_status = 'review_only'
UNION ALL
SELECT 'disabled_generated_shadow_rows', count(*)::text
FROM target_rules
WHERE source = 'generated'
  AND review_status = 'deprecated'
  AND execution_status = 'disabled'
UNION ALL
SELECT 'target_bad_type_rows', count(*)::text
FROM target_cards
WHERE lower(coalesce(type_line, '')) NOT LIKE '%land%'
UNION ALL
SELECT 'target_faces_json_rows', count(*)::text
FROM target_cards
WHERE card_faces_json IS NOT NULL
UNION ALL
SELECT 'backup_rows', count(*)::text
FROM manaloom_deploy_audit.pg062_deck6_l1_fetchlands_20260623_024200;

WITH target_names(card_name) AS (
  VALUES
    ('Arid Mesa'),
    ('Bloodstained Mire'),
    ('Flooded Strand'),
    ('Marsh Flats'),
    ('Prismatic Vista'),
    ('Scalding Tarn'),
    ('Windswept Heath'),
    ('Wooded Foothills')
),
target_cards AS (
  SELECT
    c.id AS card_id,
    c.name AS card_name,
    md5(regexp_replace(coalesce(c.oracle_text, ''), '[[:space:]]+', ' ', 'g')) AS live_oracle_hash
  FROM target_names tn
  JOIN cards c
    ON lower(c.name) = lower(tn.card_name)
  JOIN deck_cards dc
    ON dc.card_id = c.id
   AND dc.deck_id = '528c877f-f829-4207-95e6-73981776c323'::uuid
)
SELECT
  tc.card_name,
  cbr.source,
  cbr.review_status,
  cbr.execution_status,
  cbr.logical_rule_key,
  cbr.oracle_hash,
  tc.live_oracle_hash,
  cbr.effect_json,
  left(coalesce(cbr.notes, ''), 220) AS notes_excerpt
FROM target_cards tc
JOIN card_battle_rules cbr
  ON cbr.card_id = tc.card_id
ORDER BY tc.card_name, cbr.source, cbr.review_status, cbr.logical_rule_key;
