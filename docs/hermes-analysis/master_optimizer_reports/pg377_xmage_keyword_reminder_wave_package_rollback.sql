BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('adamant will', 'alabaster mage', 'angelic blessing', 'axgard cavalry', 'beaming defiance', 'bloodlust inciter', 'blossoming defense', 'brute strength', 'chase inspiration', 'coat with venom', 'confidence from strength', 'crimson mage', 'dive down', 'glint', 'goblin motivator', 'grotesque mutation', 'kindled fury', 'moment of heroism', 'mortal''s ardor', 'mortal''s resolve', 'onyx mage', 'predator''s strike', 'ranger''s guile', 'shape the sands', 'silk net', 'slaughter cry', 'snare the skies', 'sure strike', 'thunder strike', 'unlikely aid', 'whip sergeant', 'woodcutter''s grit')
   OR normalized_name LIKE 'adamant will // %'
   OR normalized_name LIKE 'alabaster mage // %'
   OR normalized_name LIKE 'angelic blessing // %'
   OR normalized_name LIKE 'axgard cavalry // %'
   OR normalized_name LIKE 'beaming defiance // %'
   OR normalized_name LIKE 'bloodlust inciter // %'
   OR normalized_name LIKE 'blossoming defense // %'
   OR normalized_name LIKE 'brute strength // %'
   OR normalized_name LIKE 'chase inspiration // %'
   OR normalized_name LIKE 'coat with venom // %'
   OR normalized_name LIKE 'confidence from strength // %'
   OR normalized_name LIKE 'crimson mage // %'
   OR normalized_name LIKE 'dive down // %'
   OR normalized_name LIKE 'glint // %'
   OR normalized_name LIKE 'goblin motivator // %'
   OR normalized_name LIKE 'grotesque mutation // %'
   OR normalized_name LIKE 'kindled fury // %'
   OR normalized_name LIKE 'moment of heroism // %'
   OR normalized_name LIKE 'mortal''s ardor // %'
   OR normalized_name LIKE 'mortal''s resolve // %'
   OR normalized_name LIKE 'onyx mage // %'
   OR normalized_name LIKE 'predator''s strike // %'
   OR normalized_name LIKE 'ranger''s guile // %'
   OR normalized_name LIKE 'shape the sands // %'
   OR normalized_name LIKE 'silk net // %'
   OR normalized_name LIKE 'slaughter cry // %'
   OR normalized_name LIKE 'snare the skies // %'
   OR normalized_name LIKE 'sure strike // %'
   OR normalized_name LIKE 'thunder strike // %'
   OR normalized_name LIKE 'unlikely aid // %'
   OR normalized_name LIKE 'whip sergeant // %'
   OR normalized_name LIKE 'woodcutter''s grit // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg377_xmage_keyword_reminder_wave_20260704_013841;

COMMIT;
