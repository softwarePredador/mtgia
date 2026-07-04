BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('barbarian general', 'lady zhurong, warrior queen', 'lu meng, wu general', 'shu cavalry', 'shu elite companions', 'wei elite companions', 'wei scout', 'wei strike force', 'wu elite cavalry', 'wu light cavalry')
   OR normalized_name LIKE 'barbarian general // %'
   OR normalized_name LIKE 'lady zhurong, warrior queen // %'
   OR normalized_name LIKE 'lu meng, wu general // %'
   OR normalized_name LIKE 'shu cavalry // %'
   OR normalized_name LIKE 'shu elite companions // %'
   OR normalized_name LIKE 'wei elite companions // %'
   OR normalized_name LIKE 'wei scout // %'
   OR normalized_name LIKE 'wei strike force // %'
   OR normalized_name LIKE 'wu elite cavalry // %'
   OR normalized_name LIKE 'wu light cavalry // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg424_xmage_static_horsemanship_new_server_20260704_1920;

COMMIT;
