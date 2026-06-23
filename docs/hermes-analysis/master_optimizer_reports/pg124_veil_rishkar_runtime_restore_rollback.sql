BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('rishkar, peema renegade', 'veil of summer');

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg124_veil_rishkar_runtime_restore_20260623_234800;

COMMIT;
