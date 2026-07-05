BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('brazen freebooter', 'plundering pirate', 'prosperous pirates', 'redcap thief', 'sailor of means', 'wily goblin')
   OR normalized_name LIKE 'brazen freebooter // %'
   OR normalized_name LIKE 'plundering pirate // %'
   OR normalized_name LIKE 'prosperous pirates // %'
   OR normalized_name LIKE 'redcap thief // %'
   OR normalized_name LIKE 'sailor of means // %'
   OR normalized_name LIKE 'wily goblin // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg536_etb_treasure_new_server_20260705_232440;

COMMIT;
