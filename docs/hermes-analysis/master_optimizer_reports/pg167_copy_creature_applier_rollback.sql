BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('imposter mech', 'mockingbird', 'flesh duplicate', 'phantasmal image')
   OR normalized_name LIKE 'imposter mech // %'
   OR normalized_name LIKE 'mockingbird // %'
   OR normalized_name LIKE 'flesh duplicate // %'
   OR normalized_name LIKE 'phantasmal image // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg167_copy_creature_applier_20260624_111913;

COMMIT;
