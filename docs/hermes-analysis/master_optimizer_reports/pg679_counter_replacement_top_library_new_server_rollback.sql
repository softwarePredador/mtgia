BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('lapse of certainty', 'memory lapse')
   OR normalized_name LIKE 'lapse of certainty // %'
   OR normalized_name LIKE 'memory lapse // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg679_counter_replacement_top_library_20260709_002134;

COMMIT;
