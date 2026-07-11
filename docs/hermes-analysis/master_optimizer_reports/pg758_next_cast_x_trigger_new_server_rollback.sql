BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('brass infiniscope')
   OR normalized_name LIKE 'brass infiniscope // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg758_next_cast_x_trigger_new_server_nex_20260711_111840;

COMMIT;
