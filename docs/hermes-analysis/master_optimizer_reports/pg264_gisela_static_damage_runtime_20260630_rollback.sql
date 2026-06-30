BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('gisela, blade of goldnight')
   OR normalized_name LIKE 'gisela, blade of goldnight // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg264_gisela_static_damage_runtime_20260630_20260630_054;

COMMIT;
