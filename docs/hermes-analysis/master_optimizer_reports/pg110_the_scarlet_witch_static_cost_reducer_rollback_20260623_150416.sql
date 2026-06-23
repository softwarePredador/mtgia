BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name = 'the scarlet witch';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg110_the_scarlet_witch_static_cost_reducer_20260623_150416;

COMMIT;
