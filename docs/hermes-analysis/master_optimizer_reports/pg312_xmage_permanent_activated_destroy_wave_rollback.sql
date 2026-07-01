BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('ark of blight', 'barbarian riftcutter', 'druid lyrist', 'elf replica', 'elvish lyrist', 'elvish scrapper', 'executioner''s capsule', 'felidar cub', 'kami of ancient law', 'keening apparition', 'mine bearer', 'priest of iroas', 'reckless reveler', 'ronom unicorn', 'royal assassin', 'ruinous gremlin', 'scavenger folk', 'torch fiend', 'universal solvent')
   OR normalized_name LIKE 'ark of blight // %'
   OR normalized_name LIKE 'barbarian riftcutter // %'
   OR normalized_name LIKE 'druid lyrist // %'
   OR normalized_name LIKE 'elf replica // %'
   OR normalized_name LIKE 'elvish lyrist // %'
   OR normalized_name LIKE 'elvish scrapper // %'
   OR normalized_name LIKE 'executioner''s capsule // %'
   OR normalized_name LIKE 'felidar cub // %'
   OR normalized_name LIKE 'kami of ancient law // %'
   OR normalized_name LIKE 'keening apparition // %'
   OR normalized_name LIKE 'mine bearer // %'
   OR normalized_name LIKE 'priest of iroas // %'
   OR normalized_name LIKE 'reckless reveler // %'
   OR normalized_name LIKE 'ronom unicorn // %'
   OR normalized_name LIKE 'royal assassin // %'
   OR normalized_name LIKE 'ruinous gremlin // %'
   OR normalized_name LIKE 'scavenger folk // %'
   OR normalized_name LIKE 'torch fiend // %'
   OR normalized_name LIKE 'universal solvent // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg312_xmage_permanent_activated_destroy_wave_20260701_15;

COMMIT;
