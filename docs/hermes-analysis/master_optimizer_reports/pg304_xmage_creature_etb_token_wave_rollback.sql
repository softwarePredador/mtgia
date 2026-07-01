BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('ambassador oak', 'aviation pioneer', 'bear''s companion', 'beetleback chief', 'clarion cathars', 'daysquad marshal', 'dragon trainer', 'eager glyphmage', 'elder auntie', 'elderleaf mentor', 'enlightened maniac', 'ferocious pup', 'ghirapur gearcrafter', 'goblin gang leader', 'goblin instigator', 'head of the homestead', 'kyoshi warriors', 'mechanized ninja cavalry', 'nimble thopterist', 'protector of gondor', 'seller of songbirds', 'silvergill mentor', 'sourbread auntie', 'tunnel surveyor', 'urbis protector', 'watchful giant', 'yavimaya sapherd')
   OR normalized_name LIKE 'ambassador oak // %'
   OR normalized_name LIKE 'aviation pioneer // %'
   OR normalized_name LIKE 'bear''s companion // %'
   OR normalized_name LIKE 'beetleback chief // %'
   OR normalized_name LIKE 'clarion cathars // %'
   OR normalized_name LIKE 'daysquad marshal // %'
   OR normalized_name LIKE 'dragon trainer // %'
   OR normalized_name LIKE 'eager glyphmage // %'
   OR normalized_name LIKE 'elder auntie // %'
   OR normalized_name LIKE 'elderleaf mentor // %'
   OR normalized_name LIKE 'enlightened maniac // %'
   OR normalized_name LIKE 'ferocious pup // %'
   OR normalized_name LIKE 'ghirapur gearcrafter // %'
   OR normalized_name LIKE 'goblin gang leader // %'
   OR normalized_name LIKE 'goblin instigator // %'
   OR normalized_name LIKE 'head of the homestead // %'
   OR normalized_name LIKE 'kyoshi warriors // %'
   OR normalized_name LIKE 'mechanized ninja cavalry // %'
   OR normalized_name LIKE 'nimble thopterist // %'
   OR normalized_name LIKE 'protector of gondor // %'
   OR normalized_name LIKE 'seller of songbirds // %'
   OR normalized_name LIKE 'silvergill mentor // %'
   OR normalized_name LIKE 'sourbread auntie // %'
   OR normalized_name LIKE 'tunnel surveyor // %'
   OR normalized_name LIKE 'urbis protector // %'
   OR normalized_name LIKE 'watchful giant // %'
   OR normalized_name LIKE 'yavimaya sapherd // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg304_xmage_creature_etb_token_wave_20260701_123004;

COMMIT;
