BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('anguished unmaking', 'ashes to ashes', 'dramatic rescue', 'last breath', 'narrow escape', 'vapor snag')
   OR normalized_name LIKE 'anguished unmaking // %'
   OR normalized_name LIKE 'ashes to ashes // %'
   OR normalized_name LIKE 'dramatic rescue // %'
   OR normalized_name LIKE 'last breath // %'
   OR normalized_name LIKE 'narrow escape // %'
   OR normalized_name LIKE 'vapor snag // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg786_removal_life_delta_new_server_20260711_203810;

COMMIT;
