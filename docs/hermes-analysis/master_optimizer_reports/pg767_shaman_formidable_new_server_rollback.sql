BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('shaman of forgotten ways')
   OR normalized_name LIKE 'shaman of forgotten ways // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg767_shaman_formidable_new_server_shama_20260711_142706;

COMMIT;
