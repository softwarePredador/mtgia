BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('stream of life')
   OR normalized_name LIKE 'stream of life // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg840_target_player_x_life_gain_new_serv_20260712_193737;

COMMIT;
