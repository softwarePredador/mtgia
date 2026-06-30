BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('cloud key')
   OR normalized_name LIKE 'cloud key // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg268_cloud_key_chosen_type_cost_reduction_20260630_clou;

COMMIT;
