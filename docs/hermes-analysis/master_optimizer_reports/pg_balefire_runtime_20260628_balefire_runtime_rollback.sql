BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('balefire liege')
   OR normalized_name LIKE 'balefire liege // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg_balefire_runtime_20260628_balefire_runtime_20260628_1;

COMMIT;
