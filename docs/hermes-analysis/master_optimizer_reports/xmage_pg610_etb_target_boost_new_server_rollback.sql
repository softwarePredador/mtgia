BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('blister beetle', 'daybreak charger', 'farbog boneflinger', 'guardian of pilgrims', 'jadecraft artisan', 'kinsbaile skirmisher', 'rubblebelt boar', 'tenth district guard', 'vulshok heartstoker', 'yeva''s forcemage')
   OR normalized_name LIKE 'blister beetle // %'
   OR normalized_name LIKE 'daybreak charger // %'
   OR normalized_name LIKE 'farbog boneflinger // %'
   OR normalized_name LIKE 'guardian of pilgrims // %'
   OR normalized_name LIKE 'jadecraft artisan // %'
   OR normalized_name LIKE 'kinsbaile skirmisher // %'
   OR normalized_name LIKE 'rubblebelt boar // %'
   OR normalized_name LIKE 'tenth district guard // %'
   OR normalized_name LIKE 'vulshok heartstoker // %'
   OR normalized_name LIKE 'yeva''s forcemage // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg610_etb_target_boost_new_server_20260707_105801;

COMMIT;
