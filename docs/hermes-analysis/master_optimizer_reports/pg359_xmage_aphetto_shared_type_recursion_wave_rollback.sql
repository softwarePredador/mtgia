BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('aphetto dredging')
   OR normalized_name LIKE 'aphetto dredging // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg359_xmage_aphetto_shared_type_recursion_wave_20260702_;

COMMIT;
