BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('khalni gem')
   OR normalized_name LIKE 'khalni gem // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg765_khalni_gem_new_server_khalni_gem_e_20260711_134814;

COMMIT;
