BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('aphotic wisps', 'viridescent wisps')
   OR normalized_name LIKE 'aphotic wisps // %'
   OR normalized_name LIKE 'viridescent wisps // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg755_color_wisps_draw_new_server_color_20260711_102501;

COMMIT;
