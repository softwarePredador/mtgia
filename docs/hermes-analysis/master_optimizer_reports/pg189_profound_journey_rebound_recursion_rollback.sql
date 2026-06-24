BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('profound journey')
   OR normalized_name LIKE 'profound journey // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg189_profound_journey_rebound_recursion_20260624_212327;

COMMIT;
