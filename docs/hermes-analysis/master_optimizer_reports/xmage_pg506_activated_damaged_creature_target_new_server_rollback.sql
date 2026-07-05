BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('ogre siegebreaker', 'opportunist', 'witch''s mist')
   OR normalized_name LIKE 'ogre siegebreaker // %'
   OR normalized_name LIKE 'opportunist // %'
   OR normalized_name LIKE 'witch''s mist // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg506_xmage_pg506_activated_damaged_crea_20260705_124220;

COMMIT;
