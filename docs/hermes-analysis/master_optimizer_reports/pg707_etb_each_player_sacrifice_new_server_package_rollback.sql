BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('abyssal gorestalker', 'fleshbag marauder', 'merciless executioner', 'slum reaper')
   OR normalized_name LIKE 'abyssal gorestalker // %'
   OR normalized_name LIKE 'fleshbag marauder // %'
   OR normalized_name LIKE 'merciless executioner // %'
   OR normalized_name LIKE 'slum reaper // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg707_etb_each_player_sacrifice_new_serv_20260710_153453;

COMMIT;
