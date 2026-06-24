\pset pager off
BEGIN;
-- Rollback for Y'shtola Variant 01 manual registration.
DELETE FROM deck_cards WHERE deck_id = '982cf6a6-c84a-5c3e-b9fc-e79127598b89'::uuid;
DELETE FROM decks WHERE id = '982cf6a6-c84a-5c3e-b9fc-e79127598b89'::uuid;
DELETE FROM commander_learned_decks
WHERE id = '3ee6a17e-c72f-540e-90fe-e05dc37ed5e9'::uuid
  AND source_system = 'manual_user_deck_registration'
  AND source_ref = 'yshtola_variant01_20260624_2165c4d41e85';
COMMIT;
