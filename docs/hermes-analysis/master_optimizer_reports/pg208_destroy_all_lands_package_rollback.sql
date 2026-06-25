BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('armageddon')
   OR normalized_name LIKE 'armageddon // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg208_destroy_all_lands_20260625_072904;

COMMIT;
