\pset pager off
BEGIN;
DELETE FROM deck_cards WHERE deck_id = 'c77cb83c-dd28-5d66-a0d8-799079a848bb'::uuid;
DELETE FROM decks WHERE id = 'c77cb83c-dd28-5d66-a0d8-799079a848bb'::uuid;
DELETE FROM commander_learned_decks
WHERE source_system = 'manual_user_deck_registration'
  AND source_ref = 'valgavoth_variant01_20260624_b037751a69fa';
COMMIT;
