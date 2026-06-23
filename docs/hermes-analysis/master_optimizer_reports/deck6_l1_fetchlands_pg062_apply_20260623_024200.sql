-- PG062 Deck 6 L1 fetchland cleanup apply.
-- This is a conservative land/mana-base package:
-- - keep the trusted executable model as effect=land;
-- - attach oracle_hash and explicit annotation-only fetch activation metadata;
-- - disable generated needs_review/review_only shadows when a trusted row exists;
-- - do not model sacrifice/search/shuffle as a dynamic executor here.

BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

DO $$
BEGIN
  IF to_regclass('manaloom_deploy_audit.pg062_deck6_l1_fetchlands_20260623_024200') IS NOT NULL THEN
    RAISE EXCEPTION 'Backup table manaloom_deploy_audit.pg062_deck6_l1_fetchlands_20260623_024200 already exists';
  END IF;
END $$;

CREATE TABLE manaloom_deploy_audit.pg062_deck6_l1_fetchlands_20260623_024200 AS
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
  SELECT c.id AS card_id
  FROM target_names tn
  JOIN cards c
    ON lower(c.name) = lower(tn.card_name)
  JOIN deck_cards dc
    ON dc.card_id = c.id
   AND dc.deck_id = '528c877f-f829-4207-95e6-73981776c323'::uuid
)
SELECT cbr.*
FROM card_battle_rules cbr
JOIN deck_target_cards dt
  ON dt.card_id = cbr.card_id;

DO $$
DECLARE
  v_target_cards integer;
  v_backup_rows integer;
  v_trusted_rows integer;
  v_generated_review_only_rows integer;
  v_bad_type_rows integer;
  v_missing_fetch_oracle_rows integer;
BEGIN
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
    SELECT c.id AS card_id, c.type_line, c.oracle_text
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
  SELECT
    (SELECT count(*) FROM deck_target_cards),
    (SELECT count(*) FROM manaloom_deploy_audit.pg062_deck6_l1_fetchlands_20260623_024200),
    (SELECT count(*) FROM target_rules WHERE source = 'curated' AND review_status IN ('verified', 'active') AND execution_status IN ('auto', 'executable')),
    (SELECT count(*) FROM target_rules WHERE source = 'generated' AND review_status = 'needs_review' AND execution_status = 'review_only'),
    (SELECT count(*) FROM deck_target_cards WHERE lower(coalesce(type_line, '')) NOT LIKE '%land%'),
    (SELECT count(*) FROM deck_target_cards WHERE lower(coalesce(oracle_text, '')) NOT LIKE '%pay 1 life%' OR lower(coalesce(oracle_text, '')) NOT LIKE '%sacrifice%' OR lower(coalesce(oracle_text, '')) NOT LIKE '%search your library%')
  INTO
    v_target_cards,
    v_backup_rows,
    v_trusted_rows,
    v_generated_review_only_rows,
    v_bad_type_rows,
    v_missing_fetch_oracle_rows;

  IF v_target_cards <> 8
     OR v_backup_rows <> 16
     OR v_trusted_rows <> 8
     OR v_generated_review_only_rows <> 8
     OR v_bad_type_rows <> 0
     OR v_missing_fetch_oracle_rows <> 0 THEN
    RAISE EXCEPTION 'PG062 precondition failed: target_cards=%, backup_rows=%, trusted_rows=%, generated_review_only_rows=%, bad_type_rows=%, missing_fetch_oracle_rows=% expected 8/16/8/8/0/0',
      v_target_cards,
      v_backup_rows,
      v_trusted_rows,
      v_generated_review_only_rows,
      v_bad_type_rows,
      v_missing_fetch_oracle_rows;
  END IF;
END $$;

WITH target_data(card_name, fetch_target_scope) AS (
  VALUES
    ('Arid Mesa', 'mountain_or_plains'),
    ('Bloodstained Mire', 'swamp_or_mountain'),
    ('Flooded Strand', 'plains_or_island'),
    ('Marsh Flats', 'plains_or_swamp'),
    ('Prismatic Vista', 'basic_land'),
    ('Scalding Tarn', 'island_or_mountain'),
    ('Windswept Heath', 'forest_or_plains'),
    ('Wooded Foothills', 'mountain_or_forest')
),
target_cards AS (
  SELECT
    c.id AS card_id,
    c.name AS card_name,
    td.fetch_target_scope,
    md5(regexp_replace(coalesce(c.oracle_text, ''), '[[:space:]]+', ' ', 'g')) AS live_oracle_hash
  FROM target_data td
  JOIN cards c
    ON lower(c.name) = lower(td.card_name)
  JOIN deck_cards dc
    ON dc.card_id = c.id
   AND dc.deck_id = '528c877f-f829-4207-95e6-73981776c323'::uuid
)
UPDATE card_battle_rules cbr
SET
  oracle_hash = tc.live_oracle_hash,
  effect_json = cbr.effect_json || jsonb_build_object(
    'battle_model_scope', 'fetchland_land_play_with_activation_annotation_v1',
    'oracle_runtime_scope', 'land_play_runtime_fetch_activation_annotation_only',
    'pg062_l1_fetchland_family', 'deck6_fetchlands',
    'fetch_target_scope', tc.fetch_target_scope,
    'modeled_functions', jsonb_build_array('land_play'),
    'annotation_only_functions', jsonb_build_array(
      'pay_1_life',
      'sacrifice_self',
      'search_library_for_allowed_land',
      'put_land_onto_battlefield',
      'shuffle_library'
    ),
    'fetch_activation_status', 'annotation_only',
    'life_payment_status', 'annotation_only',
    'library_search_shuffle_status', 'annotation_only',
    'opening_hand_fixing_status', 'runtime_name_based_fetchland_color_fixing'
  ),
  notes = CASE
    WHEN coalesce(cbr.notes, '') LIKE '%PG062 2026-06-23:%'
      THEN cbr.notes
    ELSE concat_ws(
      E'\n',
      nullif(cbr.notes, ''),
      'PG062 2026-06-23: Deck 6 L1 fetchland family cleanup. Oracle-confirmed fetchland kept as effect=land for current runtime; pay-life/sacrifice/search/shuffle activation is annotation_only, while opening-hand color fixing remains name-based runtime behavior.'
    )
  END,
  reviewed_by = 'codex_pg062',
  reviewed_at = now(),
  updated_at = now(),
  last_seen_at = now()
