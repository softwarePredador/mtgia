BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('scarscale ritual')
   OR normalized_name LIKE 'scarscale ritual // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg785_draw_minus_one_counter_cost_new_se_20260711_200216;

COMMIT;
