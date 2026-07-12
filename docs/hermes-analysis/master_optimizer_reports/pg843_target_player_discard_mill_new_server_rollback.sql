BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('horrifying revelation')
   OR normalized_name LIKE 'horrifying revelation // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg843_target_player_discard_mill_new_ser_20260712_201055;

COMMIT;
