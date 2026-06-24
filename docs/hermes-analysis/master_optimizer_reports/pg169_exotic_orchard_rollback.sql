BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('exotic orchard')
   OR normalized_name LIKE 'exotic orchard // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg169_exotic_orchard_20260624_113502;

COMMIT;
