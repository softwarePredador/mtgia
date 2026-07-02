BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('advent of the wurm', 'call the cavalry', 'call to the feast', 'jungleborn pioneer', 'knight watch', 'paladin of the bloodstained', 'queen''s commission', 'sworn companions')
   OR normalized_name LIKE 'advent of the wurm // %'
   OR normalized_name LIKE 'call the cavalry // %'
   OR normalized_name LIKE 'call to the feast // %'
   OR normalized_name LIKE 'jungleborn pioneer // %'
   OR normalized_name LIKE 'knight watch // %'
   OR normalized_name LIKE 'paladin of the bloodstained // %'
   OR normalized_name LIKE 'queen''s commission // %'
   OR normalized_name LIKE 'sworn companions // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg370_static_token_keywords_wave_20260702_102950;

COMMIT;
