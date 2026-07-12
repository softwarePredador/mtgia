BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('carbonize')
   OR normalized_name LIKE 'carbonize // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg811_damage_exile_if_dies_carbonize_new_20260712_064250;

COMMIT;
