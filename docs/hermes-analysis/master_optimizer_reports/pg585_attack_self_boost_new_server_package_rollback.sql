BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('benalish veteran', 'borderland marauder', 'bramble creeper', 'brazen wolves', 'charging bandits', 'charging paladin', 'flowstone charger', 'graceful cat', 'hollow dogs', 'jumbo cactuar', 'kiln walker', 'lurking nightstalker', 'reckless pangolin', 'steadfast cathar', 'vicious kavu', 'wei ambush force')
   OR normalized_name LIKE 'benalish veteran // %'
   OR normalized_name LIKE 'borderland marauder // %'
   OR normalized_name LIKE 'bramble creeper // %'
   OR normalized_name LIKE 'brazen wolves // %'
   OR normalized_name LIKE 'charging bandits // %'
   OR normalized_name LIKE 'charging paladin // %'
   OR normalized_name LIKE 'flowstone charger // %'
   OR normalized_name LIKE 'graceful cat // %'
   OR normalized_name LIKE 'hollow dogs // %'
   OR normalized_name LIKE 'jumbo cactuar // %'
   OR normalized_name LIKE 'kiln walker // %'
   OR normalized_name LIKE 'lurking nightstalker // %'
   OR normalized_name LIKE 'reckless pangolin // %'
   OR normalized_name LIKE 'steadfast cathar // %'
   OR normalized_name LIKE 'vicious kavu // %'
   OR normalized_name LIKE 'wei ambush force // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg585_attack_self_boost_new_server_20260707_014926;

COMMIT;
