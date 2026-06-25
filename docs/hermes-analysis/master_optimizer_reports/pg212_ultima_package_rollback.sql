BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('ultima')
   OR normalized_name LIKE 'ultima // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg212_ultima_20260625_090041;

COMMIT;
