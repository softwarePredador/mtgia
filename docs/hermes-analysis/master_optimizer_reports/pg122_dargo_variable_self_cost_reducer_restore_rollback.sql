BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('dargo, the shipwrecker');

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg122_dargo_variable_self_cost_reducer_restore_20260623_;

COMMIT;
