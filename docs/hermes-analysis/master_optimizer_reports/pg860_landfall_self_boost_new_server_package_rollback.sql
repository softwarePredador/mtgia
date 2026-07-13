BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('akoum hellhound', 'canopy baloth', 'hedron rover', 'hedron scrabbler', 'scythe leopard', 'snapping gnarlid', 'steppe lynx', 'territorial baloth', 'valakut predator')
   OR normalized_name LIKE 'akoum hellhound // %'
   OR normalized_name LIKE 'canopy baloth // %'
   OR normalized_name LIKE 'hedron rover // %'
   OR normalized_name LIKE 'hedron scrabbler // %'
   OR normalized_name LIKE 'scythe leopard // %'
   OR normalized_name LIKE 'snapping gnarlid // %'
   OR normalized_name LIKE 'steppe lynx // %'
   OR normalized_name LIKE 'territorial baloth // %'
   OR normalized_name LIKE 'valakut predator // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg860_landfall_self_boost_new_server_lan_20260713_032448;

COMMIT;
