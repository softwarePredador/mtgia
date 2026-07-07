BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('meteor storm')
   OR normalized_name LIKE 'meteor storm // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg616_meteor_storm_random_discard_damage_20260707_130403;

COMMIT;
