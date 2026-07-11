BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('lethal sting')
   OR normalized_name LIKE 'lethal sting // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg784_minus_one_counter_cost_new_server_20260711_194940;

COMMIT;
