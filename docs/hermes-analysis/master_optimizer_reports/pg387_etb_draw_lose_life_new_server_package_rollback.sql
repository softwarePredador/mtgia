BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('dusk legion zealot', 'phyrexian gargantua', 'phyrexian rager', 'tithebearer giant')
   OR normalized_name LIKE 'dusk legion zealot // %'
   OR normalized_name LIKE 'phyrexian gargantua // %'
   OR normalized_name LIKE 'phyrexian rager // %'
   OR normalized_name LIKE 'tithebearer giant // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg387_etb_draw_lose_life_new_server_20260704_055306;

COMMIT;
