BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('boros reckoner')
   OR normalized_name LIKE 'boros reckoner // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg_boros_reckoner_runtime_20260628_boros_reckoner_runtim;

COMMIT;
