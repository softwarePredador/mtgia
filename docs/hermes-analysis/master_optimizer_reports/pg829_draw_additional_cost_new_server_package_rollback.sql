BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('necrologia', 'shared discovery')
   OR normalized_name LIKE 'necrologia // %'
   OR normalized_name LIKE 'shared discovery // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg829_draw_additional_cost_new_server_20260712_114509;

COMMIT;
