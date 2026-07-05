BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('aether adept', 'angler drake', 'aven fogbringer', 'bigfin bouncer', 'dispersal technician', 'exclusion mage', 'glowing anemone', 'iceridge serpent', 'man-o''-war', 'mist raven', 'peerless ropemaster', 'riddlemaster sphinx', 'separatist voidmage', 'spider-byte, web warden', 'stern proctor', 'surrakar banisher', 'voidwielder')
   OR normalized_name LIKE 'aether adept // %'
   OR normalized_name LIKE 'angler drake // %'
   OR normalized_name LIKE 'aven fogbringer // %'
   OR normalized_name LIKE 'bigfin bouncer // %'
   OR normalized_name LIKE 'dispersal technician // %'
   OR normalized_name LIKE 'exclusion mage // %'
   OR normalized_name LIKE 'glowing anemone // %'
   OR normalized_name LIKE 'iceridge serpent // %'
   OR normalized_name LIKE 'man-o''-war // %'
   OR normalized_name LIKE 'mist raven // %'
   OR normalized_name LIKE 'peerless ropemaster // %'
   OR normalized_name LIKE 'riddlemaster sphinx // %'
   OR normalized_name LIKE 'separatist voidmage // %'
   OR normalized_name LIKE 'spider-byte, web warden // %'
   OR normalized_name LIKE 'stern proctor // %'
   OR normalized_name LIKE 'surrakar banisher // %'
   OR normalized_name LIKE 'voidwielder // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg490_creature_etb_bounce_new_server_20260705_073732;

COMMIT;
