BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('bewildering blizzard', 'blinding spray', 'hydrolash')
   OR normalized_name LIKE 'bewildering blizzard // %'
   OR normalized_name LIKE 'blinding spray // %'
   OR normalized_name LIKE 'hydrolash // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg674_boost_all_draw_new_server_boost_al_20260708_221124;

COMMIT;
