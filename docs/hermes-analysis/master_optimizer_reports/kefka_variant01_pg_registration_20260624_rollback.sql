\pset pager off
BEGIN;
DELETE FROM deck_cards WHERE deck_id = '34508aae-e393-577a-97d8-6259353664af'::uuid;
DELETE FROM decks WHERE id = '34508aae-e393-577a-97d8-6259353664af'::uuid;
DELETE FROM commander_learned_decks
WHERE source_system = 'manual_user_deck_registration'
  AND source_ref = 'kefka_variant01_20260624_ec4ca73a3063';
COMMIT;
