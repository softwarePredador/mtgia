BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('dissolve', 'memory drain')
   OR normalized_name LIKE 'dissolve // %'
   OR normalized_name LIKE 'memory drain // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg566_counter_scry_new_server_20260706_122555;

COMMIT;
