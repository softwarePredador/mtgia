BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('coveted jewel')
   OR normalized_name LIKE 'coveted jewel // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg768_coveted_jewel_new_server_coveted_j_20260711_145658;

COMMIT;
