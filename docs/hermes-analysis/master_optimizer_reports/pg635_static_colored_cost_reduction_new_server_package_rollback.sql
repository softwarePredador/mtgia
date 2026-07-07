BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('edgewalker', 'ragemonger')
   OR normalized_name LIKE 'edgewalker // %'
   OR normalized_name LIKE 'ragemonger // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg635_static_colored_cost_reduction_new_20260707_195231;

COMMIT;
