BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('ambush viper', 'ashcoat bear', 'aven reedstalker', 'benalish knight', 'bounding wolf', 'cloaked siren', 'crystacean', 'darksteel sentinel', 'dawn''s light archer', 'faerie invaders', 'fire nation ambushers', 'galewind moose', 'havenwood wurm', 'hired blade', 'hussar patrol', 'king cheetah', 'living tempest', 'merfolk of the depths', 'nephalia seakite', 'plumeveil', 'pouncing cheetah', 'raging kavu', 'riptide turtle', 'sentinels of glen elendra', 'skyline predator', 'spire monitor', 'stormrider spirit', 'swift spinner', 'tangle spider', 'vexing gull', 'wind strider', 'winged coatl', 'zealous guardian')
   OR normalized_name LIKE 'ambush viper // %'
   OR normalized_name LIKE 'ashcoat bear // %'
   OR normalized_name LIKE 'aven reedstalker // %'
   OR normalized_name LIKE 'benalish knight // %'
   OR normalized_name LIKE 'bounding wolf // %'
   OR normalized_name LIKE 'cloaked siren // %'
   OR normalized_name LIKE 'crystacean // %'
   OR normalized_name LIKE 'darksteel sentinel // %'
   OR normalized_name LIKE 'dawn''s light archer // %'
   OR normalized_name LIKE 'faerie invaders // %'
   OR normalized_name LIKE 'fire nation ambushers // %'
   OR normalized_name LIKE 'galewind moose // %'
   OR normalized_name LIKE 'havenwood wurm // %'
   OR normalized_name LIKE 'hired blade // %'
   OR normalized_name LIKE 'hussar patrol // %'
   OR normalized_name LIKE 'king cheetah // %'
   OR normalized_name LIKE 'living tempest // %'
   OR normalized_name LIKE 'merfolk of the depths // %'
   OR normalized_name LIKE 'nephalia seakite // %'
   OR normalized_name LIKE 'plumeveil // %'
   OR normalized_name LIKE 'pouncing cheetah // %'
   OR normalized_name LIKE 'raging kavu // %'
   OR normalized_name LIKE 'riptide turtle // %'
   OR normalized_name LIKE 'sentinels of glen elendra // %'
   OR normalized_name LIKE 'skyline predator // %'
   OR normalized_name LIKE 'spire monitor // %'
   OR normalized_name LIKE 'stormrider spirit // %'
   OR normalized_name LIKE 'swift spinner // %'
   OR normalized_name LIKE 'tangle spider // %'
   OR normalized_name LIKE 'vexing gull // %'
   OR normalized_name LIKE 'wind strider // %'
   OR normalized_name LIKE 'winged coatl // %'
   OR normalized_name LIKE 'zealous guardian // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg425_xmage_static_flash_keywords_new_server_20260704_19;

COMMIT;
