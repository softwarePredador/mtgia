BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('glimmerburst', 'glittermonger', 'halo scarab', 'pirate''s prize')
   OR normalized_name LIKE 'glimmerburst // %'
   OR normalized_name LIKE 'glittermonger // %'
   OR normalized_name LIKE 'halo scarab // %'
   OR normalized_name LIKE 'pirate''s prize // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg835_token_draw_new_server_20260712_175702;

COMMIT;
