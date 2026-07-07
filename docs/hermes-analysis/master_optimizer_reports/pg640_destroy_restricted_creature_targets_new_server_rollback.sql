BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('feast of dreams', 'pitfall trap', 'shoot the sheriff', 'smite')
   OR normalized_name LIKE 'feast of dreams // %'
   OR normalized_name LIKE 'pitfall trap // %'
   OR normalized_name LIKE 'shoot the sheriff // %'
   OR normalized_name LIKE 'smite // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg640_destroy_restricted_creature_target_20260707_211817;

COMMIT;
