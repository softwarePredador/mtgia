BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('expedition map', 'moonsilver key', 'weathered wayfarer')
   OR normalized_name LIKE 'expedition map // %'
   OR normalized_name LIKE 'moonsilver key // %'
   OR normalized_name LIKE 'weathered wayfarer // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg162_activated_tutor_to_hand_20260624_101026;

COMMIT;
