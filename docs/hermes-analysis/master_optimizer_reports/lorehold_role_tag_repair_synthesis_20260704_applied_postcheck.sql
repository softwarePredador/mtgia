WITH expected AS (
SELECT 'Deflecting Swat' AS expected_card_name, 'protection' AS expected_primary, '["protection","redirect_removal"]' AS expected_tags
UNION ALL
SELECT 'Emeria''s Call // Emeria, Shattered Skyclave' AS expected_card_name, 'protection' AS expected_primary, '["protection","board_development","token_maker"]' AS expected_tags
UNION ALL
SELECT 'Promise of Loyalty' AS expected_card_name, 'board_wipe' AS expected_primary, '["board_wipe","protection","interaction"]' AS expected_tags
UNION ALL
SELECT 'Redirect Lightning' AS expected_card_name, 'protection' AS expected_primary, '["protection","redirect_removal","interaction"]' AS expected_tags
UNION ALL
SELECT 'Tragic Arrogance' AS expected_card_name, 'board_wipe' AS expected_primary, '["board_wipe","removal","interaction"]' AS expected_tags
)
SELECT e.expected_card_name, dc.functional_tag, dc.functional_tags_json,
       CASE WHEN dc.functional_tag = e.expected_primary
             AND replace(dc.functional_tags_json, ' ', '') = e.expected_tags
            THEN 'ok' ELSE 'mismatch' END AS status
FROM expected e
LEFT JOIN deck_cards dc
  ON dc.deck_id = 607
 AND dc.card_name = e.expected_card_name
ORDER BY e.expected_card_name;
