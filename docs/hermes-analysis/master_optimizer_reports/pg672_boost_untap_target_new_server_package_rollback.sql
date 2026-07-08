BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('fancy footwork', 'gerrard''s command', 'hope and glory', 'inspirit', 'join forces', 'ornamental courage', 'refuse to yield', 'savage surge', 'synchronized strike', 'veteran''s reflexes')
   OR normalized_name LIKE 'fancy footwork // %'
   OR normalized_name LIKE 'gerrard''s command // %'
   OR normalized_name LIKE 'hope and glory // %'
   OR normalized_name LIKE 'inspirit // %'
   OR normalized_name LIKE 'join forces // %'
   OR normalized_name LIKE 'ornamental courage // %'
   OR normalized_name LIKE 'refuse to yield // %'
   OR normalized_name LIKE 'savage surge // %'
   OR normalized_name LIKE 'synchronized strike // %'
   OR normalized_name LIKE 'veteran''s reflexes // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg672_boost_untap_target_new_server_20260708_205718;

COMMIT;
