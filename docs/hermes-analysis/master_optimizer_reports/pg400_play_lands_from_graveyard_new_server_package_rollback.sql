BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('crucible of worlds', 'ramunap excavator')
   OR normalized_name LIKE 'crucible of worlds // %'
   OR normalized_name LIKE 'ramunap excavator // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg400_play_lands_from_graveyard_new_server_20260704_1043;

COMMIT;
