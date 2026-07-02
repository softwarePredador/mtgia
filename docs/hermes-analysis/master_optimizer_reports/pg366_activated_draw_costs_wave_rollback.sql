BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('akki scrapchomper', 'book of rass', 'carnage altar', 'destructive digger', 'dockside chef', 'greed', 'hardened tactician', 'infernal tribute', 'phyrexian vault', 'slagdrill scrapper', 'soulreaper of mogis', 'thallid soothsayer')
   OR normalized_name LIKE 'akki scrapchomper // %'
   OR normalized_name LIKE 'book of rass // %'
   OR normalized_name LIKE 'carnage altar // %'
   OR normalized_name LIKE 'destructive digger // %'
   OR normalized_name LIKE 'dockside chef // %'
   OR normalized_name LIKE 'greed // %'
   OR normalized_name LIKE 'hardened tactician // %'
   OR normalized_name LIKE 'infernal tribute // %'
   OR normalized_name LIKE 'phyrexian vault // %'
   OR normalized_name LIKE 'slagdrill scrapper // %'
   OR normalized_name LIKE 'soulreaper of mogis // %'
   OR normalized_name LIKE 'thallid soothsayer // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg366_activated_draw_costs_wave_20260702_090704;

COMMIT;
