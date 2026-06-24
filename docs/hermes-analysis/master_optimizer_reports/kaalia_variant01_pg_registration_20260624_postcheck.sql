\pset pager off
SELECT
  'pg_kaalia_variant01_postcheck_deck' AS check_name,
  d.id,
  d.name,
  d.archetype,
  COUNT(dc.*) AS deck_card_rows,
  COALESCE(SUM(dc.quantity),0)::int AS deck_qty,
  COALESCE(SUM(CASE WHEN dc.is_commander THEN dc.quantity ELSE 0 END),0)::int AS commander_qty
FROM decks d
LEFT JOIN deck_cards dc ON dc.deck_id = d.id
WHERE d.id = 'b629f227-b2b2-5e71-9854-99d345a8e01c'::uuid
GROUP BY d.id, d.name, d.archetype;

SELECT
  'pg_kaalia_variant01_postcheck_learned' AS check_name,
  id,
  commander_name,
  source_system,
  source_ref,
  card_count,
  legal_status,
  is_active,
  promoted_at
FROM commander_learned_decks
WHERE source_system = 'manual_user_deck_registration'
  AND source_ref = 'kaalia_variant01_20260624_b895928feb6f';

SELECT
  'pg_kaalia_variant01_postcheck_missing_deck_cards' AS check_name,
  COUNT(*) AS missing_rows
FROM deck_cards dc
LEFT JOIN cards c ON c.id = dc.card_id
WHERE dc.deck_id = 'b629f227-b2b2-5e71-9854-99d345a8e01c'::uuid
  AND c.id IS NULL;
