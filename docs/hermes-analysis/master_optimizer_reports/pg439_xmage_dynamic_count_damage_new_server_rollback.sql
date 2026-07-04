BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('armed response', 'artillery blast', 'divine retribution', 'dogpile', 'earth tremor', 'feedback bolt', 'goblin war strike', 'ground assault', 'massive raid', 'mob justice', 'outflank', 'outnumber', 'rockslide ambush', 'rumbling rockslide', 'seismic strike', 'spiraling embers', 'spire barrage', 'spitting earth', 'stonefury', 'tribal flames', 'welding sparks')
   OR normalized_name LIKE 'armed response // %'
   OR normalized_name LIKE 'artillery blast // %'
   OR normalized_name LIKE 'divine retribution // %'
   OR normalized_name LIKE 'dogpile // %'
   OR normalized_name LIKE 'earth tremor // %'
   OR normalized_name LIKE 'feedback bolt // %'
   OR normalized_name LIKE 'goblin war strike // %'
   OR normalized_name LIKE 'ground assault // %'
   OR normalized_name LIKE 'massive raid // %'
   OR normalized_name LIKE 'mob justice // %'
   OR normalized_name LIKE 'outflank // %'
   OR normalized_name LIKE 'outnumber // %'
   OR normalized_name LIKE 'rockslide ambush // %'
   OR normalized_name LIKE 'rumbling rockslide // %'
   OR normalized_name LIKE 'seismic strike // %'
   OR normalized_name LIKE 'spiraling embers // %'
   OR normalized_name LIKE 'spire barrage // %'
   OR normalized_name LIKE 'spitting earth // %'
   OR normalized_name LIKE 'stonefury // %'
   OR normalized_name LIKE 'tribal flames // %'
   OR normalized_name LIKE 'welding sparks // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg439_xmage_dynamic_count_damage_new_server_20260704_220;

COMMIT;
