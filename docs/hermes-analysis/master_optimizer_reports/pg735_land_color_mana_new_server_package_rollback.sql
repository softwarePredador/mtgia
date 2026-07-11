BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('harvester druid', 'naga vitalist', 'quirion explorer', 'sylvok explorer')
   OR normalized_name LIKE 'harvester druid // %'
   OR normalized_name LIKE 'naga vitalist // %'
   OR normalized_name LIKE 'quirion explorer // %'
   OR normalized_name LIKE 'sylvok explorer // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg735_land_color_mana_new_server_20260711_024205;

COMMIT;
