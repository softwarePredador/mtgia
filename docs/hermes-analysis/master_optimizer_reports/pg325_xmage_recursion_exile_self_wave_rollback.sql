BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('flood of recollection', 'restock', 'treasured find')
   OR normalized_name LIKE 'flood of recollection // %'
   OR normalized_name LIKE 'restock // %'
   OR normalized_name LIKE 'treasured find // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg325_xmage_recursion_exile_self_wave_20260701_194250;

COMMIT;
