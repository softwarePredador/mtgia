BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('blood moon', 'karn, the great creator', 'chandra''s ignition', 'karn''s sylex', 'naktamun lorespinner // wheel of fortune', 'charmbreaker devils', 'ancient gold dragon', 'deathbellow war cry')
   OR normalized_name LIKE 'blood moon // %'
   OR normalized_name LIKE 'karn, the great creator // %'
   OR normalized_name LIKE 'chandra''s ignition // %'
   OR normalized_name LIKE 'karn''s sylex // %'
   OR normalized_name LIKE 'naktamun lorespinner // wheel of fortune // %'
   OR normalized_name LIKE 'charmbreaker devils // %'
   OR normalized_name LIKE 'ancient gold dragon // %'
   OR normalized_name LIKE 'deathbellow war cry // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg282_final_eight_runtime_closure_20260630_20260630_1558;

COMMIT;
