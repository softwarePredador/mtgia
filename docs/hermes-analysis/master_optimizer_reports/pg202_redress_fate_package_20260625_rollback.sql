BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('redress fate')
   OR normalized_name LIKE 'redress fate // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg202_redress_fate_20260625_040611;

COMMIT;
