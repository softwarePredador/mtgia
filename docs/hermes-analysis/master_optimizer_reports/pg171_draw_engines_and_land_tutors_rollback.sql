BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('mystic remora', 'rhystic study', 'crop rotation', 'elvish reclaimer')
   OR normalized_name LIKE 'mystic remora // %'
   OR normalized_name LIKE 'rhystic study // %'
   OR normalized_name LIKE 'crop rotation // %'
   OR normalized_name LIKE 'elvish reclaimer // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg171_draw_engines_and_land_tutors_20260624_121147;

COMMIT;
