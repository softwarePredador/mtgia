BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('cursed mirror')
   OR normalized_name LIKE 'cursed mirror // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg260_cursed_mirror_exact_runtime_20260629_20260629_1725;

COMMIT;
