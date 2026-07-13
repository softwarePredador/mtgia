BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('akroma''s vengeance', 'fuel the flames', 'hush', 'starstorm', 'sweltering suns')
   OR normalized_name LIKE 'akroma''s vengeance // %'
   OR normalized_name LIKE 'fuel the flames // %'
   OR normalized_name LIKE 'hush // %'
   OR normalized_name LIKE 'starstorm // %'
   OR normalized_name LIKE 'sweltering suns // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg866_board_wipe_neutral_auxiliary_20260713_054814;

COMMIT;
