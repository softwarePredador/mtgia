BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('punk frogs', 'rimeshield frost giant', 'spider-rex, daring dino', 'tomakul honor guard', 'waterfall aerialist')
   OR normalized_name LIKE 'punk frogs // %'
   OR normalized_name LIKE 'rimeshield frost giant // %'
   OR normalized_name LIKE 'spider-rex, daring dino // %'
   OR normalized_name LIKE 'tomakul honor guard // %'
   OR normalized_name LIKE 'waterfall aerialist // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg856_static_ward_creature_new_server_st_20260713_015130;

COMMIT;
