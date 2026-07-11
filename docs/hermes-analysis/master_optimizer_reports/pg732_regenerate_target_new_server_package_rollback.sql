BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('draconian cylix', 'medicine bag', 'niall silvain', 'ragnar', 'rushwood herbalist', 'suture spirit')
   OR normalized_name LIKE 'draconian cylix // %'
   OR normalized_name LIKE 'medicine bag // %'
   OR normalized_name LIKE 'niall silvain // %'
   OR normalized_name LIKE 'ragnar // %'
   OR normalized_name LIKE 'rushwood herbalist // %'
   OR normalized_name LIKE 'suture spirit // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg732_regenerate_target_new_server_20260711_012001;

COMMIT;
