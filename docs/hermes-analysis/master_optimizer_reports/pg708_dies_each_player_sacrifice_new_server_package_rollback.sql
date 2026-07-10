BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('abyssal gatekeeper', 'akki blizzard-herder', 'hurloon shaman')
   OR normalized_name LIKE 'abyssal gatekeeper // %'
   OR normalized_name LIKE 'akki blizzard-herder // %'
   OR normalized_name LIKE 'hurloon shaman // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg708_dies_each_player_sacrifice_new_ser_20260710_155036;

COMMIT;
