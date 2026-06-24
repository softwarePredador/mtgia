BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('patrol signaler')
   OR normalized_name LIKE 'patrol signaler // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg146_patrol_signaler_20260624_061620;

COMMIT;
