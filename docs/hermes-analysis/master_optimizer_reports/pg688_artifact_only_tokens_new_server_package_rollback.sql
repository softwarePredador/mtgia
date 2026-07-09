BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('argothian opportunist', 'beamsaw prospector', 'blood servitor', 'cartographer''s companion', 'crustacean commando', 'falkenrath celebrants', 'fierce witchstalker', 'forecasting fortune teller', 'galactic wayfarer', 'koilos roc', 'mintstrosity', 'powerstone engineer', 'slithering cryptid', 'spyglass siren', 'stone retrieval unit', 'waterwind scout')
   OR normalized_name LIKE 'argothian opportunist // %'
   OR normalized_name LIKE 'beamsaw prospector // %'
   OR normalized_name LIKE 'blood servitor // %'
   OR normalized_name LIKE 'cartographer''s companion // %'
   OR normalized_name LIKE 'crustacean commando // %'
   OR normalized_name LIKE 'falkenrath celebrants // %'
   OR normalized_name LIKE 'fierce witchstalker // %'
   OR normalized_name LIKE 'forecasting fortune teller // %'
   OR normalized_name LIKE 'galactic wayfarer // %'
   OR normalized_name LIKE 'koilos roc // %'
   OR normalized_name LIKE 'mintstrosity // %'
   OR normalized_name LIKE 'powerstone engineer // %'
   OR normalized_name LIKE 'slithering cryptid // %'
   OR normalized_name LIKE 'spyglass siren // %'
   OR normalized_name LIKE 'stone retrieval unit // %'
   OR normalized_name LIKE 'waterwind scout // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg688_pg688_artifact_only_tokens_new_ser_20260709_033512;

COMMIT;
