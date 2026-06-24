BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('goblin bombardment');

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg130_goblin_bombardment_exact_runtime_restore_20260624_;

COMMIT;
