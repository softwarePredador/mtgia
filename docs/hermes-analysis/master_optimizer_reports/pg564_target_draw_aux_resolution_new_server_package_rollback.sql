BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('ancestral vision', 'comparative analysis', 'oona''s grace')
   OR normalized_name LIKE 'ancestral vision // %'
   OR normalized_name LIKE 'comparative analysis // %'
   OR normalized_name LIKE 'oona''s grace // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg564_target_draw_aux_resolution_new_ser_20260706_115249;

COMMIT;
