BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('damning verdict', 'fight to the death', 'forced march', 'iridian maelstrom', 'retaliate', 'ruinous ultimatum', 'serene heart', 'slash the ranks', 'tivadar''s crusade', 'tranquil domain', 'winds of rath')
   OR normalized_name LIKE 'damning verdict // %'
   OR normalized_name LIKE 'fight to the death // %'
   OR normalized_name LIKE 'forced march // %'
   OR normalized_name LIKE 'iridian maelstrom // %'
   OR normalized_name LIKE 'retaliate // %'
   OR normalized_name LIKE 'ruinous ultimatum // %'
   OR normalized_name LIKE 'serene heart // %'
   OR normalized_name LIKE 'slash the ranks // %'
   OR normalized_name LIKE 'tivadar''s crusade // %'
   OR normalized_name LIKE 'tranquil domain // %'
   OR normalized_name LIKE 'winds of rath // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg681_extended_destroy_board_wipe_new_se_20260709_010121;

COMMIT;
