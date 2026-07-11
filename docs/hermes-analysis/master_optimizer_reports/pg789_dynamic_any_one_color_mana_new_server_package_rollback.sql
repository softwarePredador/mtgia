BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('deathbloom ritualist', 'harabaz druid', 'rofellos, llanowar emissary', 'sanctum weaver', 'wirewood channeler')
   OR normalized_name LIKE 'deathbloom ritualist // %'
   OR normalized_name LIKE 'harabaz druid // %'
   OR normalized_name LIKE 'rofellos, llanowar emissary // %'
   OR normalized_name LIKE 'sanctum weaver // %'
   OR normalized_name LIKE 'wirewood channeler // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg789_dynamic_any_one_color_mana_new_ser_20260711_213604;

COMMIT;
