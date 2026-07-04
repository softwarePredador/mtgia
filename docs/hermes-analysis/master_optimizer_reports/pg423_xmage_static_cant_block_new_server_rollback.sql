BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('ashenmoor gouger', 'craven giant', 'craven knight', 'goblin raider', 'hulking cyclops', 'hulking goblin', 'hulking ogre', 'jungle lion', 'ogre taskmaster', 'scavenging scarab', 'spineless thug', 'yellow scarves troops', 'young wei recruits')
   OR normalized_name LIKE 'ashenmoor gouger // %'
   OR normalized_name LIKE 'craven giant // %'
   OR normalized_name LIKE 'craven knight // %'
   OR normalized_name LIKE 'goblin raider // %'
   OR normalized_name LIKE 'hulking cyclops // %'
   OR normalized_name LIKE 'hulking goblin // %'
   OR normalized_name LIKE 'hulking ogre // %'
   OR normalized_name LIKE 'jungle lion // %'
   OR normalized_name LIKE 'ogre taskmaster // %'
   OR normalized_name LIKE 'scavenging scarab // %'
   OR normalized_name LIKE 'spineless thug // %'
   OR normalized_name LIKE 'yellow scarves troops // %'
   OR normalized_name LIKE 'young wei recruits // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg423_xmage_static_cant_block_new_server_20260704_190640;

COMMIT;
