BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('artisan''s sorrow', 'expose to daylight', 'get the point', 'guiding bolt', 'rubble reading', 'skywhaler''s shot', 'tel-jilad justice', 'vanquish the foul')
   OR normalized_name LIKE 'artisan''s sorrow // %'
   OR normalized_name LIKE 'expose to daylight // %'
   OR normalized_name LIKE 'get the point // %'
   OR normalized_name LIKE 'guiding bolt // %'
   OR normalized_name LIKE 'rubble reading // %'
   OR normalized_name LIKE 'skywhaler''s shot // %'
   OR normalized_name LIKE 'tel-jilad justice // %'
   OR normalized_name LIKE 'vanquish the foul // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg460_xmage_destroy_target_scry_new_server_20260705_0047;

COMMIT;
