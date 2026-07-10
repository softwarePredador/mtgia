BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('aetherize', 'evacuation', 'filter out', 'hibernation', 'inundate', 'part the veil', 'reduce to dreams', 'retract', 'sunder', 'whelming wave')
   OR normalized_name LIKE 'aetherize // %'
   OR normalized_name LIKE 'evacuation // %'
   OR normalized_name LIKE 'filter out // %'
   OR normalized_name LIKE 'hibernation // %'
   OR normalized_name LIKE 'inundate // %'
   OR normalized_name LIKE 'part the veil // %'
   OR normalized_name LIKE 'reduce to dreams // %'
   OR normalized_name LIKE 'retract // %'
   OR normalized_name LIKE 'sunder // %'
   OR normalized_name LIKE 'whelming wave // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg709_mass_return_to_hand_new_server_20260710_161253;

COMMIT;
