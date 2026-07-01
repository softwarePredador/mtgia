BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('adun oakenshield', 'argivian archaeologist', 'corpse hauler', 'dowsing shaman', 'font of return', 'groundskeeper', 'hanna, ship''s navigator', 'rootwater diver', 'salvage scout', 'skull of orm', 'spellkeeper weird')
   OR normalized_name LIKE 'adun oakenshield // %'
   OR normalized_name LIKE 'argivian archaeologist // %'
   OR normalized_name LIKE 'corpse hauler // %'
   OR normalized_name LIKE 'dowsing shaman // %'
   OR normalized_name LIKE 'font of return // %'
   OR normalized_name LIKE 'groundskeeper // %'
   OR normalized_name LIKE 'hanna, ship''s navigator // %'
   OR normalized_name LIKE 'rootwater diver // %'
   OR normalized_name LIKE 'salvage scout // %'
   OR normalized_name LIKE 'skull of orm // %'
   OR normalized_name LIKE 'spellkeeper weird // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg311_xmage_permanent_activated_recursion_to_hand_wave_2;

COMMIT;
