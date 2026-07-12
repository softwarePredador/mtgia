BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('angelic purge')
   OR normalized_name LIKE 'angelic purge // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg807_exile_ace_target_new_server_exile_20260712_050443;

COMMIT;
