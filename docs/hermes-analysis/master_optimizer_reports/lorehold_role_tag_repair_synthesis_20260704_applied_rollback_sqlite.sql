BEGIN;
UPDATE deck_cards
SET functional_tag = 'draw',
    functional_tags_json = '["draw","protection","redirect_removal"]'
WHERE deck_id = 607
  AND card_name = 'Deflecting Swat'
  AND card_id = 'ae0d54e1-1471-4bb7-8b8d-09ef5b51b2ed';

UPDATE deck_cards
SET functional_tag = 'unknown',
    functional_tags_json = '["unknown"]'
WHERE deck_id = 607
  AND card_name = 'Emeria''s Call // Emeria, Shattered Skyclave'
  AND card_id = '356b93e3-62db-44ec-9322-4e999eefc674';

UPDATE deck_cards
SET functional_tag = 'draw',
    functional_tags_json = '["draw"]'
WHERE deck_id = 607
  AND card_name = 'Promise of Loyalty'
  AND card_id = '6a219f1a-0b0a-4628-9d60-b81f7dbcab5c';

UPDATE deck_cards
SET functional_tag = 'draw',
    functional_tags_json = '["draw"]'
WHERE deck_id = 607
  AND card_name = 'Redirect Lightning'
  AND card_id = '558a8bda-ea1a-4c01-b3c2-186a2ad6478d';

UPDATE deck_cards
SET functional_tag = 'unknown',
    functional_tags_json = '["unknown"]'
WHERE deck_id = 607
  AND card_name = 'Tragic Arrogance'
  AND card_id = 'abe21b14-7c49-4629-bbf2-8fce03d66d94';
COMMIT;
