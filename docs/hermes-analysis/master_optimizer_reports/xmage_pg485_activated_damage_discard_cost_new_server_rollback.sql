BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('fodder tosser', 'kris mage')
   OR normalized_name LIKE 'fodder tosser // %'
   OR normalized_name LIKE 'kris mage // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg485_activated_damage_discard_cost_new_20260705_055422;

COMMIT;
