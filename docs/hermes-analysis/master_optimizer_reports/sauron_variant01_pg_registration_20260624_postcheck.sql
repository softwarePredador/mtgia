\pset pager off
SELECT
  'pg_sauron_variant01_postcheck_deck' AS check_name,
  d.id,
  d.name,
  d.archetype,
  COUNT(dc.*) AS deck_card_rows,
  COALESCE(SUM(dc.quantity),0)::int AS deck_qty,
  COALESCE(SUM(CASE WHEN dc.is_commander THEN dc.quantity ELSE 0 END),0)::int AS commander_qty
FROM decks d
LEFT JOIN deck_cards dc ON dc.deck_id = d.id
WHERE d.id = 'c2230827-7963-52e4-a6ba-298d7be3478a'::uuid
GROUP BY d.id, d.name, d.archetype;

SELECT
  'pg_sauron_variant01_postcheck_learned' AS check_name,
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
  AND source_ref = 'sauron_variant01_20260624_6aa4f012e11d';

SELECT
  'pg_sauron_variant01_postcheck_missing_deck_cards' AS check_name,
  COUNT(*) AS missing_rows
FROM deck_cards dc
LEFT JOIN cards c ON c.id = dc.card_id
WHERE dc.deck_id = 'c2230827-7963-52e4-a6ba-298d7be3478a'::uuid
  AND c.id IS NULL;
