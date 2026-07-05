BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('adventurous impulse', 'ancient stirrings', 'anticipate', 'commune with beavers', 'commune with nature', 'commune with spirits', 'drawn from dreams', 'forging the anchor', 'impulse', 'lead the stampede', 'peer through depths', 'seek the wilds', 'shimmer of possibility', 'sleight of hand', 'stock up')
   OR normalized_name LIKE 'adventurous impulse // %'
   OR normalized_name LIKE 'ancient stirrings // %'
   OR normalized_name LIKE 'anticipate // %'
   OR normalized_name LIKE 'commune with beavers // %'
   OR normalized_name LIKE 'commune with nature // %'
   OR normalized_name LIKE 'commune with spirits // %'
   OR normalized_name LIKE 'drawn from dreams // %'
   OR normalized_name LIKE 'forging the anchor // %'
   OR normalized_name LIKE 'impulse // %'
   OR normalized_name LIKE 'lead the stampede // %'
   OR normalized_name LIKE 'peer through depths // %'
   OR normalized_name LIKE 'seek the wilds // %'
   OR normalized_name LIKE 'shimmer of possibility // %'
   OR normalized_name LIKE 'sleight of hand // %'
   OR normalized_name LIKE 'stock up // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg479_look_library_pick_bottom_new_server_20260705_03405;

COMMIT;
