BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('mind shatter', 'mind twist', 'voices from the void')
   OR normalized_name LIKE 'mind shatter // %'
   OR normalized_name LIKE 'mind twist // %'
   OR normalized_name LIKE 'voices from the void // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg775_dynamic_target_player_discard_new_20260711_170300;

COMMIT;
