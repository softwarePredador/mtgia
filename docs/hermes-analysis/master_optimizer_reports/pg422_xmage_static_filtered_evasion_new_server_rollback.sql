BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('amrou kithkin', 'amrou seekers', 'arlinn''s wolf', 'barrenton cragtreads', 'bog rats', 'deathcult rogue', 'dread warlock', 'duskmantle operative', 'fleet-footed monk', 'goldmeadow dodger', 'kor castigator', 'mudbrawler raiders', 'prowling nightstalker', 'rampart crawler', 'raven''s run dragoon', 'river darter', 'rubblebelt runner', 'sacred knight', 'skirk shaman', 'sootwalkers', 'wanderbrine rootcutters')
   OR normalized_name LIKE 'amrou kithkin // %'
   OR normalized_name LIKE 'amrou seekers // %'
   OR normalized_name LIKE 'arlinn''s wolf // %'
   OR normalized_name LIKE 'barrenton cragtreads // %'
   OR normalized_name LIKE 'bog rats // %'
   OR normalized_name LIKE 'deathcult rogue // %'
   OR normalized_name LIKE 'dread warlock // %'
   OR normalized_name LIKE 'duskmantle operative // %'
   OR normalized_name LIKE 'fleet-footed monk // %'
   OR normalized_name LIKE 'goldmeadow dodger // %'
   OR normalized_name LIKE 'kor castigator // %'
   OR normalized_name LIKE 'mudbrawler raiders // %'
   OR normalized_name LIKE 'prowling nightstalker // %'
   OR normalized_name LIKE 'rampart crawler // %'
   OR normalized_name LIKE 'raven''s run dragoon // %'
   OR normalized_name LIKE 'river darter // %'
   OR normalized_name LIKE 'rubblebelt runner // %'
   OR normalized_name LIKE 'sacred knight // %'
   OR normalized_name LIKE 'skirk shaman // %'
   OR normalized_name LIKE 'sootwalkers // %'
   OR normalized_name LIKE 'wanderbrine rootcutters // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg422_xmage_static_filtered_evasion_new_server_20260704_;

COMMIT;