FROM target_cards tc
WHERE cbr.card_id = tc.card_id
  AND cbr.source = 'curated'
  AND cbr.review_status IN ('verified', 'active')
  AND cbr.execution_status IN ('auto', 'executable')
  AND cbr.effect_json->>'effect' = 'land';

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
  SELECT c.id AS card_id
  FROM target_names tn
  JOIN cards c
    ON lower(c.name) = lower(tn.card_name)
  JOIN deck_cards dc
    ON dc.card_id = c.id
   AND dc.deck_id = '528c877f-f829-4207-95e6-73981776c323'::uuid
)
UPDATE card_battle_rules cbr
SET
  review_status = 'deprecated',
  execution_status = 'disabled',
  notes = CASE
    WHEN coalesce(cbr.notes, '') LIKE '%PG062 2026-06-23:%'
      THEN cbr.notes
    ELSE concat_ws(
      E'\n',
      nullif(cbr.notes, ''),
      'PG062 2026-06-23: Disabled generated needs_review/review_only fetchland shadow after trusted curated land rule received oracle hash and annotation-only fetch scope.'
    )
  END,
  updated_at = now(),
  last_seen_at = now()
FROM target_cards tc
WHERE cbr.card_id = tc.card_id
  AND cbr.source = 'generated'
  AND cbr.review_status = 'needs_review'
  AND cbr.execution_status = 'review_only';

DO $$
DECLARE
  v_trusted_rows integer;
  v_missing_hash_rows integer;
  v_hash_mismatch_rows integer;
  v_missing_scope_rows integer;
  v_active_review_only_rows integer;
  v_disabled_shadow_rows integer;
BEGIN
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
  SELECT
    (SELECT count(*) FROM target_rules WHERE source = 'curated' AND review_status IN ('verified', 'active') AND execution_status IN ('auto', 'executable')),
    (SELECT count(*) FROM target_rules WHERE source = 'curated' AND review_status IN ('verified', 'active') AND execution_status IN ('auto', 'executable') AND coalesce(oracle_hash, '') = ''),
    (SELECT count(*) FROM target_rules WHERE source = 'curated' AND review_status IN ('verified', 'active') AND execution_status IN ('auto', 'executable') AND oracle_hash <> live_oracle_hash),
    (SELECT count(*) FROM target_rules WHERE source = 'curated' AND review_status IN ('verified', 'active') AND execution_status IN ('auto', 'executable') AND effect_json->>'battle_model_scope' <> 'fetchland_land_play_with_activation_annotation_v1'),
    (SELECT count(*) FROM target_rules WHERE review_status = 'needs_review' OR execution_status = 'review_only'),
    (SELECT count(*) FROM target_rules WHERE source = 'generated' AND review_status = 'deprecated' AND execution_status = 'disabled')
  INTO
    v_trusted_rows,
    v_missing_hash_rows,
    v_hash_mismatch_rows,
    v_missing_scope_rows,
    v_active_review_only_rows,
    v_disabled_shadow_rows;

  IF v_trusted_rows <> 8
     OR v_missing_hash_rows <> 0
     OR v_hash_mismatch_rows <> 0
     OR v_missing_scope_rows <> 0
     OR v_active_review_only_rows <> 0
     OR v_disabled_shadow_rows <> 8 THEN
    RAISE EXCEPTION 'PG062 postcondition failed: trusted_rows=%, missing_hash=%, hash_mismatch=%, missing_scope=%, active_review_only=%, disabled_shadow=% expected 8/0/0/0/0/8',
      v_trusted_rows,
      v_missing_hash_rows,
      v_hash_mismatch_rows,
      v_missing_scope_rows,
      v_active_review_only_rows,
      v_disabled_shadow_rows;
  END IF;
END $$;

COMMIT;
