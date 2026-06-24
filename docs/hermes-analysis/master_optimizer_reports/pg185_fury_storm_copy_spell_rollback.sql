BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('fury storm')
   OR normalized_name LIKE 'fury storm // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg185_fury_storm_copy_spell_20260624_201931;

COMMIT;
