BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('brainstone')
   OR normalized_name LIKE 'brainstone // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg272_brainstone_executable_topdeck_20260630;

COMMIT;
