BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('eject', 'escape detection')
   OR normalized_name LIKE 'eject // %'
   OR normalized_name LIKE 'escape detection // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg810_bounce_draw_aux_new_server_20260712_062447;

COMMIT;
