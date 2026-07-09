BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('coordinated assault', 'cutthroat maneuver', 'press the advantage')
   OR normalized_name LIKE 'coordinated assault // %'
   OR normalized_name LIKE 'cutthroat maneuver // %'
   OR normalized_name LIKE 'press the advantage // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg702_boost_keyword_multi_target_new_ser_20260709_081420;

COMMIT;
