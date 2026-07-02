BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('afflict', 'aggressive urge', 'befuddle', 'bewilder', 'defiant strike', 'fleeting distraction', 'rebellious strike', 'shocking grasp', 'sudden strength', 'sugar rush')
   OR normalized_name LIKE 'afflict // %'
   OR normalized_name LIKE 'aggressive urge // %'
   OR normalized_name LIKE 'befuddle // %'
   OR normalized_name LIKE 'bewilder // %'
   OR normalized_name LIKE 'defiant strike // %'
   OR normalized_name LIKE 'fleeting distraction // %'
   OR normalized_name LIKE 'rebellious strike // %'
   OR normalized_name LIKE 'shocking grasp // %'
   OR normalized_name LIKE 'sudden strength // %'
   OR normalized_name LIKE 'sugar rush // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg372_boost_draw_spell_wave_20260702_105410;

COMMIT;
