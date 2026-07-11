BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('cerulean wisps', 'niveous wisps')
   OR normalized_name LIKE 'cerulean wisps // %'
   OR normalized_name LIKE 'niveous wisps // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg756_color_tap_untap_wisps_draw_new_ser_20260711_103725;

COMMIT;
