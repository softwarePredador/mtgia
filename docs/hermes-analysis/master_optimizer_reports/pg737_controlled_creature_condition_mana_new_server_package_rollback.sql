BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('ilysian caryatid', 'leafkin druid', 'raucous audience')
   OR normalized_name LIKE 'ilysian caryatid // %'
   OR normalized_name LIKE 'leafkin druid // %'
   OR normalized_name LIKE 'raucous audience // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg737_controlled_creature_condition_mana_20260711_032028;

COMMIT;
