BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('repercussion')
   OR normalized_name LIKE 'repercussion // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg_repercussion_runtime_20260628_repercussion_runtime_20;

COMMIT;
