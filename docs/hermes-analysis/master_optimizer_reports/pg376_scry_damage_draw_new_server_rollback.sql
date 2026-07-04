BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('behold the multiverse', 'deliberate', 'ember shot', 'foresee', 'introduction to prophecy', 'opt', 'playful shove', 'preordain', 'scour all possibilities', 'serum visions', 'tamiyo''s epiphany', 'zap')
   OR normalized_name LIKE 'behold the multiverse // %'
   OR normalized_name LIKE 'deliberate // %'
   OR normalized_name LIKE 'ember shot // %'
   OR normalized_name LIKE 'foresee // %'
   OR normalized_name LIKE 'introduction to prophecy // %'
   OR normalized_name LIKE 'opt // %'
   OR normalized_name LIKE 'playful shove // %'
   OR normalized_name LIKE 'preordain // %'
   OR normalized_name LIKE 'scour all possibilities // %'
   OR normalized_name LIKE 'serum visions // %'
   OR normalized_name LIKE 'tamiyo''s epiphany // %'
   OR normalized_name LIKE 'zap // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg376_scry_damage_draw_20260704_011604;

COMMIT;
