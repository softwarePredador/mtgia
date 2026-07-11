BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('cruel bargain', 'infernal contract')
   OR normalized_name LIKE 'cruel bargain // %'
   OR normalized_name LIKE 'infernal contract // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg763_draw_lose_half_life_new_server_dra_20260711_130850;

COMMIT;
