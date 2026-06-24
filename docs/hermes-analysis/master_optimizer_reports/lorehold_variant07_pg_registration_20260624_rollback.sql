\pset pager off
BEGIN;
-- PG register rollback for Lorehold Variant 07.
DELETE FROM deck_cards WHERE deck_id = '231281c3-e6a2-579b-93fe-21ddfdd13bda'::uuid;
DELETE FROM decks WHERE id = '231281c3-e6a2-579b-93fe-21ddfdd13bda'::uuid;
DELETE FROM commander_learned_decks
WHERE source_system = 'manual_user_deck_registration'
  AND source_ref = 'lorehold_variant07_20260624_5570c465c492';
COMMIT;
