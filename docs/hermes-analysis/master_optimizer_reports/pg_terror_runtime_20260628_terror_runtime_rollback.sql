BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('terror of the peaks')
   OR normalized_name LIKE 'terror of the peaks // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg_terror_runtime_20260628_terror_runtime_20260628_11084;

COMMIT;
