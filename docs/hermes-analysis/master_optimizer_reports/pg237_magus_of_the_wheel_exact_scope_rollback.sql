BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('magus of the wheel')
   OR normalized_name LIKE 'magus of the wheel // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg237_magus_of_the_wheel_exact_scope_20260626_093314;

COMMIT;
