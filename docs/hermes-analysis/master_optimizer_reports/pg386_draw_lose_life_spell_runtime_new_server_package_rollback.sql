BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('ambition''s cost', 'ancient craving', 'blood pact', 'harrowing journey', 'night''s whisper', 'painful lesson', 'sign in blood', 'succumb to temptation')
   OR normalized_name LIKE 'ambition''s cost // %'
   OR normalized_name LIKE 'ancient craving // %'
   OR normalized_name LIKE 'blood pact // %'
   OR normalized_name LIKE 'harrowing journey // %'
   OR normalized_name LIKE 'night''s whisper // %'
   OR normalized_name LIKE 'painful lesson // %'
   OR normalized_name LIKE 'sign in blood // %'
   OR normalized_name LIKE 'succumb to temptation // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg386_draw_lose_life_spell_runtime_new_server_20260704_0;

COMMIT;
