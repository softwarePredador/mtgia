BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('last word', 'out of bounds', 'saw it coming')
   OR normalized_name LIKE 'last word // %'
   OR normalized_name LIKE 'out of bounds // %'
   OR normalized_name LIKE 'saw it coming // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg565_counter_aux_resolution_new_server_20260706_120412;

COMMIT;
