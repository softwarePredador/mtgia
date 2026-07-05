BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('army of allah', 'eyeblight massacre', 'festergloom', 'hazardous conditions', 'hold the line', 'holy light', 'morale', 'nocturnal raid', 'rally', 'stench of decay', 'trumpet blast', 'valorous charge')
   OR normalized_name LIKE 'army of allah // %'
   OR normalized_name LIKE 'eyeblight massacre // %'
   OR normalized_name LIKE 'festergloom // %'
   OR normalized_name LIKE 'hazardous conditions // %'
   OR normalized_name LIKE 'hold the line // %'
   OR normalized_name LIKE 'holy light // %'
   OR normalized_name LIKE 'morale // %'
   OR normalized_name LIKE 'nocturnal raid // %'
   OR normalized_name LIKE 'rally // %'
   OR normalized_name LIKE 'stench of decay // %'
   OR normalized_name LIKE 'trumpet blast // %'
   OR normalized_name LIKE 'valorous charge // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg527_boost_all_filtered_new_server_20260705_200027;

COMMIT;
