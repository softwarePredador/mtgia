BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('cobbled lancer', 'maestros initiate')
   OR normalized_name LIKE 'cobbled lancer // %'
   OR normalized_name LIKE 'maestros initiate // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg730_graveyard_self_exile_draw_new_serv_20260711_002716;

COMMIT;
