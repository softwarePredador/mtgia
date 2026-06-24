\pset pager off
BEGIN;
DELETE FROM deck_cards WHERE deck_id = 'b629f227-b2b2-5e71-9854-99d345a8e01c'::uuid;
DELETE FROM decks WHERE id = 'b629f227-b2b2-5e71-9854-99d345a8e01c'::uuid;
DELETE FROM commander_learned_decks
WHERE source_system = 'manual_user_deck_registration'
  AND source_ref = 'kaalia_variant01_20260624_b895928feb6f';
COMMIT;
