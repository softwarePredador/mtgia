-- PG062 Deck 6 L1 fetchland cleanup precheck.
-- Scope: Arid Mesa, Bloodstained Mire, Flooded Strand, Marsh Flats,
-- Prismatic Vista, Scalding Tarn, Windswept Heath, Wooded Foothills.

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
deck_target_cards AS (
  SELECT
    tn.card_name AS target_name,
    c.id AS card_id,
    c.name AS card_name,
    c.type_line,
    c.layout,
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
  SELECT cbr.*
  FROM card_battle_rules cbr
  JOIN deck_target_cards dt
    ON dt.card_id = cbr.card_id
)
SELECT 'deck_target_cards' AS metric, count(*)::text AS value FROM deck_target_cards
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
SELECT 'trusted_without_scope_rows', count(*)::text
FROM target_rules
WHERE source = 'curated'
  AND review_status IN ('verified', 'active')
  AND execution_status IN ('auto', 'executable')
  AND NOT (effect_json ? 'battle_model_scope')
UNION ALL
SELECT 'trusted_bad_effect_rows', count(*)::text
FROM target_rules
WHERE source = 'curated'
  AND review_status IN ('verified', 'active')
  AND execution_status IN ('auto', 'executable')
  AND effect_json->>'effect' <> 'land'
UNION ALL
SELECT 'generated_review_only_rows', count(*)::text
FROM target_rules
WHERE source = 'generated'
  AND review_status = 'needs_review'
  AND execution_status = 'review_only'
UNION ALL
SELECT 'target_bad_type_rows', count(*)::text
FROM deck_target_cards
WHERE lower(coalesce(type_line, '')) NOT LIKE '%land%'
UNION ALL
SELECT 'target_faces_json_rows', count(*)::text
FROM deck_target_cards
WHERE card_faces_json IS NOT NULL
UNION ALL
SELECT 'target_missing_fetch_oracle_rows', count(*)::text
FROM deck_target_cards
WHERE lower(coalesce(oracle_text, '')) NOT LIKE '%pay 1 life%'
   OR lower(coalesce(oracle_text, '')) NOT LIKE '%sacrifice%'
   OR lower(coalesce(oracle_text, '')) NOT LIKE '%search your library%'
UNION ALL
SELECT 'backup_table_exists', CASE
  WHEN to_regclass('manaloom_deploy_audit.pg062_deck6_l1_fetchlands_20260623_024200') IS NULL THEN '0'
  ELSE '1'
END;

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
deck_target_cards AS (
  SELECT
    tn.card_name AS target_name,
    c.id AS card_id,
    c.name AS card_name,
    c.type_line,
    c.layout,
    md5(regexp_replace(coalesce(c.oracle_text, ''), '[[:space:]]+', ' ', 'g')) AS live_oracle_hash,
    regexp_replace(coalesce(c.oracle_text, ''), '[[:space:]]+', ' ', 'g') AS oracle_text_one_line
  FROM target_names tn
  JOIN cards c
    ON lower(c.name) = lower(tn.card_name)
  JOIN deck_cards dc
    ON dc.card_id = c.id
   AND dc.deck_id = '528c877f-f829-4207-95e6-73981776c323'::uuid
)
SELECT
  dt.card_name,
  dt.card_id,
  dt.type_line,
  dt.layout,
  dt.live_oracle_hash,
  left(dt.oracle_text_one_line, 180) AS oracle_excerpt,
  cbr.source,
  cbr.review_status,
  cbr.execution_status,
  cbr.logical_rule_key,
  cbr.oracle_hash,
  cbr.effect_json
FROM deck_target_cards dt
LEFT JOIN card_battle_rules cbr
  ON cbr.card_id = dt.card_id
ORDER BY dt.card_name, cbr.source, cbr.review_status, cbr.logical_rule_key;
