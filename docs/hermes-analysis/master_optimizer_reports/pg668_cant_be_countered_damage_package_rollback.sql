BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('heated debate', 'rending volley')
   OR normalized_name LIKE 'heated debate // %'
   OR normalized_name LIKE 'rending volley // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg668_cant_be_countered_damage_20260708_185901;

COMMIT;
