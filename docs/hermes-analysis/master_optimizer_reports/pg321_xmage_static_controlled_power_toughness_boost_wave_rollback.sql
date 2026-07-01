BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('anthem of champions', 'battle sliver', 'benalish marshal', 'bladestitched skaab', 'blessed orator', 'broodwarden', 'chief of the edge', 'chief of the foundry', 'chief of the scale', 'cleaving sliver', 'collective blessing', 'day of destiny', 'fire nation''s conquest', 'flowstone surge', 'gaea''s anthem', 'glorious anthem', 'inspiring veteran', 'kargan warleader', 'king of the pride', 'kongming, "sleeping dragon"', 'megantic sliver', 'pride of the perfect', 'regal imperiosaur', 'squirrel sovereign', 'steelform sliver', 'tempered steel', 'thirsting bloodlord', 'veteran armorer', 'veteran armorsmith', 'veteran swordsmith', 'wizened cenn', 'yotian tactician')
   OR normalized_name LIKE 'anthem of champions // %'
   OR normalized_name LIKE 'battle sliver // %'
   OR normalized_name LIKE 'benalish marshal // %'
   OR normalized_name LIKE 'bladestitched skaab // %'
   OR normalized_name LIKE 'blessed orator // %'
   OR normalized_name LIKE 'broodwarden // %'
   OR normalized_name LIKE 'chief of the edge // %'
   OR normalized_name LIKE 'chief of the foundry // %'
   OR normalized_name LIKE 'chief of the scale // %'
   OR normalized_name LIKE 'cleaving sliver // %'
   OR normalized_name LIKE 'collective blessing // %'
   OR normalized_name LIKE 'day of destiny // %'
   OR normalized_name LIKE 'fire nation''s conquest // %'
   OR normalized_name LIKE 'flowstone surge // %'
   OR normalized_name LIKE 'gaea''s anthem // %'
   OR normalized_name LIKE 'glorious anthem // %'
   OR normalized_name LIKE 'inspiring veteran // %'
   OR normalized_name LIKE 'kargan warleader // %'
   OR normalized_name LIKE 'king of the pride // %'
   OR normalized_name LIKE 'kongming, "sleeping dragon" // %'
   OR normalized_name LIKE 'megantic sliver // %'
   OR normalized_name LIKE 'pride of the perfect // %'
   OR normalized_name LIKE 'regal imperiosaur // %'
   OR normalized_name LIKE 'squirrel sovereign // %'
   OR normalized_name LIKE 'steelform sliver // %'
   OR normalized_name LIKE 'tempered steel // %'
   OR normalized_name LIKE 'thirsting bloodlord // %'
   OR normalized_name LIKE 'veteran armorer // %'
   OR normalized_name LIKE 'veteran armorsmith // %'
   OR normalized_name LIKE 'veteran swordsmith // %'
   OR normalized_name LIKE 'wizened cenn // %'
   OR normalized_name LIKE 'yotian tactician // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg321_xmage_static_controlled_power_toughness_boost_wave;

COMMIT;
