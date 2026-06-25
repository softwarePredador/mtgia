BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('gods willing', 'sejiri shelter // sejiri glacier')
   OR normalized_name LIKE 'gods willing // %'
   OR normalized_name LIKE 'sejiri shelter // sejiri glacier // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg204_targeted_protection_20260625_051947;

COMMIT;
