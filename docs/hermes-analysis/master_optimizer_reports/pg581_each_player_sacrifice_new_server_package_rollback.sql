BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('barter in blood', 'crack the earth', 'innocent blood', 'renounce the guilds', 'simplify', 'tergrid''s shadow', 'tremble')
   OR normalized_name LIKE 'barter in blood // %'
   OR normalized_name LIKE 'crack the earth // %'
   OR normalized_name LIKE 'innocent blood // %'
   OR normalized_name LIKE 'renounce the guilds // %'
   OR normalized_name LIKE 'simplify // %'
   OR normalized_name LIKE 'tergrid''s shadow // %'
   OR normalized_name LIKE 'tremble // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg581_each_player_sacrifice_new_server_20260706_235302;

COMMIT;
