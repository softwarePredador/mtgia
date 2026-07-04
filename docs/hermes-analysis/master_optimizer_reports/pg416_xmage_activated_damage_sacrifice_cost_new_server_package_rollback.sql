BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('arms dealer', 'barrage ogre', 'blazing hellhound', 'fodder cannon', 'heartwood giant', 'hurler cyclops', 'magmaw', 'orcish bloodpainter', 'orcish mechanics', 'orcish vandal', 'scorched rusalka', 'skirsdag cultist', 'skull catapult', 'tar pitcher')
   OR normalized_name LIKE 'arms dealer // %'
   OR normalized_name LIKE 'barrage ogre // %'
   OR normalized_name LIKE 'blazing hellhound // %'
   OR normalized_name LIKE 'fodder cannon // %'
   OR normalized_name LIKE 'heartwood giant // %'
   OR normalized_name LIKE 'hurler cyclops // %'
   OR normalized_name LIKE 'magmaw // %'
   OR normalized_name LIKE 'orcish bloodpainter // %'
   OR normalized_name LIKE 'orcish mechanics // %'
   OR normalized_name LIKE 'orcish vandal // %'
   OR normalized_name LIKE 'scorched rusalka // %'
   OR normalized_name LIKE 'skirsdag cultist // %'
   OR normalized_name LIKE 'skull catapult // %'
   OR normalized_name LIKE 'tar pitcher // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg416_xmage_activated_damage_sacrifice_cost_new_server_2;

COMMIT;
