\pset pager off
BEGIN;
DELETE FROM card_legalities WHERE card_id IN (SELECT id FROM cards WHERE scryfall_id = '3db94749-340c-4454-a15d-ba6353e0c4a4'::uuid);
DELETE FROM cards WHERE scryfall_id = '3db94749-340c-4454-a15d-ba6353e0c4a4'::uuid;
COMMIT;
