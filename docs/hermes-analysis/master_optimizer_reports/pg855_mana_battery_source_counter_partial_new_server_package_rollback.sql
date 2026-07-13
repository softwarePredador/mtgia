BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('black mana battery', 'blue mana battery', 'green mana battery', 'red mana battery', 'white mana battery')
   OR normalized_name LIKE 'black mana battery // %'
   OR normalized_name LIKE 'blue mana battery // %'
   OR normalized_name LIKE 'green mana battery // %'
   OR normalized_name LIKE 'red mana battery // %'
   OR normalized_name LIKE 'white mana battery // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg855_mana_battery_source_counter_partia_20260713_011956;

COMMIT;
