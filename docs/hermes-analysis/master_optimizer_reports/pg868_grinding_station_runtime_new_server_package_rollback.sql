BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('grinding station')
   OR normalized_name LIKE 'grinding station // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg868_grinding_station_runtime_new_serve_20260715_163640;

COMMIT;
