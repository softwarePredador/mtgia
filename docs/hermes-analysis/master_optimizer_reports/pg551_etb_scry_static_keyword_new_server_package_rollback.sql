BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('augury owl', 'cloudreader sphinx', 'faerie seer', 'glider kids', 'grey havens navigator', 'horizon scholar', 'senate griffin', 'silver raven', 'thaumaturge''s familiar', 'wall of runes', 'willow-wind')
   OR normalized_name LIKE 'augury owl // %'
   OR normalized_name LIKE 'cloudreader sphinx // %'
   OR normalized_name LIKE 'faerie seer // %'
   OR normalized_name LIKE 'glider kids // %'
   OR normalized_name LIKE 'grey havens navigator // %'
   OR normalized_name LIKE 'horizon scholar // %'
   OR normalized_name LIKE 'senate griffin // %'
   OR normalized_name LIKE 'silver raven // %'
   OR normalized_name LIKE 'thaumaturge''s familiar // %'
   OR normalized_name LIKE 'wall of runes // %'
   OR normalized_name LIKE 'willow-wind // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg551_etb_scry_static_keyword_new_server_20260706_050009;

COMMIT;
