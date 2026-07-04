BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('arms dealer', 'aven archer', 'barrage ogre', 'bear trap', 'blazing hellhound', 'crimson manticore', 'cunning sparkmage', 'dive bomber', 'divebomber griffin', 'fanatical firebrand', 'fodder cannon', 'heartwood giant', 'hurler cyclops', 'jeska, warrior adept', 'kamahl, pit fighter', 'magmaw', 'mawcor', 'orcish bloodpainter', 'orcish mechanics', 'orcish vandal', 'sarpadian simulacrum', 'scaldkin', 'scorched rusalka', 'shivan hellkite', 'skirsdag cultist', 'skull catapult', 'skyway sniper', 'springjaw trap', 'stinging barrier', 'storm spirit', 'tar pitcher', 'thornwind faeries', 'vulshok sorcerer')
   OR normalized_name LIKE 'arms dealer // %'
   OR normalized_name LIKE 'aven archer // %'
   OR normalized_name LIKE 'barrage ogre // %'
   OR normalized_name LIKE 'bear trap // %'
   OR normalized_name LIKE 'blazing hellhound // %'
   OR normalized_name LIKE 'crimson manticore // %'
   OR normalized_name LIKE 'cunning sparkmage // %'
   OR normalized_name LIKE 'dive bomber // %'
   OR normalized_name LIKE 'divebomber griffin // %'
   OR normalized_name LIKE 'fanatical firebrand // %'
   OR normalized_name LIKE 'fodder cannon // %'
   OR normalized_name LIKE 'heartwood giant // %'
   OR normalized_name LIKE 'hurler cyclops // %'
   OR normalized_name LIKE 'jeska, warrior adept // %'
   OR normalized_name LIKE 'kamahl, pit fighter // %'
   OR normalized_name LIKE 'magmaw // %'
   OR normalized_name LIKE 'mawcor // %'
   OR normalized_name LIKE 'orcish bloodpainter // %'
   OR normalized_name LIKE 'orcish mechanics // %'
   OR normalized_name LIKE 'orcish vandal // %'
   OR normalized_name LIKE 'sarpadian simulacrum // %'
   OR normalized_name LIKE 'scaldkin // %'
   OR normalized_name LIKE 'scorched rusalka // %'
   OR normalized_name LIKE 'shivan hellkite // %'
   OR normalized_name LIKE 'skirsdag cultist // %'
   OR normalized_name LIKE 'skull catapult // %'
   OR normalized_name LIKE 'skyway sniper // %'
   OR normalized_name LIKE 'springjaw trap // %'
   OR normalized_name LIKE 'stinging barrier // %'
   OR normalized_name LIKE 'storm spirit // %'
   OR normalized_name LIKE 'tar pitcher // %'
   OR normalized_name LIKE 'thornwind faeries // %'
   OR normalized_name LIKE 'vulshok sorcerer // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg433_xmage_permanent_activated_damage_new_server_202607;

COMMIT;
