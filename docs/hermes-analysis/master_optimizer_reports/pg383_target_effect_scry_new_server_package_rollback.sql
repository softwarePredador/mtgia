BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('artisan''s sorrow', 'bolt of keranos', 'expose to daylight', 'fateful end', 'get the point', 'guiding bolt', 'jaya''s firenado', 'jaya''s greeting', 'lightning javelin', 'magma jet', 'piercing light', 'rubble reading', 'select for inspection', 'skywhaler''s shot', 'spark jolt', 'tel-jilad justice', 'vanquish the foul', 'voyage''s end')
   OR normalized_name LIKE 'artisan''s sorrow // %'
   OR normalized_name LIKE 'bolt of keranos // %'
   OR normalized_name LIKE 'expose to daylight // %'
   OR normalized_name LIKE 'fateful end // %'
   OR normalized_name LIKE 'get the point // %'
   OR normalized_name LIKE 'guiding bolt // %'
   OR normalized_name LIKE 'jaya''s firenado // %'
   OR normalized_name LIKE 'jaya''s greeting // %'
   OR normalized_name LIKE 'lightning javelin // %'
   OR normalized_name LIKE 'magma jet // %'
   OR normalized_name LIKE 'piercing light // %'
   OR normalized_name LIKE 'rubble reading // %'
   OR normalized_name LIKE 'select for inspection // %'
   OR normalized_name LIKE 'skywhaler''s shot // %'
   OR normalized_name LIKE 'spark jolt // %'
   OR normalized_name LIKE 'tel-jilad justice // %'
   OR normalized_name LIKE 'vanquish the foul // %'
   OR normalized_name LIKE 'voyage''s end // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg383_target_effect_scry_new_server_20260704_042451;

COMMIT;
