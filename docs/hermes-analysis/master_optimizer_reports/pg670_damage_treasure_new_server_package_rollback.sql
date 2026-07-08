BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('improvised weaponry')
   OR normalized_name LIKE 'improvised weaponry // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg670_damage_treasure_new_server_20260708_195352;

COMMIT;
