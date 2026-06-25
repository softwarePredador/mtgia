BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('squee, goblin nabob')
   OR normalized_name LIKE 'squee, goblin nabob // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg196_squee_goblin_nabob_20260625_003756;

COMMIT;
