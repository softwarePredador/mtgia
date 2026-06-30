BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('eight-and-a-half-tails')
   OR normalized_name LIKE 'eight-and-a-half-tails // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg266_eight_tails_targeted_protection_20260630_061624;

COMMIT;
