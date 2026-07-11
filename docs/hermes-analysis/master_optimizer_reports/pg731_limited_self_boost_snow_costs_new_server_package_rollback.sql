BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('boreal centaur', 'chilling shade', 'frostwalla', 'hailstorm valkyrie', 'icebind pillar', 'immolating souleater', 'ohran yeti', 'phyrexian battleflies', 'pit imp', 'rimebound dead', 'roterothopter', 'sewer rats', 'vampire bats')
   OR normalized_name LIKE 'boreal centaur // %'
   OR normalized_name LIKE 'chilling shade // %'
   OR normalized_name LIKE 'frostwalla // %'
   OR normalized_name LIKE 'hailstorm valkyrie // %'
   OR normalized_name LIKE 'icebind pillar // %'
   OR normalized_name LIKE 'immolating souleater // %'
   OR normalized_name LIKE 'ohran yeti // %'
   OR normalized_name LIKE 'phyrexian battleflies // %'
   OR normalized_name LIKE 'pit imp // %'
   OR normalized_name LIKE 'rimebound dead // %'
   OR normalized_name LIKE 'roterothopter // %'
   OR normalized_name LIKE 'sewer rats // %'
   OR normalized_name LIKE 'vampire bats // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg731_limited_self_boost_snow_costs_new_20260711_004701;

COMMIT;
