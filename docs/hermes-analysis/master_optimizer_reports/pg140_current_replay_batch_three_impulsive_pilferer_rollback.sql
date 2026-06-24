BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('impulsive pilferer')
   OR normalized_name LIKE 'impulsive pilferer // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg140_current_replay_batch_three_impulsive_pilferer_2026;

COMMIT;
