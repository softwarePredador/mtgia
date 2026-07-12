BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('the golden throne')
   OR normalized_name LIKE 'the golden throne // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg847_golden_throne_new_server_20260712_215759;

COMMIT;
