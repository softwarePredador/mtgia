BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('vampiric tutor', 'imperial seal', 'mystical tutor', 'worldly tutor')
   OR normalized_name LIKE 'vampiric tutor // %'
   OR normalized_name LIKE 'imperial seal // %'
   OR normalized_name LIKE 'mystical tutor // %'
   OR normalized_name LIKE 'worldly tutor // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg160_topdeck_tutors_20260624_092630;

COMMIT;
