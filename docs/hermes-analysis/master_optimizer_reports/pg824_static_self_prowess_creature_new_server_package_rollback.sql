BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('bloodfire expert', 'dragon bell monk', 'dragon-style twins', 'elementalist adept', 'iguana parrot', 'jeskai brushmaster', 'jeskai student', 'jeskai windscout', 'lightning visionary', 'lotus path djinn', 'mistral singer', 'monastery swiftspear', 'niblis of dusk', 'nimble-blade khenra', 'ringwarden owl', 'riverwheel aerialists', 'sanguinary mage', 'stormchaser mage', 'thor odinson', 'umara entangler', 'vedalken blademaster', 'whirlwind adept', 'wing commando')
   OR normalized_name LIKE 'bloodfire expert // %'
   OR normalized_name LIKE 'dragon bell monk // %'
   OR normalized_name LIKE 'dragon-style twins // %'
   OR normalized_name LIKE 'elementalist adept // %'
   OR normalized_name LIKE 'iguana parrot // %'
   OR normalized_name LIKE 'jeskai brushmaster // %'
   OR normalized_name LIKE 'jeskai student // %'
   OR normalized_name LIKE 'jeskai windscout // %'
   OR normalized_name LIKE 'lightning visionary // %'
   OR normalized_name LIKE 'lotus path djinn // %'
   OR normalized_name LIKE 'mistral singer // %'
   OR normalized_name LIKE 'monastery swiftspear // %'
   OR normalized_name LIKE 'niblis of dusk // %'
   OR normalized_name LIKE 'nimble-blade khenra // %'
   OR normalized_name LIKE 'ringwarden owl // %'
   OR normalized_name LIKE 'riverwheel aerialists // %'
   OR normalized_name LIKE 'sanguinary mage // %'
   OR normalized_name LIKE 'stormchaser mage // %'
   OR normalized_name LIKE 'thor odinson // %'
   OR normalized_name LIKE 'umara entangler // %'
   OR normalized_name LIKE 'vedalken blademaster // %'
   OR normalized_name LIKE 'whirlwind adept // %'
   OR normalized_name LIKE 'wing commando // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg824_pg824_static_self_prowess_creature_20260712_095650;

COMMIT;
