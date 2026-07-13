BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('congregate')
   OR normalized_name LIKE 'congregate // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg865_dynamic_target_player_life_gain_20260713_053416;

COMMIT;
