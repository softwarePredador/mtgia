BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('rise from the wreck', 'rogues'' gallery')
   OR normalized_name LIKE 'rise from the wreck // %'
   OR normalized_name LIKE 'rogues'' gallery // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg364_multi_target_recursion_wave_20260702_082426;

COMMIT;
