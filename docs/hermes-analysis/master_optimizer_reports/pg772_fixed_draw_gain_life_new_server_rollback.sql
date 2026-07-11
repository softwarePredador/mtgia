BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('voyage home')
   OR normalized_name LIKE 'voyage home // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg772_fixed_draw_gain_life_new_server_fi_20260711_161412;

COMMIT;
