BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('erode', 'sundering eruption // volcanic fissure')
   OR normalized_name LIKE 'erode // %'
   OR normalized_name LIKE 'sundering eruption // volcanic fissure // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg220_erode_sundering_destroy_exact_20260626_030046;

COMMIT;
