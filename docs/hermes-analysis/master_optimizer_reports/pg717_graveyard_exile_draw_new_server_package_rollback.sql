BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('cremate')
   OR normalized_name LIKE 'cremate // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg717_graveyard_exile_draw_new_server_gr_20260710_194318;

COMMIT;
