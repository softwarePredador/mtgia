\pset pager off
SELECT
  'kaalia_alicia_card_backfill_postcheck_card' AS check_name,
  id,
  scryfall_id,
  oracle_id,
  name,
  set_code,
  collector_number,
  mana_cost,
  type_line,
  cmc
FROM cards
WHERE scryfall_id = '3db94749-340c-4454-a15d-ba6353e0c4a4'::uuid;

SELECT
  'kaalia_alicia_card_backfill_postcheck_legalities' AS check_name,
  COUNT(*) AS legality_rows,
  COUNT(*) FILTER (WHERE format = 'commander' AND status = 'legal') AS commander_legal_rows
FROM card_legalities cl
JOIN cards c ON c.id = cl.card_id
WHERE c.scryfall_id = '3db94749-340c-4454-a15d-ba6353e0c4a4'::uuid;
