BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('possibility storm')
   OR normalized_name LIKE 'possibility storm // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg279_possibility_storm_shared_type_free_cast_20260630_1;

COMMIT;
