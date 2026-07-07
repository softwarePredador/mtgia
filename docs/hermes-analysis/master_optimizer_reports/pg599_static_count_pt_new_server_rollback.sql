BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('battle squadron', 'beast of burden', 'burrowguard mentor', 'crusader of odric', 'dakkon blackblade', 'dungrove elder', 'heedless one', 'krovikan mist', 'molimo, maro-sorcerer', 'nightmare', 'reckless one', 'scion of the wild', 'squelching leeches')
   OR normalized_name LIKE 'battle squadron // %'
   OR normalized_name LIKE 'beast of burden // %'
   OR normalized_name LIKE 'burrowguard mentor // %'
   OR normalized_name LIKE 'crusader of odric // %'
   OR normalized_name LIKE 'dakkon blackblade // %'
   OR normalized_name LIKE 'dungrove elder // %'
   OR normalized_name LIKE 'heedless one // %'
   OR normalized_name LIKE 'krovikan mist // %'
   OR normalized_name LIKE 'molimo, maro-sorcerer // %'
   OR normalized_name LIKE 'nightmare // %'
   OR normalized_name LIKE 'reckless one // %'
   OR normalized_name LIKE 'scion of the wild // %'
   OR normalized_name LIKE 'squelching leeches // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg599_static_count_pt_new_server_pg599_s_20260707_065427;

COMMIT;
