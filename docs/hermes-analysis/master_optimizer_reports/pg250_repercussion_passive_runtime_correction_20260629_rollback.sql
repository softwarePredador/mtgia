BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name = 'repercussion'
   OR normalized_name LIKE 'repercussion // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg250_repercussion_passive_runtime_correction_20260629_145402;

COMMIT;
