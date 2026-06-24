\pset pager off
-- Precheck for single-card catalog backfill required by Kaalia Variant 01.
SELECT
  'kaalia_alicia_card_backfill_precheck' AS check_name,
  (SELECT COUNT(*) FROM cards WHERE scryfall_id = '3db94749-340c-4454-a15d-ba6353e0c4a4'::uuid) AS by_scryfall_id,
  (SELECT COUNT(*) FROM cards WHERE lower(name) = lower('Alicia Masters, Skilled Sculptor')) AS by_name,
  (SELECT COUNT(*) FROM cards WHERE oracle_id = '223504ba-174a-46f2-a4a2-5d663a82dfd3'::uuid) AS by_oracle_id,
  (SELECT COUNT(*) FROM card_legalities cl JOIN cards c ON c.id = cl.card_id WHERE c.scryfall_id = '3db94749-340c-4454-a15d-ba6353e0c4a4'::uuid) AS legality_rows;
