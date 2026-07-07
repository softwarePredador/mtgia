BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('catapult squad', 'ghirapur aether grid', 'hand of justice', 'kyren negotiations', 'nullmage shepherd')
   OR normalized_name LIKE 'catapult squad // %'
   OR normalized_name LIKE 'ghirapur aether grid // %'
   OR normalized_name LIKE 'hand of justice // %'
   OR normalized_name LIKE 'kyren negotiations // %'
   OR normalized_name LIKE 'nullmage shepherd // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg632_activated_tap_cost_new_server_20260707_190216;

COMMIT;
