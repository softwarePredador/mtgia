BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('brilliant restoration', 'wake the past')
   OR normalized_name LIKE 'brilliant restoration // %'
   OR normalized_name LIKE 'wake the past // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg203_recursion_lorehold_610_20260625_044242;

COMMIT;
