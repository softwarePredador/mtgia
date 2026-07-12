BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('glimpse the unthinkable', 'mind sculpt', 'tome scour')
   OR normalized_name LIKE 'glimpse the unthinkable // %'
   OR normalized_name LIKE 'mind sculpt // %'
   OR normalized_name LIKE 'tome scour // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg806_target_player_mill_new_server_targ_20260712_044819;

COMMIT;
