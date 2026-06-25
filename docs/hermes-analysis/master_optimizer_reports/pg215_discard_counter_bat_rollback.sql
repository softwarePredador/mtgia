BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('aclazotz, deepest betrayal // temple of the dead', 'green goblin, nemesis')
   OR normalized_name LIKE 'aclazotz, deepest betrayal // temple of the dead // %'
   OR normalized_name LIKE 'green goblin, nemesis // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg215_discard_counter_bat_20260625_101926;

COMMIT;
