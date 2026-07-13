BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('ashen monstrosity', 'berserkers of blood ridge', 'bloodrock cyclops', 'crazed goblin', 'flameborn hellion', 'frontline rebel', 'goblin brigand', 'impetuous sunchaser', 'reckless brute', 'riot piker', 'rubblebelt recluse', 'tattermunge maniac', 'urborg drake', 'utvara scalper', 'valley dasher')
   OR normalized_name LIKE 'ashen monstrosity // %'
   OR normalized_name LIKE 'berserkers of blood ridge // %'
   OR normalized_name LIKE 'bloodrock cyclops // %'
   OR normalized_name LIKE 'crazed goblin // %'
   OR normalized_name LIKE 'flameborn hellion // %'
   OR normalized_name LIKE 'frontline rebel // %'
   OR normalized_name LIKE 'goblin brigand // %'
   OR normalized_name LIKE 'impetuous sunchaser // %'
   OR normalized_name LIKE 'reckless brute // %'
   OR normalized_name LIKE 'riot piker // %'
   OR normalized_name LIKE 'rubblebelt recluse // %'
   OR normalized_name LIKE 'tattermunge maniac // %'
   OR normalized_name LIKE 'urborg drake // %'
   OR normalized_name LIKE 'utvara scalper // %'
   OR normalized_name LIKE 'valley dasher // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg857_static_attacks_each_combat_new_ser_20260713_021240;

COMMIT;
