BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('ethereal haze', 'harmless assault', 'hunter''s ambush', 'thwart the enemy', 'vine snare')
   OR normalized_name LIKE 'ethereal haze // %'
   OR normalized_name LIKE 'harmless assault // %'
   OR normalized_name LIKE 'hunter''s ambush // %'
   OR normalized_name LIKE 'thwart the enemy // %'
   OR normalized_name LIKE 'vine snare // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg643_creature_source_prevention_new_ser_20260707_220414;

COMMIT;
