BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('electro, assaulting battery')
   OR normalized_name LIKE 'electro, assaulting battery // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg261_electro_ramp_engine_runtime_20260629_20260629_1733;

COMMIT;
