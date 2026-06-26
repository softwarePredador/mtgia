BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('razorgrass ambush // razorgrass field')
   OR normalized_name LIKE 'razorgrass ambush // razorgrass field // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg227_razorgrass_ambush_exact_scope_20260626_053850;

COMMIT;
