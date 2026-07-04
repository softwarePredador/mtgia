BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('death speakers', 'galina''s knight', 'goblin outlander', 'guma', 'ihsan''s shade', 'karoo meerkat', 'llanowar knight', 'nacatl outlander', 'oraxid', 'oversoul of dusk', 'repentant blacksmith', 'scalebane''s elite', 'shivan zombie', 'valeron outlander', 'vedalken outlander', 'vodalian zombie', 'vulshok refugee', 'yavimaya barbarian', 'zombie outlander')
   OR normalized_name LIKE 'death speakers // %'
   OR normalized_name LIKE 'galina''s knight // %'
   OR normalized_name LIKE 'goblin outlander // %'
   OR normalized_name LIKE 'guma // %'
   OR normalized_name LIKE 'ihsan''s shade // %'
   OR normalized_name LIKE 'karoo meerkat // %'
   OR normalized_name LIKE 'llanowar knight // %'
   OR normalized_name LIKE 'nacatl outlander // %'
   OR normalized_name LIKE 'oraxid // %'
   OR normalized_name LIKE 'oversoul of dusk // %'
   OR normalized_name LIKE 'repentant blacksmith // %'
   OR normalized_name LIKE 'scalebane''s elite // %'
   OR normalized_name LIKE 'shivan zombie // %'
   OR normalized_name LIKE 'valeron outlander // %'
   OR normalized_name LIKE 'vedalken outlander // %'
   OR normalized_name LIKE 'vodalian zombie // %'
   OR normalized_name LIKE 'vulshok refugee // %'
   OR normalized_name LIKE 'yavimaya barbarian // %'
   OR normalized_name LIKE 'zombie outlander // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg413_static_protection_colors_new_server_20260704_16014;

COMMIT;
