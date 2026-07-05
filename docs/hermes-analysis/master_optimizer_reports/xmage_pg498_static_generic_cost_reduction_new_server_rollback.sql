BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('ballyrush banneret', 'bosk banneret', 'dragonlord''s servant', 'dragonspeaker shaman', 'emerald medallion', 'etherium sculptor', 'foundry inspector', 'goblin anarchomancer', 'goblin electromancer', 'jet medallion', 'kinjalli''s caller', 'knight of the stampede', 'krosan drover', 'mana matrix', 'planar gate', 'sapphire medallion', 'starnheim aspirant', 'stinkdrinker daredevil', 'stone calendar', 'thornscape familiar', 'voyager quickwelder')
   OR normalized_name LIKE 'ballyrush banneret // %'
   OR normalized_name LIKE 'bosk banneret // %'
   OR normalized_name LIKE 'dragonlord''s servant // %'
   OR normalized_name LIKE 'dragonspeaker shaman // %'
   OR normalized_name LIKE 'emerald medallion // %'
   OR normalized_name LIKE 'etherium sculptor // %'
   OR normalized_name LIKE 'foundry inspector // %'
   OR normalized_name LIKE 'goblin anarchomancer // %'
   OR normalized_name LIKE 'goblin electromancer // %'
   OR normalized_name LIKE 'jet medallion // %'
   OR normalized_name LIKE 'kinjalli''s caller // %'
   OR normalized_name LIKE 'knight of the stampede // %'
   OR normalized_name LIKE 'krosan drover // %'
   OR normalized_name LIKE 'mana matrix // %'
   OR normalized_name LIKE 'planar gate // %'
   OR normalized_name LIKE 'sapphire medallion // %'
   OR normalized_name LIKE 'starnheim aspirant // %'
   OR normalized_name LIKE 'stinkdrinker daredevil // %'
   OR normalized_name LIKE 'stone calendar // %'
   OR normalized_name LIKE 'thornscape familiar // %'
   OR normalized_name LIKE 'voyager quickwelder // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.xmage_pg498_static_generic_cost_reductio_20260705_095259;

COMMIT;
