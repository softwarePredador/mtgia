\pset pager off
-- PG register postcheck for Lorehold Variant 04.
SELECT
  'pg_lorehold_variant04_deck' AS check_name,
  d.id::text AS deck_id,
  d.name,
  d.format,
  d.archetype,
  d.is_public,
  d.deleted_at IS NULL AS not_deleted
FROM decks d
WHERE d.id = '917674eb-6a3d-58de-acce-5a2a3ac9e497'::uuid;

SELECT
  'pg_lorehold_variant04_deck_cards' AS check_name,
  COUNT(*) AS rows,
  COALESCE(SUM(quantity),0)::int AS qty,
  COALESCE(SUM(CASE WHEN is_commander THEN quantity ELSE 0 END),0)::int AS commander_qty,
  COUNT(DISTINCT card_id) AS distinct_cards
FROM deck_cards
WHERE deck_id = '917674eb-6a3d-58de-acce-5a2a3ac9e497'::uuid;

SELECT
  'pg_lorehold_variant04_learned' AS check_name,
  id::text AS learned_id,
  commander_name,
  deck_name,
  source_system,
  source_ref,
  card_count,
  legal_status,
  is_active,
  metadata->>'deck_hash' AS deck_hash,
  metadata->>'hermes_deck_id' AS hermes_deck_id,
  metadata->>'pg_deck_id' AS metadata_pg_deck_id
FROM commander_learned_decks
WHERE source_system = 'manual_user_deck_registration'
  AND source_ref = 'lorehold_variant04_20260624_ba7d06f86f23';

SELECT
  'pg_lorehold_variant04_missing_card_rows' AS check_name,
  COUNT(*) AS missing_card_rows
FROM deck_cards dc
LEFT JOIN cards c ON c.id = dc.card_id
WHERE dc.deck_id = '917674eb-6a3d-58de-acce-5a2a3ac9e497'::uuid
  AND c.id IS NULL;
