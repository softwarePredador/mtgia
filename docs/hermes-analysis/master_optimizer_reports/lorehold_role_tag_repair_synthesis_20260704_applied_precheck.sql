SELECT deck_id, card_name, quantity, functional_tag, functional_tags_json, card_id
FROM deck_cards
WHERE deck_id = 607
  AND card_name IN ('Deflecting Swat', 'Emeria''s Call // Emeria, Shattered Skyclave', 'Promise of Loyalty', 'Redirect Lightning', 'Tragic Arrogance')
ORDER BY card_name;
