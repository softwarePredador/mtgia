BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('ambassador laquatus', 'cathartic adept', 'drowner of secrets', 'hair-strung koto', 'merfolk mesmerist', 'millstone', 'tower of murmurs', 'vedalken entrancer')
   OR normalized_name LIKE 'ambassador laquatus // %'
   OR normalized_name LIKE 'cathartic adept // %'
   OR normalized_name LIKE 'drowner of secrets // %'
   OR normalized_name LIKE 'hair-strung koto // %'
   OR normalized_name LIKE 'merfolk mesmerist // %'
   OR normalized_name LIKE 'millstone // %'
   OR normalized_name LIKE 'tower of murmurs // %'
   OR normalized_name LIKE 'vedalken entrancer // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg851_activated_target_player_mill_20260712_233444;

COMMIT;
