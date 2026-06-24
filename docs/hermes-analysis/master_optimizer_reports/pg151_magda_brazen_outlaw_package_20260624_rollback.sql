BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('magda, brazen outlaw')
   OR normalized_name LIKE 'magda, brazen outlaw // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg151_magda_brazen_outlaw_20260624_073825;

COMMIT;
