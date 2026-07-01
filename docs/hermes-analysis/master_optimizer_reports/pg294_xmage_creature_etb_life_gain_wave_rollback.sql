BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('amateur hero', 'angel of mercy', 'arashin cleric', 'arborback stomper', 'aven battle priest', 'aven of enduring hope', 'bulwark giant', 'cathedral sanctifier', 'centaur healer', 'courier griffin', 'dawning angel', 'devout monk', 'healer of the glade', 'hill giant herdgorger', 'honey mammoth', 'inspiring cleric', 'jedit''s dragoons', 'kemba''s skyguard', 'koala-sheep', 'lone missionary', 'mesa cavalier', 'mossbeard ancient', 'peace strider', 'primordial pachyderm', 'ravenous lindwurm', 'savannah sage', 'shu grain caravan', 'shu soldier-farmers', 'spiritual guardian', 'springmane cervin', 'staunch defenders', 'sylvan brushstrider', 'temple acolyte', 'teroh''s faithful', 'tireless missionaries', 'turntimber ascetic', 'venerable monk')
   OR normalized_name LIKE 'amateur hero // %'
   OR normalized_name LIKE 'angel of mercy // %'
   OR normalized_name LIKE 'arashin cleric // %'
   OR normalized_name LIKE 'arborback stomper // %'
   OR normalized_name LIKE 'aven battle priest // %'
   OR normalized_name LIKE 'aven of enduring hope // %'
   OR normalized_name LIKE 'bulwark giant // %'
   OR normalized_name LIKE 'cathedral sanctifier // %'
   OR normalized_name LIKE 'centaur healer // %'
   OR normalized_name LIKE 'courier griffin // %'
   OR normalized_name LIKE 'dawning angel // %'
   OR normalized_name LIKE 'devout monk // %'
   OR normalized_name LIKE 'healer of the glade // %'
   OR normalized_name LIKE 'hill giant herdgorger // %'
   OR normalized_name LIKE 'honey mammoth // %'
   OR normalized_name LIKE 'inspiring cleric // %'
   OR normalized_name LIKE 'jedit''s dragoons // %'
   OR normalized_name LIKE 'kemba''s skyguard // %'
   OR normalized_name LIKE 'koala-sheep // %'
   OR normalized_name LIKE 'lone missionary // %'
   OR normalized_name LIKE 'mesa cavalier // %'
   OR normalized_name LIKE 'mossbeard ancient // %'
   OR normalized_name LIKE 'peace strider // %'
   OR normalized_name LIKE 'primordial pachyderm // %'
   OR normalized_name LIKE 'ravenous lindwurm // %'
   OR normalized_name LIKE 'savannah sage // %'
   OR normalized_name LIKE 'shu grain caravan // %'
   OR normalized_name LIKE 'shu soldier-farmers // %'
   OR normalized_name LIKE 'spiritual guardian // %'
   OR normalized_name LIKE 'springmane cervin // %'
   OR normalized_name LIKE 'staunch defenders // %'
   OR normalized_name LIKE 'sylvan brushstrider // %'
   OR normalized_name LIKE 'temple acolyte // %'
   OR normalized_name LIKE 'teroh''s faithful // %'
   OR normalized_name LIKE 'tireless missionaries // %'
   OR normalized_name LIKE 'turntimber ascetic // %'
   OR normalized_name LIKE 'venerable monk // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg294_xmage_creature_etb_life_gain_wave_20260701_100228;

COMMIT;
