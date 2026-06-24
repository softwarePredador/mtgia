BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('sun titan')
   OR normalized_name LIKE 'sun titan // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg193_sun_titan_recursion_20260624_232910;

COMMIT;
