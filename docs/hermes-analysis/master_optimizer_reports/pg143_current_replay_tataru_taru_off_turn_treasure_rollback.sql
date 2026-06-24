BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('tataru taru')
   OR normalized_name LIKE 'tataru taru // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg143_current_replay_tataru_taru_off_turn_treasure_20260;

COMMIT;
