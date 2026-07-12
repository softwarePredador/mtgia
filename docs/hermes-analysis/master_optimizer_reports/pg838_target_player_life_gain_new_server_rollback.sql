BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('heroes'' reunion', 'natural spring', 'soothing balm')
   OR normalized_name LIKE 'heroes'' reunion // %'
   OR normalized_name LIKE 'natural spring // %'
   OR normalized_name LIKE 'soothing balm // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg838_target_player_life_gain_new_server_20260712_190745;

COMMIT;
