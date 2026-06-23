-- PG050 Deck 6 L1A land model cleanup apply.
-- Scope: metadata/provenance cleanup only; no deck swap and no executor change.
-- Expected precheck:
--   deck_target_cards=11
--   target_rule_rows=31
--   generated_review_only_rows=11
--   trusted_missing_hash_rows=20
--   card_id_mismatch_same_oracle_rows=5
--   card_id_mismatch_unknown_or_mismatch_oracle_rows=0

BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE manaloom_deploy_audit.pg050_deck6_l1a_land_model_cleanup_20260623_010026 AS
WITH target_names(name) AS (
  VALUES
    ('Ancient Den'),
    ('Ancient Tomb'),
    ('Command Tower'),
    ('Gemstone Caverns'),
    ('Great Furnace'),
    ('Hall of Heliod''s Generosity'),
    ('Inventors'' Fair'),
    ('Plateau'),
    ('Sunbaked Canyon'),
    ('Urza''s Saga'),
    ('War Room')
),
deck_target AS (
  SELECT lower(c.name) AS normalized_name
  FROM deck_cards dc
  JOIN cards c ON c.id = dc.card_id
  JOIN target_names tn ON tn.name = c.name
  WHERE dc.deck_id = '528c877f-f829-4207-95e6-73981776c323'::uuid
)
SELECT cbr.*
FROM card_battle_rules cbr
JOIN deck_target dt ON dt.normalized_name = cbr.normalized_name;

WITH target_names(name) AS (
  VALUES
    ('Ancient Den'),
    ('Ancient Tomb'),
    ('Command Tower'),
    ('Gemstone Caverns'),
    ('Great Furnace'),
    ('Hall of Heliod''s Generosity'),
    ('Inventors'' Fair'),
    ('Plateau'),
    ('Sunbaked Canyon'),
    ('Urza''s Saga'),
    ('War Room')
),
deck_target AS (
  SELECT
    lower(c.name) AS normalized_name,
    c.id AS deck_card_id,
    c.oracle_id,
    md5(coalesce(c.oracle_text, '')) AS target_oracle_hash
  FROM deck_cards dc
  JOIN cards c ON c.id = dc.card_id
  JOIN target_names tn ON tn.name = c.name
  WHERE dc.deck_id = '528c877f-f829-4207-95e6-73981776c323'::uuid
)
UPDATE card_battle_rules cbr
SET
  card_id = dt.deck_card_id,
  oracle_hash = dt.target_oracle_hash,
  notes = concat_ws(
    E'\n',
    nullif(cbr.notes, ''),
    'PG050 2026-06-23: Deck 6 L1A land cleanup. Oracle hash added and card_id aligned to the Lorehold deck printing when the existing rule matched the same oracle_id. No executor/effect_json change.'
  ),
  updated_at = now()
FROM deck_target dt
WHERE cbr.normalized_name = dt.normalized_name
  AND cbr.source = 'curated'
  AND cbr.review_status IN ('verified', 'active')
  AND cbr.execution_status = 'auto'
  AND (
    coalesce(cbr.oracle_hash, '') = ''
    OR (
      cbr.card_id IS DISTINCT FROM dt.deck_card_id
      AND EXISTS (
        SELECT 1
        FROM cards rc
        WHERE rc.id = cbr.card_id
          AND rc.oracle_id = dt.oracle_id
      )
    )
  );

WITH target_names(name) AS (
  VALUES
    ('Ancient Den'),
    ('Ancient Tomb'),
    ('Command Tower'),
    ('Gemstone Caverns'),
    ('Great Furnace'),
    ('Hall of Heliod''s Generosity'),
    ('Inventors'' Fair'),
    ('Plateau'),
    ('Sunbaked Canyon'),
    ('Urza''s Saga'),
    ('War Room')
),
deck_target AS (
  SELECT lower(c.name) AS normalized_name
  FROM deck_cards dc
  JOIN cards c ON c.id = dc.card_id
  JOIN target_names tn ON tn.name = c.name
  WHERE dc.deck_id = '528c877f-f829-4207-95e6-73981776c323'::uuid
)
UPDATE card_battle_rules cbr
SET
  review_status = 'deprecated',
  execution_status = 'disabled',
  notes = concat_ws(
    E'\n',
    nullif(cbr.notes, ''),
    'PG050 2026-06-23: Disabled generated review_only land shadow after retaining curated oracle-backed land model for Deck 6 L1A cleanup.'
  ),
  updated_at = now()
FROM deck_target dt
WHERE cbr.normalized_name = dt.normalized_name
  AND cbr.source = 'generated'
  AND cbr.review_status = 'needs_review'
  AND cbr.execution_status = 'review_only';

COMMIT;
