BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('aegis of the heavens', 'antagonize', 'auger spree', 'brute force', 'bull rush', 'dark deed', 'dark remedy', 'demon''s grasp', 'disfigure', 'disorient', 'eyes of the beholder', 'fatal fumes', 'feral roar', 'fists of the anvil', 'flatten', 'flowstone infusion', 'giant growth', 'grasp of darkness', 'howling fury', 'hydrosurge', 'infuriate', 'lash of malice', 'lash of the whip', 'last gasp', 'might of oaks', 'monstrous growth', 'mutagenic growth', 'overkill', 'phytoburst', 'pull under', 'qilin''s blessing', 'scorpion''s sting', 'show of valor', 'shrink', 'spatial contortion', 'stab', 'strangling spores', 'tar snare', 'throttle', 'titanic growth', 'wielding the green dragon', 'wring flesh')
   OR normalized_name LIKE 'aegis of the heavens // %'
   OR normalized_name LIKE 'antagonize // %'
   OR normalized_name LIKE 'auger spree // %'
   OR normalized_name LIKE 'brute force // %'
   OR normalized_name LIKE 'bull rush // %'
   OR normalized_name LIKE 'dark deed // %'
   OR normalized_name LIKE 'dark remedy // %'
   OR normalized_name LIKE 'demon''s grasp // %'
   OR normalized_name LIKE 'disfigure // %'
   OR normalized_name LIKE 'disorient // %'
   OR normalized_name LIKE 'eyes of the beholder // %'
   OR normalized_name LIKE 'fatal fumes // %'
   OR normalized_name LIKE 'feral roar // %'
   OR normalized_name LIKE 'fists of the anvil // %'
   OR normalized_name LIKE 'flatten // %'
   OR normalized_name LIKE 'flowstone infusion // %'
   OR normalized_name LIKE 'giant growth // %'
   OR normalized_name LIKE 'grasp of darkness // %'
   OR normalized_name LIKE 'howling fury // %'
   OR normalized_name LIKE 'hydrosurge // %'
   OR normalized_name LIKE 'infuriate // %'
   OR normalized_name LIKE 'lash of malice // %'
   OR normalized_name LIKE 'lash of the whip // %'
   OR normalized_name LIKE 'last gasp // %'
   OR normalized_name LIKE 'might of oaks // %'
   OR normalized_name LIKE 'monstrous growth // %'
   OR normalized_name LIKE 'mutagenic growth // %'
   OR normalized_name LIKE 'overkill // %'
   OR normalized_name LIKE 'phytoburst // %'
   OR normalized_name LIKE 'pull under // %'
   OR normalized_name LIKE 'qilin''s blessing // %'
   OR normalized_name LIKE 'scorpion''s sting // %'
   OR normalized_name LIKE 'show of valor // %'
   OR normalized_name LIKE 'shrink // %'
   OR normalized_name LIKE 'spatial contortion // %'
   OR normalized_name LIKE 'stab // %'
   OR normalized_name LIKE 'strangling spores // %'
   OR normalized_name LIKE 'tar snare // %'
   OR normalized_name LIKE 'throttle // %'
   OR normalized_name LIKE 'titanic growth // %'
   OR normalized_name LIKE 'wielding the green dragon // %'
   OR normalized_name LIKE 'wring flesh // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg291_xmage_boost_target_spell_wave_20260701_092129;

COMMIT;
