BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('blood moon', 'deathbellow war cry')
   OR normalized_name LIKE 'blood moon // %'
   OR normalized_name LIKE 'deathbellow war cry // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg281_blood_moon_deathbellow_static_tutor_20260630_13402;

COMMIT;
