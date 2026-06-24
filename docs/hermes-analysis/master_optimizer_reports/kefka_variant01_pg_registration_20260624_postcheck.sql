\pset pager off
SELECT
  'pg_kefka_variant01_postcheck_deck' AS check_name,
  d.id,
  d.name,
  d.archetype,
  COUNT(dc.*) AS deck_card_rows,
  COALESCE(SUM(dc.quantity),0)::int AS deck_qty,
  COALESCE(SUM(CASE WHEN dc.is_commander THEN dc.quantity ELSE 0 END),0)::int AS commander_qty
FROM decks d
LEFT JOIN deck_cards dc ON dc.deck_id = d.id
WHERE d.id = '34508aae-e393-577a-97d8-6259353664af'::uuid
GROUP BY d.id, d.name, d.archetype;

SELECT
  'pg_kefka_variant01_postcheck_learned' AS check_name,
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
  AND source_ref = 'kefka_variant01_20260624_ec4ca73a3063';

SELECT
  'pg_kefka_variant01_postcheck_missing_deck_cards' AS check_name,
  COUNT(*) AS missing_rows
FROM deck_cards dc
LEFT JOIN cards c ON c.id = dc.card_id
WHERE dc.deck_id = '34508aae-e393-577a-97d8-6259353664af'::uuid
  AND c.id IS NULL;
