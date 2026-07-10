BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('bankrupt in blood', 'merciless resolve')
   OR normalized_name LIKE 'bankrupt in blood // %'
   OR normalized_name LIKE 'merciless resolve // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg706_draw_sacrifice_additional_cost_new_20260710_151446;

COMMIT;
