BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('nature''s rhythm', 'chord of calling', 'green sun''s zenith', 'whir of invention')
   OR normalized_name LIKE 'nature''s rhythm // %'
   OR normalized_name LIKE 'chord of calling // %'
   OR normalized_name LIKE 'green sun''s zenith // %'
   OR normalized_name LIKE 'whir of invention // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg173_x_tutor_battlefield_spells_20260624_123404;

COMMIT;
