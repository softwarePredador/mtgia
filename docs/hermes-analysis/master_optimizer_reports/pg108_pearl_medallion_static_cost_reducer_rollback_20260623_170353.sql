BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name = 'pearl medallion';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg108_pearl_medallion_static_cost_reducer_20260623_170353;

COMMIT;
